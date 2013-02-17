//
//  Controller.m
//  uH Router
//
//  Created by Kok Chen on 5/2/06.
	#include "Copyright.h"
	
#import "Controller.h"
#import "LogMacro.h"
#import "Router.h"
#import "RouterPlist.h"
#import "RouterCommands.h"
#import "WinKeyer.h"
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/IOMessage.h>
#include <sys/stat.h>

#define ROUTERTEST 1

@implementation Controller

static void powerManagerCallback( void *refcon, io_service_t service, natural_t messageType, void *message ) ;


- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	IONotificationPortRef notify ;
	io_object_t	ioIterator ;
	
	
	diagLock = [ [ NSLock alloc ] init ] ;
	debug = NO ;
	logIntoWindow = NO ;
	
	[ [ debugTextView window ] setDelegate:self ] ;
		
	//  catches sleep and wakeup
	powerManager = IORegisterForSystemPower( self, &notify, powerManagerCallback, &ioIterator ) ;
	CFRunLoopAddSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notify), kCFRunLoopDefaultMode ) ;
	
	routers = prototypes = 0 ;
	[ [ NSApplication sharedApplication ] setDelegate:self ] ;
	
	//  Create individual routers for each device
	//  NOTE: array in object allows up to 8 routers
	//  NOTE: must maintain this order 0: microKEYER, 1: CW KEYER, 2: DIGI KEYER
	Log( debug, "creating Router Prototypes\n" ) ;
	prototype[prototypes] = [ [ Router alloc ] initPrototype:@"microKeyer" fifo:@"/tmp/microRouter" deviceName:@"usbserial-MK" command:OPENMICROKEYER controller:self ] ;
	prototypes++ ;
	prototype[prototypes] = [ [ Router alloc ] initPrototype:@"CW Keyer" fifo:@"/tmp/cwRouter" deviceName:@"usbserial-CK" command:OPENCWKEYER controller:self ] ;
	[ prototype[prototypes] setHasFSK:NO ] ;
	prototypes++ ;
	prototype[prototypes] = [ [ Router alloc ] initPrototype:@"digiKeyer" fifo:@"/tmp/digiRouter" deviceName:@"usbserial-DK" command:OPENDIGIKEYER controller:self ] ;
	[ prototype[prototypes] setHasWINKEY:NO ] ;
	prototypes++ ;
    
	winKeyer = [ [ WinKeyer alloc ] initIntoWindow:winKeyPrefPanel router:self ] ;
        //[ WinkeyerSettingsWindow setTitle:title ] ;
    
	Log( debug, "updating from plist\n" ) ;
	[ self initFromPlist ] ;
	[ self pickupMicroHamDevices ] ;
	
	//  remove original dummy tab view item in Preference and KeyerMode Nibs
	//	v1.80 moved here after devices are discovered
	if ( [ prefTabView numberOfTabViewItems ] == 1 ) {
		//  v1.80 leave "No device found" tab
	}
	else {
		[ prefTabView removeTabViewItem:[ prefTabView tabViewItemAtIndex:0 ] ] ;
		[ modeTabView removeTabViewItem:[ modeTabView tabViewItemAtIndex:0 ] ] ;
	}
	
	//  Now create a named pipe (FIFO) to listen for requests to the master port
	//  As the server, we read from the client's "Write" fifo.
	mainFIFO = [ [ NamedFIFOPair alloc ] initWithPipeName:"/tmp/microHamRouter" ] ;
	if ( mainFIFO ) {
		if ( [ mainFIFO inputFileDescriptor ] > 0 && [ mainFIFO outputFileDescriptor ] > 0 ) {
			//  start a thread to listen for and respond to requests
			[ NSThread detachNewThreadSelector:@selector(monitorThread:) toTarget:self withObject:self ] ;
		}
	}
	//  v1.40 -- UDP support
	//  create router socket address
	routerSocket = 0 ;
	memset( &udpServer, 0, sizeof( udpServer ) ) ;				//  clear structure
	udpServer.sin_family = AF_INET ;							//  create as IP
	udpServer.sin_addr.s_addr = htonl( INADDR_ANY ) ;			//  accept connection from any host
	udpServer.sin_port = htons( mHUDPServerPort ) ;				//  mH Router master port
	//  get socket
	if ( ( routerSocket = socket( PF_INET, SOCK_DGRAM, IPPROTO_UDP ) ) >= 0 ) {
		//  Bind socket to address of router 
		if ( bind( routerSocket, (struct sockaddr* )&udpServer, sizeof( udpServer ) ) >= 0 ) {
			//  start a thread to listen for and respond to requests
			[ NSThread detachNewThreadSelector:@selector(udpMonitorThread:) toTarget:self withObject:self ] ;
		}
		else {
			NSLog( @"cannot bind router's master port!!!" ) ;
		}
	}
	
	//  Bring up the router test (NOTE:this test bypasses the server)
	routerTest = nil ;

	#ifdef ROUTERTEST
	routerTest = [ [ RouterTest alloc ] initWithRouters:&router[0] count:routers ] ;
	#endif
	
	[ self setInterface:debugFrameButton to:@selector(debugFrameButtonChanged:) ] ;
	[ self setInterface:debugRadioButton to:@selector(debugRadioButtonChanged:) ] ;
	[ self setInterface:debugFlagsButton to:@selector(debugFlagsButtonChanged:) ] ;
	[ self setInterface:debugControlButton to:@selector(debugControlButtonChanged:) ] ;
	[ self setInterface:debugBytesButton to:@selector(debugBytesButtonChanged:) ] ;
}

