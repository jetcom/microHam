//
//  KeyerSettings.h
//  µH Router
//
//  Created by Kok Chen on 3/17/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Router.h"

@interface KeyerSettings : NSObject <NSTableViewDataSource>{

	IBOutlet id settingsView ;
	IBOutlet id digiSettingsView ;
	
	IBOutlet id extendedSettingsWindow ;

	IBOutlet id digitalPTTMenu ;
	IBOutlet id voicePTTMenu ;
	IBOutlet id cwPTTMenu ;
	
	IBOutlet id digitalAudioMenu ;
	IBOutlet id voiceAudioMenu ;
	IBOutlet id cwAudioMenu ;
	
	IBOutlet id digitalReceiveString ;
	IBOutlet id digitalTransmitString ;
	IBOutlet id digitalFootswitchString ;
	
	IBOutlet id voiceReceiveString ;
	IBOutlet id voiceTransmitString ;
	IBOutlet id voiceFootswitchString ;
	
	IBOutlet id cwReceiveString ;
	IBOutlet id cwTransmitString ;
	IBOutlet id cwFootswitchString ;
	
	IBOutlet id forcedKeyerMatrix ;

	IBOutlet id pttMatrix ;
	IBOutlet id fskMatrix ;
	IBOutlet id cwMatrix ;

	IBOutlet id pttStepper ;
	IBOutlet id pttDelayField ;

	IBOutlet id sidetoneMenu ;
	IBOutlet id wpmStepper ;
	IBOutlet id wpmField ;

	//  DK2 menus
	IBOutlet id d2DigitalPTTMenu ;
	IBOutlet id d2CwPTTMenu ;
	IBOutlet id d2ForcedKeyerMatrix ;
	IBOutlet id d2PttMatrix ;
	IBOutlet id d2FskMatrix ;
	IBOutlet id d2CwMatrix ;
	IBOutlet id d2PttStepper ;
	IBOutlet id d2PttDelayField ;
	IBOutlet id d2SidetoneMenu ;
	IBOutlet id d2WpmStepper ;
	IBOutlet id d2WpmField ;

	IBOutlet id extendedSettingsButton ;		//  microKeyer II and digiKeyer II only

 
	//  LCD settings (microKeyer II)
	IBOutlet id lcdUTCMatrix ;
    IBOutlet id lcdLine1Setting;
    IBOutlet id lcdLine2Setting;
	IBOutlet id lcdLine1Message ;
	IBOutlet id lcdLine2Message ;
	IBOutlet id lcdContrast ;
	IBOutlet id lcdBrightness ;
	
	//  other extensions settings
	IBOutlet id mpkFlagsMatrix ;
	
	// iLink settings
	IBOutlet id iLinkBaud ;
	IBOutlet id iLinkFunction ;				// v 1.50
	
	//  CI-V settings	
	IBOutlet id civBaud ;					// v 1.50
	IBOutlet id civAddress ;				// v 1.50
	IBOutlet id civFunction ;				// v 1.50
	IBOutlet id d2CivBaud ;					// v 1.62
	IBOutlet id d2CivAddress ;				// v 1.62
	IBOutlet id d2CivFunction ;				// v 1.62
		
    IBOutlet id line1Events;
    IBOutlet id line2Events;
	IBOutlet id eventDurationStepper ;
	IBOutlet id eventDurationField ;
	
	IBOutlet id digitalMonitorStepper ;
	IBOutlet id digitalMonitorField ;
	IBOutlet id digitalRecordingMatrix ;

	IBOutlet id voiceMonitorStepper ;
	IBOutlet id voiceMonitorField ;
	IBOutlet id voiceRecordingMatrix ;

	IBOutlet id cwMonitorStepper ;
	IBOutlet id cwMonitorField ;
	IBOutlet id cwRecordingMatrix ;
	
	NSTimer *utcTimer ;
	int utcSelection ;
	int utcRefreshCycle ;

	Router *router ;
	Boolean isMK2, isDK2 ;
	NSWindow *settingsWindow ;
    
    NSMutableArray *events;

	
	unsigned char settingsString[56] ;		//  first 12 bytesare MK, and the rest are MK2 extensions
}

- (IBAction)storeSettings:(id)sender ;
- (IBAction)resetEEPROM:(id)sender ;
- (IBAction)storeMessages:(id)sender ;

- (id)initIntoWindow:(NSWindow*)settingsWindow router:(Router*)inRouter ;
- (void)setAsMicroKeyer2 ;
- (void)setAsDigiKeyer2 ;
- (void)show ;

- (int)makeDigitalKeyerBase ;
- (int)makeCWKeyerBase ;
- (int)makeVoiceKeyerBase ;

- (void)makeUpRoutingExplainations ;

//  backdoors
- (void)setFSKInvert:(Boolean)state ;
- (void)setRouting:(int)index ;
- (void)setOOK:(int)index state:(int)index ;

//  Plist
- (void)setupKeyerFromPref:(NSDictionary*)prefs ;
- (void)sendSettingsToKeyer ;
- (NSMutableDictionary*)settingsPlist ;
- (NSMutableDictionary*)defaultSettingsPlist ;

- (void)lcdSettingsChanged ;

- (void)shutdown ;

//  forward references
- (void)utcSelectionChanged:(id)sender ;

@end
