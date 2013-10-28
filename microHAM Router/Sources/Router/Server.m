//
//  Server.m
//  µH Router
//
//  Created by Kok Chen on 5/23/06.
	#include "Copyright.h"
	
	
#import "Server.h"
#include "LogMacro.h"
#include "Router.h"
#include "RouterCommands.h"
#include <sys/stat.h>


@implementation Server

#define	LATENCYTIMEOUT	60				//  v1.20

//  v1.30 returns latency from last written time, not current time
static int fifoLatency( int fd )
{
	struct stat filestat ;

	if ( fstat( fd, &filestat ) != 0 ) return 100000 ;
	//return time( nil ) - filestat.st_atime ;
	return filestat.st_mtime - filestat.st_atime ;			//  v1.30
}


//  Server.m is the µH Router's endpoint to the clients (cocoaModem, MacLoggerDX, etc)
//
//	Each device has its own router/server/keyer objects.

//  millisecond date string  v1.11j
- (NSString*)dateString
{
	NSTimeInterval interval = [ NSDate timeIntervalSinceReferenceDate ] ;
	NSDate *tdate = [ NSDate dateWithTimeIntervalSinceReferenceDate:interval  ] ;
	NSCalendarDate *cDate =[ tdate dateWithCalendarFormat:@"%H:%M:%S" timeZone:nil ] ;
	
	int hour = [ cDate hourOfDay ] ;
	int min = [ cDate minuteOfHour ] ;
	int sec = [ cDate secondOfMinute ] ;

	interval -= 255370000 ;
	long intv = interval*1000  ;
	long tint =  interval ;
	int msec = intv - tint*1000 ;
	
	return [ NSString stringWithFormat:@"%02d:%02d:%02d.%03d", hour, min, sec, msec ] ;
}

- (id)initWithName:(NSString*)fifoName router:(Router*)control writeLock:(NSLock*)lock
{
	int fd ;
	NSDate *date ;
	SelectInfo *info ;
	
	self = [ super init ] ;
	if ( self ) {
		router = control ;
		baseName = [ fifoName retain ] ;
		radioAggregateTimeout = 0.02 ;		//  20 ms -- best for FT-1000MP
		debugRadioPort = NO ;
		debugRadioPortCount = 0 ;
		
		//  identify the keyer
		NSString *devName = [ baseName lastPathComponent ] ;
		deviceType = DIGIKEYER ;
		if ( [ devName isEqualToString:@"microRouter" ] ) deviceType = MICROKEYER ;
		else if ( [ devName isEqualToString:@"cwRouter" ] ) deviceType = CWKEYER ;
		
		writeLock = [ lock retain ] ;
		debug = NO ;
		logToConsole = NO ;		//  v1.11
		
		//  control packet filtering
		previous78Value = -1 ;
		current78Index = 0 ;
		//  heartbeat and LCD filtering
		passHeartbeat = passLCD = NO ;
		filteredTail = 0 ;
		//  start with null set for select()
		portCount = 0 ;
		actualSetSize = 0 ;
		hasWinKey = hasFSK = YES ;
		FD_ZERO( &selectSet ) ;
		
		date = [ [ NSDate alloc ] init ] ;		
		for ( fd = 0; fd < FD_SETSIZE; fd++ ) {
			info = &readSelect[fd] ;
			info->type = 0 ;
			info->fifo = nil ;
			info->routerfd = 0 ;			
			info->pending = NO ;
			info->timestamp = [ date retain ] ;
			info->writeOnly = NO ;			//  v1.13
			
			radiofd[fd] = controlfd[fd] = pttfd[fd] = cwfd[fd] = rtsfd[fd] = winkeyfd[fd] = fskfd[fd] = flagsfd[fd] = 0 ;
		}
		[ date release ] ;
		
		//  create a backdoor router fifo (Unix named pipe). 
		//  As the server, we read from the client's "Write" fifo.
		//  NOTE: the usual way a client talks to a router is to as the master port for a router fifo instead of using this backdoor
		//  The backdoor in addition to AppleScripts can be used for debugging
		
		//  backdoor names are /tmp/microRouterWrite, /tmp/cwRouterWrite, /tmp/digiRouterWrite
		
		backdoorFIFO = [ [ NamedFIFOPair alloc ] initWithPipeName:[ baseName UTF8String  ] ] ;		
		if ( backdoorFIFO ) {
				if ( [ backdoorFIFO inputFileDescriptor ] > 0 && [ backdoorFIFO outputFileDescriptor ] > 0 ) {
				[ self insertIntoSelectSet:backdoorFIFO type:ROUTERPORT router:0 writeOnly:NO ] ;
				//  start the server thread to listen for and respond to requests
				[ NSThread detachNewThreadSelector:@selector(serverThread:) toTarget:self withObject:self ] ;
			}
		}
	}
	return self ;
}