- (void)dealloc
{
	[ diagLock release ] ;
	[ super dealloc ] ;
}

// (local) update (open/close) microHAM ports according to state in the preference
- (void)updatePorts
{
	int i ;
	
	Log( debug, "connecting to devices\n" ) ;
	for ( i = 0; i < routers; i++ ) {
		[ router[i] connect ] ;
	}
	Log( debug, "connected\n" ) ;
}

//  (local) find all serial port on the computer
//  collect the stream name and the Unix device path name for each one and return the number that is found
- (int)findPorts:(NSString**)path stream:(NSString**)stream max:(int)maxCount
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
			stream[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
            CFRelease( cfString ) ;
			cfString = IORegistryEntryCreateCFProperty( modemService, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0 ) ;
			if ( cfString )  {
				path[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
				CFRelease( cfString ) ;
				count++ ;
			}
		}
        IOObjectRelease( modemService ) ;
    }
	IOObjectRelease( serialPortIterator ) ;
	return count ;
}

//	v1.90
- (NSDictionary*)findSetupDictionaryForKeyerID:(NSString*)keyerID
{
	int k, setups ;
	NSArray *setupArray ;
	NSString *string ;
	NSDictionary *setupDictionary ;

	setupArray = [ prefs objectForKey:kDeviceSetups ] ;
	if ( setupArray != nil ) {
		setups = [ setupArray count ] ;
		for ( k = 0; k < setups; k++ ) {
			//  fetch each item in array, it should be a setup dictionary
			setupDictionary = [ setupArray objectAtIndex:k ] ;
			string = [ setupDictionary objectForKey:kKeyerID ] ;
			if ( string ) {
				//  check keyer ID of the plist with the keyerID of the stream
				if ( [ string isEqualToString:keyerID ] == YES ) return setupDictionary ;
			}
		}
	}
	return nil ;
}

//  v1.90
- (NSDictionary*)findSetupDictionaryForStream:(NSString*)stream
{
	int dash ;
	NSString *keyerID ;
	
	//  remove the "usbserial-" prefix of the stream name
	dash = [ stream rangeOfString:@"-" ].location ;
	if ( dash < 1 || dash > 16 ) return nil ;				//  stream name does not contain -
	
	//	get keyerID of stream
	keyerID = [ stream substringFromIndex:dash+1 ] ;
	return [ self findSetupDictionaryForKeyerID:keyerID ] ;
}

