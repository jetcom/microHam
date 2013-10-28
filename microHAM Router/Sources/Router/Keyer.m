//
//  Keyer.m
//  µH Router
//
//  Created by Kok Chen on 5/2//06.
	#include "Copyright.h"
	

#import "Keyer.h"
#include "Router.h"
#include "LogMacro.h"

//  This is the layer that talks to the physical keyer.
//  Each time a port is open to the device, Keyer will create a thread to monitor the status from the device.

@implementation Keyer

- (id)initFromRouter:(Router*)client writeLock:(NSLock*)lock
{
	self = [ super init ] ;
	if ( self ) {
		fd = -1 ;
		errorCode = 0 ;
		byteOrderInFrame = 0 ;
		stream = path = nil ;
		router = client ;
		heartbeat = nil ;
		reopenOnWakeup = NO ;
		writeLock = [ lock retain ] ;
		debug = NO ;
	}
	return self ;
}

- (void)dealloc
{
	if ( stream ) [ stream release ] ;
	if ( path ) [ path release ] ;
	if ( writeLock ) [ writeLock release ] ;
	if ( fd > 0 ) close( fd ) ;
	[ super dealloc ] ;
}

- (Boolean)debug
{
	return debug ;
}

- (void)setDebug:(Boolean)state
{
	debug = state ;
}

- (NSLock*)writeLock
{
	return writeLock ;
}

- (void)writeFrames:(unsigned char*)array length:(int)length
{
	if ( fd > 0 ) {
		Log( debug, "send %d frames\n", length/4 ) ;
		[ writeLock lock ] ;
		write( fd, array, length ) ;
		[ writeLock unlock ] ;
	}
}

//  write a single frame of four bytes
- (void)writeFrame:(unsigned char*)array
{
	if ( fd > 0 ) {
		Log( debug, "send frame %02x %02x %02x %02x\n", array[0],  array[1],  array[2],  array[3] ) ;
		[ writeLock lock ] ;
		write( fd, array, 4 ) ;
		[ writeLock unlock ] ;
	}
}

- (void)setStream:(NSString*)name
{
	if ( stream ) return ; // use the first one that is found
	stream = [ name retain ] ;
}

- (void)setPath:(NSString*)name
{
	if ( path ) return ; // use the first one that is found
	path = [ name retain ] ;
}

- (NSString*)path
{
	return path ;
}

- (Boolean)opened
{
	return ( fd > 0 ) ;
}

- (int)errorCode
{
	return errorCode ;
}

//  return true if opened
- (Boolean)openSerialDevice
{
	char msg[256] ;
	struct termios options ;
	
	if ( fd > 0 ) return YES ;
	
	if ( path ) {
		//  Unix path exist for device, try opening it as a serial port
		fd = open( [ path UTF8String  ], O_RDWR ) ; // | O_NOCTTY ) ; // | O_NDELAY ) ;
		if ( fd < 0 ) errorCode = errno ;
		if ( fd >= 0 ) {
			if ( fcntl( fd, F_SETFL, 0 ) >= 0 ) {
				// Get the current options and save them for later reset
				tcgetattr( fd, &originalTTYAttrs ) ;
				// These options are documented in the man page for termios
				// (in Terminal enter: man termios)
				options = originalTTYAttrs ;
				// set device to 230400 baud, 8 bits no parity,one stop
				options.c_cflag = (CS8) | (CREAD) | (CLOCAL) ;			// set flags first for Linux compatibility
				cfsetispeed( &options, B230400 ) ;
				cfsetospeed( &options, B230400 ) ;
				// Set raw input, 1 minute timeout
				options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
				options.c_oflag &= ~OPOST;
				options.c_cc[ VMIN ] = 0;
				options.c_cc[ VTIME ] = 255 ;
				// Set the options
				tcsetattr( fd, TCSANOW, &options ) ;
				[ NSThread detachNewThreadSelector:@selector(scannerThread:) toTarget:self withObject:self ] ;
				[ self startHeartbeat ] ;
				return YES ;
			}
			close( fd ) ;
			fd = -1 ;
			sprintf( msg, "Problem with port named \"%s\".", [ stream UTF8String  ] ) ;
			[ self alertMessage:@"Cannot execute fcntl." informativeText:[ NSString stringWithCString:msg ] ] ;
			return NO ;
		}
		//  could not open or set
		sprintf( msg, "Problem with port named \"%s\".", [ stream UTF8String  ] ) ;
		[ self alertMessage:@"Cannot open port." informativeText:[ NSString stringWithCString:msg ] ] ;
	}
	return NO ;
}