- (void)dealloc
{
	if ( backdoorFIFO ) [ backdoorFIFO release ] ;
	if ( writeLock ) [ writeLock release ] ;
	[ super dealloc ] ;
}

//  v1.11t
- (void)setRadioAggregateTimeout:(float)value
{
	radioAggregateTimeout = value ;
}

- (Boolean)hasWinKey
{
	return hasWinKey ;
}

- (void)setHasWinKey:(Boolean)state
{
	hasWinKey = state ;
}

- (Boolean)hasFSK
{
	return hasFSK ;
}

- (void)setHasFSK:(Boolean)state
{
	hasFSK = state ;
}

- (Boolean)debug
{
	return debug ;
}

- (void)setDebug:(Boolean)state
{
	debug = state ;
}

//  this will cause the server thread to exit
- (void)quitKeyer
{
	char buf = _QUITKEYER_ ;
	[ writeLock lock ] ;				//  v1.11
	write( [ backdoorFIFO inputFileDescriptor ], &buf, 1 ) ;
	[ writeLock unlock ] ;
}

//  timestamps a request and turn on the pending flag so time need not be checked when the next data comes in
- (void)updateTimestamp:(NSDate*)time fd:(int)fd
{
	SelectInfo *info ;
	
	info = &readSelect[fd] ;
	[ info->timestamp release ] ;
	info->timestamp = [ time retain ] ;
	info->pending = YES ;
}

//  all this thread does is wait for requests from clients
- (void)serverThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int count, fd ;
	SelectInfo *info ;
	fd_set readSet, exceptionSet ;
	unsigned char buf[2] ;
	Boolean quit ;
	
	quit = NO ;
	while ( !quit ) {
		//  block indefinitely, waiting for a request from active file descriptors		
		FD_COPY( &selectSet, &readSet ) ;		
		FD_COPY( &selectSet, &exceptionSet ) ;	

		count = select( FD_SETSIZE, &readSet, nil, nil, nil ) ;				//  v 0.80
		if ( count < 0 ) break ;  //  select error
		if ( count > 0 ) {		
			deferredClose = 0 ;	
			for ( fd = 0; fd < actualSetSize && count > 0; fd++ ) {
			
				if ( FD_ISSET( fd, &readSet ) ) {				
				
					info = &readSelect[fd] ;
					count-- ;	//  reduce the count of fd is found
					
					switch( info->type ) {
					case ROUTERPORT:
						if ( [ self serverRequestReceived:fd ] == 0 ) quit = YES ;
						break ;
					case OPENPTT:
						[ self setFlagUsing:@selector(setPTT:) from:fd ] ;
						break ;
					case OPENCW:
						[ self setFlagUsing:@selector(setSerialCW:) from:fd ] ;
						break ;
					case OPENRTS:
						[ self setFlagUsing:@selector(setRTS:) from:fd ] ;
						break ;
					case OPENWINKEY:
						[ self sendStringUsing:@selector(setWINKEY:) from:fd ] ;
						break ;
					case OPENFSK:
						[ self sendStringUsing:@selector(setFSK:) from:fd ] ;
						break ;
					case OPENEMULATOR:
						[ self sendStringUsing:@selector(setWinKeyEmulate:) from:fd ] ;
						break ;
					case OPENCONTROL:
						[ self sendBytesUsing:@selector(setControl:length:) from:fd ] ;
						break ;
					case OPENRADIO:
					case OPENDEBUGRADIO:
						[ self sendBytesUsing:@selector(setRadio:length:) from:fd ] ;
						break ;
					case OPENFLAGS:
						//  do nothing to flags but just updating the timestamp 
						break ;
					default:
						Log( debug, "*** unimplemented select fd %d, flushing... ***\n", fd ) ;
						read( fd, buf, 1 ) ;
						break;
					}
				}
			}
			if ( deferredClose ) {
				if ( logToConsole ) NSLog( @"close all connections" ) ;
				[ self closeAllConnectionsTo:deferredClose ] ;
				deferredClose = 0 ;
			}
			if ( count > 0 && FD_ISSET( fd, &exceptionSet ) ) {
				count-- ;	//  reduce the count of fd if found
				Log( debug, "*** exception on fd %d ***\n", fd ) ;
			}
		}
		if ( count > 0 ) {
			for ( fd = 0; fd < FD_SETSIZE && count > 0; fd++ ) {
				if ( FD_ISSET( fd, &readSet ) ) {
					Log( debug, "*** unimplemented select fd %d, flushing... ***\n", fd ) ;
					read( fd, buf, 1 ) ;
				}
			}
		}
	}
	//  abort polling when an error is seen
	[ pool release ] ;
}