//  pick out the path and stream of microHam ports from the available devices
//	if multiple devices (e.g., 2 microKEYERS) exist, this method picks the first one
- (void)pickupMicroHamDevices
{
	NSString *check, *alias ;
	int i, j, ports ;
	Router *device, *proto ;
	NSString *stream[32], *path[32] ;
	NSArray *setupArray ;
	NSDictionary *setupDictionary ;
	NSMutableDictionary *mutableSetupDictionary ;
	enum KeyerType keyerType ;
	
	//  create a dummy router for each type of keyer for AppleScript (unconnected to any keyer)
	for ( i = 0; i < 3; i++ ) {
		router[routers++] = [ [ Router alloc ] initIntoTabView:prefTabView keyerModeTabView:modeTabView prototype:prototype[i] streamName:@"" index:routers ] ;
	}
	
	//  find all serial ports
	ports = [ self findPorts:&path[0] stream:&stream[0] max:32 ] ;
	//  now find the ones that are associated with the microHAM devices
	for ( i = 0; i < ports; i++ ) {
		check = ( [ stream[i] length ] < 13 ) ? @"" : [ stream[i] substringToIndex:12 ] ;
		alias = [ NSString stringWithString:check ] ;
		
		keyerType = notAKeyerType ;
		if ( [ alias isEqualToString:@"usbserial-MK" ] ) keyerType = microKeyerType ;
		else if ( [ alias isEqualToString:@"usbserial-CK" ] ) keyerType = cwKeyerType ;
		else if ( [ alias isEqualToString:@"usbserial-DK" ] ) keyerType = digiKeyerType ;
		
		else if ( [ alias isEqualToString:@"usbserial-M2" ] ) keyerType = microKeyer2Type ;
		else if ( [ alias isEqualToString:@"usbserial-D2" ] ) keyerType = digiKeyer2Type ;						//  v1.62
		
		if ( keyerType == microKeyer2Type ) alias = @"usbserial-MK" ;			//  alias microKeyer 2 as a microKeyer
		if ( keyerType == digiKeyer2Type ) alias = @"usbserial-DK" ;			//  alias digiKeyer 2 as a digiKeyer
	
		for ( j = 0; j < prototypes; j++ ) {
		
			proto = prototype[j] ;
			if ( [ alias isEqualToString:[ proto deviceName ] ] ) {
			
				device = [ [ Router alloc ] initIntoTabView:prefTabView keyerModeTabView:modeTabView prototype:proto streamName:stream[i] index:routers ] ;
				router[routers++] = device ;

				Log( debug, "Found device %s\n", [ stream[i] cString ] ) ;
				[ device setStream:stream[i] ] ;
				[ device setPath:path[i] ] ;

				//  set up SETTINGS string : array of NSDictionary
				setupArray = [ prefs objectForKey:kDeviceSetups ] ;
				if ( setupArray != nil  ) {
					if ( [ [ prefs objectForKey:kPrefVersion ] intValue ] < 3 ) {
						//  old style plist and workaround for v1.8 bug
						int arrayIndex = ( [ setupArray count ] < 4 ) ? j : 3 ;
						setupDictionary = nil ;
						if ( setupArray != nil && [ setupArray count ] >= arrayIndex ) {
							setupDictionary = [ setupArray objectAtIndex:arrayIndex ] ;
						}
						mutableSetupDictionary = [ [ NSMutableDictionary alloc  ] initWithCapacity:8 ] ;
						if ( setupDictionary ) [ mutableSetupDictionary setDictionary:setupDictionary ] ;
						[ device setupDeviceFromPref:mutableSetupDictionary keyerType:keyerType ] ;
					}
					else {
						//	v1.90 check for plist setting with the same keyer ID (includes serial number)
						mutableSetupDictionary = [ [ NSMutableDictionary alloc  ] initWithCapacity:8 ] ;
						setupDictionary = [ self findSetupDictionaryForStream:stream[i] ] ;
						if ( setupDictionary ) {
							//  found keyer setting with matching keyerID, set up from plist
							[ mutableSetupDictionary setDictionary:setupDictionary ] ;
						}
						[ device setupDeviceFromPref:mutableSetupDictionary keyerType:keyerType ] ;
					}
				}
			}
		}
		[ stream[i] release ] ;
		[ path[i] release ] ;
	}
	for ( j = 0; j < routers; j++ ) [ router[j] setupParameters ] ;
	[ self updatePorts ] ;
	for ( j = 0; j < routers; j++ ) {
		if ( [ router[j] connected ] ) [ router[j] finishUpdateAfterConnection ] ;
	}
}

//  set up preferences from plist
- (void)initFromPlist
{
	NSString *bundleName, *errorString ;
	NSData *xmlData ;
	char str[128] ;
	Boolean alive ;
	id plist ;
		
	//  initial default preference value
	prefs = [ [ NSMutableDictionary alloc ] init ] ;
	[ prefs setObject:[ NSNumber numberWithInt:3 ] forKey:kPrefVersion ] ;
	[ prefs setObject:[ prefPanel stringWithSavedFrame ] forKey:kWindowPosition ] ;
	//  stay alive state
	[ prefs setObject:[ NSNumber numberWithBool:NO ] forKey:kStayAlive ] ;
	
	//  ---- update prefs from plist file ----
	bundleName = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleIdentifier" ] ;
	strcpy( str, kPlistDirectory ) ;
	if ( bundleName ) {
		//strcat( str, [ bundleName cString ] ) ;
		strcat( str, "w7ay.mH Router" ) ;			//  0.80
		strcat( str, ".plist" ) ;
		[ bundleName release ] ;
	}
	plistPath = [ [ [ NSString stringWithCString:str encoding:NSASCIIStringEncoding ] stringByExpandingTildeInPath ] retain ] ;
	xmlData = [ NSData dataWithContentsOfFile:plistPath ] ;
	plist = (id)CFPropertyListCreateFromXMLData( kCFAllocatorDefault, (CFDataRef)xmlData, kCFPropertyListImmutable, (CFStringRef*)&errorString ) ;
	if ( plist ) {
		// merge and overwrite default values
		[ prefs addEntriesFromDictionary:plist ] ;
	}
	[ plist release ] ;
	
	//  update objects after reading plist
	[ prefPanel setFrameFromString:[ prefs objectForKey:kWindowPosition ] ] ;

	//  update stay alive state
	alive =  [ [ prefs objectForKey:kStayAlive ] boolValue ] ;	
	[ stayAliveItem setState: ( alive ) ? NSOnState : NSOffState ] ;
}

- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info
{
	[ [ NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] runModal ] ;
}

