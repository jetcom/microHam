//
//  Router.m
//  uH Router
//
//  Created by Kok Chen on 5/4/06.
	#include "Copyright.h"

#import "Router.h"
#import "Controller.h"
#import "Keyer.h"
#import "KeyerMode.h"
#import "KeyerSettings.h"
#import "LogMacro.h"
#import "RouterCommands.h"
#import "RouterPlist.h"
#import "RouterTest.h"
#import "Server.h"
#import "WinKeyEmulator.h"


@implementation Router

#define	LATENCYTIMEOUT			60.0				//  v1.40
#define	DEFAULTRESPONSEWINDOW	1.0

static int asciiHex[] = {
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0,	1,	2,	3,	4,	5,	6,	7,	8,	9,  0,	0,	0,	0,	0,	0,	
	0, 10, 11, 12, 13, 14, 15,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0, 10, 11, 12, 13, 14, 15,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
} ;

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

//  v1.40
static struct sockaddr_in *localSocket( in_port_t port )
{
	struct sockaddr_in *sock ;
	
	sock = (struct sockaddr_in*)calloc( 1, sizeof( struct sockaddr_in ) ) ;
	
	sock->sin_family = AF_INET ;							//  create as IP
	sock->sin_addr.s_addr = inet_addr( LocalHost ) ;		//  local IP number
	sock->sin_port = htons( port ) ;						//  port
	return sock ;
}

//	v1.80
- (id)initPrototype:(NSString*)inKeyerName fifo:(NSString*)inFifoName deviceName:(NSString*)devName command:(int)commandValue controller:(Controller*)inController
{	
	self = [ super init ] ;
	if ( self ) {
		controller = inController ;
		deviceName = [ devName retain ] ;
		command = commandValue ;  // commandvalue is either OPENMICROKEYER or OPENCWKEYER or OPENDIGIKEYER
		routerRetainCount = 0 ;
		prefs = nil ;
		keyerName = [ inKeyerName retain ] ;
		fifoName = [ inFifoName retain ] ;
	}
	return self ;
}