- (Boolean)inUse 
{
	int fd ;
	SelectInfo *info ;
	Boolean hasConnection ;
	
	for ( fd = 0; fd < FD_SETSIZE; fd++ ) {
		info = &readSelect[fd] ;
		if ( info->fifo && fd != [ backdoorFIFO inputFileDescriptor ] ) break ;
	}
	hasConnection = ( fd < FD_SETSIZE ) ;
	if ( logToConsole ) {
		for ( fd = 0; fd < FD_SETSIZE; fd++ ) {
			info = &readSelect[fd] ;
			if ( info->fifo && fd != [ backdoorFIFO inputFileDescriptor ] ) NSLog( @"Server:inUse: server is still connected to file descriptor %d", fd ) ;
		}
	}
	return hasConnection ;
}

//  create a fifo by appending a sequence number to the base FIFO name, e.g., /tmp//tmp/digiRouter1
- (NamedFIFOPair*)createNewFIFO
{
	NSString *fifoName ;
	
	fifoName = [ baseName stringByAppendingFormat:@"%d", portCount ] ;
	portCount++ ;
	return [ [ NamedFIFOPair alloc ] initWithPipeName:[ fifoName UTF8String  ] ] ;
}

//  Create a new FIFO with type ROUTERPORT to accept router requests (for getting ports and closing router connection).
//  Return base name (without "Read" or "Write") if successul, otherwise return empty string.
- (const char*)addClient
{
	NamedFIFOPair *fifo ;
	int readfd, writefd ;
	char buf = _UPDATEKEYER_ ;
	
	fifo = [ self createNewFIFO ] ;	
	if ( fifo != nil ) {
		readfd = [ fifo inputFileDescriptor ] ;
		writefd = [ fifo outputFileDescriptor ] ;
		if ( readfd > 0 && writefd > 0 ) {
			[ self insertIntoSelectSet:fifo type:ROUTERPORT router:0 writeOnly:NO ] ;
			//  send an update character to refresh the select set
			[ writeLock lock ] ;		//  v1.11
			write( [ backdoorFIFO inputFileDescriptor ], &buf, 1 ) ;
			[ writeLock unlock ] ;
			return [ fifo name ] ;
		}
	}
	return "" ;
}

//  create new fifo and send name to fd
//  v1.30 added write-only support
- (void)replyWithNewFIFO:(int)fd type:(int)type router:(int)readfd writeOnly:(Boolean)writeOnly
{
	const char *name ;
	NamedFIFOPair *fifo ;
			
	//  open a port to serve one of the functions
	fifo = [ self createNewFIFO ] ;
	//  insert into the select() set
	[ self insertIntoSelectSet:fifo type:type router:readfd writeOnly:writeOnly ] ;
	//  now send response back from the request
	name = [ fifo name ] ;
	[ writeLock lock ] ;
	write( fd, name, strlen( name )+1 ) ;
	[ writeLock unlock ] ;
}