//  Open preference window
- (IBAction)openPref:(id)sender
{
	[ prefPanel orderFront:self ] ; 
	[ NSApp activateIgnoringOtherApps:YES ] ; 	
}

- (IBAction)openModePanel:(id)sender
{
	[ modePanel makeKeyAndOrderFront:self ] ; 
}

- (IBAction)openTest:(id)sender 
{
	[ routerTest openPanel ] ;
	[ NSApp activateIgnoringOtherApps:YES ] ; 	
}

- (IBAction)openWinKeyPrefs:(id)sender
{
    [ winKeyPrefPanel orderFront:self ];
    [ NSApp activateIgnoringOtherApps:YES];
}

//	return a list of non-dummy keyers
- (Router*)keyerAtIndex:(int)p
{
	int i, n ;
	Router *r ;
	NSMutableArray *array ;
	
	array = [ NSMutableArray array ] ;
	
	n = 0 ;
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r isDummy ] == NO ) {
			if ( p == n ) return r ;
			n++ ;
		}
	}
	return nil ;
}

//	v1.80
- (void)processFIFOOpenCommand:(Router*)r fd:(int)writefd
{
	const char *name ;

	if ( logToConsole ) {
		NSLog( @"Adding new client to %s", [ [ r deviceName ] UTF8String ] ) ; 
	}
	name = [ r addNewClient ] ;
	//  return name to client or an empty string if -addNewClient failed
	if ( name ) write( writefd, name, strlen(name)+1 ) ; 
	else {
		if ( logToConsole ) NSLog( @"Failed to add new client to %s", [ [ r deviceName ] cString ] ) ; 
		write( writefd, "", 1 ) ;
	}
}

//  v1.80
- (void)processFIFOKeyerIDCommand:(int)n fd:(int)writefd
{
	Router *r ;
	const char *s ;
	
	r = [ self keyerAtIndex:n ] ;
	if ( r == nil ) {
		write( writefd, "", 1 ) ;
		return ;
	}
	s = [ [ r keyerID ] cString ] ;
	write( writefd, s, strlen(s)+1 ) ;
}

//  v1.80
- (void)processFIFOOpenKeyerCommand:(char*)name fd:(int)writefd
{
	int i ;
	Router *r ;
	NSString *keyerID ;
	
	//  look for a router with name
	keyerID = [ NSString stringWithCString:name ] ;
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r isDummy ] == NO ) {
			if ( [ keyerID isEqualToString:[ r keyerID ] ] == YES ) {
				if ( logToConsole ) {
					NSLog( @"Adding new client to device named %s", name ) ; 
				}
				[ self processFIFOOpenCommand:r fd:writefd ] ;
				return ;
			}
		}
	}
	if ( logToConsole ) NSLog( @"Failed to add new client to device named %s", name ) ; 
	write( writefd, "", 1 ) ;
}

- (void)returnVersion:(float)ver fd:(int)writefd
{
	unsigned char dat[2] ;
	
	dat[0] = ver ;
	dat[1] = ( ver - dat[0] )*100 ;
	
	write( writefd, dat, 2 ) ;
}

//  This thread listens for requests from clients and create ports for the clients to access the routers
- (void)monitorThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	unsigned char command ;
	char name[21] ;
	int i, count, n, readfd, writefd ;
	fd_set readSet ;
	NSString *version ;
	float fver ;
	
	readfd = [ mainFIFO inputFileDescriptor ] ;
	writefd = [ mainFIFO outputFileDescriptor ] ;
	
	FD_ZERO( &readSet ) ;
	FD_SET( readfd, &readSet ) ;
	
	while ( 1 ) {
		//  block indefinitely, waiting for a request to the main read pipe		
		count = select( FD_SETSIZE, &readSet, nil, nil, nil ) ;
		
		if ( count < 0 ) break ;  //  select error
		if ( count > 0 ) {
			//  read command
			n = read( readfd, &command, 1 ) ;
			
			if ( n > 0 ) {
				switch ( command ) {
				case QUITIFNOKEYER:
					[ self quitIfNoKeyer ] ;
					break ;
				case QUITIFNOTINUSE:
					[ self quitIfNotInUse ] ;
					break ;
				case QUITALWAYS:
					[ self quitAlways ] ;
					break ;
				case ROUTERVERSION:
					version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
					sscanf( [ version cString ], "%f", &fver ) ;
					[ self returnVersion:fver fd:writefd ] ;
					break ;
				case KEYERID:
					//  read argument of KEYERID
					n = read( readfd, &command, 1 ) ;
					[ self processFIFOKeyerIDCommand:command fd:writefd ] ;
					break ;
				case OPENMICROKEYER:
					[ self processFIFOOpenCommand:[ self microKEYER ] fd:writefd ] ;
					break ;
				case OPENCWKEYER:
					[ self processFIFOOpenCommand:[ self cwKEYER ] fd:writefd ] ;
					break ;
				case OPENDIGIKEYER:
					[ self processFIFOOpenCommand:[ self digiKEYER ] fd:writefd ] ;
					break ;
				case OPENKEYER:
					for ( i = 0; i < 20; i++ ) {
						n = read( readfd, &name[i], 1 ) ;
						if ( n < 1 || name[i] == 0 ) break ;
					}
					name[i] = 0 ;
					[ self processFIFOOpenKeyerCommand:name fd:writefd ] ;
					break ;
				}
			}
		}
	}
	//  abort polling when an error is seen
	[ pool release ] ;
}