//	v1.80
//	note: if streamName is @"", generate a dummy router for AppleScript
- (id)initIntoTabView:(NSTabView*)tabview keyerModeTabView:(NSTabView*)keyerModeTabView prototype:(Router*)prototype streamName:(NSString*)streamName index:(int)offset
{
	int port, index ;
	NSString *title, *tabName, *indexedFifoName ;
	
	self = [ super init ] ;
	if ( self ) {
		controller = [ prototype controller ] ;
		deviceName = [ [ prototype deviceName ] retain ] ;
		keyerName = [ [ prototype keyerName ] retain ] ;
		isDummy = NO ;
		version = 1 ;
		
		indexedFifoName = [ [ prototype fifoName ] stringByAppendingString:[ NSString stringWithFormat:@"%c", 'A'+offset ] ] ;
		
		index = [ streamName rangeOfString:@"-" ].location ;
		if ( index < 0 || index > 16 ) index = 0 ; else index++ ;
		
		tabName = keyerName ;
		keyerID = [ [ streamName substringFromIndex:index ] retain ] ;
		
		if ( [ keyerID length ] > 2 && [ keyerID characterAtIndex:1 ]== '2' ) {
			tabName = [ tabName stringByAppendingString:@" II" ] ;
			version = 2 ;
		}
		command = [ prototype commandValue ] ;  // commandvalue is either OPENMICROKEYER or OPENCWKEYER or OPENDIGIKEYER
		routerRetainCount = 0 ;
		prefs = nil ;
		
		//	get winkey and FSK availability from prototype
		[ self setHasFSK:[ prototype hasFSK ] ] ;
		[ self setHasWINKEY:[ prototype hasWINKEY ] ] ;
		
		//  v1.40 -- each router has its own UDP port
		udpSocket = 0 ;
		udpControlIndex = udpRadioIndex = 1 ;		// index 0 reserved for UDP prefix
		udpServer = nil ;
		udpLock = [ [ NSLock alloc ] init ] ;
		if ( ( udpSocket = socket( PF_INET, SOCK_DGRAM, IPPROTO_UDP ) ) < 0 ) return nil ;
		
		port = 0 ;
		switch ( command ) {
		case OPENMICROKEYER:
			port = mHUDPServerPort+offset+1 ;		//  offset provides unique UDP port number (+0 is master port)
			title = @"microKeyer Settings" ;
			break ;
		case OPENCWKEYER:
			port = mHUDPServerPort+offset+1 ;
			title = @"cwKeyer Settings" ;
			break ;
		case OPENDIGIKEYER:
			port = mHUDPServerPort+offset+1 ;
			title = @"digiKeyer Settings" ;
			break ;
		}
		udpServer = localSocket( port ) ;	//  port follows mHUDPServerPort
		udpClients = 0 ;		
		int bindErr = bind( udpSocket, (struct sockaddr*)udpServer, sizeof( struct sockaddr ) ) ;	
		
		if ( bindErr == 0 ) {
			//  v 1.50 bypass UDP if it cannot be opened
			//  start a thread to listen for and respond to keyer requests
			[ NSThread detachNewThreadSelector:@selector(udpRouterThread:) toTarget:self withObject:self ] ;
			udpRadioTimer = [ NSTimer scheduledTimerWithTimeInterval:5.7 target:self selector:@selector(flushRadioForUDP:) userInfo:self repeats:YES ] ;
		}
		debug = NO ;
		debugFrame = debugFramesIntoWindow = debugRadioIntoWindow = debugFlagsIntoWindow = debugControlIntoWindow = debugBytesIntoWindow = NO ;
		debugChannel = NO ;
		debugRadio = NO ;
		debugControl = NO ;
		logToConsole = NO ;
		
		//  radio data buffering
		radioString = @"RADIO < " ;
		radioDataTimer = [ NSTimer scheduledTimerWithTimeInterval:55.0 target:self selector:@selector(radioDataCheck:) userInfo:self repeats:YES ] ;
		
		if ( [ NSBundle loadNibNamed:@"Router" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( controlView && tabview ) {
				if ( [ streamName length ] > 0 ) {
					//  create a new TabViewItem for keyer and place an instance of the Nib in the tab item
					tabItem = [ [ NSTabViewItem alloc ] init ] ;
					[ tabItem setView:controlView ] ;
					[ tabItem setLabel:tabName ] ;
					//  and insert as tabView item at head of the tabs
					controllingTabView = tabview ;
					[ controllingTabView addTabViewItem:tabItem ] ;
				}
				[ self setEnabled:YES ] ;
				// pref panel changes
				[ enableFlag setAction:@selector( paramsChanged: ) ] ;
				[ enableFlag setTarget:self ] ;
				//  create reply buffers
				radio = [ [ ReplyBuf alloc ] init ] ;
				control = [ [ ReplyBuf alloc ] init ] ;
				flags = [ [ ReplyBuf alloc ] init ] ;
				winkey = [ [ ReplyBuf alloc ] init ] ;
				fsk = [ [ ReplyBuf alloc ] init ] ;
				// clear the shared data
				flagByte = 0 ;
				//  sendRadio interface
				sendRadioLock = [ [ NSLock alloc ] init ] ;
				//  sendControl interface
				sendControlLock = [ [ NSLock alloc ] init ] ;
				//  serial interface for router
				sequence = 0 ;
				parserLock = [ [ NSLock alloc ] init ] ;
				writeLock =  [ [ NSLock alloc ] init ] ;
															
				keyer = [ [ Keyer alloc ] initFromRouter:self writeLock:writeLock ] ;
				//  create serial emulator
				emulator = [ [ WinKeyEmulator alloc ] initWithRouter:self ] ;
				//  create server to listen to clients
				server = [ [ Server alloc ] initWithName:indexedFifoName router:self writeLock:writeLock ] ;
				// set up keyer mode panel
				keyerMode = [ [ KeyerMode alloc ] initIntoTabView:keyerModeTabView name:keyerName router:self controller:controller ] ;
				//  set up keyer config panel
				keyerSettings = [ [ KeyerSettings alloc ] initIntoWindow:keyerSettingsWindow router:self ] ; 
				[ keyerSettingsWindow setTitle:title ] ;
				[ timeoutTextField setRefusesFirstResponder:YES ] ;
				//  v1.80
				[ self setNameString:keyerID ] ;
				if ( [ streamName length ] <= 0 ) isDummy = YES ;
				return self ;
			}
		}
	}
	return nil ;
}

//	v1.80
- (void)setNameString:(NSString*)string
{
	[ nameStringField setStringValue:string ] ;
}

//	v1.80
- (Controller*)controller
{
	return controller ;
}

//	v1.80
- (int)commandValue
{
	return command ;
}

- (NSString*)keyerName
{
	return keyerName ;
}

- (NSString*)fifoName
{
	return fifoName ;
}

- (NSString*)keyerID
{
	return keyerID ;
}

- (int)version
{
	return version ;
}

- (Boolean)isDummy
{
	return isDummy ;
}

- (void)dealloc
{
	[ udpRadioTimer invalidate ] ;		//  v1.80
	
	Log( debug, "release resources for router %s\n", [ deviceName cString ]+10 ) ;
	if ( server ) {
		Log( debug, "releasing server\n" ) ;
		[ server quitKeyer ] ;
		[ server release ] ;
		server = nil ;
	}
	if ( udpSocket > 0 ) close( udpSocket ) ;
	if ( udpServer != nil ) free( udpServer ) ;
	[ udpLock release ] ;
	[ deviceName release ] ;
	[ keyerName release ] ;
	[ fifoName release ] ;
	[ keyer release ] ;
	[ super dealloc ] ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//  KeyerSettings's window
- (IBAction)openSettingsWindow:(id)sender ;
{
	[ keyerSettings show ] ;
}

- (void)setupParameters
{	
	//  v1.11t -- add adjustable RADIO aggregate
	[ self setInterface:timeoutTextField to:@selector(timeoutFieldChanged:) ] ;
}

- (const char*)addNewClient
{
	if ( keyer == nil || server == nil || ![ keyer opened ] ) return "" ; 
	return [ server addClient ] ;
}

//  v1.40
- (int)sendUDPBytes:(char*)str length:(int)length socket:(struct sockaddr_in*)socket
{
	if ( udpServer == nil ) return 0 ;
	return sendto( udpSocket, str, length, 0, (struct sockaddr*)socket, sizeof( struct sockaddr ) ) ;
}

- (int)command
{
	return command ;
}

- (Boolean)hasWINKEY
{
	if ( server ) return [ server hasWinKey ] ; else return NO ;
}

- (void)setHasWINKEY:(Boolean)state
{
	if ( server ) [ server setHasWinKey:state ] ;
}

- (Boolean)hasFSK
{
	if ( server ) return [ server hasFSK ] ; else return NO ;
}

- (void)setHasFSK:(Boolean)state
{
	if ( server ) [ server setHasFSK:state ] ;
}

- (Boolean)debug
{
	return debug ;
}

- (void)setDebug:(Boolean)value
{
	debug = value ;
	if ( server ) [ server setDebug:debug ] ;
	if ( keyer ) [ keyer setDebug:debug ] ;
}

//  main router parsing is done here
//
//  Keyer.m sends a 4 byte frame here each time a frame is received from the device.
//
//  The header (first byte) of a frame is identified by having the 0x80 bit (frame sync) of the byte turned off.
//  Each frame has three data bytes, for the Radio, ExtRadio and a channel that is shared by FLAGS(PTT, CW), CONTROL, WINKEY, FSK, EXTFSK.
//
//  The shared channels are obtained by demultiplexing the shared data channel according to the order of a frame in a sequence
//  A frame sequence starts if the first byte of the frame has the 0x40 bit (sequence sync) turned off.
//  The data from the FLAGS channel are contained in the shared byte of the first frame of a sequence, the data for the CONTROL channel
//	are contained in the shared byte of the second frame of a sequence, etc.
//
//	Since the three data bytes need to have their MSB turned on for frame sync purposes, their real MSB are located in the header byte.
//
//  Each of the three bytes of a frame can contain data or not, depending on the "valid" flag for each of the data bytes in the header of the
//	frame (i.e., the header contains a MSB bit and a valid bit for the 3 data bytes).  The two remaining bits of the header are used as 
//	frame sync and sequence sync indicators.
//
//	The exception to the above rule is that CONTROL bytes need not have the valid flag turned on.  A CONTROL byte with the valid flags turned
//	off are the first and last byte of a control packet.

- (void)lockedParseFrame:(unsigned char*)frame
{
	int header, data ;
	
	Log( debugFrame, "received frame %02x %02x %02x %02x\n", frame[0], frame[1], frame[2], frame[3] ) ;
	
	header = frame[0] ;
	if ( header & 0x80 ) {
		//  this bit should be cleared! Ignore frame if the bit is set
		
		if ( debugFramesIntoWindow ) {
			char buf[256] ;
			
			[ controller log:"*** Discarding following frame ***\n" ] ;
			
			if ( ( header & 0x20 ) != 0 ) {
				data = frame[1] & 0x7f ;
				if ( ( header & 0x04 ) != 0 ) data |= 0x80 ;
				sprintf( buf, " discard frame sequence %d:  %02X %02X %02X %02X radio: %02X\n", sequence, frame[0], frame[1], frame[2], frame[3], data ) ;
			}
			else {
				sprintf( buf, " discard frame sequence %d:  %02X %02X %02X %02X\n", sequence, frame[0], frame[1], frame[2], frame[3] ) ;
			}
			[ controller log:buf ] ;
		}
		return ;
	}
	if ( ( header & 0x40 ) == 0 ) sequence = 0 ; else sequence++ ;
	
	// check RADIO byte
	if ( ( header & 0x20 ) != 0 ) {
		data = frame[1] & 0x7f ;
		if ( ( header & 0x04 ) != 0 ) data |= 0x80 ;
		[ self receivedRadio:data ] ;
	}
	
	if ( debugFramesIntoWindow ) {
		char buf[256] ;
		if ( ( header & 0x20 ) != 0 ) {
			data = frame[1] & 0x7f ;
			if ( ( header & 0x04 ) != 0 ) data |= 0x80 ;
			sprintf( buf, "received frame sequence %d:  %02X %02X %02X %02X radio: %02X\n", sequence, frame[0], frame[1], frame[2], frame[3], data ) ;
		}
		else {
			sprintf( buf, "received frame sequence %d:  %02X %02X %02X %02X\n", sequence, frame[0], frame[1], frame[2], frame[3] ) ;
		}
		[ controller log:buf ] ;
	}

	// check EXT RADIO byte
	if ( ( header & 0x10 ) != 0 ) {
		data = frame[2] & 0x7f ;
		if ( ( header & 0x02 ) != 0 ) data |= 0x80 ;
		[ self receivedExtRadio:data ] ;
	}
	
	//  check valid bit for shared channel, unless it is sequence #1 (CONTROL channel)
	if ( ( header & 0x08 ) || sequence == 1 ) {
		//  merge in MSB from the 0SB of the header
		//  and demux to one of the shared destinations
		data = frame[3] & 0x7f ;
		if ( header & 0x1 ) data |= 0x80 ;
		
		switch ( sequence ) {
		case 0:
			[ self receivedFlags:data ] ;
			break ;
		case 1:
			[ self receivedControl:data valid:header&0x08 ] ;
			break ;
		case 2:
			[ self receivedWinKey:data ] ;
			break ;
		case 3:
			//  do nothing for now -- this is the PS2 port for keyer responses
			//[ self receivedFSK:data ] ;
			break ;
		case 4:
			//  do nothing for now -- this frame does not exist in the current firmware
			//[ self receivedExtFSK:data ] ;
			break ;
		}
	}
}

- (void)parseFrame:(unsigned char*)frame
{
	[ parserLock lock ] ;
	[ self lockedParseFrame:frame ] ;
	[ parserLock unlock ] ;
}

//  framing error from scanner in Keyer.m
- (void)framingError:(unsigned char*)frame byteOrder:(int)byteOrder
{
	int i ;
	char msg[16] ;
	
	[ controller log:"*** framing error, received unexpected frame sync: " ] ;
	for ( i = 0; i < byteOrder; i++ ) {
		sprintf( msg, " %02X", frame[i] & 0xff ) ;
		[ controller log:msg ] ;
	}
	[ controller log:"\n" ] ;
}

//  missing frame sync in scanner of Keyer.m
- (void)missingFrameSync:(unsigned char)byte
{
	char msg[64] ;
	
	sprintf( msg, "*** Expected a frame sync byte, instead received %02X", byte & 0xff ) ;
	[ controller log:msg ] ;
}

- (void)receivedByteInScanner:(unsigned char)byte
{
	if ( debugBytesIntoWindow ) {
		char buf[64] ;
		sprintf( buf, "byte: %02x\n", byte&0xff ) ;
		[ controller log:buf ] ;
	}
}

//  v1.40  send RADIO strings to UDP ports, after it reaches the timeout

- (void)flushRadioForUDP:(NSTimer*)timer
{
	int i, n, garbageCollection ;
	NSTimeInterval now, delta ; 
	UDPClient *u ;

	[ udpLock lock ] ;
	
	if ( udpRadioIndex > 1 ) {
	
		garbageCollection = -1 ;
		n = udpRadioIndex ;
		udpRadioIndex = 1 ;
		udpRadioString[0] = RADIO_PREFIX ;	
		now = [ NSDate timeIntervalSinceReferenceDate ] ;
		
		for ( i = 0; i < udpClients; i++ ) {
			u = &udpClient[i] ;
			if ( garbageCollection < 0 ) if ( ( now - u->lastAccessed ) > LATENCYTIMEOUT ) garbageCollection = i ;
			delta = now - u->timePreviousCommandReceived[ RADIO_INDEX ] ;
			if ( delta < u->responseWindow[ RADIO_INDEX ] ) {
				if ( udpSocket > 0 ) sendto( udpSocket, udpRadioString, n, 0, (struct sockaddr*)&u->socket, sizeof( struct sockaddr ) ) ;
			}
		}
		//  remove UDP client has been idle for a long time
		if ( garbageCollection >= 0 ) {
			u = &udpClient[garbageCollection] ;
			[ self removeUDPClient:&u->socket ] ;
		}
	}
	[ udpRadioTimer setFireDate:[ NSDate dateWithTimeIntervalSinceNow:5.70 ] ] ;
	
	[ udpLock unlock ] ;
}

//  aggregate RADIO data for UDP
- (void)aggregateRadioForUDP:(int)data
{	
	[ udpLock lock ] ;
	udpRadioString[udpRadioIndex] = data ;
	udpRadioIndex++ ;
	if ( udpRadioIndex >= 1023 ) udpRadioIndex = 1023 ;
	[ udpRadioTimer setFireDate:[ NSDate dateWithTimeIntervalSinceNow:aggregateTimeout*0.0011 ] ] ;		//  10% longer than FIFO case
	[ udpLock unlock ] ;
}

- (void)receivedRadio:(int)data
{
	//  Radio data received
	Log( debugRadio, "RADIO: %02x\n", data ) ;
	
	if ( debugRadioIntoWindow ) {
		char buf[64] ;
		sprintf( buf, "from RADIO %02x\n", data ) ;
		[ controller log:buf ] ;
	}
	[ server receivedRadio:data ] ;
	[ self aggregateRadioForUDP:data ] ;
	[ radio append:data ] ;
}

- (void)receivedExtRadio:(int)data
{
	//  ExtRadio data received
	Log( debugRadio, "EXT RADIO: %02x\n", data ) ;
}

- (void)receivedFlags:(int)data
{
	int i ;
	NSTimeInterval delta, now, flagsWindow ; 
	char buf[64] ;
	UDPClient *u ;
	int garbageCollection ;
	
	//  flag received, need to further demux the bits
	Log( debugChannel, "FLAG: %02x\n", data ) ;
	
	if ( debugFlagsIntoWindow ) {
		sprintf( buf, "from FLAG %02x\n", data ) ;
		[ controller log:buf ] ;
	}
	[ server receivedFlags:data ] ;
	[ flags append:data ] ;

	//  now send FLAG to UDP clients
	[ udpLock lock ] ;
	garbageCollection = -1 ;	
	//  v1.40  send flags to FLAGS, PTT, CW, RTS and FSK UDP ports
	now = [ NSDate timeIntervalSinceReferenceDate ] ;
	for ( i = 0; i < udpClients; i++ ) {
		u = &udpClient[i] ;
		if ( garbageCollection < 0 ) if ( ( now - u->lastAccessed ) > LATENCYTIMEOUT ) garbageCollection = i ;
		
		//  check FLAGS, PTT, FSK, CW and RTS ports
		flagsWindow = u->responseWindow[ FLAGS_INDEX ] ;
		delta = now - u->timePreviousCommandReceived[ FLAGS_INDEX ] ;
		if ( delta >= flagsWindow ) {
			delta = now - u->timePreviousCommandReceived[ FSK_INDEX ] ;
			if ( delta >= flagsWindow ) {
				delta = now - u->timePreviousCommandReceived[ PTT_INDEX ] ;
				if ( delta >= flagsWindow ) {
					delta = now - u->timePreviousCommandReceived[ CW_INDEX ] ;
					if ( delta >= flagsWindow ) delta = now - u->timePreviousCommandReceived[ RTS_INDEX ] ;
				}
			}
		}
		if ( delta < flagsWindow ) {
			buf[0] = FLAGS_PREFIX ;
			buf[1] = data ;
			if ( udpSocket > 0 ) sendto( udpSocket, buf, 2, 0, (struct sockaddr*)&u->socket, sizeof( struct sockaddr ) ) ;
		}
	}
	//  remove UDP client has been idle for a long time
	if ( garbageCollection >= 0 ) {
		u = &udpClient[garbageCollection] ;
		[ self removeUDPClient:&u->socket ] ;
	}
	[ udpLock unlock ] ;
}

- (void)accumulateControlForUDP:(int)data valid:(int)valid
{
	int i, n, p, head, garbageCollection ;
	NSTimeInterval now ;
	UDPClient *u ;
	
	[ udpLock lock ] ;
	garbageCollection = -1 ;
	udpControlString[udpControlIndex] = data ;
	udpControlIndex++ ;
	if ( udpControlIndex >= 1023 ) udpControlIndex = 1023 ;
	if ( valid == 0 && ( data & 0x80 ) == 0x80 ) {
		n = udpControlIndex ;
		udpControlIndex = 1 ;
		//  found end of control string
		head = data & 0x7f ;
		if ( head == ( udpControlString[1]&0xff ) ) {
			udpControlString[0] = CONTROL_PREFIX ;	
			//  v1.40  send CONTROL srings to UDP ports
			now = [ NSDate timeIntervalSinceReferenceDate ] ;
			for ( i = 0; i < udpClients; i++ ) {
				u = &udpClient[i] ;
				if ( garbageCollection < 0 ) if ( ( now - u->lastAccessed ) > LATENCYTIMEOUT ) garbageCollection = i ;
				if ( u->allowControlPacket[head] > 0 ) {
					if ( udpSocket > 0 ) sendto( udpSocket, udpControlString, n, 0, (struct sockaddr*)&u->socket, sizeof( struct sockaddr ) ) ;
					p = u->allowControlPacket[head] - 1 ;
					if ( p < 0 ) p = 0 ;
					u->allowControlPacket[head] = p ;
				}
			}
		}
	}
	//  remove UDP client has been idle for a long time
	if ( garbageCollection >= 0 ) {
		u = &udpClient[garbageCollection] ;
		[ self removeUDPClient:&u->socket ] ;
	}
	[ udpLock unlock ] ;
}

- (void)receivedControl:(int)data valid:(int)valid
{
	//  control byte received 
	Log( debugChannel, "CONTROL: %02x%c\n", data, ( valid == 0 )?'*' : ' '  ) ;
	
	if ( debugControlIntoWindow ) {
		char buf[64] ;
		sprintf( buf, "from CONTROL %02x%c\n", data, ( valid == 0 )?'*' : ' '  ) ;
		[ controller log:buf ] ;
	}
	[ server receivedControl:data valid:valid ] ;
	[ self accumulateControlForUDP:data valid:valid ] ;
	if ( valid ) [ control append:data ] ; else [ control appendInvalid:data ] ;
}

- (void)receivedWinKey:(int)data
{
	int i, garbageCollection ;
	NSTimeInterval now, delta ;
	unsigned char buf[2] ;
	UDPClient *u ;

	//  WinKey byte received 
	if ( ( data & 0xc0 ) == 0xc0 ) {
		Log( debugChannel, "WINKEY STATUS 0x%02x\n", data & 0x3f ) ;
	}
	else {
		Log( debugChannel, "WINKEY: [%c]\n", data  ) ;
	}
	[ server receivedWinKey:data ] ;			// v 0.60
	[ winkey append:data ] ;
	
	//  v1.40 now send WINKEY to UDP clients
	[ udpLock lock ] ;
	garbageCollection = -1 ;	
	now = [ NSDate timeIntervalSinceReferenceDate ] ;
	for ( i = 0; i < udpClients; i++ ) {
		u = &udpClient[i] ;
		if ( garbageCollection < 0 ) if ( ( now - u->lastAccessed ) > LATENCYTIMEOUT ) garbageCollection = i ;
		delta = now - u->timePreviousCommandReceived[ WINKEY_INDEX ] ;
		if ( delta < u->responseWindow[ WINKEY_INDEX ] ) {
			buf[0] = WINKEY_PREFIX ;
			buf[1] = data ;
			if ( udpSocket > 0 ) sendto( udpSocket, buf, 2, 0, (struct sockaddr*)&u->socket, sizeof( struct sockaddr ) ) ;
		}
	}
	//  remove UDP client has been idle for a long time
	if ( garbageCollection >= 0 ) {
		u = &udpClient[garbageCollection] ;
		[ self removeUDPClient:&u->socket ] ;
	}
	[ udpLock unlock ] ;
}

//  currently, the keyer does not send any FSK data back
- (void)receivedFSK:(int)data
{
	int i, garbageCollection ;
	NSTimeInterval now, delta ;
	unsigned char buf[2] ;
	UDPClient *u ;

	//  FSK byte received 
	Log( debugChannel, "FSK: %02x\n", data  ) ;
	[ fsk append:data ] ;
	
	//  v1.40 now send FSK to UDP clients
	[ udpLock lock ] ;
	garbageCollection = -1 ;	
	now = [ NSDate timeIntervalSinceReferenceDate ] ;
	for ( i = 0; i < udpClients; i++ ) {
		u = &udpClient[i] ;
		if ( garbageCollection < 0 ) if ( ( now - u->lastAccessed ) > LATENCYTIMEOUT ) garbageCollection = i ;
		delta = now - u->timePreviousCommandReceived[ FSK_INDEX ] ;
		if ( delta < u->responseWindow[ FSK_INDEX ] ) {
			buf[0] = FSK_PREFIX ;
			buf[1] = data ;
			if ( udpSocket > 0 ) sendto( udpSocket, buf, 2, 0, (struct sockaddr*)&u->socket, sizeof( struct sockaddr ) ) ;
		}
	}
	//  remove UDP client has been idle for a long time
	if ( garbageCollection >= 0 ) {
		u = &udpClient[garbageCollection] ;
		[ self removeUDPClient:&u->socket ] ;
	}
	[ udpLock unlock ] ;
}

- (void)receivedExtFSK:(int)data
{
	//  Ext FSK byte received 
	Log( debugChannel, "EXT FSK: %02x\n", data  ) ;
}

//  gray indicator if there is no such device
//  yellow indicator if device exists but not open
//  green indicator if device is open
- (void)updateActiveIndicator
{
	NSColor *color ;
	Boolean opened ;
	NSString *path, *err ;
	int errorCode = 0 ;
	
	opened = [ keyer opened ] ;
	path = [ keyer path ] ;
	
	color = ( opened ) ? [ NSColor greenColor ] : ( ( path != nil ) ? [ NSColor yellowColor ] : [ NSColor grayColor ] ) ;
	if ( !opened && path != nil ) {
		errorCode = [ keyer errorCode ] ;
		err = [ NSString stringWithCString:strerror( errorCode ) ] ;
	}
	if ( errorCode == 0 ) err = @"" ;	
	[ errorString setStringValue:err ] ;
	
	[ activeIndicator setBackgroundColor:color ] ;
}

- (void)connect
{	
	if ( keyer ) {
		[ keyer openSerialDevice ] ;
		[ self updateActiveIndicator ] ;
		[ keyerMode updateState:3 ] ;
	}
}

- (Boolean)connected
{
	if ( !keyer ) return NO ;
	return [ keyer opened ] ;
}

- (int)retainRouter 
{
	routerRetainCount++ ;
	if ( logToConsole ) NSLog( @"Router retain count increased to %d", routerRetainCount ) ;
	return routerRetainCount ;
}

- (int)releaseRouter
{
	routerRetainCount-- ;
	if ( routerRetainCount < 0 ) routerRetainCount = 0 ;
	if ( logToConsole ) NSLog( @"Router retain count decreased to %d", routerRetainCount ) ;
	return routerRetainCount ;
}

- (Boolean)inUse 
{
	if ( !server ) return NO ;
	if ( routerRetainCount > 0 ) {
		if ( logToConsole ) NSLog( @"Router still has retain count of %d", routerRetainCount ) ;
		return YES ;
	}
	return [ server inUse ] ;
}

- (NSString*)deviceName
{
	return deviceName ;
}

- (void)setStream:(NSString*)name
{
	[ keyer setStream:name ] ;
}

- (void)setPath:(NSString*)name
{
	[ keyer setPath:name ] ;
}

- (Boolean)isEnabled
{
	return isEnabled ;
}

- (void)setEnabled:(Boolean)state
{
	isEnabled = state ;
	[ enableFlag setState:( isEnabled )? NSOnState : NSOffState ] ;
	[ self updateActiveIndicator ] ;
}

- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info
{
	[ [ NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] runModal ] ;
}

//  NOTE: for now pty port changes are not updated until a relaunch
- (void)paramsChanged:(id)sender
{
	Boolean wasEnabled ;
	
	wasEnabled = isEnabled ;
	isEnabled = ( [ enableFlag state ] == NSOnState ) ;
	if ( wasEnabled != isEnabled ) {
		if ( isEnabled ) {
			//  turned on
			if ( isEnabled ) [ keyer openSerialDevice ] ;
			[ self updateActiveIndicator ] ;
			return ;
		}
		// turned off
		[ keyer closeSerialDevice ] ;
		[ self updateActiveIndicator ] ;
	}
}

//  send FLAGS channel, NOP the other two
- (void)sendFlags
{
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80 } ;

	if ( flagByte & 0x80 ) nop[0] |= 1 ;				// MSB of flag data
	nop[3] |= flagByte ;								// 7 bit flag with MSB set
	
	if ( debugFlagsIntoWindow ) {
		char msg[64] ;
		sprintf( msg, "to FLAG: %02X\n", flagByte ) ;
		[ controller log:msg ] ;
	}
	[ keyer writeFrames:nop length:4 ] ;
}

- (int)appendControl:(int)ctrl toArray:(unsigned char*)array valid:(Boolean)isValid
{
	//  NOTE: validity bit (0x08) is off for the first and last bytes of a control packet
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80 } ;
	int i ;

	if ( flagByte & 0x80 ) nop[0] |= 1 ;				// MSB of flag data
	nop[3] |= flagByte ;								// 7 bit flag with MSB set
	nop[4] |= ( isValid ) ? 0x08 : 0x00 ;				// valid 0x08 or 0x00
	if ( ctrl & 0x80 ) nop[4] |= 1 ;					// MSB of control data
	nop[7] |= ctrl ;									// 7 bit control with MSB set
	for ( i = 0; i < 8; i++ ) *array++ = nop[i] ;
	
	return 8 ;
}

