//
//  Controller.m
//  µH Utils
//
//  Created by Kok Chen on 7/21/06.

#import "Controller.h"
#include "Downloader.h"
#import <IOKit/IOMessage.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/usb/IOUSBLib.h>
#include <termios.h>


#define Log( debug, s,... )	{ if ( debug ) NSLog( [ NSString stringWithCString:s ], ##__VA_ARGS__ ) ; }

//  µH Utils is a Utility program for the microHam keyers
//
//  It current only has the firmware downloader, but when there is need to do other things with the keyer, I will be
//  adding to this program.

@implementation Controller

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
	
		[ [ NSAlert alertWithMessageText:@"Please make sure µH Router is not running!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Any other application that connects to the keyer can interfere with the downloads.\n\nBe sure the µH Router or any logging software that connects to the keyer are not running.\n" ] runModal ] ;

		debug = NO ;
		devices = 0 ;
		fd = 0 ;
		hasFirmware = NO ;
		downloadLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	NSString *name ;
	int i ;
	
	[ window setLevel:kCGNormalWindowLevel ] ; 
	[ window orderFront:self ] ; 
	[ window setHidesOnDeactivate:NO ] ; 
	
	[ tab setHidden:YES ] ;
	
	[ self pickupMicroHamDevices ] ;
	if ( devices ) {
		for ( i = 0; i < devices; i++ ) {
			name = [ stream[i] substringFromIndex:10 ] ;
			[ deviceMenu insertItemWithTitle:name atIndex:i ] ;
		}
		[ deviceMenu removeItemAtIndex:i ] ;
		[ deviceMenu selectItemAtIndex:0 ] ;
	}
	
	[ self setInterface:connectButton to:@selector(connectButtonPressed) ] ;
	[ self setInterface:downloadButton to:@selector(downloadButtonPressed) ] ;
	[ self setInterface:bootloadButton to:@selector(bootloadButtonPressed) ] ;
}