//	v1.80
- (void)processUDPOpenCommand:(Router*)r client:(struct sockaddr_in*)udpClient
{
	char str[3] ;
	int port ;
	
	if ( logToConsole ) NSLog( @"Adding new UDP client to %s", [ [ r deviceName ] UTF8String ] ) ; 
	
	port = ( [ r connected ] == NO ) ? 0 : [ r addNewUDPClient:udpClient ] ;
	
	//  if router has no UDP port, send back 0
	if ( port != 0 ) {
		port = htons( port ) ;
		str[1] = ( port/256 ) & 0xff ;
		str[2] = port & 0xff ;
	}
	else {
		if ( logToConsole ) NSLog( @"Failed to add new UDP client to %s", [ [ r deviceName ] cString ] ) ; 
		str[1] = str[2] = 0 ;
	}
	str[0] = [ r command ] ;	
	sendto( routerSocket, str, 3, 0, (struct sockaddr*)udpClient, sizeof( struct sockaddr ) ) ;
}

- (void)processUDPKeyerIDCommand:(int)n client:(struct sockaddr_in*)udpClient
{
	const char *name ;
	char str[2] ;
	Router *r ;
	
	r = [ self keyerAtIndex:n ] ;
	
	if ( r == nil ) {
		str[0] = 0 ;
		sendto( routerSocket, str, 1, 0, (struct sockaddr*)udpClient, sizeof( struct sockaddr ) ) ;
		return ;
	}
	name = [ [ r keyerID ] cString ] ;
	sendto( routerSocket, name, strlen(name)+1, 0, (struct sockaddr*)udpClient, sizeof( struct sockaddr ) ) ;
}

//  v1.80
- (void)processUDPOpenKeyerCommand:(char*)name client:(struct sockaddr_in*)udpClient
{
	int i ;
	Router *r ;
	char str[3] ;
	NSString *keyerID ;
	
	//  look for a router with name
	keyerID = [ NSString stringWithCString:name ] ;
	
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r isDummy ] == NO ) {
			if ( [ keyerID isEqualToString:[ r keyerID ] ] == YES ) {
				if ( logToConsole ) NSLog( @"Adding new client to device named %s", name ) ; 
				[ self processUDPOpenCommand:r client:(struct sockaddr_in*)udpClient ] ;
				return ;
			}
		}
	}
	if ( logToConsole ) NSLog( @"Failed to add new UDP client to device named %s", name ) ; 
	//  failed -- return <OPENKEYER><0><0>
	str[0] = OPENKEYER ;
	str[1] = str[2] = 0 ;
	sendto( routerSocket, str, 3, 0, (struct sockaddr*)udpClient, sizeof( struct sockaddr ) ) ;
}

- (void)returnUDPVersion:(float)ver client:(struct sockaddr_in*)udpClient
{
	unsigned char dat[2] ;
	
	dat[0] = ver ;
	dat[1] = ( ver - dat[0] )*100 ;
	
	sendto( routerSocket, dat, 2, 0, (struct sockaddr*)udpClient, sizeof( struct sockaddr ) ) ;
}

//  v1.40 -- this thread listens for UDP requests from clients and create ports for the clients to access the routers
- (void)udpMonitorThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int n, i ;
	unsigned char p[21] ;
	unsigned char command ;
	char name[21] ;
	struct sockaddr_in udpClient ;
	socklen_t addrLength ;
	NSString *version ;
	float fver ;
	
	while ( 1 ) {
		//  block indefinitely, waiting for a single byte request from a client	
		addrLength = sizeof( struct sockaddr_in ) ;
		n = recvfrom( routerSocket, p, 20, 0, (struct sockaddr *)&udpClient, &addrLength ) ;
		
		command = p[0] ;
		
		if ( n > 0 ) {
			switch ( command ) {
			case WATCHDOG:
				for ( i = 0; i < routers; i++ ) [ router[i] wakeupFrom:&udpClient ] ;
				break ;
			case QUITIFNOKEYER:
				[ self quitIfNoKeyer ] ;
				break ;
			case QUITIFNOTINUSE:
				[ self quitIfNotInUse ] ;
				break ;
			case QUITALWAYS:
				[ self quitAlways ] ;
				break ;
			case ROUTERVERSION:
				version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
				sscanf( [ version cString ], "%f", &fver ) ;
				[ self returnUDPVersion:fver client:&udpClient ] ;
				break ;
			case KEYERID:
				[ self processUDPKeyerIDCommand:p[1] client:&udpClient ] ;
				break ;
			case OPENMICROKEYER:
				[ self processUDPOpenCommand:[ self microKEYER ] client:&udpClient ] ;
				break ;
			case OPENCWKEYER:
				[ self processUDPOpenCommand:[ self cwKEYER ] client:&udpClient ] ;
				break ;
			case OPENDIGIKEYER:
				[ self processUDPOpenCommand:[ self digiKEYER ] client:&udpClient ] ;
				break ;
			case OPENKEYER:
				for ( i = 0; i < 20; i++ ) {
					name[i] = p[i+1] ;
					if ( name[i] == 0 ) break ;
				}
				name[i] = 0 ;
				[ self processUDPOpenKeyerCommand:name client:&udpClient ] ;
				break ;
			}
		}
	}
	//  abort polling when an error is seen
	[ pool release ] ;
}