//  close fifo and send name to fd
- (void)closeFIFO:(int)type router:(int)readfd
{
	//  insert into the select() set
	[ self removeFromSelectSet:type router:readfd ] ;
}

//  v1.11
- (void)writeNull:(int)fd
{
	[ writeLock lock ] ;
	NSLog( @"Bad client request\n" ) ;
	write( fd, "", 1 ) ;
	[ writeLock unlock ] ;
}

//  v1.30 -- support write only ports
- (int)serverRequestReceived:(int)readfd
{
	int n, type, writefd ;
	unsigned char buffer[2] ;
	NamedFIFOPair *fifo ;
	Boolean writeOnly ;
	
	fifo = readSelect[readfd].fifo ;	
	writefd = [ fifo outputFileDescriptor ] ;
	n = read( readfd, buffer, 1 ) ;	
	
	if ( n > 0 ) {
		type = buffer[0] ;
		writeOnly = ( ( type & WRITEONLY ) == WRITEONLY ) ;		//  v1.30 get write-only flag
		switch ( type  ) {
		case OPENRADIO:
		case OPENRADIO|WRITEONLY:
		case OPENCONTROL:
		case OPENCONTROL|WRITEONLY:
		case OPENPTT:
		case OPENPTT|WRITEONLY:
		case OPENCW:
		case OPENCW|WRITEONLY:
		case OPENRTS:
		case OPENRTS|WRITEONLY:
		case OPENFLAGS:
		case OPENFLAGS|WRITEONLY:
			type = type & ( ~WRITEONLY ) ;	//  v1.30 remove write-only from type
			if ( logToConsole ) NSLog( @"Open (%02x)%s command rceived from client with file descriptor %d", type, ( ( writeOnly ) ? " (write-only)" : ""  ) , readfd ) ;
			[ self replyWithNewFIFO:writefd type:type router:readfd writeOnly:writeOnly ] ;
			break ;
		case OPENDEBUGRADIO:
			if ( logToConsole ) NSLog( @"Open (%02x) command rceived from client with file descriptor %d", type , readfd ) ;
			[ self replyWithNewFIFO:writefd type:type router:readfd writeOnly:NO ] ;
			break ;
		case CLOSERADIO:
		case CLOSECONTROL:
		case CLOSEPTT:
		case CLOSECW:
		case CLOSERTS:
		case CLOSEFLAGS:
		case CLOSEDEBUGRADIO:
			if ( logToConsole ) NSLog( @"Close (%02x) command rceived from client with file descriptor %d", type, readfd ) ;			
			[ self closeFIFO:type router:readfd ] ;
			break ;
		case OPENFSK:
		case OPENFSK|WRITEONLY:
			//  CW KEYER has no FSK channel
			if ( hasFSK ) {
				[ self replyWithNewFIFO:writefd type:OPENFSK router:readfd writeOnly:writeOnly ] ; 
				if ( logToConsole ) NSLog( @"Open (%02x) command rceived from client with file descriptor %d", type, readfd ) ;
			}
			else [ self writeNull:writefd ] ;
			break ;
		case CLOSEFSK:
			//  CW KEYER has no FSK channel
			if ( hasFSK ) {
				[ self closeFIFO:CLOSEFSK router:readfd ] ;  
				if ( logToConsole ) NSLog( @"Close (%02x) command rceived from client with file descriptor %d", type, readfd ) ;
			}
			else [ self writeNull:writefd ] ;
			break ;
		case OPENWINKEY:
		case OPENWINKEY|WRITEONLY:
			//  DIGI KEYER has no Winkey channel
			if ( hasWinKey ) {
				[ self replyWithNewFIFO:writefd type:OPENWINKEY router:readfd writeOnly:writeOnly ] ; 
				if ( logToConsole ) NSLog( @"Open (%02x) command rceived from client with file descriptor %d", type, readfd ) ;
			}
			else [ self writeNull:writefd ] ;
			break ;
		case CLOSEWINKEY:
			//  DIGI KEYER has no Winkey channel
			if ( hasWinKey ) [ self closeFIFO:CLOSEWINKEY router:readfd ] ;  else [ self writeNull:writefd ] ;
			break ;
		case OPENEMULATOR:
		case OPENEMULATOR|WRITEONLY:
			//  WinKey emulator for DIGI KEYER
			if ( !hasWinKey ) {
				[ self replyWithNewFIFO:writefd type:OPENEMULATOR router:readfd writeOnly:writeOnly ] ; 
			}
			else [ self writeNull:writefd ] ;
			break ;
		case CLOSEEMULATOR:
			//  WinKey emulator for DIGI KEYER
			if ( !hasWinKey ) [ self closeFIFO:CLOSEEMULATOR router:readfd ] ; else [ self writeNull:writefd ] ;
			break ;
		case CLOSEKEYER:
			deferredClose = readfd ;
			if ( logToConsole ) NSLog( @"CLOSEKEYER (%02x) command rceived from client with file descriptor %d, deferring...", type, readfd ) ;
			//  defer this method 
			//  [ self closeAllConnectionsTo:readfd ] ;
			//	until others that other commands that arrive at the same select() get executed first
			break ;
		case _QUITKEYER_:
			// returning 0 will case the server thread to exit
			return 0 ;
		case _UPDATEKEYER_:
			//  does not have to do anything -- the intended purpose is to update the select() set
			break ;	
		default:
			//  unrecognized request from client, return null string
			[ self writeNull:writefd ] ;
			break ;
		}
	}
	return 1 ;
}