//  v1.40
//  backdoor commands using 0f...8f control commands (unused as a control write in the keyer)
- (void)executeBackdoor:(unsigned char*)controlBytes length:(int)length
{
	switch ( controlBytes[1] ) {
	case 1:
		//  FSK Invert
		[ keyerSettings setFSKInvert:( controlBytes[2] != 0 ) ] ;
		break ;
            
    case 2:
		//  v1.61 routing selection
		[ keyerSettings setRouting:controlBytes[2] ] ;
		break ;
	case 3:
		//  v1.62 q-PSK and p-FSK
		[ keyerSettings setOOK:controlBytes[2] state:controlBytes[3] ] ;
		break ;
	}
}

//  send CONTROL string
//  the control byte is the second frame of a shared sequence, so we need to send a nop frame first
//	send the flag in the first frame just in case
- (void)sendControl:(unsigned char*)controlBytes length:(int)length
{
	int i, last ;
	unsigned char string[8] ;
	char more[8], msg[1024] ;
	
	if ( controlBytes[0] == kRouterBackdoor ) {
		[ self executeBackdoor:controlBytes length:length ] ;
		return ;
	}
	
	if ( debugChannel || debugControl || debugControlIntoWindow ) {
		strcpy( msg, "to CONTROL: " ) ;
		for ( i = 0; i < length; i++ ) {
			sprintf( more, "%02x ", controlBytes[i] ) ;
			strcat( msg, more ) ;
		}
		if ( debugChannel ) {
			Log( debugChannel, "%s\n", msg ) ;
		}
		if ( debugControl ) {
			Log( debugControl, "%s\n", msg ) ;
		}
		if ( debugControlIntoWindow ) {
			strcat( msg, "\n" ) ;
			[ controller log:msg ] ;
		}
	}	
	[ sendControlLock lock ] ;		//  v1.11g
	
	last = length-1 ;
	for ( i = 0; i < length; i++ ) {
		[ self appendControl:controlBytes[i] toArray:string valid: !( i==0 || i==last ) ] ;
		[ keyer writeFrames:string length:8 ] ;		//  v1.11q
	}
	[ sendControlLock unlock ] ;
	
	if ( controlBytes[0] == 0x0a ) {
		[ keyerMode updateMatrix:controlBytes[1] ] ;
	}
}