//  (local) find all serial port on the computer
//  collect the stream name and the Unix device path name for each one and return the number that is found
- (int)findPorts:(NSString**)tpath stream:(NSString**)tstream max:(int)maxCount
{
    kern_return_t kernResult ; 
    mach_port_t masterPort ;
	io_iterator_t serialPortIterator ;
	io_object_t modemService ;
    CFMutableDictionaryRef classesToMatch ;
	CFTypeRef cfString ;
	int count ;

    kernResult = IOMasterPort( MACH_PORT_NULL, &masterPort ) ;
    if ( kernResult != KERN_SUCCESS ) return 0 ;
	
    classesToMatch = IOServiceMatching( kIOSerialBSDServiceValue ) ;
    if ( classesToMatch == NULL ) return 0 ;

	// get iterator for serial ports (ignore modems)
	CFDictionarySetValue( classesToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDRS232Type) ) ;
    kernResult = IOServiceGetMatchingServices( masterPort, classesToMatch, &serialPortIterator ) ;    
	// walk through the iterator
	count = 0 ;
	while ( ( modemService = IOIteratorNext( serialPortIterator ) ) && count < maxCount ) {
        cfString = IORegistryEntryCreateCFProperty( modemService, CFSTR(kIOTTYDeviceKey), kCFAllocatorDefault, 0 ) ;
        if ( cfString ) {
			tstream[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
            CFRelease( cfString ) ;
			cfString = IORegistryEntryCreateCFProperty( modemService, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0 ) ;
			if ( cfString )  {
				tpath[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
				CFRelease( cfString ) ;
				count++ ;
			}
		}
        IOObjectRelease( modemService ) ;
    }
	IOObjectRelease( serialPortIterator ) ;
	return count ;
}

//  pick out the path and stream of microHam ports from the available devices
//	if multiple devices (e.g., 2 microKEYERS) exist, this method picks the first one
- (void)pickupMicroHamDevices
{
	NSString *check ;
	int i, j, ports ;
	NSString *tstream[32] ;
	NSString *tpath[32] ;
	NSString *deviceName[4] = { @"usbserial-MK", @"usbserial-DK", @"usbserial-CK", @"usbserial-M2" } ;

	//  find all serial ports
	ports = [ self findPorts:&tpath[0] stream:&tstream[0] max:32 ] ;
	//  now find the ones that are associated with the microHAM devices
	for ( i = 0; i < ports; i++ ) {
		check = ( [ tstream[i] length ] < 13 ) ? @"" : [ tstream[i] substringToIndex:12 ] ;
		for ( j = 0; j < 4; j++ ) {
			if ( [ check isEqualToString:deviceName[ j ] ] ) {
				Log( debug, "Found device %s\n", [ tstream[i] cString ] ) ;
				stream[ devices ] = [ [ NSString alloc ] initWithString:tstream[i] ] ;
				path[ devices ] = [ [ NSString alloc ] initWithString:tpath[i] ] ;
				devices++ ;
				break ;
			}
		}
		[ tstream[i] release ] ;
		[ tpath[i] release ] ;
	}
}

- (void)openConnection
{
	int index ;
	struct termios originalTTYAttrs, options ;
	Utility *utility ;
	Boolean debugSave ;
	NSString *string ;
	
	bundleFolder = nil ;
	[ versionField setStringValue:@"" ] ;
	[ versionField display ] ;
	index = [ deviceMenu indexOfSelectedItem ] ;
	if ( fd > 0 ) close( fd ) ;
	
	[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.025 ] ] ;	
	
	
	fd = open( [ path[index] cString ], O_RDWR ) ; // | O_NOCTTY ) ; // | O_NDELAY ) ;
	if ( fd > 0 ) {
		if ( fcntl( fd, F_SETFL, 0 ) >= 0 ) {
			// Get the current options and save them for later reset
			tcgetattr( fd, &originalTTYAttrs ) ;
			// These options are documented in the man page for termios
			// (in Terminal enter: man termios)
			options = originalTTYAttrs ;
			// set device to 230400 baud, 8 bits no parity,one stop
			cfsetispeed( &options, B230400 ) ;
			cfsetospeed( &options, B230400 ) ;
			options.c_cflag = (CS8) | (CREAD) | (CLOCAL) ;
			// Set raw input, 1 minute timeout
			options.c_lflag &= ~( ICANON | ECHO | ECHOE | ISIG);
			options.c_oflag &= ~OPOST;
			options.c_cc[ VMIN ] = 0;
			options.c_cc[ VTIME ] = 255 ;
			// Set the options
			tcsetattr( fd, TCSANOW, &options ) ;
			
			[ NSThread detachNewThreadSelector:@selector(readThread:) toTarget:self withObject:self ] ;
		
				
			debugSave = debug ;
			debug = NO ;
			utility = [ [ Utility alloc ] initWithClient:self ] ;
			hasFirmware = [ utility getVersion:&app bootloader:&bootloader from:fd ] ;
			[ utility release ] ;
			debug = debugSave ;
			
			string = ( hasFirmware ) ? [ NSString stringWithFormat:@ "Firmware version %d.%d\n", app.major, app.minor ] : @"No response from keyer!  Check 12 volt suppy to the keyer." ;
			[ versionField setStringValue:string ] ;
			
			[ tab setHidden:!hasFirmware ] ;
			if ( bundleFolder ) [ bundleFolder release ] ;
			bundleFolder = nil ;

			if ( hasFirmware ) {
				NSBundle *bundle = [ NSBundle mainBundle ];
				bundleFolder = [ [ NSString alloc ] initWithString:[ bundle bundlePath ] ] ;
				Log( debug, "opened %s\n", [ path[index] cString ] ) ;
				[ connectButton setTitle:@"Disconnect" ] ;
			}
			else {
				close( fd ) ;
				fd = 0 ;
			}
			return ;
		}
	}
	Log( debug, "cannot open port\n" ) ;
}

- (void)closeConnection
{
	close( fd ) ;
	fd = 0 ;
	[ connectButton setTitle:@"Connect" ] ;
	[ versionField setStringValue:@"" ] ;
	[ tab setHidden:YES ] ;
}

- (void)connectButtonPressed
{
	if ( fd <= 0 ) [ self openConnection ] ; else [ self closeConnection ] ;
}

//  this thread reads the input from the device (prevents blocking of other threads)
- (void)readThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	unsigned char buf ;
	int n ;
	
	producer = consumer = 0 ;
	while ( 1 ) {
		n = read( fd, &buf, 1 ) ;
		if ( n <= 0 ) break ;
		ring[ producer&0xfff ] = buf ;
		Log( debug, "input: %02x\n", buf ) ;
		producer++ ;
	}
	Log( debug, "port closed\n" ) ;
	[ pool release ] ;
}

- (void)resetBuffer
{
	producer = consumer = 0 ;
}

- (int)buflen
{
	int n ;
	
	n = ( producer - consumer ) ;
	return n ;
}

//  read up to length characters
- (int)read:(unsigned char*)buf length:(int)len
{
	int i, n ;
	
	n = ( producer - consumer ) ;
	if ( n < len ) len = n ;
	for ( i = 0; i < len; i++ ) {
		buf[i] = ring[ consumer&0xfff ] ;
		consumer++ ;
	}
	return len ;
}