//  flag (PTT, serialCW, RTS) requests
- (void)setFlagUsing:(SEL)method from:(int)fd
{
	int n ;
	unsigned char buffer[2] ;
	
	n = read( fd, buffer, 1 ) ;
	switch ( buffer[0] ) {
	case '0':
		[ router performSelector:method withObject:NO ] ;
		break ;
	case '1':
		[ router performSelector:method withObject:(void*)YES ] ;
		break ;
	}
}

- (void)setFlagValueUsing:(SEL)method from:(int)fd
{
	int n ;
	unsigned char buffer[2] ;
	
	n = read( fd, buffer, 1 ) ;
	switch ( buffer[0] ) {
	case '0':
		[ router performSelector:method withObject:NO ] ;
		break ;
	case '1':
		[ router performSelector:method withObject:(void*)YES ] ;
		break ;
	}
}

- (void)sendBytesUsing:(SEL)method from:(int)fd
{
	long bytes ;
	
	bytes = read( fd, commandBuffer, 30 ) ;
	[ router performSelector:method withObject:(void*)commandBuffer withObject:(void*)bytes] ;
}

// v 0.5
- (void)sendStringUsing:(SEL)method from:(int)fd
{
	int i, bytes ;
	unichar chars[30] ;
	NSString *string ;
	
	bytes = read( fd, commandBuffer, 30 ) ;
	//  make bytes into unicode characters
	for ( i = 0; i < bytes; i++ ) chars[i] = commandBuffer[i] ;
	string = [ NSString stringWithCharacters:chars length:bytes ] ;	
	[ router performSelector:method withObject:string ] ;
}

//  v1.30 added write-only mode
- (void)insertIntoSelectSet:(NamedFIFOPair*)fifo type:(int)type router:(int)routerfd writeOnly:(Boolean)writeOnly
{
	int fd, outfd ;
	
	//  insert fifo fd into read select() set and local database
	fd = [ fifo inputFileDescriptor ] ;
	
	if ( logToConsole ) {
		NSLog( @"Server: adding file descriptor %d of FIFO %s", fd, [ fifo name ] ) ;
	}
	
	FD_SET( fd, &selectSet ) ;
	readSelect[fd].fifo = fifo ;
	readSelect[fd].type = type ;
	readSelect[fd].routerfd = routerfd ;
	if ( fd > actualSetSize ) actualSetSize = fd+1 ;
	
	if ( writeOnly == NO ) {
		outfd = [ fifo outputFileDescriptor ] ;		
		switch ( type ) {
		case OPENRADIO:
			debugRadioPortCount = 0 ;
			debugRadioPort = NO ;
			radiofd[fd] = outfd ;
			break ;
		case OPENDEBUGRADIO:
			debugRadioPortCount = 0 ;
			debugRadioPort = YES ;
			radiofd[fd] = outfd ;
			break ;
		case OPENCONTROL:
			controlfd[fd] = outfd ;
			break ;
		case OPENPTT:
			pttfd[fd] = outfd ;
			break ;
		case OPENCW:
			cwfd[fd] = outfd ;
			break ;
		case OPENRTS:
			rtsfd[fd] = outfd ;
			break ;
		case OPENWINKEY:
			winkeyfd[fd] = outfd ;
			break ;
		case OPENFSK:
			fskfd[fd] = outfd ;
			break ;
		case OPENFLAGS:
			flagsfd[fd] = outfd ;
			break ;
		}
	}
}