- (int)appendRadio:(int)radioData toArray:(unsigned char*)array
{
	unsigned char nop[] = { 0x28, 0x80, 0x80, 0x80 } ;
	int i ;

	if ( flagByte & 0x80 ) nop[0] |= 1 ;				// MSB of flag data
	nop[3] |= flagByte ;								// 7 bit flag with MSB set (just in case)
	if ( radioData & 0x80 ) nop[0] |= 4 ;				// MSB of radio data
	nop[1] |= radioData ;								// 7 bit control with MSB set
	for ( i = 0; i < 4; i++ ) *array++ = nop[i] ;
	
	return 4 ;
}

//  flush radio data Console message if it has timed out
- (void)radioDataCheck:(NSTimer*)timer
{
	//  go back to idling
	[ radioDataTimer setFireDate:[ NSDate distantFuture ] ] ;
	if ( [ radioString length ] > 8 ) {
		//  send to console
		NSString *str = [ radioString stringByAppendingFormat:@" [%s]", [ [ self dateString ] UTF8String ] ] ;		//  v1.11j
		NSLog( str ) ;
		radioString = @"RADIO < " ;
	}
}

- (void)sendRadio:(unsigned char*)radioBytes length:(int)length
{
	int i ;
	unsigned char string[1024] ;
	char more[8], msg[1024] ;
	
	// v1.11
	if ( logToConsole ) {
		for ( i = 0; i < length; i++ ) {
			radioString = [ radioString stringByAppendingFormat:@"%02X ", radioBytes[i] & 0xff ] ;
		}
		[ radioDataTimer setFireDate:[ NSDate dateWithTimeIntervalSinceNow:0.05 ] ] ;
	}
	if ( debugChannel || debugRadio || debugRadioIntoWindow ) {
		strcpy( msg, "to RADIO: " ) ;
		for ( i = 0; i < length; i++ ) {
			sprintf( more, "%02X ", radioBytes[i] ) ;
			strcat( msg, more ) ;
		}
	}
	if ( debugChannel ) {
		Log( debugChannel, "%s\n", msg ) ;
	}
	if ( debugRadio ) {
		Log( debugRadio, "%s\n", msg ) ;
	}
	if ( debugRadioIntoWindow ) {
		strcat( msg, "\n" ) ;
		[ controller log:msg ] ;
	}
	[ sendRadioLock lock ] ;						//  v1.11q
	for ( i = 0; i < length; i++ ) {
		[ self appendRadio:radioBytes[i] toArray:&string[i*4] ] ;
		//[ keyer writeFrame:string ] ;
	}
	[ keyer writeFrames:string length:length*4 ] ;	//	v1.11q
	[ sendRadioLock unlock ] ;						//  v1.11q
}