- (void)closeSerialDevice
{
	if ( fd > 0 ) {
		[ self stopHeartbeat ] ;
		close( fd ) ;
		fd = -1 ;
		errorCode = 0 ;
	}
}

//  periodic calls to send heartbeat to the device
- (void)heartbeat:(NSTimer*)timer
{
	[ router sendHeartbeat ] ;
}

- (void)startHeartbeat
{
	float period ;
	
	period = 5.0 + ( rand() & 0xff )/512.0 ;
	[ router sendHeartbeat ] ;  //  send the initial heartbeat
	heartbeat = [ NSTimer scheduledTimerWithTimeInterval:period target:self selector:@selector(heartbeat:) userInfo:self repeats:YES ] ;
}

//  stop heartbeat timer if it is running
- (void)stopHeartbeat
{
	if ( heartbeat ) {
		[ heartbeat invalidate ] ;
		heartbeat = nil ;
	}
}

//  background thread to scan data from the device
//	when a frame of four bytes having the correct FRAME SYNC pattern is collected, the frame is submitted to the parser in Router.m.
- (void)scannerThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int n ;
	unsigned char frame[5], byte ;

	while ( 1 ) {
		n = read( fd, &byte, 1 ) ;
		[ router receivedByteInScanner: byte ] ;
		
		if ( n == 0 ) /* line input timed out */ continue ;
		if ( n < 0 ) /* closed */ break ;		
		if ( ( byte & 0x80  ) == 0 ) {
			//  first byte in frame
			if ( ( byteOrderInFrame%4 ) != 0 ) {
				Log( 1, "read: out of order byte %02x, expected first byte\n", byte ) ;
				frame[byteOrderInFrame] = byte ;
				[ router framingError:frame byteOrder:byteOrderInFrame%4 ] ;
			}
			frame[0] = byte ;
			byteOrderInFrame = 1 ;
		}
		else {
			//  not first byte in frame
			if ( byteOrderInFrame <= 3 ) {
				frame[byteOrderInFrame] = byte ;
				byteOrderInFrame++ ;
				if ( byteOrderInFrame == 4 ) [ router parseFrame:frame ] ;
			}
			else {
				Log( 1, "read: out of order byte %02x, expected internal byte\n", byte ) ;
				[ router missingFrameSync:byte ] ;
			}
		}
	}
	printf( "mHRouter: scannerThread error\n" ) ;
	//  abort polling when an error is seen
	[ pool release ] ;
}

- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info
{
	[ [ NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] runModal ] ;
}

//  Sleep Manager
//	To handle devices that don't handle sleep well, when the system is about to go to sleep, first stop sending 
//	heartbeats and then close the serial port of an active device.  Mark the keyer as requiring re-opening.
//	When the system wakes up, the closed serial ports are reopened.
- (void)aboutToSleep
{
	if ( fd > 0 ) {
		[ self stopHeartbeat ] ;
		[ self closeSerialDevice ] ;
		reopenOnWakeup = YES ;
	}
}

//  Reopen a serial port and resume sending heartbeats to an active device
- (void)wakeFromSleep
{
	if ( reopenOnWakeup ) {
		reopenOnWakeup = NO ;
		[ self openSerialDevice ] ;
		[ self startHeartbeat ] ;
	}
}

@end