//  make sure all the FIFOs are closed
- (void)shutdown
{
	int i ;
	
	Log( debug, "Shutting down FIFOs.\n" ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] release ] ;
	[ mainFIFO release ] ;
}

- (void)deferredQuit:(NSTimer*)timer
{
	[ NSApp terminate:self ] ;
}

//  NSAApplication delegate for AppleScript
- (BOOL)application:(NSApplication*)sender delegateHandlesKey:(NSString*)key 
{
	//  AppleScript properties
	if ( [ key isEqual:@"quitIfNoKeyer" ] ) return YES ;		
	if ( [ key isEqual:@"quitIfNotInUse" ] ) return YES ;		
	if ( [ key isEqual:@"debug" ] ) return YES ;		
	if ( [ key isEqual:@"microKEYER" ] ) return YES ;		
	if ( [ key isEqual:@"digiKEYER" ] ) return YES ;		
	if ( [ key isEqual:@"cwKEYER" ] ) return YES ;		
	if ( [ key isEqual:@"keyers" ] ) return YES ;				//  v1.80
	if ( [ key isEqual:@"routerVersion" ] ) return YES ;		//  v1.80
	return NO;
}

//  NSTerminate message received by Router.m which in turn sends a message here
//  clean up and save Plist
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
	NSString *string, *activeID, *originalID ;
	NSMutableArray *activeSetups, *originalSetups ;
	NSMutableDictionary *settingsPlist ;
	NSDictionary *originalSetup, *activeSetup ;
	int i, j, originalSize, activeSize ;
	
	if ( logToConsole ) NSLog( @"Application terminate received" ) ;
	
	//  update prefs before writing it out
	[ prefs setObject:[ prefPanel stringWithSavedFrame ] forKey:kWindowPosition ] ;
	//  stay alive state
	[ prefs setObject:[ NSNumber numberWithBool:( [ stayAliveItem state ] == NSOnState )  ] forKey:kStayAlive ] ;
	
	activeSetups = [ NSMutableArray arrayWithCapacity:0 ] ;
	//  v1.90 only include active routers in plist
	for ( i = 0; i < routers; i++ ) {
		settingsPlist = [ router[i] settingsPlist ] ;
		if ( settingsPlist ) {
			string = [ settingsPlist objectForKey:kKeyerID ] ;
			if ( string != nil && [ string length ] > 0 ) {
				//  only save active routers with a keyer ID
				[ activeSetups addObject:settingsPlist ] ;
			}
		}
	}
	//  now include inactive devices that were in the plist before we started
	originalSetups = [ prefs objectForKey:kDeviceSetups ] ;
	if ( originalSetups != nil && [ originalSetups count ] > 0 ) {
		originalSize = [ originalSetups count ] ;
		for ( i = 0; i < originalSize; i++ ) {
			originalSetup = [ originalSetups objectAtIndex:i ] ;
			originalID = [ originalSetup objectForKey:kKeyerID ] ;
			if ( originalID != nil ) {
				activeSize = [ activeSetups count ] ;
				for ( j = 0; j < activeSize; j++ ) {
					activeSetup = [ activeSetups objectAtIndex:j ] ;
					activeID = [ activeSetup objectForKey:kKeyerID ] ;
					if ( activeID != nil ) {
						if ( [ activeID isEqualToString:originalID ] == YES ) break ;
					}
				}
				if ( j >= activeSize ) {
					//  no match found, add the original keyer setting to the active setting
					[ activeSetups addObject:originalSetup ] ;
				}
			}
		}
	}
	[ prefs setObject:activeSetups forKey:kDeviceSetups ] ;

	[ prefs setObject:[ NSNumber numberWithInt:5 ] forKey:kPrefVersion ] ;
	
	[ prefs removeObjectForKey:kMicroKeyerIILCDLine1 ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDLine2 ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDMessage1 ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDMessage2 ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDClock ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDContrast ] ;
	[ prefs removeObjectForKey:kMicroKeyerIILCDBrightness ] ;
    [ prefs removeObjectForKey:kMicrokeyerIIEnableModeOverride ];
	[ prefs removeObjectForKey:@"microKeyer II default string" ] ;
	[ prefs removeObjectForKey:@"Radio Aggregate Timeouts" ] ;
	[ prefs removeObjectForKey:@"Enabled Devices" ] ;
	
	//  save plist
    if ( ![ prefs writeToFile:plistPath atomically:YES ] )
    {
        Log( true, "Could not write pref files");
    }
	
	for ( i = 0; i < routers; i++ ) [ router[i] shutdown ] ;
	[ self shutdown ] ;
	
	return NSTerminateNow ;
}