//  remove from select set and also release the fifo
- (void)removeFromSelectSet:(NamedFIFOPair*)fifo
{
	int fd, i ;

	if ( fifo != nil ) {
		fd = [ fifo inputFileDescriptor ] ;
		if ( fd > 0 && fd < FD_SETSIZE ) {
			FD_CLR( fd, &selectSet ) ;
			//  remove from the output sets
			switch ( readSelect[fd].type ) {
			case OPENRADIO:
			case OPENDEBUGRADIO:
				radiofd[fd] = 0 ;
				break ;
			case OPENCONTROL:
				controlfd[fd] = 0 ;
				break ;
			case OPENPTT:
				pttfd[fd] = 0 ;
				break ;
			case OPENCW:
				cwfd[fd] = 0 ;
				break ;
			case OPENRTS:
				rtsfd[fd] = 0 ;
				break ;
			case OPENWINKEY:
				winkeyfd[fd] = 0 ;
				break ;
			case OPENFSK:
				fskfd[fd] = 0 ;
				break ;
			case OPENFLAGS:
				flagsfd[fd] = 0 ;
				break ;
			}
			readSelect[fd].type = 0 ;
			readSelect[fd].fifo = nil ;
		}
		//  the following will close the ports
		[ fifo release ] ;
		//  now redicover the actualSetSize (so we don't have to check all of FD_SETSIZE)
		actualSetSize = 0 ;
		for ( i = 0; i < FD_SETSIZE; i++ ) {
			if ( FD_ISSET( i, &selectSet ) ) actualSetSize = i+1 ;
		}
	}
}

//  close and remove ( type, routerfd ) from select set
//  v1.11x  added unconditional closetype (-1)
- (void)removeFromSelectSet:(int)closetype router:(int)routerfd
{
	NamedFIFOPair* fifo ;
	SelectInfo *info ;
	int i, type ;
	
	if ( closetype > 0 ) {
		type = closetype & ( 0xff ^ CLOSEFUNCTION ) ;
	
		for ( i = 0; i < FD_SETSIZE; i++ ) {
			info = &readSelect[i] ;
			if ( info->type == type && info->routerfd == routerfd ) break ;
		}
		if ( i >= FD_SETSIZE ) return ;
	}
	else {
		//  v1.11x unconditional close
		for ( i = 0; i < FD_SETSIZE; i++ ) {
			info = &readSelect[i] ;
			if ( info->routerfd == routerfd ) break ;
		}
		if ( i >= FD_SETSIZE ) {
			if ( logToConsole ) NSLog( @"*** cannot find file descriptor (%d) to remove FIFO?", routerfd ) ;
			return ;
		}
	}
	fifo = info->fifo ;
	if ( logToConsole ) NSLog( @"removing FIFO %s", [ fifo name ] ) ;
	[ self removeFromSelectSet:fifo ] ;
}

//  v1.11x
- (void)removeFileDescriptor:(int)fd typefd:(int*)typefd
{
	if ( fd > 0 && fd < FD_SETSIZE ) {
		if ( logToConsole ) NSLog( @"removing file descriptor %d from set (was typefd %d)", fd, typefd[0] ) ;
		close( fd ) ; 
		*typefd = 0 ;
	}
	else if ( logToConsole ) NSLog( @"***  removing a file descriptor that is out of range? (%d)", fd ) ;
}