//  send WinKey
//  the control byte is the second frame of a shared sequence, so we need to send a nop frame first
//	send the flag in the first frame just in case
- (void)sendWinkey:(int)byte
{
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x48, 0x80, 0x80, 0x80 } ;
	
	if ( flagByte & 0x80 ) nop[0] |= 1 ;			// MSB of flag data
	nop[3] |= flagByte ;							// 7 bit flag with MSB set
	if ( byte & 0x80 ) nop[8] |= 1 ;				// MSB of WinKey data
	nop[11] |= byte ;								// 7 bit WinKey with MSB set
	[ keyer writeFrames:nop length:12 ] ;
}

- (void)sendFSK:(int)byte
{
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x48, 0x80, 0x80, 0x80 } ;
	
	if ( flagByte & 0x80 ) nop[0] |= 1 ;			// MSB of flag data
	nop[3] |= flagByte ;								// 7 bit flag with MSB set
	if ( byte & 0x80 ) nop[12] |= 1 ;				// MSB of FSK data
	nop[15] |= byte ;								// 7 bit FSK with MSB set
	[ keyer writeFrames:nop length:16 ] ;
}

- (void)sendExtFSK:(int)byte
{
	unsigned char nop[] = { 0x08, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80, 0x40, 0x80, 0x80, 0x80 } ;
	
	if ( flagByte & 0x80 ) nop[0] |= 1 ;			// MSB of flag data
	nop[3] |= flagByte ;							// 7 bit flag with MSB set
	if ( byte & 0x80 ) nop[16] |= 1 ;				// MSB of ExtFSK data
	nop[19] |= byte ;								// 7 bit ExtFSK with MSB set
	[ keyer writeFrames:nop length:16 ] ;
}