//  sleep manager
- (void)aboutToSleep:(long)message
{
	int i ;
	
	Log( debug, "About to sleep.\n" ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] aboutToSleep ] ;
	IOAllowPowerChange( powerManager,(long)message ) ;
}

- (void)allowSleep:(long)message
{
	IOAllowPowerChange( powerManager, (long)message ) ;
}

- (void)wakingFromSleep
{
	int i ;
	
	Log( debug, "Waken from sleep.\n" ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] wakeFromSleep ] ;
}

static void powerManagerCallback( void *refcon, io_service_t service, natural_t messageType, void *message )
{
	Controller *ctrl = (Controller*)refcon ;
	
	switch ( messageType ) {
	case kIOMessageSystemWillSleep:
		[ ctrl aboutToSleep:(long)message ] ;
		break;
	case kIOMessageCanSystemSleep:
		[ ctrl allowSleep:(long)message ] ;
		break;
	case kIOMessageSystemHasPoweredOn:
		[ ctrl wakingFromSleep ] ;
		break;
    }
}

- (void)deferredQuitOnMainThread
{
	[ NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(deferredQuit:) userInfo:self repeats:NO ] ;
}

//  Applescript support

- (Boolean)quitIfNoKeyer
{
	int i ;
	
	for ( i = 0; i < routers; i++ ) {
		if ( [ router[i] connected ] ) break ;
	}
	if ( i < routers ) return NO ;
	
	//  will quit in 1 second
	Log( debug, "Quitting because no keyer found.\n" ) ;
	[ self performSelectorOnMainThread:@selector(deferredQuitOnMainThread) withObject:nil waitUntilDone:NO ] ;
	return YES ;
}

- (IBAction)stayAliveSelected:(id)sender
{
	[ stayAliveItem setState:( [ stayAliveItem state ] == NSOnState ) ? NSOffState : NSOnState ] ;
}

- (Boolean)quitIfNotInUse
{
	int i ;
	
	if ( logToConsole ) NSLog( @"QUIT If Not In Use received, stayAliveAlways = %d", ( [ stayAliveItem state ] == NSOnState ) ) ;
	
	if ( [ stayAliveItem state ] == NSOnState ) return NO ;
	
	//  wait a little in case keyers were just closed
	[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:1.5 ] ] ;
	for ( i = 0; i < routers; i++ ) {
		if ( [ router[i] inUse ] ) {
			if ( logToConsole ) NSLog( @"Router %d is still connected", i ) ;
			break ;
		}
	}
	if ( i < routers ) return NO ;
	
	//  will quit in 1 second
	if ( logToConsole ) NSLog( @"Quitting because there is no connection remaining." ) ;
	[ self performSelectorOnMainThread:@selector(deferredQuitOnMainThread) withObject:nil waitUntilDone:NO ] ;
	return YES ;
}

- (void)quitAlways
{
	if ( logToConsole ) NSLog( @"Unconditional QUIT received" ) ;
	[ self performSelectorOnMainThread:@selector(deferredQuitOnMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (Boolean)debug
{
	return debug ;
}

- (void)setDebug:(Boolean)state
{
	debug = state ;
}

- (Router*)microKEYER
{
	int i ;
	Router *r ;
	
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r command ] == OPENMICROKEYER && [ r isDummy ] == NO ) return r ;
	}
	return router[0] ;		//  return a (unconnected) dummy microKeyer
}

- (Router*)cwKEYER
{
	int i ;
	Router *r ;
	
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r command ] == OPENCWKEYER && [ r isDummy ] == NO ) return r ;
	}
	return router[1] ;		//  return a (unconnected) dummy cwKeyer
}

- (Router*)digiKEYER
{
	int i ;
	Router *r ;
	
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r command ] == OPENDIGIKEYER && [ r isDummy ] == NO ) return r ;
	}
	return router[2] ;		//  return a (unconnected) dummy digiKeyer
}

//	v1.80
//	return a list of non-dummy keyers
- (NSArray*)keyers
{
	int i, n ;
	Router *r ;
	NSMutableArray *array ;
	
	array = [ NSMutableArray array ] ;
	
	n = 0 ;
	for ( i = 0; i < routers; i++ ) {
		r = router[i] ;
		if ( [ r isDummy ] == NO ) {
			[ array addObject:r ] ;
			[ r setApplescriptListIndex:n++ ] ;
		}
	}
	return array ;
}