- (void)receivedData:(int)data typefd:(int*)typefd
{
	int i, status, fd ;
	unsigned char buf ;
	
	//  v 1.11
	if ( logToConsole ) {
		NSLog( @"DATA  > %02X", data & 0xff ) ;
	}
	
	buf = data ;
	if ( actualSetSize > 0 ) {
		[ writeLock lock ] ;					//  v1.11
		for ( i = 0; i < actualSetSize; i++ ) {
			fd = typefd[i] ;
			if ( fd > 0 ) {
				if ( fifoLatency( fd ) > LATENCYTIMEOUT ) {
					if ( logToConsole ) NSLog( @"*** shutting down aux FIFO because of client inactivity (> %d seconds) ***", LATENCYTIMEOUT ) ;
					[ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
				}
				else {
					status = write( fd, &buf, 1 ) ;
					if ( status != 1 ) {
						if ( logToConsole ) NSLog( @"Write Error for RADIO FIFO (fd %d)", fd ) ;
						//  if write error occurred, for sanity check, close and invalidate the fd
						[ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
					}
				}
			}
		}
		[ writeLock unlock ] ;
	}
}

- (void)receivedChar:(char)c typefd:(int*)typefd
{
    int i = 0;
    int fd = 0;
    int status = 0;
    if ( logToConsole)
    {
        NSLog( @"Radio > 0x%02x", c ) ;
    }
    [ writeLock lock ] ;
    if (actualSetSize > 0)
    {
        for ( i = 0; i < actualSetSize; i++ ) {
            fd = typefd[i] ;
            if ( fd > 0 ) {
                if ( fifoLatency( fd ) > LATENCYTIMEOUT ) {
                    //  one of the clients has stopped draining the FIFO?!
                    if ( logToConsole ) NSLog( @"*** shutting down RADIO FIFO because of client inactivity (> %d seconds) ***", LATENCYTIMEOUT ) ;
                    [ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
                }
                else {
                    status = write( fd, &c, 1 ) ;
                    if ( status != 1 ) {
                        NSLog( @"Write Error for RADIO FIFO %d\n", fd ) ;
                        //  if write error occurred, for sanity check, close and invalidate the fd
                        [ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
                    }
                }
            }
        }
    }
    [ writeLock unlock ] ;

    

}

//  new RADIO byte received from Keyer

- (void)receivedRadio:(int)data
{
    [ self receivedChar:data typefd:radiofd ] ;
}



- (void)sendControlChar:(char)c typefd:(int*)typefd
{
    int i = 0;
    int fd = 0;
    int status = 0;
    if ( logToConsole)
    {
        NSLog( @"CTRL > 0x%02x", c ) ;
    }
	if ( actualSetSize > 0 ) {
		[ writeLock lock ] ;
		for ( i = 0; i < actualSetSize; i++ ) {
			fd = typefd[i] ;
			if ( fd > 0 ) {
				if ( fifoLatency( fd ) > LATENCYTIMEOUT ) {
					//  the client has stopped draining the FIFO?!
					if ( logToConsole ) NSLog( @"*** shutting down CONTROL FIFO because af client inactivity (> %d seconds) ***", LATENCYTIMEOUT ) ;
					[ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
				}
				else {
					status = write( fd, &c, 1 ) ;
					if ( status != 1 ) {
						// error has occurred, close and remove controlfd as sanity check
						if ( logToConsole ) NSLog( @"FIFO write error, removing FIFO" ) ;
						[ self removeFileDescriptor:fd typefd:&typefd[i] ] ;
					}
				}
			}
		}
		[ writeLock unlock ] ;
	}

}


//  new CONTROL data received from Keyer
//  find all connected CONTROL clients and send the data to them
//  NOTE: CONTROL is sent as two byte pairs.  The first byte is a "valid" byte (first and last valid bytes of a control string are 0 instead of 0x08)
- (void)receivedControlInner:(int)data valid:(int)valid
{
	//  v1.11  accumulate as much data as possible
    [ self sendControlChar:data  typefd:controlfd ] ;
}

- (void)receivedControl:(int)data valid:(int)valid
{
	if ( valid == 0 ) {
		//  check if it is one of the filtered cases
		if ( data == 0x78 ) {
			//  MK-II voltage reports
			bufferFor78Packet[0] = data & 0xff ;
			current78Index = 1 ;
			return ;
		}
		if ( filteredTail != 0 ) {
			if ( filteredTail == data ) {
				// all is well... the packet is now filtered away, and we resume normal parsing
				filteredTail = 0 ;
				return ;
			}
			// something went wrong, so we just send the filtered byte and the current byte...
			[ self receivedControlInner:( filteredTail & 0x7f ) valid:0 ] ;
			[ self receivedControlInner:data valid:0 ] ;
			filteredTail = 0 ;
			return ;
		}
		if ( data == 0x2c && passHeartbeat == NO ) {
			filteredTail = 0xac ;
			return ;
		}
		if ( data == 0x7e && passLCD == NO ) {
			filteredTail = 0xfe ;
			return ;
		}
	}
	//  clear filtered packets since they should not contain valid data bytes (but just the head and tail bytes)
	filteredTail = 0 ;
	
	//  check MK-II status change packets; don't send to clients if only voltage change is sensed
	if ( current78Index != 0 ) {
		bufferFor78Packet[current78Index++] = data & 0xff ;
		if ( valid != 0 ) {
			if ( current78Index <= 4 ) return ;
			//  did not find end of sequence??
			//  NOTE: Keyer Protocol document appears wrong, there are three bytes between 0x78 and 0xf8.
		}
		else {
			if (data == 0xf8 ) {
				if ( bufferFor78Packet[1] != previous78Value ) {
					//  save the current voltage
					previous78Value = bufferFor78Packet[1] ;
					//  send the 78..f8 packet since voltage has changed
					[ self receivedControlInner:0x78 valid:0 ] ;
					[ self receivedControlInner:bufferFor78Packet[1] valid:0x08 ] ;
					[ self receivedControlInner:bufferFor78Packet[2] valid:0x08 ] ;
					[ self receivedControlInner:0xf8 valid:0 ] ;
					current78Index = 0 ;
					return ;
				}
			}
			current78Index = 0 ;
			return ;
		}
		if ( logToConsole ) NSLog( @"voltage change packet error %02x at index %d", data, current78Index ) ;
		current78Index = 0 ;
		return ;
	}
	if ( valid == 0 ) {
		//  only let one filtered packet pass per request from a client
		if ( data == 0x2c && passHeartbeat == YES ) passHeartbeat = NO ;
		if ( data == 0x7e && passLCD == YES ) passLCD = NO ;
	}
	[ self receivedControlInner:data valid:valid ] ;
}

- (void)passFilteredControl:(int)command
{
	switch ( command ) {
	case 0x2c:
		passHeartbeat = YES ;
		break ;
	case 0x7e:
		passLCD = YES ;
		break ;
	}
}

//  new Winkey byte received from Keyer
//  find all connected Winkey clients and send the data byte to them
- (void)receivedWinKey:(int)data
{
	[ self receivedData:(int)data typefd:winkeyfd ] ;
}

- (void)receivedFSK:(int)data
{
	[ self receivedData:(int)data typefd:fskfd ] ;
}

//  new flag byte received from Keyer
//  find all connected CW, PTT and FLAG clients and send the flag byte to them
- (void)receivedFlags:(int)data
{
	[ self receivedData:(int)data typefd:flagsfd ] ;
	[ self receivedData:(int)data typefd:cwfd ] ;
	[ self receivedData:(int)data typefd:pttfd ] ;
	[ self receivedData:(int)data typefd:rtsfd ] ;
}

- (void)closeAllConnectionsTo:(int)fd
{
	int i, routerfd ;
	
	if ( fd <= 0 ) return ;
	
	//  check for all the FIFOs that are created by the given fd and remove them (also the fd itself)
	for ( i = 0; i < FD_SETSIZE; i++ ) {
		routerfd = readSelect[i].routerfd ;
		if ( routerfd == fd || i == fd ) {
			[ self removeFromSelectSet:readSelect[i].fifo ] ;
		}
	}
}

//  v1.11
- (void)setConsoleDebug:(Boolean)state
{
	logToConsole = state ;
}

@end