- (void)sendHeartbeat
{
	unsigned char areYouThere[2] = { 0x7e, 0xfe } ;
	Log( debug, "sending heartbeat to %s\n", [ deviceName cString ]+10 ) ;
	[ self sendControl:areYouThere length:2 ] ;
}

- (void)getVersion
{
	unsigned char getVersion[2] = { 0x05, 0x85 } ;
	[ self sendControl:getVersion length:2 ] ;
}

- (Boolean)PTT
{
	return ( ( flagByte & PTTFLAG ) != 0 ) ;
}

- (void)setPTT:(Boolean)state
{
	[ flags reset ] ;
	if ( state == YES ) flagByte |= PTTFLAG  ; else flagByte &= ~( PTTFLAG ) ;
	[ self sendFlags ] ;
}

- (Boolean)RTS
{
	return ( ( flagByte & RTSFLAG ) != 0 ) ;
}

- (void)setRTS:(Boolean)state
{
	[ flags reset ] ;
	if ( state == YES ) flagByte |= RTSFLAG ; else flagByte &= ~( RTSFLAG ) ;
	[ self sendFlags ] ;
}

- (Boolean)serialCW
{
	return ( ( flagByte & CWFLAG ) != 0 ) ;
}

- (void)setSerialCW:(Boolean)state
{
	[ flags reset ] ;
	if ( state == YES ) flagByte |= CWFLAG ; else flagByte &= ~( CWFLAG ) ;
	[ self sendFlags ] ;
}

- (NSString*)FSK
{
	return [ fsk get ] ;
}

//  send string to FSK channel
- (void)setFSK:(NSString*)nsstring
{
	const char *string ;
	
	if ( nsstring ) {
		[ fsk reset ] ;
		string = [ nsstring cString ] ;
		while ( *string ) [ self sendFSK:( *string++ )&0xff ] ;
	}
}

- (NSString*)WINKEY
{
	return [ winkey get ] ;
}

// v 0.5
- (void)setWINKEY:(NSString*)nsstring
{
	int length, i ;
	
	if ( nsstring ) {
		[ winkey reset ] ;
		length = [ nsstring length ] ;
		for ( i = 0; i < length; i++ ) [ self sendWinkey:[ nsstring characterAtIndex:i ] ] ;
	}
}


- (NSString*)WinKeyEmulate 
{
	return @"" ;
}

//  send string to WinKey Emulator
- (void)setWinKeyEmulate:(NSString*)nsstring
{
	const char *input ;
	int i, length ;
	
	if ( nsstring ) {
		length = [ nsstring length ] ;
		input = [ nsstring cString ] ;
		for ( i = 0; i < length; i++ ) {
			[ emulator sendWinkey:( *input++ )&0x7f ] ;
		}
	}
}

- (NSString*)WinKeyEmulateHex
{
	return @"" ;
}

//  send string to WinKey Emulator
- (void)setWinKeyEmulateHex:(NSString*)nsstring
{
	const char *input ;
	int i, length, v ;
	
	if ( nsstring ) {
		length = [ nsstring length ]/2 ;
		input = [ nsstring cString ] ;
		for ( i = 0; i < length; i++ ) {
			v = asciiHex[ ( *input++ )&0x7f ] * 16 ;
			v += asciiHex[ ( *input++ )&0x7f ] ;
			[ emulator sendWinkey:v ] ;
		}
	}
}

- (void)sendSerialCW:(Boolean)state
{
	if ( state == YES ) flagByte |= CWFLAG ; else flagByte &= ~( CWFLAG ) ;
	[ self sendFlags ] ;
}

//  convert a hex string to a binary string and return length of returned string
static int convertHexString( unsigned char *result, NSString *nsstring )
{
	int i, length, v ;
	const char *input ;
	
	if ( nsstring ) {
		length = [ nsstring length ]/2 ;
		input = [ nsstring cString ] ;
		for ( i = 0; i < length; i++ ) {
			v = asciiHex[ ( *input++ )&0x7f ] * 16 ;
			v += asciiHex[ ( *input++ )&0x7f ] ;
			result[i] = v ;
		}
		return length ;
	}
	return 0 ;
}

//  write-only AppleScript
- (NSString*)WINKEYhex
{
	return @"" ;
}

- (void)setWINKEYhex:(NSString*)nsstring
{
	unsigned char string[256] ;
	int i, length ;
	
	length = convertHexString( string, nsstring ) ;
	for ( i = 0; i < length; i++ )  [ self sendWinkey:string[i]&0xff ] ;
}

- (NSString*)CONTROL
{
	return [ control get ] ;
}

