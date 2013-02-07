//
//  Controller.h
//  µH Router
//
//  Created by Kok Chen on 5/2/06.

#ifndef _CONTROLLER_H_
	#define _CONTROLLER_H_

	#import <Cocoa/Cocoa.h>
	#import "Router.h"
	#import "RouterTest.h"
	#import "NamedFIFOPair.h"
	#import "KeyerMode.h"
	
	@interface Controller : NSScriptCommand {

		IBOutlet id prefPanel ;
		IBOutlet id prefTabView ;
		IBOutlet id modePanel ;
		IBOutlet id modeTabView ;
		IBOutlet id stayAliveItem ;
		
		IBOutlet id debugTextView ;
		IBOutlet id debugFrameButton ;
		IBOutlet id debugRadioButton ;
		IBOutlet id debugFlagsButton ;
		IBOutlet id debugControlButton ;
		IBOutlet id debugBytesButton ;
		
		IBOutlet id diagWindowMenu ;
		
		NamedFIFOPair *mainFIFO ;
		
		// v1.40  UDP
		int routerSocket ;
		struct sockaddr_in udpServer ;

		//  router (one for each microHAM device)
		//  current index = 0:microKEYER, 1:CW KEYER, 2:DIGI KEYER
		Router *prototype[3] ;
		Router *router[8] ;
		int routers, prototypes ;
		
		NSMutableDictionary *prefs ;
		NSString *plistPath ;
		//  sleep manager
		io_connect_t powerManager ;
		
		//  test
		RouterTest *routerTest ;
		Boolean debug ;
		Boolean logIntoWindow ;
		Boolean logToConsole ;
		NSLock *diagLock ;
	}
	
	- (IBAction)openPref:(id)sender ;
	- (IBAction)openModePanel:(id)sender ;
	- (IBAction)openTest:(id)sender ;
	- (IBAction)stayAliveSelected:(id)sender ;
	
	- (IBAction)toggleDebugWindow:(id)sender ;
	- (IBAction)toggleConsoleDiagnostics:(id)sender ;
	- (IBAction)clearDebugView:(id)sender ;
	- (void)log:(char*)str ;
	
	- (void)initFromPlist ;
	- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info ;
	
	- (void)pickupMicroHamDevices ;
	- (void)shutdown ;
	
	- (void)aboutToSleep:(long)message ;
	- (void)allowSleep:(long)message ;
	- (void)wakingFromSleep ;
	
	//  AppleScriptSupport
	- (Boolean)quitIfNoKeyer ;
	- (Boolean)quitIfNotInUse ;
	- (void)quitAlways ;
	
	- (Router*)microKEYER ;
	- (Router*)digiKEYER ;
	- (Router*)cwKEYER ;
	- (NSArray*)keyers ;
	- (NSString*)routerVersion ;
	
	- (Boolean)debug ;
	- (void)setDebug:(Boolean)state ;

	@end

#endif
