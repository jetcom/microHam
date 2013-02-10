//
//  Router.h
//  uH Router
//
//  Created by Kok Chen on 5/4/06.


#ifndef _ROUTER_H_
	#define	_ROUTER_H_
	
	#import <Cocoa/Cocoa.h>
	#import "NamedFIFOPair.h"
	#import "ReplyBuf.h"
	#import "UDP.h"
	
	@class Controller ;
	@class Keyer ;
	@class KeyerMode ;
	@class KeyerSettings ;
	@class KeyerTest ;
	@class Server ;
	@class WinKeyEmulator ;
	
	enum KeyerType {					//  v1.62
		notAKeyerType = 0,
		microKeyerType,
		cwKeyerType,
		digiKeyerType,
		microKeyer2Type,
		digiKeyer2Type
	} KeyerType ;
	
	typedef struct {
		struct sockaddr_in socket ;
		NSTimeInterval lastAccessed ;
		NSTimeInterval timePreviousCommandReceived[6] ;
		float responseWindow[6] ;
		int allowControlPacket[128] ;
	} UDPClient ;

	#define	RADIO_INDEX			0
	#define	CONTROL_INDEX		1
	#define	PTT_INDEX			2		//  same as FLAGS_INDEX
	#define	CW_INDEX			2		//  same as FLAGS_INDEX
	#define RTS_INDEX			2		//  same as FLAGS_INDEX
	#define	FLAGS_INDEX			2		//  same as FLAGS_INDEX
	#define	FSK_INDEX			3
	#define	WINKEY_INDEX		4
	#define	EMULATOR_INDEX		5

	
	@interface Router : NSObject {
		IBOutlet id controlView ;
		IBOutlet id timeoutTextField ;				//  v1.11t
		IBOutlet id activeIndicator ;
		IBOutlet id enableFlag ;
		IBOutlet id errorString ;
		IBOutlet id nameStringField ;
				
		//  Config
		IBOutlet id keyerSettingsWindow ;		
		IBOutlet id digiKeyerSettingsWindow ;		
		KeyerSettings *keyerSettings, *alternateKeyerSettings ;
		
		WinKeyEmulator *emulator ;
		NSMutableDictionary *prefs ;
		
		KeyerMode *keyerMode ;
		
		NSTabViewItem *tabItem ;
		NSTabView *controllingTabView ;
		
		int command ;
		Boolean isEnabled ;
		Boolean debug ;
		Boolean logToConsole ;			//  v1.11
		Boolean debugChannel ;
		Boolean debugRadio ;			//  v1.11
		Boolean debugControl ;			//  v1.11
		Boolean debugFrame ;
		Boolean debugFramesIntoWindow, debugRadioIntoWindow, debugFlagsIntoWindow, debugControlIntoWindow, debugBytesIntoWindow ;
		NSString *deviceName ;			// e.g., "usbserial-DK"
		Boolean isDummy ;
		
		Controller *controller ;
		Server *server ;
		Keyer *keyer ;
		int routerRetainCount ;
		NSLock *parserLock ;
		NSLock *writeLock ;
		NSLock *sendControlLock ;
		NSLock *sendRadioLock ;			//  v1.11q
		int aggregateTimeout ;			//  milliseconds
		
		ReplyBuf *radio, *control, *flags, *winkey, *fsk ;		//  AppleScript data buffers
		
		//  shared channel data
		int flagByte ;
		int sequence ;
		
		//  v1.40 UDP support
		struct sockaddr_in *udpServer ;
		int udpSocket ;
		int udpClients ;
		UDPClient udpClient[256] ;
		NSLock *udpLock ;
		int udpControlIndex ;
		unsigned char udpControlString[1024] ;
		int udpRadioIndex ;
		unsigned char udpRadioString[1024] ;
		NSTimer *udpRadioTimer ;

		//  accumulate radio string v 1.11
		NSString *radioString ;
		NSTimer *radioDataTimer ;
		
		//	v1.80
		NSString *keyerName ;
		NSString *fifoName ;
		NSString *keyerID ;			//  D2xxxxxx, DKxxxxxx, etc
		int version ;
		int applescriptListIndex ;	//  for applescript list
	}
	
	- (IBAction)openSettingsWindow:(id)sender ;

	- (IBAction)testPTT:(id)sender ;
	- (IBAction)testUnPTT:(id)sender ;
	
	//  v1.80
	- (id)initPrototype:(NSString*)inKeyerName fifo:(NSString*)inFifoName deviceName:(NSString*)devName command:(int)commandValue controller:(Controller*)inController ;
	- (id)initIntoTabView:(NSTabView*)tabview keyerModeTabView:(NSTabView*)keyerModeTabView prototype:(Router*)prototype streamName:(NSString*)name index:(int)index ;
	- (Controller*)controller ;
	- (int)commandValue ;
	- (NSString*)keyerName ;
	- (NSString*)fifoName ;
	- (NSString*)keyerID ;
	- (Boolean)isDummy ;
	- (int)version ;
	- (void)setNameString:(NSString*)string ;
	- (void)setApplescriptListIndex:(int)n ;
	
	//- (id)initIntoTabView:(NSTabView*)tabview keyerModeTabView:(NSTabView*)keyerModeTabView name:(NSString*)keyerName fifo:(NSString*)fifoName deviceName:(NSString*)devName command:(int)commandValue controller:(Controller*)inController ;
	- (const char*)addNewClient ;
	- (int)command ;
	- (void)setupDeviceFromPref:(NSMutableDictionary*)inPrefs keyerType:(enum KeyerType)keyerType ;
	- (void)setupParameters ;
	- (void)finishUpdateAfterConnection ;
	
	//  v1.40
	- (int)addNewUDPClient:(struct sockaddr_in*)socket ;
	- (void)wakeupFrom:(struct sockaddr_in*)socket ;
		
	- (Boolean)hasWINKEY ;
	- (void)setHasWINKEY:(Boolean)state ;
	- (Boolean)hasFSK ;
	- (void)setHasFSK:(Boolean)state ;
	
	- (void)parseFrame:(unsigned char*)frame ;
	
	- (void)receivedRadio:(int)data ;
	- (void)receivedExtRadio:(int)data ;
	- (void)receivedFlags:(int)data ;
	- (void)receivedControl:(int)data valid:(int)isValid ;
	- (void)receivedWinKey:(int)data ;
	- (void)receivedFSK:(int)data ;
	- (void)receivedExtFSK:(int)data ;
	
	- (void)connect ;
	
	- (int)retainRouter ;
	- (int)releaseRouter ;
	
	- (Boolean)connected ;
	- (Boolean)inUse ;
	- (void)shutdown ;
	
	- (Boolean)isEnabled ;
	- (void)setEnabled:(Boolean)state ;
	
	- (NSString*)deviceName ;
	- (void)setStream:(NSString*)name ;
	- (void)setPath:(NSString*)name ;
	
	- (void)sendFlags ;
	- (void)sendControl:(unsigned char*)controlBytes length:(int)length ;
	- (void)sendRadio:(unsigned char*)radioBytes length:(int)length ;
	- (void)sendWinkey:(int)byte ;
	- (void)sendFSK:(int)byte ;
	- (void)sendExtFSK:(int)byte ;

	- (void)sendHeartbeat ;
	
	- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info ;
	
	- (void)aboutToSleep ;
	- (void)wakeFromSleep ;
	
	//  client and AppleScript requests
	- (NSString*)FLAGS ;
	- (void)setFLAGS:(NSString*)flag ;
	- (Boolean)PTT ;
	- (void)setPTT:(Boolean)state ;
	- (Boolean)RTS;
	- (void)setRTS:(Boolean)state ;
	- (Boolean)serialCW ;
	- (void)setSerialCW:(Boolean)state ;
	- (NSString*)WINKEY ;
	- (void)setWINKEY:(NSString*)string ;
	- (NSString*)WINKEYhex ;
	- (void)setWINKEYhex:(NSString*)string ;
	- (NSString*)FSK ;
	- (void)setFSK:(NSString*)string ;
	- (NSString*)CONTROL ;
	- (void)setCONTROL:(NSString*)string ;
	- (NSString*)RADIO ;
	- (void)setRADIO:(NSString*)string ;
	- (Boolean)debug ;
	- (void)setDebug:(Boolean)state ;
	
	- (void)setDebugFrames:(Boolean)state ;
	- (void)setDebugRadio:(Boolean)state ;
	- (void)setDebugFlags:(Boolean)state ;
	- (void)setDebugControl:(Boolean)state ;
	- (void)setDebugBytes:(Boolean)state ;
	- (void)setConsoleDebug:(Boolean)state ;
	
	- (void)setControl:(unsigned char*)string length:(long)length ;
	- (void)setRadio:(unsigned char*)string length:(long)length ;
	
	//  WinKeyEmulator
	- (NSString*)WinKeyEmulate ;
	- (void)setWinKeyEmulate:(NSString*)string ;
	- (void)sendSerialCW:(Boolean)state ;
	
	//  diagnostic window support
	- (void)framingError:(unsigned char*)frame byteOrder:(int)byteOrder ;
	- (void)missingFrameSync:(unsigned char)byte ;
	- (void)receivedByteInScanner:(unsigned char)byte ;

	//  plist support  v1.11t
	- (int)aggregateTimeout ;
	- (void)setAggregateTimeout:(int)timeout ;
	// v1.40
	- (NSMutableDictionary*)settingsPlist ;
	
	- (void)removeUDPClient:(struct sockaddr_in*)socket ;
	
	//  plist support for KeySettings
	- (void)setInt:(int)intval forKey:(NSString*)key ;
	- (void)setFloat:(float)floatval forKey:(NSString*)key ;
	- (void)setString:(NSString*)stringval forKey:(NSString*)key ;
	- (int)intForKey:(NSString*)key ;
	
	@end

	//  shared channel sequence
	#define	kFLAGS				0
	#define	kCONTROL			1
	#define	kWINKEY				2
	#define	kFSK				3
	#define	kEXTFSK				4
	
	//  special 0f.. 8f command
	//  these are not use to werite to keyers, so we use them as special cases
	
	//  0f 01 LL 8f		LL is whether FSK is inverted
	
	#define	kRouterBackdoor		0x0f
	#define	kInvertFSK			1
	
#endif