- (void)downloadButtonPressed
{
	if ( fd > 0 ) {
		if ( [ downloadLock tryLock ] ) {
			[ downloadLock unlock ] ;
			//  do actual downloading away from main thread
			[ NSThread detachNewThreadSelector:@selector(downloadThread:) toTarget:self withObject:self ] ;	
		}
	}
	else Log( debug, "Not connected\n" ) ;
}

- (void)bootloadButtonPressed
{
	if ( fd > 0 ) {
		if ( [ downloadLock tryLock ] ) {
			[ downloadLock unlock ] ;
			//  do actual downloading away from main thread
			[ NSThread detachNewThreadSelector:@selector(bootloadThread:) toTarget:self withObject:self ] ;	
		}
	}
	else Log( debug, "Not connected\n" ) ;
}

- (void)outputMessage:(NSString*)msg
{
	[ versionField setStringValue:msg ] ;
	[ versionField display ] ;
}

- (void)downloadThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	NSString *resourceFolder ;
	NSString *subDirectory ;
	
	[ downloadLock lock ] ;
	if ( bundleFolder ) {	
	
		subDirectory = ( [ [ [ deviceMenu title ] substringToIndex:2 ] isEqualToString:@"M2" ] == YES ) ? @"microKeyer II" : @"microKeyer" ;
		
		resourceFolder = [ [ bundleFolder stringByAppendingString:@"/Contents/Resources/" ] stringByAppendingString:subDirectory ] ;
		if ( [ (Downloader*)downloader loadFile:resourceFolder ] ) {
			[ (Downloader*)downloader downloadTo:fd client:self ] ;
		}
	}
	[ downloadLock unlock ] ;
	[ pool release ] ;
}

- (void)bootloadThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int response ;
	NSString *resourceFolder ;

	[ downloadLock lock ] ;
	response = [ [ NSAlert alertWithMessageText:@"Ready to Download" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Power off the keyer and Click on OK (or hit Return) within 1.5 seconds after turning the power to the keyer back on." ] runModal ] ;
	
	if ( response == 1 ) {
		if ( bundleFolder ) {
			resourceFolder = [ bundleFolder stringByAppendingString:@"/Contents/Resources/" ] ;
			if ( [ (Downloader*)downloader loadFile:resourceFolder ] ) {
				[ (Downloader*)downloader bootloadTo:fd client:self ] ;
			}
		}
	}
	else Log( debug, "Bootload cancelled\n" ) ;
	
	[ downloadLock unlock ] ;
	[ pool release ] ;
}


#ifdef NOTBEINGUSED
//  ---------- device connect notification (not currently used) --------------

//  callback notification when device added
void deviceAddedProc(void *refcon, io_iterator_t iterator )
{
	NSLog( @"device connected\n" ) ;
	//  Controller *ctrl = ( Controller* )refcon ;	
	//  [ NSThread detachNewThreadSelector:@selector(deviceAddedThread:) toTarget:ctrl withObject:ctrl ] ;	
}

//  callback notification when device removed
void deviceRemovedProc(void *refcon, io_iterator_t iterator )
{
	NSLog( @"device removed\n" ) ;
}

- (void)startNotification
{
	CFMutableDictionaryRef matchingDict ;
	io_object_t serialPortService ;
	
	notificationPort = IONotificationPortCreate( kIOMasterPortDefault ) ;
	CFRunLoopAddSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource( notificationPort ), kCFRunLoopDefaultMode ) ;
	matchingDict = IOServiceMatching( kIOSerialBSDServiceValue ) ;
	CFRetain( matchingDict ) ;
	CFDictionarySetValue( matchingDict, CFSTR(kIOSerialBSDTypeKey), CFSTR( kIOSerialBSDAllTypes ) ) ;
	
	IOServiceAddMatchingNotification( notificationPort, kIOFirstMatchNotification, matchingDict, deviceAddedProc, self, &addIterator ) ;
	while ( serialPortService = IOIteratorNext( addIterator ) ) IOObjectRelease( serialPortService ) ;

	IOServiceAddMatchingNotification( notificationPort, kIOTerminatedNotification, matchingDict, deviceRemovedProc, self, &removeIterator ) ;
	while ( serialPortService = IOIteratorNext( removeIterator ) ) IOObjectRelease( serialPortService ) ;
}

- (void)stopNotification
{
	IOObjectRelease( addIterator ) ;
	addIterator = nil ; 
	
	IOObjectRelease( removeIterator ) ;
	removeIterator = nil ;

	CFRunLoopRemoveSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource( notificationPort ), kCFRunLoopDefaultMode ) ;
	IONotificationPortDestroy( notificationPort ) ;
	notificationPort = nil ;
}
#endif

@end