- (void)setCONTROL:(NSString*)nsstring
{
	unsigned char string[256] ;
	int length ;
	
	length = convertHexString( string, nsstring ) ;
	if ( length ) {
		[ control reset ] ;
		[ self sendControl:string length:length ] ;
	}
}

- (void)setControl:(unsigned char*)string length:(long)length
{
	int first = string[0] & 0xff ;
	
	if ( first == 0x2c || first == 0x7e ) [ server passFilteredControl:first ] ;
	[ self sendControl:string length:length ] ;
}

- (NSString*)RADIO
{
	return [ radio get ] ;
}

- (void)setRADIO:(NSString*)nsstring
{
	unsigned char string[256] ;
	int length ;
	
	length = convertHexString( string, nsstring ) ;
	if ( length ) {
		[ radio reset ] ;
		[ self sendRadio:string length:length ] ;
	}
}

- (void)setRadio:(unsigned char*)string length:(long)length
{
	[ self sendRadio:string length:length ] ;
}

- (NSString*)FLAGS
{
	return [ flags get ] ;
}

//  NOTE: avoid using this, use -setPTT:, -setRTS: or -setSerialCW: instead
- (void)setFLAGS:(NSString*)flag
{
}

- (IBAction)testPTT:(id)sender
{
	flagByte |= PTTFLAG ;				//  set PTT flag
	[ self sendFlags ] ;
}

- (IBAction)testUnPTT:(id)sender
{
	flagByte &= ~( PTTFLAG ) ;			//  clear PTT flag
	[ self sendFlags ] ;
}

- (void)setInt:(int)intval forKey:(NSString*)key
{
	[ prefs setObject:[ NSNumber numberWithInt:intval ] forKey:key ] ;
}

- (void)setFloat:(float)floatval forKey:(NSString*)key
{
	[ prefs setObject:[ NSNumber numberWithFloat:floatval ] forKey:key ] ;
}

- (void)setString:(NSString*)stringval forKey:(NSString*)key
{
	[ prefs setObject:[ NSString stringWithString:stringval ] forKey:key ] ;
}

- (int)intForKey:(NSString*)key
{
	return [ [ prefs objectForKey:key ] intValue ] ;
}

//  set up keyer
- (void)setupDeviceFromPref:(NSMutableDictionary*)inPrefs keyerType:(enum KeyerType)keyerType
{	
	NSNumber *number ;
	int timeoutValue ;
	
	prefs = inPrefs ;
	if ( keyerType == microKeyer2Type ) [ keyerSettings setAsMicroKeyer2 ] ;
	else if ( keyerType == digiKeyer2Type ) [ keyerSettings setAsDigiKeyer2 ] ;		//  v1.62

	[ keyerSettings setupKeyerFromPref:prefs ] ;
	
	//  v1.90 aggregate timeout for each keyerID (kAggregateTimeouts moved to setupDictionary)
	number = [ prefs objectForKey:kAggregateTimeout ] ;
	if ( number ) {
		timeoutValue = [ number intValue ] ;
		if ( timeoutValue > 2 && timeoutValue < 200 ) [ self setAggregateTimeout:timeoutValue ] ;
	}
	//  v1.90 enable for each keyerID
	number = [ prefs objectForKey:kKeyerEnabled ] ;
	[ self setEnabled:( number != nil ) ? [ number boolValue ] : YES ] ;
}

- (NSMutableDictionary*)settingsPlist
{
	NSMutableDictionary *keyerPlist ;
	int timeoutValue ;
	
	keyerPlist = ( [ self connected ] ) ? [ keyerSettings settingsPlist ] : [ keyerSettings defaultSettingsPlist ] ;
	
	//	v1.90 place keyer ID (including serial number) into plist
	if ( keyerID ) [ keyerPlist setObject:keyerID forKey:kKeyerID ] ;
	//	v1.90 place aggregate timeout into plist
	timeoutValue = [ self aggregateTimeout ] ;
	if ( timeoutValue <= 2 || timeoutValue >= 200 ) timeoutValue = 20 ;
	[ keyerPlist setObject:[ NSNumber numberWithInt:timeoutValue ] forKey:kAggregateTimeout ] ;
	//	v1.90 place enable into plist
	[ keyerPlist setObject:[ NSNumber numberWithBool:[ self isEnabled ] ] forKey:kKeyerEnabled ] ;
	return keyerPlist ;

}

- (void)finishUpdateAfterConnection
{
	[ keyerSettings sendSettingsToKeyer ] ;
}

//  v1.11t -- aggregate timeout in milliseconds
- (void)timeoutFieldChanged:(id)sender
{
	[ self setAggregateTimeout:[ sender intValue ] ] ;
}

//  v1.11
- (void)setConsoleDebug:(Boolean)state
{
	logToConsole = state ;
	if ( server ) [ server setConsoleDebug:state ] ;
}

- (void)setDebugFrames:(Boolean)state
{
	debugFramesIntoWindow = state ;
}

- (void)setDebugRadio:(Boolean)state
{
	debugRadioIntoWindow = state ;
}

- (void)setDebugFlags:(Boolean)state
{
	debugFlagsIntoWindow = state ;
}

- (void)setDebugControl:(Boolean)state
{
	debugControlIntoWindow = state ;
}

- (void)setDebugBytes:(Boolean)state
{
	debugBytesIntoWindow = state ;
}

- (int)aggregateTimeout
{
	return [ timeoutTextField intValue ] ;
}

- (void)setAggregateTimeout:(int)t
{
	if ( t <= 1 ) t = 1 ; else if ( t > 250 ) t = 250 ;

	aggregateTimeout = t ;
	[ timeoutTextField setIntValue:t ] ;
	[ server setRadioAggregateTimeout:t*0.001 ] ;
}

- (void)shutdown
{
	[ keyerSettings shutdown ] ;
}

//  send sleep manager calls to keyer interface (serial port to keyer)
- (void)aboutToSleep
{
	[ keyer aboutToSleep ] ;
}

- (void)wakeFromSleep
{
	[ keyer wakeFromSleep ] ;
}

//  v1.40
- (Boolean)addUDPClient:(struct sockaddr_in*)socket
{
	int i ;
	UDPClient *u ;
	NSTimeInterval now ;
	
	//  first check if it is aready in the list
	if ( udpClients >= 255 ) return NO ;
	
	for ( i = 0; i < udpClients; i++ ) {
		if ( socket->sin_port == udpClient[i].socket.sin_port ) return YES ;
	}
	u = &udpClient[udpClients++] ;
	now = [ NSDate timeIntervalSinceReferenceDate ] ;
	u->lastAccessed = now ; 
	for ( i = 0; i < 6; i++ ) {
		u->timePreviousCommandReceived[i] = now ; 
		u->responseWindow[i] = DEFAULTRESPONSEWINDOW ;			//  default value
	}
	for ( i = 0; i < 128; i++ ) u->allowControlPacket[i] = 0 ;
	u->socket = *socket ;
	return YES ;
}

//  v1.40
//  remove a UDP client and move the rest, if any, up the list
- (void)removeUDPClient:(struct sockaddr_in*)socket
{
	int i, j ;
	
	for ( i = 0; i < udpClients; i++ ) {
		if ( socket->sin_port == udpClient[i].socket.sin_port ) {
			//  found the element to remove
			udpClients-- ;
			if ( i < udpClients ) {
				for ( j = i; j < udpClients; j++ ) udpClient[j] = udpClient[j+1] ;
			}
			return ;
		}
	}
}