//	v1.80
- (NSString*)routerVersion
{
	return [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
}

- (void)displayString:(NSString*)str
{
	[ debugTextView insertText: [ [ NSDate date ] descriptionWithCalendarFormat:@"%H:%M:%S.%F " timeZone:nil locale:nil ] ] ;
	[ debugTextView insertText:str ] ;
	[ debugTextView setNeedsDisplay:YES ] ;
	[ str release ] ;
}

- (void)log:(char*)str
{
	NSString *string ;
	
	[ diagLock lock ] ;
	string = [ [ NSString alloc ] initWithCString:str encoding:NSASCIIStringEncoding ] ;
	[ self performSelectorOnMainThread:@selector(displayString:) withObject:string waitUntilDone:NO ] ;
	[ diagLock unlock ] ;
}

- (void)debugFrameButtonChanged:(id)sender
{
	Boolean debugFrames ;
	int i ;
	
	debugFrames = ( [ debugFrameButton state ] == NSOnState ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] setDebugFrames:debugFrames ] ;	
}

- (void)debugControlButtonChanged:(id)sender
{
	Boolean debugControl ;
	int i ;
	
	debugControl = ( [ debugControlButton state ] == NSOnState ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] setDebugControl:debugControl ] ;	
}

- (void)debugBytesButtonChanged:(id)sender
{
	Boolean debugBytes ;
	int i ;
	
	debugBytes = ( [ debugBytesButton state ] == NSOnState ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] setDebugBytes:debugBytes ] ;	
}

- (void)debugFlagsButtonChanged:(id)sender
{
	Boolean debugFlags ;
	int i ;
	
	debugFlags = ( [ debugFlagsButton state ] == NSOnState ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] setDebugFlags:debugFlags ] ;	
}

- (void)debugRadioButtonChanged:(id)sender
{
	Boolean debugRadio ;
	int i ;
	
	debugRadio = ( [ debugRadioButton state ] == NSOnState ) ;
	for ( i = 0; i < routers; i++ ) [ router[i] setDebugRadio:debugRadio ] ;	
}

- (void)setDiagnosticWindowState:(Boolean)state
{
	NSWindow *window ;
	Boolean debugFrames, debugRadio, debugFlags, debugControl, debugBytes ;
	int i ;
	
	window = [ debugTextView window ] ;
	if ( state == NO ) {
		[ diagWindowMenu setState:NSOffState ] ;
		logIntoWindow = NO ;
		for ( i = 0; i < routers; i++ ) {
			[ router[i] setDebugFrames:NO ] ;
			[ router[i] setDebugRadio:NO ] ;
			[ router[i] setDebugFlags:NO ] ;
			[ router[i] setDebugControl:NO ] ;
			[ router[i] setDebugBytes:NO ] ;
		}
	}
	else {
		[ diagWindowMenu setState:NSOnState ] ;
		debugFrames = ( [ debugFrameButton state ] == NSOnState ) ;
		debugRadio = ( [ debugRadioButton state ] == NSOnState ) ;
		debugFlags = ( [ debugFlagsButton state ] == NSOnState ) ;
		debugControl = ( [ debugControlButton state ] == NSOnState ) ;
		debugBytes = ( [ debugBytesButton state ] == NSOnState ) ;
		logIntoWindow = YES ;
		for ( i = 0; i < routers; i++ ) {
			[ router[i] setDebugFrames:debugFrames ] ;
			[ router[i] setDebugRadio:debugRadio ] ;
			[ router[i] setDebugFlags:debugFlags ] ;
			[ router[i] setDebugControl:debugControl ] ;
			[ router[i] setDebugBytes:debugBytes ] ; 
		}
	}
}

- (IBAction)toggleDebugWindow:(id)sender
{
	NSWindow *window ;
	Boolean isVisible ;
	
	window = [ debugTextView window ] ;
	isVisible = [ window isVisible ]  ;
	if ( isVisible ) [ window orderOut:self ] ; else [ window orderFront:self ]  ; 
	
	[ self setDiagnosticWindowState:( isVisible == NO ) ] ;
}

- (IBAction)toggleConsoleDiagnostics:(id)sender
{
	int i ;
	
	logToConsole = !logToConsole ;

	[ sender setState:( logToConsole ) ? NSOnState : NSOffState ] ;
	for ( i = 0; i < routers; i++ ) {
		[ router[i] setConsoleDebug:logToConsole ] ;
	}
}

- (IBAction)clearDebugView:(id)sender
{
	[ debugTextView setString:@"" ] ;
	[ debugTextView setNeedsDisplay:YES ] ;
}


//  delegate of diagnostic window
- (BOOL)windowShouldClose:(id)window
{
	[ self setDiagnosticWindowState:NO ] ;
	return YES ;
}

@end