//  v1.40
- (int)addNewUDPClient:(struct sockaddr_in*)socket
{
	struct sockaddr_in udp ;
	socklen_t addrLength ;
	
	if ( udpServer == nil || [ self addUDPClient:socket ] == NO ) return 0 ;
	
	//  get port of server (us).
	getsockname( udpSocket, (struct sockaddr*)&udp, &addrLength ) ;
	
	return udp.sin_port ;
}

//  v1.40 find the udp client
- (UDPClient*)udpClient:(struct sockaddr_in*)socket
{
	int i ;
	
	for ( i = 0; i < udpClients; i++ ) {
		if ( socket->sin_port == udpClient[i].socket.sin_port ) return &udpClient[i] ;
	}
	return nil ;
}

- (void)wakeupFromClient:(UDPClient*)u
{
	u->lastAccessed = [ NSDate timeIntervalSinceReferenceDate ] ;
}

- (void)wakeupFrom:(struct sockaddr_in*)socket
{
	UDPClient *u ;
	
	u = [ self udpClient:socket ] ;
	if ( u ) [ self wakeupFromClient:u ] ;
}

//  v1.40
//  update last accessed date andindividual access date
- (void)updateUDPClient:(UDPClient*)client index:(int)index writeOnly:(Boolean)writeOnly
{
	NSTimeInterval now ;
	
	now = [ NSDate timeIntervalSinceReferenceDate ] ;
	client->lastAccessed = now ;
	if ( index < 6 && !writeOnly ) client->timePreviousCommandReceived[index] = now ;
}

//	1.40 UDP support
- (void)udpRouterThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int i, n, windowIndex ;
	Boolean state, writeOnly ;
	unsigned char commandByte, str[1024] ;
	UDPClient *udpClientPtr ;
	unichar chars[1024] ;
	NSString *string ;
	struct sockaddr_in udp ;
	socklen_t addrLength ;
	
	while ( 1 ) {
		//  block indefinitely, waiting for a single byte request from a client	
		addrLength = sizeof( struct sockaddr_in ) ;
		n = recvfrom( udpSocket, &str, 256, 0, (struct sockaddr *)&udp, &addrLength ) ;

		// find UDPClient that has the same socket as the received socket
		udpClientPtr = [ self udpClient:&udp ] ;
		
		if ( n > 0 && udpClientPtr != nil ) {
			commandByte = str[0] ;
			writeOnly = ( ( commandByte & WRITEONLY ) == WRITEONLY ) ;
			commandByte &= ( ~WRITEONLY ) ; 
			
			switch ( commandByte ) {
			case WATCHDOG:
				[ self wakeupFromClient:udpClientPtr ] ;
				break ;
			case PTT_PREFIX:
			case CW_PREFIX:
			case RTS_PREFIX:
				state = ( str[1] == 0 || str[1] == '0' ) ? NO : YES ;
				switch ( commandByte ) {
				case PTT_PREFIX:
					[ self setPTT:state ] ;
					[ self updateUDPClient:udpClientPtr index:PTT_INDEX writeOnly:writeOnly ] ;
					break ;
				case CW_PREFIX:
					[ self setSerialCW:state ] ;
					[ self updateUDPClient:udpClientPtr index:CW_INDEX writeOnly:writeOnly ] ;
					break ;
				case RTS_PREFIX:
					[ self setRTS:state ] ;
					[ self updateUDPClient:udpClientPtr index:RTS_INDEX writeOnly:writeOnly ] ;
					break ;
				}
				break ;
			case WINKEY_PREFIX:
			case FSK_PREFIX:
				//  make bytes into unicode characters
				for ( i = 0; i < n-1; i++ ) chars[i] = str[i+1]&0xff ;
				string = [ NSString stringWithCharacters:chars length:n-1 ] ;
				switch ( commandByte ) {	
				case WINKEY_PREFIX:
					[ self setWINKEY:string ] ;
					[ self updateUDPClient:udpClientPtr index:WINKEY_INDEX writeOnly:writeOnly ] ;
					break ;
				case FSK_PREFIX:
					[ self setFSK:string ] ;
					[ self updateUDPClient:udpClientPtr index:FSK_INDEX writeOnly:writeOnly ] ;
					break ;
				}
				break ;
			case CONTROL_PREFIX:
				[ self setControl:&str[1] length:n-1 ] ;
				[ self updateUDPClient:udpClientPtr index:CONTROL_INDEX writeOnly:writeOnly ] ;
				[ udpLock lock ] ;
				udpClientPtr->allowControlPacket[str[1]&0x7f] += 1 ;
				[ udpLock unlock ] ;
				break ;
			case RADIO_PREFIX:
				[ self setRadio:&str[1] length:n-1 ] ;
				[ self updateUDPClient:udpClientPtr index:RADIO_INDEX writeOnly:writeOnly ] ;
				break ;
			case WINDOW_PREFIX:
				//  E.g., <WINDOW_PREFIX> <RADIO_PREFIX> <n> where n = 16 == 1 second, n = 254 == approx 16 seconds and n == 0 => default n == 255 => indefinite
				windowIndex = -1 ;
				switch ( str[1] & 0xff ) {
				case RADIO_PREFIX:
					windowIndex = RADIO_INDEX ;
					break ;
				case CONTROL_PREFIX:
					windowIndex = CONTROL_INDEX ;
					break ;
				case FLAGS_PREFIX:
				case RTS_PREFIX:
				case PTT_PREFIX:
				case CW_INDEX:
					windowIndex = FLAGS_INDEX ;
					break ;
				case FSK_PREFIX:
					windowIndex = FSK_INDEX ;
					break ;
				case WINKEY_PREFIX:
					windowIndex = WINKEY_INDEX ;
					break ;
				case EMULATOR_PREFIX:
					windowIndex = EMULATOR_INDEX ;
					break ;
				}
				if ( windowIndex >= 0 ) {
					float actualTime ;
					int time = str[2] & 0xff ;
					if ( time == 0 ) actualTime = DEFAULTRESPONSEWINDOW ;
					else if ( time == 255 ) actualTime = 100.0*1000000.0 ;
					else actualTime = time/16.0 ;
					udpClientPtr->responseWindow[windowIndex] = actualTime ;
				}
				break ;
			default:
				break ;
			}
		}
	}
	//  abort polling when an error is seen
	[ pool release ] ;
}

//	the order this router object is in the list that is sent to AppleScript
- (void)setApplescriptListIndex:(int)n
{
	applescriptListIndex = n ;
}

//  For applescript array support
- (NSScriptObjectSpecifier*)objectSpecifier
{
	NSScriptClassDescription *cdesc ;
	NSScriptObjectSpecifier *spec ;
	
	cdesc = (NSScriptClassDescription*)[ NSScriptClassDescription classDescriptionForClass:[ Router class ] ] ;	
	spec = [ [ NSIndexSpecifier allocWithZone:[ self zone ] ] initWithContainerClassDescription:cdesc containerSpecifier:nil key:@"keyers" index:applescriptListIndex ] ;
	
	return [ spec autorelease ] ;
}

@end
