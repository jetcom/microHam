//
//  KeyerSettings.m
//  µH Router
//
//  Created by Kok Chen on 3/17/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "KeyerSettings.h"
#import "RouterPlist.h"

@implementation KeyerSettings

//  Default SETTINGS -- force to digital mode, both PTT, when CW and voice forces, use PTT2
static char factory[56] = {
	0xc5,	0x00,	0x00,	0x02,	0x00,	0x20,	0x01,	0x60,	0x00,	0x00,
	0x80,	0xae,	0x00,	0x08 ,	0x15,	0x01,	0x01,	0xdf,	0xff,	0xfa,
	0xff,	0x14,	0x00,	0x02,	0x00,	0x50,	0x00,	0x00,	0x00,	0x00,
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00
} ;

unsigned char abcdEncoding[] = { 'D', 'B', 'A', 'C' } ;


- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoWindow:(NSWindow*)inSettingsWindow router:(Router*)inRouter 
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
        
		router = inRouter ;
		isMK2 = isDK2 = NO ;			//  v1.62
		utcTimer = nil ;
		utcSelection = 0 ;
		utcRefreshCycle = 0 ;
		for ( i = 0; i < 56; i++ ) settingsString[i] = 0 ;
		settingsWindow = inSettingsWindow ;
		
		if ( [ NSBundle loadNibNamed:@"KeyerSettings" owner:self ] ) {
		
			// loadNib should have set up contentView connection
			if ( settingsView ) {
			
				[ settingsWindow setContentView:settingsView ] ;
				
				//  routing changed
				[ self setInterface:digitalPTTMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:voicePTTMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:d2DigitalPTTMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:cwPTTMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:d2CwPTTMenu to:@selector(routingChanged:) ] ;

				[ self setInterface:digitalAudioMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:voiceAudioMenu to:@selector(routingChanged:) ] ;
				[ self setInterface:cwAudioMenu to:@selector(routingChanged:) ] ;
				
				//  mode changes
				[ self setInterface:forcedKeyerMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:pttMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:fskMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:cwMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:pttDelayField to:@selector(settingChanged:) ] ;
				[ self setInterface:sidetoneMenu to:@selector(settingChanged:) ] ;
				
				[ self setInterface:pttStepper to:@selector(pttStepperChanged:) ] ;
				[ self setInterface:wpmStepper to:@selector(wpmChanged:) ] ;

				[ self setInterface:civBaud to:@selector(settingChanged:) ] ;
				[ self setInterface:civAddress to:@selector(settingChanged:) ] ;
				[ self setInterface:civFunction to:@selector(settingChanged:) ] ;

				//  digiKeyer II mode changes
				[ self setInterface:d2ForcedKeyerMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:d2PttMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:d2FskMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:d2CwMatrix to:@selector(settingChanged:) ] ;
				[ self setInterface:d2PttDelayField to:@selector(settingChanged:) ] ;
				[ self setInterface:d2SidetoneMenu to:@selector(settingChanged:) ] ;
				
				[ self setInterface:d2PttStepper to:@selector(pttStepperChanged:) ] ;
				[ self setInterface:d2WpmStepper to:@selector(wpmChanged:) ] ;

				[ self setInterface:d2CivBaud to:@selector(settingChanged:) ] ;
				[ self setInterface:d2CivAddress to:@selector(settingChanged:) ] ;
				[ self setInterface:d2CivFunction to:@selector(settingChanged:) ] ;

				//  LCD panel
				[ extendedSettingsButton setHidden:YES ] ;
				[ self setInterface:lcdUTCMatrix to:@selector(utcSelectionChanged:) ] ;
				
				[ self setInterface:lcdLine1Setting to:@selector(lcdSettingsChanged) ] ;
				[ self setInterface:lcdLine2Setting to:@selector(lcdSettingsChanged) ] ;
				[ self setInterface:lcdContrast to:@selector(lcdSettingsChanged) ] ;
				[ self setInterface:lcdBrightness to:@selector(lcdSettingsChanged) ] ;
				
				[ self setInterface:lcdLine1Message to:@selector(lcdMessageChanged:) ] ;
				[ self setInterface:lcdLine2Message to:@selector(lcdMessageChanged:) ] ;

				//  other extended settings
				[ self setInterface:iLinkBaud to:@selector(settingChanged:) ] ;
				[ self setInterface:iLinkFunction to:@selector(settingChanged:) ] ;

				[ self setInterface:mpkFlagsMatrix to:@selector(auxChanged:) ] ;
				[ self setInterface:line1Events to:@selector(settingChanged:) ] ;
				[ self setInterface:line2Events to:@selector(settingChanged:) ] ;
				[ self setInterface:eventDurationStepper to:@selector(eventsStepperChanged:) ] ;
				
				[ self setInterface:digitalMonitorStepper to:@selector(digitalMonitorStepperChanged:) ] ;
				[ self setInterface:digitalRecordingMatrix to:@selector(settingChanged:) ] ;

				[ self setInterface:voiceMonitorStepper to:@selector(voiceMonitorStepperChanged:) ] ;
				[ self setInterface:voiceRecordingMatrix to:@selector(settingChanged:) ] ;

				[ self setInterface:cwMonitorStepper to:@selector(cwMonitorStepperChanged:) ] ;
				[ self setInterface:cwRecordingMatrix to:@selector(settingChanged:) ] ;
				
				[ lcdLine1Message setRefusesFirstResponder:YES ] ;
				[ lcdLine2Message setRefusesFirstResponder:YES ] ;
				//  unselect
				[ iLinkBaud setRefusesFirstResponder:YES ] ;
				[ civBaud setRefusesFirstResponder:YES ] ;
				[ civAddress setRefusesFirstResponder:YES ] ;
				[ d2CivBaud setRefusesFirstResponder:YES ] ;
				[ d2CivAddress setRefusesFirstResponder:YES ] ;
                
                
                eventList = [[NSMutableArray alloc] init];
                [ eventList addObject: @"Recoding Message" ];
                [ eventList addObject: @"Playback Message" ];
                [ eventList addObject: @"TX data During PTT" ];
                [ eventList addObject: @"RX data During Receive" ];
                [ eventList addObject: @"Bars During Recording" ];
                [ eventList addObject: @"WPM Change when in CW" ];
                [ eventList addObject: @"SteppIR Command" ];
                [ eventList addObject: @"RX Frequency Change" ];
                [ eventList addObject: @"TX Frequency Change" ];
                [ eventList addObject: @"Mode Change" ];
                [ eventList addObject: @"Mic Change" ];
                [ eventList addObject: @"SteppIR Lock" ];
                [ eventList addObject: @"Supply Voltage When Out of Range" ];
                [ eventList addObject: @"Current WPM" ];
                [ eventList addObject: @"Config Override" ];
                [ eventList addObject: @"WPM/SN Change" ];
                [ eventList addObject: @"Serial Number Change when in CW" ];
                [ eventList addObject: @"Current Serial Number" ];
                [ eventList addObject: @"WPN/Serial Number when in CW" ];
                [ eventList addObject: @"Operating Frequency" ];
                [ eventList addObject: @"VFO A Frequency" ];
                [ eventList addObject: @"VFO B Frequency" ];
                [ eventList addObject: @"SteppIR State" ];
                [ eventList addObject: @"Station Master Lock" ];
                [ eventList addObject: @"SubRX Frequency" ];
                [ eventList addObject: @"Preset" ];
                
                line1EventsSet = [[NSMutableIndexSet alloc] init];
                line2EventsSet = [[NSMutableIndexSet alloc] init];
                    
				
				return self ;
			}
		}
	}
	return nil ;
}

- (void)setAsMicroKeyer2
{
	isMK2 = YES ;
	
	//  change the routing menus to MK2 menus
	[ cwAudioMenu removeAllItems ] ;
	[ cwAudioMenu addItemWithTitle:@"DDD" ] ;
	[ voiceAudioMenu removeAllItems ] ;
	[ voiceAudioMenu addItemWithTitle:@"ACA" ] ;
	[ voiceAudioMenu addItemWithTitle:@"DBD" ] ;
	[ digitalAudioMenu removeAllItems ] ;
	[ digitalAudioMenu addItemWithTitle:@"BBD" ] ;
	[ digitalAudioMenu addItemWithTitle:@"CCA" ] ;
	[ extendedSettingsButton setHidden:NO ] ;
	[ self setInterface:extendedSettingsButton to:@selector(extendedMicroKeyerButtonPushed:) ] ;
}

//	v1.62
- (void)setAsDigiKeyer2
{
	NSRect frame ;

	isDK2 = YES ;	
	[ router setHasWINKEY:YES ] ;

	if ( digiSettingsView ) {
		//  reduce window size to fit digiKeyer's view
		frame = [ settingsWindow frame ] ;
		frame.size = [ digiSettingsView bounds ].size ;
		frame.size.height += 16 ;
		[ settingsWindow setFrame:frame display:YES ] ;
		[ settingsWindow setContentView:digiSettingsView ] ;
	}
}

- (NSString*)meaning:(char)c
{
	switch ( c ) {
	case 'A':
		return @"Microphone to Radio Mic" ;
	case 'B':
		return @"Soundcard Out to Radio Line" ;
	case 'C':
		return @"Soundcard Out to Radio Mic" ;
	case 'D':
		return @"Soundcard Out to Radio Line (Mic)" ;
	}
	return @"" ;
}

- (void)makeUpRoutingExplainations
{
	const char *s ;
	
	s = [ [ digitalAudioMenu titleOfSelectedItem ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
	[ digitalReceiveString setStringValue:[ self meaning:s[0] ] ] ;
	[ digitalTransmitString setStringValue:[ self meaning:s[1] ] ] ;
	[ digitalFootswitchString setStringValue:[ self meaning:s[2] ] ] ;
	
	s = [ [ voiceAudioMenu titleOfSelectedItem ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
	[ voiceReceiveString setStringValue:[ self meaning:s[0] ] ] ;
	[ voiceTransmitString setStringValue:[ self meaning:s[1] ] ] ;
	[ voiceFootswitchString setStringValue:[ self meaning:s[2] ] ] ;
	
	s = [ [ cwAudioMenu titleOfSelectedItem ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
	[ cwReceiveString setStringValue:[ self meaning:s[0] ] ] ;
	[ cwTransmitString setStringValue:[ self meaning:s[1] ] ] ;
	[ cwFootswitchString setStringValue:[ self meaning:s[2] ] ] ;
}

static int abcd( int c ) 
{
	switch ( c ) {
	case 'B':
		return 1 ;
	case 'A':
		return 2 ;
	case 'C':
		return 3 ;
	case 'D':
		return 0 ;
	}
	return 0 ;
}

- (int)makeKeyerBase:(NSString*)audio ptt:(NSString*)ptt
{
	int n ;
	const char *s ;
	
	s = [ audio cStringUsingEncoding:NSASCIIStringEncoding ] ;	
	n = abcd( s[0] ) + abcd( s[1] )*4 + abcd( s[2] )*16 ;
	if ( [ ptt isEqualToString:@"Both" ] || [ ptt isEqualToString:@"PTT1" ] ) n |= 0x40 ;
	if ( [ ptt isEqualToString:@"Both" ] || [ ptt isEqualToString:@"PTT2" ] ) n |= 0x80 ;
	
	return n ;
}

- (int)makeDigitalKeyerBase
{
	if ( isDK2 ) {
		//	r1FrBase_Digital for digiKeyer II
		return ( [ [ d2DigitalPTTMenu titleOfSelectedItem ] isEqualToString:@"PTT" ] ) ? 0x80 : 0 ;
	}
	return [ self makeKeyerBase:[ digitalAudioMenu titleOfSelectedItem ] ptt:[ digitalPTTMenu titleOfSelectedItem ] ] ;
}

- (int)makeCWKeyerBase
{
	if ( isDK2 ) {
		return ( [ [ d2CwPTTMenu titleOfSelectedItem ] isEqualToString:@"PTT" ] ) ? 0x80 : 0 ;
	}
	return [ self makeKeyerBase:[ cwAudioMenu titleOfSelectedItem ] ptt:[ cwPTTMenu titleOfSelectedItem ] ] ;
}

- (int)makeVoiceKeyerBase
{
	if ( isDK2 ) return 0 ;

	return [ self makeKeyerBase:[ voiceAudioMenu titleOfSelectedItem ] ptt:[ voicePTTMenu titleOfSelectedItem ] ] ;
}

- (Boolean)selected:(NSMatrix*)matrix row:(int)row
{
	return ( [ [ matrix cellAtRow:row column:0 ] state ] == NSOnState ) ;
}

//  v1.62  digiKeyer II extensions
- (void)makeDK2ExtensionSettingsString
{
	unsigned char *X ;
	int n, baud ;
	NSMenuItem *item ;

	X = &settingsString[0] ;
	for ( n = 12; n < 56; n++ ) settingsString[n] = 0 ;
	
	//  mpkFlags matrix in extension panel (auto PTT, OOK, etc)
	n = 0 ;
	if ( [ self selected:d2PttMatrix row:4 ] ) n |= 0x4 ;		//  auto PTT
	if ( [ self selected:d2CwMatrix row:6 ] ) n |= 0x8 ;		//  sidetone only from Paddle
	if ( [ self selected:d2PttMatrix row:5 ] ) n |= 0x20 ;		//  audio overrides footswitch
	if ( [ self selected:d2CwMatrix row:5 ] ) n |= 0x40 ;		//  CW with OOK
	if ( [ self selected:d2FskMatrix row:3 ] ) n |= 0x80 ;		//  FSK with OOK
	X[28] = n ;
	
	//  CI-V settings
	char *hexs = (char*)[ [ d2CivAddress stringValue ] UTF8String ] ;
	int hexv ;
	sscanf( hexs,"%02x", &hexv ) ;
	X[40] = hexv ;
	
	baud = [ d2CivBaud intValue ] ;
	if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
	[ d2CivBaud setIntValue:baud ] ;
	X[41] = (  230400/baud ) & 0xff ;
	
	item = [ d2CivFunction selectedItem ] ;
	X[42] = [ item tag ] ;
}

- (void)makeExtensionSettingsString
{
	unsigned char *X ;
	int n, baud ;
    __block int b;
	NSMenuItem *item ;

	X = &settingsString[0] ;
	for ( n = 12; n < 56; n++ ) settingsString[n] = 0 ;
	
	//  r1FrMpkExtra_Digital
	n = [ digitalMonitorStepper intValue ] ;
	if ( n < 0 ) n= 0 ; else if ( n > 25 ) n = 25 ;
	if ( [ self selected:digitalRecordingMatrix row:0 ] ) n |= 0x40 ;
	if ( [ self selected:digitalRecordingMatrix row:1 ] ) n |= 0x80 ;
	X[12] = n ;

	//  LCD parameters
	X[13] = 13 - [ lcdContrast intValue ] ;
	X[14] = [ lcdBrightness intValue ] ;
	X[15] = [ lcdLine1Setting selectedTag ]  ;
	X[16] = [ lcdLine2Setting selectedTag ]  ;
	
	//  event flags
 /*enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [events addObject: [NSNumber numberWithInt:idx]];
            }];*/
    b = 0;
    [ line1EventsSet enumerateIndexesInRange: NSMakeRange(0,7) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx;
        }
    ];
    X[17] = b;
    
    b = 0;
    [ line1EventsSet enumerateIndexesInRange: NSMakeRange(8,15) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-8;
        }
    ];
    X[18] = b;
    
    b = 0;
    [ line1EventsSet enumerateIndexesInRange: NSMakeRange(16,23) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-16;
        }
    ];
    X[19] = b;
    
    b = 0;
    [ line1EventsSet enumerateIndexesInRange: NSMakeRange(24,31) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-24;
        }
    ];
    X[20] = b;
	
    b = 0;
    [ line2EventsSet enumerateIndexesInRange: NSMakeRange(0,7) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx;
        }
    ];
    X[21] = b;
    
    b = 0;
    [ line2EventsSet enumerateIndexesInRange: NSMakeRange(8,15) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-8;
        }
    ];
    X[22] = b;
    
    b = 0;
    [ line2EventsSet enumerateIndexesInRange: NSMakeRange(16,23) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-16;
        }
    ];
    X[23] = b;
    
    b = 0;
    [ line2EventsSet enumerateIndexesInRange: NSMakeRange(24,31) options: 0 usingBlock:^(NSUInteger idx, BOOL *stop)
        {
           b |= 1 << idx-24;
        }
    ];
    X[24] = b;
	
	n = [ eventDurationStepper intValue ] ;
	if ( n < 0 ) n= 0 ; else if ( n > 255 ) n = 255 ;
	X[25] = n ;
	
	//  r1FrMpkExtra_Cw
	n = [ cwMonitorStepper intValue ] ;
	if ( n < 0 ) n= 0 ; else if ( n > 25 ) n = 25 ;
	if ( [ self selected:cwRecordingMatrix row:0 ] ) n |= 0x40 ;
	if ( [ self selected:cwRecordingMatrix row:1 ] ) n |= 0x80 ;
	X[26] = n ;

	//  r1FrMpkExtra_Voice
	n = [ voiceMonitorStepper intValue ] ;
	if ( n < 0 ) n= 0 ; else if ( n > 25 ) n = 25 ;
	if ( [ self selected:voiceRecordingMatrix row:0 ] ) n |= 0x40 ;
	if ( [ self selected:voiceRecordingMatrix row:1 ] ) n |= 0x80 ;
	X[27] = n ;	

	//  mpkFlags matrix in extension panel (auto select Front Panel Mic, etc)
	n = 0 ;
	if ( [ self selected:mpkFlagsMatrix row:0 ] ) n |= 1 ;
	if ( [ self selected:mpkFlagsMatrix row:1 ] ) n |= 2 ;
	if ( [ self selected:mpkFlagsMatrix row:2 ] ) n |= 4 ;
	if ( [ self selected:mpkFlagsMatrix row:3 ] ) n |= 8 ;
	if ( [ self selected:mpkFlagsMatrix row:4 ] ) n |= 0x10 ;
	if ( [ self selected:mpkFlagsMatrix row:5 ] ) n |= 0x20 ;
	X[28] = n ;
	
	baud = [ iLinkBaud intValue ] ;
	if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
	[ iLinkBaud setIntValue:baud ] ;
	X[29] = (  230400/baud ) & 0xff ;

	//  CI-V settings
	char *hexs = (char*)[ [ civAddress stringValue ] UTF8String ] ;
	int hexv ;
	sscanf( hexs,"%02x", &hexv ) ;
	X[40] = hexv ;
	
	baud = [ civBaud intValue ] ;
	if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
	[ civBaud setIntValue:baud ] ;
	X[41] = (  230400/baud ) & 0xff ;
	
	item = [ civFunction selectedItem ] ;
	X[42] = [ item tag ] ;
	
	item = [ iLinkFunction selectedItem ] ;
	n = [ item tag ];											//  v1.90 UB3ABM
	X[43] = n & 0x7f ;											//  v1.90 UB3ABM
	if ( n & 0x80 ) X[2] |= 0x80 ; else X[2] &= 0x7f ;			//  v1.90 UB3ABM  also sets bit r1I2cCoupled in X2
}


// Use Automatic Routing (X6.r1ForceKeyerMode=1; X6.r1FollowTxMode=1)
// Use Manual Mode Dependent Routing (X6.r1ForceKeyerMode=0; X6.r1FollowTxMode=0)
// Use Fixed Digital Routing (X6.r1ForceKeyerMode=1; X6.r1FollowTxMode=0; X7.r1KeyerMode=DIGITAL)
// Use Fixed Voice Routing (X6.r1ForceKeyerMode=1; X6.r1FollowTxMode=0; X7.r1KeyerMode=VOICE)
// Use Fixed CW Routing (X6.r1ForceKeyerMode=1; X6.r1FollowTxMode=0; X7.r1KeyerMode=CW)
// Use Fixed FSK Routing (X6.r1ForceKeyerMode=1; X6.r1FollowTxMode=0; X7.r1KeyerMode=FSK).

//  create the first 12 bytes of settings string from the Settings panel
- (void)makeBasicSettingsString
{
	int i, n, m, routingRow ;
	unsigned char *X ;
	NSMatrix *matrix ;
	
	X = &settingsString[0] ;
	for ( i = 0; i < 12; i++ ) settingsString[i] = 0 ;

	//  create the base for digital
	
	X[0] = [ self makeDigitalKeyerBase ] ;
	
	n = 0 ;
	if ( [ self selected:pttMatrix row:0 ] ) n |= 1 ;		//  ptt delay
	if ( [ self selected:fskMatrix row:1 ] ) n |= 2 ;		//  fsk diddle
	if ( [ self selected:fskMatrix row:2 ] ) n |= 4 ;		//  fsk usos
	if ( [ self selected:pttMatrix row:2 ] ) n |= 0x40 ;	//  lna ptt
	if ( [ self selected:fskMatrix row:0 ] ) n |= 0x80 ;	//  invert fsk
	X[1] = n ;

	n = 0 ;
	if ( [ self selected:pttMatrix row:1 ] ) n |= 1 ;		//  pa ptt 
	X[2] = n ;
	
	n = [ pttStepper intValue ] ;
	if ( n < 0 ) n = 0 ; else if ( n > 255 ) n = 255 ;
	X[3] = n ;
	
	if ( isDK2 == NO ) {
		n = [ sidetoneMenu indexOfSelectedItem ] & 0x7 ;
		n += ( [ wpmStepper intValue ] & 0xf ) << 4 ;
	}
	else {
		//  DK2
		n = [ d2SidetoneMenu indexOfSelectedItem ] & 0x7 ;
		n += ( [ d2WpmStepper intValue ] & 0xf ) << 4 ;
	}
	X[5] = n ;
	
	n = 0 ;
	if ( !isDK2 ) {
		routingRow = [ forcedKeyerMatrix selectedRow ] ;
		if ( routingRow != 1 ) n |= 1 ;														//  v1.60 r1ForceKeyerMode
		if ( routingRow == 0 && isMK2 ) n |= 0x10 ;											//  v1.60 r1FollowTxMode
		if ( [ self selected:pttMatrix row:3 ] ) n |= 8 ;									//  no delay on lna
		if ( [ [ cwPTTMenu titleOfSelectedItem ] isEqualToString:@"QSK" ] ) n |= 0x80 ;		//  r1Qsk
		if ( [ self selected:cwMatrix row:5 ] ) n |= 0x20 ;									//  r1AllowCwInVoice
	}
	else {
		//  v1.62 digiKeyer II
		routingRow = [ d2ForcedKeyerMatrix selectedRow ] ;
		if ( routingRow != 1 ) n |= 1 ;														//  r1ForceKeyerMode
		if ( routingRow == 0 ) n |= 0x10 ;													//  r1FollowTxMode
		if ( [ self selected:d2PttMatrix row:3 ] ) n |= 8 ;									//  no delay on lna
		if ( [ [ d2CwPTTMenu titleOfSelectedItem ] isEqualToString:@"QSK" ] ) n |= 0x80 ;	//  r1Qsk
	}
	X[6] = n ;
	
	m = 0 ;
	if ( !isDK2 ) {
		switch ( routingRow ) {
		case 2:
			m = 3 ;				//  digital
			break ;
		case 3:
			m = 1 ;				//  voice
			break ;
		case 5:
			m = 2 ;				//  fsk
			break ;
		}
		matrix = cwMatrix ;
	}
	else {
		//  v1.62 digiKeyer II
		switch ( routingRow ) {
		case 2:
			m = 3 ;				//  digital
			break ;
		case 4:
			m = 2 ;				//  fsk
			break ;
		}
		matrix = d2CwMatrix ;
	}
	n = ( m << 5 ) ;	
	if ( [ self selected:matrix row:0 ] ) n |= 2 ;
	if ( [ self selected:matrix row:1 ] ) n |= 4 ;
	if ( [ self selected:matrix row:2 ] ) n |= 8 ;
	if ( [ self selected:matrix row:3 ] ) n |= 0x10 ;
	if ( [ self selected:matrix row:4 ] ) n |= 0x80 ;
	X[7] = n ;	
	
	X[8] = X[9] = 0 ;			// reserved (these are adding in 18th June by microHAM, but not yet implemented here)
	
	//  create the bases for voice and CW
	X[10] = [ self makeCWKeyerBase ] ;
	X[11] = [ self makeVoiceKeyerBase ] ;
}

//  Called from lcdMessageChanged (when message fields change) or storeMessages (when "save messages to EEPROM)
- (void)updateLCDMessages:(Boolean)store mask:(int)mask
{
	int i ;
	unsigned char *s, line1[22], line2[22] ;

	if ( mask & 0x1 ) {
		for ( i = 0; i < 22; i++ ) line1[i] = ' ' ;
		line1[18] = line1[19] = 0 ;
		line1[1] = 0 ;
	
		s = (unsigned char*)[ [ lcdLine1Message stringValue ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
		for ( i = 0; i < 16; i++ ) {
			if ( *s == 0 ) break ;
			line1[i+2] = *s++ ;
		}
		if ( store ) {
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.15 ] ] ;
			line1[0] = 0x2e ;
			line1[20] = 0xae ;
			[ router sendControl:line1 length:21 ] ;
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.15 ] ] ;
		}
		else {
			line1[0] = 0x2c ;
			line1[20] = 0xac ;
			[ router sendControl:line1 length:21 ] ;
		}
		//  Clear Host Strings if stored message is selected in X15/X16
		if ( [ lcdLine1Setting selectedTag ] != 1 ) {
			unsigned char cancel[] = { 0x2d, 0, 0xad } ;
			[ router sendControl:cancel length:3 ] ;
		}
	}
	if ( mask & 2 ) {
		for ( i = 0; i < 22; i++ ) line2[i] = ' ' ;
		line2[18] = line2[19] = 0 ;
		line2[1] = 1 ;
	
		s = (unsigned char*)[ [ lcdLine2Message stringValue ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
		for ( i = 0; i < 16; i++ ) {
			if ( *s == 0 ) break ;
			line2[i+2] = *s++ ;
		}
		if ( store ) {
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.15 ] ] ;
			line2[0] = 0x2e ;
			line2[20] = 0xae ;
			[ router sendControl:line2 length:21 ] ;
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.15 ] ] ;
		}
		else {
			line2[0] = 0x2c ;
			line2[20] = 0xac ;
			[ router sendControl:line2 length:21 ] ;
		}
		//  Clear Host Strings if stored message is selected in X15/X16
		if ( [ lcdLine2Setting selectedTag ] != 1 ) {
			unsigned char cancel[] = { 0x2d, 1, 0xad } ;
			[ router sendControl:cancel length:3 ] ;
		}
	}
}

- (void)lcdMessageChanged:(id)sender
{
	[ self updateLCDMessages:NO mask:3 ] ;
}

- (IBAction)storeMessages:(id)sender
{
	[ self updateLCDMessages:YES mask:3 ] ;
}

- (void)makeSettingsString
{
	int i ;
	
	[ self makeBasicSettingsString ] ;
	if ( isMK2 ) [ self makeExtensionSettingsString ] ;
	else {
		if ( isDK2 ) [ self makeDK2ExtensionSettingsString ] ;
		else {
			for ( i = 12; i < 56; i++ ) settingsString[i] = 0 ;
		}
	}
}

- (void)diagnosticPrint:(int)n
{
	int i ;
	
	printf( "\n" ) ;
	for ( i = 0; i < n; i++ ) printf( "%02d ", i ) ;
	printf( "\n" ) ;
	for ( i = 0; i < n; i++ ) printf( "%02x ", settingsString[i]&0xff ) ;
	printf( "\n" ) ;
}

//  Cancel host strings if X15 and X16 are not set to display messages, otherwise send the strings from X15/X15
- (void)updateHostStrings
{
	int utcSelect = [ lcdUTCMatrix selectedColumn ] ;
	
	if ( settingsString[15] != 1 ) {
		if ( utcSelect != 1 ) {
			unsigned char cancelLine1[] = { 0x2d, 0, 0xad } ;
			[ router sendControl:cancelLine1 length:3 ] ;
		}
	}
	else {
		[ self updateLCDMessages:NO mask:1 ] ;
	}
	
	if ( settingsString[16] != 1 && utcSelect != 2 ) {
		unsigned char cancelLine2[] = { 0x2d, 1, 0xad } ;
		[ router sendControl:cancelLine2 length:3 ] ;
	}
	else {
		[ self updateLCDMessages:NO mask:2 ] ;
	}
}

//  send settings string to keyer
- (void)setSettingAndStore:(Boolean)store count:(int)count
{
	unsigned char msg[58] ;
	int i ;
	
	for ( i = 0; i < count; i++ ) msg[i+1] = settingsString[i] ;
	if ( store ) {
		msg[0] = 0x08 ;
		msg[count+1] = 0x88 ;
		[ router sendControl:msg length:count+2 ] ;
	}
	msg[0] = 0x09 ;
	msg[count+1] = 0x89 ;
	[ router sendControl:msg length:count+2 ] ;
}

//  set (and store) SETTINGS string and update host LCD messages 
- (void)setSettingAndStore:(Boolean)store
{
	if ( isMK2 || isDK2 ) {
		[ self setSettingAndStore:store count:56 ] ;
		if ( isMK2 ) [ self updateHostStrings ] ;
	}
	else {
		[ self setSettingAndStore:store count:12 ] ;
	}
}

//  settings has changed. update the keyer 
- (void)settingChanged:(id)sender
{
	[ self makeSettingsString ] ;
	[ self setSettingAndStore:NO ] ;
}

- (void)auxChanged:(id)sender
{
	[ self settingChanged:sender ] ;
}

- (void)routingChanged:(id)sender
{
	[ self makeUpRoutingExplainations ] ;
	[ self settingChanged:sender ] ;
}

- (void)changeStepper:(NSStepper*)stepper field:(NSTextField*)field scale:(int)scale
{
	[ field setIntValue:[ stepper intValue ]*scale ] ;
	[ self makeSettingsString ] ;
	[ self setSettingAndStore:NO ] ;
}

- (void)pttStepperChanged:(id)sender
{
	if ( isDK2 ) {
		[ self changeStepper:d2PttStepper field:d2PttDelayField scale:10 ] ;
	}
	else {
		[ self changeStepper:pttStepper field:pttDelayField scale:10 ] ;
	}
}

- (void)wpmChanged:(id)sender
{
	if ( isDK2 ) {
		[ self changeStepper:d2WpmStepper field:d2WpmField scale:1 ] ;
	}
	else {
		[ self changeStepper:wpmStepper field:wpmField scale:1 ] ;
	}
}

- (void)eventsStepperChanged:(id)sender
{
	[ self changeStepper:eventDurationStepper field:eventDurationField scale:10 ] ;
}

- (void)digitalMonitorStepperChanged:(id)sender
{
	[ self changeStepper:digitalMonitorStepper field:digitalMonitorField scale:1 ] ;
}

- (void)voiceMonitorStepperChanged:(id)sender
{
	[ self changeStepper:voiceMonitorStepper field:voiceMonitorField scale:1 ] ;
}

- (void)cwMonitorStepperChanged:(id)sender
{
	[ self changeStepper:cwMonitorStepper field:cwMonitorField scale:1 ] ;
}

- (void)extendedMicroKeyerButtonPushed:(id)sender
{
	[ extendedSettingsWindow center ] ;
	[ extendedSettingsWindow makeKeyAndOrderFront:self ] ;
}

- (void)syncFields
{
	[ self makeUpRoutingExplainations ] ;
	[ pttDelayField setIntValue:[ pttStepper intValue ]*10 ] ;
	[ wpmField setIntValue:[ wpmStepper intValue ] ] ;
}

- (void)show
{
	NSWindow *window ;
	
	[ self syncFields ] ;
	window = ( isDK2 ) ? [ d2DigitalPTTMenu window ] : [ digitalPTTMenu window ] ;
	[ window center ] ;
	[ window makeKeyAndOrderFront:self ] ;
}

//  set the cell of the matrix if any bits of mask is on
- (void)setMatrix:(NSMatrix*)matrix row:(int)row mask:(int)any
{
	[ [ matrix cellAtRow:row column:0 ] setState:( ( any != 0 ) ? NSOnState : NSOffState ) ] ;
}

- (void)setAudioRouting:(NSPopUpButton*)audioPopup pttRouting:(NSPopUpButton*)pttPopup toBase:(int)base qsk:(Boolean)qsk
{
	char str[16], *pttstr, *pttSelection[] = { "None", "PTT1", "PTT2", "Both" } ;
	NSString *cstr ;

	str[0] = abcdEncoding[ base & 0x3 ] ;
	str[1] = abcdEncoding[ ( base >> 2 ) & 0x3 ] ;
	str[2] = abcdEncoding[ ( base >> 4 ) & 0x3 ] ;
	str[3] = 0 ;
	
	cstr = [ NSString stringWithCString:str encoding:NSASCIIStringEncoding ] ;
	[ audioPopup selectItemWithTitle:[ NSString stringWithCString:str encoding:NSASCIIStringEncoding ] ] ;
	if ( [ audioPopup indexOfSelectedItem ] < 0 ) [ audioPopup selectItemAtIndex:0 ] ;
	
	pttstr = ( qsk ) ? "QSK" : pttSelection[ ( base >> 6 ) & 3 ] ;
	[ pttPopup selectItemWithTitle:[ NSString stringWithCString:pttstr encoding:NSASCIIStringEncoding ] ] ;
	if ( [ pttPopup indexOfSelectedItem ] < 0 ) [ pttPopup selectItemAtIndex:0 ] ;
}

- (void)setDigitalBaseFromByte:(int)byte
{
	if ( isDK2 ) {
		[ d2DigitalPTTMenu selectItemWithTitle:( ( byte & 0x80 ) != 0 ) ? @"PTT" : @"None" ] ;
	}
	else {
		[ self setAudioRouting:digitalAudioMenu pttRouting:digitalPTTMenu toBase:byte qsk:NO ] ;
	}
}

- (void)setCWBaseFromByte:(int)byte qsk:(Boolean)qsk
{
	if ( isDK2 ) {
		if ( qsk ) [ d2CwPTTMenu selectItemWithTitle:@"QSK" ] ;
		else {
			if ( ( byte & 0x80 ) != 0 ) [ d2CwPTTMenu selectItemWithTitle:@"PTT" ] ;
			else {
				[ d2CwPTTMenu selectItemWithTitle:@"Semi Break-in" ] ;
			}
		}
	}
	else {
		[ self setAudioRouting:cwAudioMenu pttRouting:cwPTTMenu toBase:byte qsk:qsk ] ;
	}
}

- (void)setVoiceBaseFromByte:(int)byte
{
	if ( isDK2 ) return ;

	[ self setAudioRouting:voiceAudioMenu pttRouting:voicePTTMenu toBase:byte qsk:NO ] ;
}

- (void)setMpkExtra:(NSStepper*)stepper field:(NSTextField*)field matrix:(NSMatrix*)matrix toExtra:(int)extra 
{
	int n ;
	
	n = extra & 0x1f ;
	if ( n < 0 ) n = 0 ; else if ( n > 25 ) n = 25 ;
	[ stepper setIntValue:n ] ;
	[ field setIntValue:n ] ;
	[ self setMatrix:matrix row:0 mask:( extra&0x40 ) ] ;
	[ self setMatrix:matrix row:1 mask:( extra&0x80 ) ] ;
}

//  v1.62 change GUI to SETTINGS string for digiKeyer II
- (void)changeDK2SettingsToMatchString:(char*)string length:(int)length
{
	int i, byte, n, baud, tag ;
	Boolean qsk ;
	
	//  Check if plist was pre-CI-V version, if so set up default CI-V parameters
	if ( ( string[40] & 0xff ) == 0 && ( string[41] & 0xff ) == 0 && ( string[42] & 0xff ) == 0 && ( string[43] & 0xff ) == 0 ) {
		string[40] = 0x6a ;
		string[41] = 24 ;
		string[42] = 1 ;
		string[29] = 24 ;
	}
		
	for ( i = 0; i < length; i++ ) {
		byte = string[i] & 0xff ;
		switch ( i ) {
		case 0:
			[ self setDigitalBaseFromByte:byte ] ;
			break ;
		case 1:
			[ self setMatrix:d2PttMatrix row:0 mask:( byte & 0x1 ) ] ;
			[ self setMatrix:d2FskMatrix row:1 mask:( byte & 0x2 ) ] ;
			[ self setMatrix:d2FskMatrix row:2 mask:( byte & 0x4 ) ] ;
			[ self setMatrix:d2PttMatrix row:2 mask:( byte & 0x40 ) ] ;
			[ self setMatrix:d2FskMatrix row:0 mask:( byte & 0x80 ) ] ;
			break ;
		case 2:
			[ self setMatrix:d2PttMatrix row:1 mask:( byte & 0x1 ) ] ;
			break ;
		case 3:
			[ d2PttStepper setIntValue:byte ] ;
			[ d2PttDelayField setIntValue:byte*10 ] ;
			break ;
		case 4:
			//  reserved
			break ;
		case 5:
			n = byte & 0x7 ;
			if ( n > 4 ) n = 0 ;
			[ d2SidetoneMenu selectItemAtIndex:n ] ;
			n = ( byte >> 4 ) ;
			[ d2WpmStepper setIntValue:n ] ;
			[ d2WpmField setIntValue:n ] ;
			break ;
		case 6:
			if ( ( byte & 0x1 ) == 0 ) {
				//  not forceKeyer mode
				[ d2ForcedKeyerMatrix selectCellAtRow:1 column:0 ] ;
			}
			else {
				if ( ( byte & 0x10 ) != 0 ) {
					//  r1FollowTxMode
					[ d2ForcedKeyerMatrix selectCellAtRow:0 column:0 ] ;
				}
				else {
					int x7 = string[7] ;
					
					n = ( x7 >> 5 ) & 0x3 ;
					switch ( n ) {
					case 0:
						//  forceKeyer to CW
						[ d2ForcedKeyerMatrix selectCellAtRow:3 column:0 ] ;
						break ;
					case 1:
						//  no Voice mode in digiKeyer II
						break ;
					case 2:
						//  force keyer to FSK
						[ d2ForcedKeyerMatrix selectCellAtRow:4 column:0 ] ;
						break ;
					default:
						//  force keyer to Digital
						[ d2ForcedKeyerMatrix selectCellAtRow:2 column:0 ] ;
						break ;
					}
				}
			}
			[ self setMatrix:d2PttMatrix row:3 mask:( byte & 0x8 ) ] ;
			[ self setMatrix:d2CwMatrix row:5 mask:( byte & 0x20 ) ] ;
			break ;
		case 7:
			[ self setMatrix:d2CwMatrix row:0 mask:( byte & 0x2 ) ] ;
			[ self setMatrix:d2CwMatrix row:1 mask:( byte & 0x4 ) ] ;
			[ self setMatrix:d2CwMatrix row:2 mask:( byte & 0x8 ) ] ;
			[ self setMatrix:d2CwMatrix row:3 mask:( byte & 0x10 ) ] ;
			[ self setMatrix:d2CwMatrix row:4 mask:( byte & 0x80 ) ] ;
			break ;
		case 8:
		case 9:
			//  reserved
			break ;
		case 10:
			qsk = ( ( string[6] & 0x80 ) == 0x80 ) ;
			[ self setCWBaseFromByte:byte qsk:qsk ] ;
			break ;
		case 11:
			//  no voice mode
			break ;
		case 12:
		case 13:
		case 14:
		case 15:
		case 16:
		case 17:
		case 18:
		case 19:
		case 20:
		case 21:
		case 22:
		case 23:
		case 24:
		case 25:
		case 26:
		case 27:
		case 29:
		case 43:
			//  these are "reserved" for the digiKeyer 2 (used for LCD etc in MK2)
			break ;
		case 28:
			//  "mpkFlags"
			[ self setMatrix:d2PttMatrix row:4 mask:( byte & 0x4 ) ] ;		// auto PTT
 			[ self setMatrix:d2PttMatrix row:5 mask:( byte & 0x20 ) ] ;		// audio overides footswitch
 			[ self setMatrix:d2CwMatrix row:6 mask:( byte & 0x8 ) ] ;		// sidetone only from paddle
 			[ self setMatrix:d2CwMatrix row:5 mask:( byte & 0x40 ) ] ;		// CW OOK
			[ self setMatrix:d2FskMatrix row:3 mask:( byte & 0x80 ) ] ;		// FSK OOK
 			break ;
		case 40:
			[ d2CivAddress setStringValue:[ NSString stringWithFormat:@"%02X", byte & 0xff ] ] ;
			break ;
		case 41:
			byte &= 0xff ;
			if ( byte > 1 ) {
				baud = 230401/byte ;
				if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
			}
			else baud = 9600 ;
			[ d2CivBaud setIntValue:baud ] ;
			break ;
		case 42:
			tag = byte & 0x7f ;
			[ d2CivFunction selectItemWithTag:tag ] ;
			break ;
		}
	}
}

//  change GUI to SETTINGS string
- (void)changeSettingsToMatchString:(char*)string length:(int)length
{
	int i, j, byte, n, mask, baud, tag ;
	Boolean qsk ;
	
	if ( isDK2 ) {
		//  v1.62 digiKeyer II
		[ self changeDK2SettingsToMatchString:string length:length ] ;
		return ;
	}
	
	//  v 1.50 check if plist was pre-CI-V version, if so set up default CI-V parameters
	if ( ( string[40] & 0xff ) == 0 && ( string[41] & 0xff ) == 0 && ( string[42] & 0xff ) == 0 && ( string[43] & 0xff ) == 0 ) {
		string[40] = 0x6a ;
		string[41] = 24 ;
		string[42] = 1 ;
		string[29] = 24 ;
	}
	
	for ( i = 0; i < length; i++ ) {
		byte = string[i] & 0xff ;
		switch ( i ) {
		case 0:
			[ self setDigitalBaseFromByte:byte ] ;
			break ;
		case 1:
			[ self setMatrix:pttMatrix row:0 mask:( byte & 0x1 ) ] ;
			[ self setMatrix:fskMatrix row:1 mask:( byte & 0x2 ) ] ;
			[ self setMatrix:fskMatrix row:2 mask:( byte & 0x4 ) ] ;
			[ self setMatrix:pttMatrix row:2 mask:( byte & 0x40 ) ] ;
			[ self setMatrix:fskMatrix row:0 mask:( byte & 0x80 ) ] ;
			break ;
		case 2:
			[ self setMatrix:pttMatrix row:1 mask:( byte & 0x1 ) ] ;
			break ;
		case 3:
			[ pttStepper setIntValue:byte ] ;
			[ pttDelayField setIntValue:byte*10 ] ;
			break ;
		case 4:
			//  reserved
			break ;
		case 5:
			n = byte & 0x7 ;
			if ( n > 4 ) n = 0 ;
			[ sidetoneMenu selectItemAtIndex:n ] ;
			n = ( byte >> 4 ) ;
			[ wpmStepper setIntValue:n ] ;
			[ wpmField setIntValue:n ] ;
			break ;
		case 6:
			if ( ( byte & 0x1 ) == 0 ) {
				//  not forceKeyer mode
				[ forcedKeyerMatrix selectCellAtRow:1 column:0 ] ;
			}
			else {
				if ( ( byte & 0x10 ) != 0 ) {
					//  r1FollowTxMode
					[ forcedKeyerMatrix selectCellAtRow:0 column:0 ] ;
				}
				else {
					int x7 = string[7] ;
					
					n = ( x7 >> 5 ) & 0x3 ;
					switch ( n ) {
					case 0:
						//  forceKeyer to CW
						[ forcedKeyerMatrix selectCellAtRow:4 column:0 ] ;
						break ;
					case 1:
						//  force keyer to Voice
						[ forcedKeyerMatrix selectCellAtRow:3 column:0 ] ;
						break ;
					case 2:
						//  force keyer to FSK
						[ forcedKeyerMatrix selectCellAtRow:5 column:0 ] ;
						break ;
					default:
						//  force keyer to Digital
						[ forcedKeyerMatrix selectCellAtRow:2 column:0 ] ;
						break ;
					}
				}
			}
			[ self setMatrix:pttMatrix row:3 mask:( byte & 0x8 ) ] ;
			[ self setMatrix:cwMatrix row:5 mask:( byte & 0x20 ) ] ;
			break ;
		case 7:
			[ self setMatrix:cwMatrix row:0 mask:( byte & 0x2 ) ] ;
			[ self setMatrix:cwMatrix row:1 mask:( byte & 0x4 ) ] ;
			[ self setMatrix:cwMatrix row:2 mask:( byte & 0x8 ) ] ;
			[ self setMatrix:cwMatrix row:3 mask:( byte & 0x10 ) ] ;
			[ self setMatrix:cwMatrix row:4 mask:( byte & 0x80 ) ] ;
			break ;
		case 8:
		case 9:
			//  reserved
			break ;
		case 10:
			qsk = ( ( string[6] & 0x80 ) == 0x80 ) ;
			[ self setCWBaseFromByte:byte qsk:qsk ] ;
			break ;
		case 11:
			[ self setVoiceBaseFromByte:byte ] ;
			break ;
		
		//  ------- extended settings (X15-X25 are LCD settings) v1.62 ignore for digiKeyer II -------

		case 12:
			[ self setMpkExtra:digitalMonitorStepper field:digitalMonitorField matrix:digitalRecordingMatrix toExtra:byte ] ; 
			break ;
		case 13:
			n = byte & 0x1f ;
			if ( n < 0 ) n= 0 ; else if ( n > 19 ) n = 19 ;	//  limit to 19 since 19-25 is too dark
			[ lcdContrast setIntValue:n ] ;
			break ;
		case 14:
			n = byte & 0x1f ;
			if ( n < 0 ) n= 0 ; else if ( n > 25 ) n = 25 ;
			[ lcdBrightness setIntValue:n ] ;
			break ;
		case 15:
            n = byte & 0x1f;
			if ( n < 0 ) n = 0 ; else if ( n > 0x12 ) n = 0x12 ;
            [ lcdLine1Setting selectItemWithTag:tag ] ;
			break ;
        case 16:
            n = byte & 0x1f;
			if ( n < 0 ) n = 0 ; else if ( n > 0x12 ) n = 0x12 ;
            [ lcdLine2Setting selectItemWithTag:tag ] ;
			break ;
		case 17:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line1EventsSet addIndex: j ];
                }
			}
            break ;
		case 18:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line1EventsSet addIndex: j+8 ];
                }
			}
            break ;
		case 19:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line1EventsSet addIndex: j+16 ];
                }
			}
            break ;
		case 20:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line1EventsSet addIndex: j+24 ];
                }
			}
            break ;
		case 21:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line2EventsSet addIndex: j ];
                }
			}
            break ;
        case 22:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line2EventsSet addIndex: j+8 ];
                }
			}
            break ;
        case 23:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line2EventsSet addIndex: j+16 ];
                }
			}
            break ;
        case 24:
			for ( j = 0; j < 8; j++ ) {
                if ( 1<<j & byte  )
                {
                    [ line2EventsSet addIndex: j+24 ];
                }
			}
            break ;
		case 25:
			[ eventDurationStepper setIntValue:byte ] ;
			[ eventDurationField setIntValue:byte*10 ] ;
			break ;
		case 26:
			[ self setMpkExtra:cwMonitorStepper field:cwMonitorField matrix:cwRecordingMatrix toExtra:byte ] ; 
			break ;
		case 27:
			[ self setMpkExtra:voiceMonitorStepper field:voiceMonitorField matrix:voiceRecordingMatrix toExtra:byte ] ; 
			break ;
		case 28:
			mask = 1 ;
			for ( j = 0; j < 6; j++ ) {
				[ self setMatrix:mpkFlagsMatrix row:j mask:( byte & mask ) ] ;
				mask *= 2 ;
			}
			break ;
		case 29:
			//  v1.41
			byte &= 0xff ;
			if ( byte > 1 ) {
				baud = 230401/byte ;
				if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
			}
			else baud = 9600 ;
			[ iLinkBaud setIntValue:baud ] ;
			break ;
		case 40:
			//  v 1.50
			[ civAddress setStringValue:[ NSString stringWithFormat:@"%02X", byte & 0xff ] ] ;
			break ;
		case 41:
			//  v 1.50
			byte &= 0xff ;
			if ( byte > 1 ) {
				baud = 230401/byte ;
				if ( baud < 1000 ) baud = 1000 ; else if ( baud > 19200 ) baud = 19200 ;
			}
			else baud = 9600 ;
			[ civBaud setIntValue:baud ] ;
			break ;
		case 42:
			tag = byte & 0x7f ;
			[ civFunction selectItemWithTag:tag ] ;
			break ;
		case 43:
			tag = byte & 0x7f ;
			[ iLinkFunction selectItemWithTag:( string[2] & 0x80 ) ? 0x80 : tag ] ;	// v1.90 UB3ABM: check MSB of X2 (r1I2CCoupled)
			break ;
		}
	}
}

static Boolean isHex( int c )
{
	if ( c >= '0' && c <= '9' ) return YES ;
	if ( c >= 'a' && c <= 'f' ) return YES ;
	if ( c >= 'A' && c <= 'F' ) return YES ;
	return NO ;
}

static int hexValue( int c )
{
	if ( c >= '0' && c <= '9' ) return c - '0' ;
	if ( c >= 'a' && c <= 'f' ) return c - 'a' + 10 ;
	if ( c >= 'A' && c <= 'F' ) return c - 'A' + 10 ;
	return 0 ;
}

static int hexFor( int v )
{
	v &= 0xf ;
	if ( v < 10 ) return '0' + v ;
	return 'A' + v - 10 ;
}

- (void)changeSettingsToMatchHexString:(NSString*)cstr length:(int)length
{
	char *str ;
	const char *hex ;
	int i, value ;
	
	str = malloc( length+1 ) ;
	hex = [ cstr cStringUsingEncoding:NSASCIIStringEncoding ] ;
	
	for ( i = 0; i < length; i++ ) {
		value = hexValue( hex[i*2] )*16 + hexValue( hex[i*2+1] ) ;
		str[i] = value ;
	}
	[ self changeSettingsToMatchString:str length:length ] ;
	free( str ) ;
}

//  at this point connection to the physical keyer is not made yet -- just update GUI for now and wait for -sendSettingsToKeyer to send GUI setting to the keyer
- (void)setupKeyerFromPref:(NSDictionary*)prefs 
{
	int tag, column, i, count;
	float contrast, brightness ;
	NSNumber *number ;
	NSString *string ;
	NSArray *prefEvents ;
	
	if ( isMK2 ) {	
		//  set GUI up from SETTINGS in Plist
		string = [ prefs objectForKey:kSetupHexString ] ;
		//  v 1.50 check if prior to version 3
		number = [ prefs objectForKey:kPrefVersion ] ;
		if ( string != nil ) [ self changeSettingsToMatchHexString:string length:56 ] ; else [ self changeSettingsToMatchString:factory length:56 ] ;
		
		//  set up LCD
		number = [ prefs objectForKey:kMicroKeyerIILCDLine1 ] ;
		tag = ( number != nil ) ? [ number intValue ] : 1 ;
        [ lcdLine1Setting selectItemWithTag:tag ] ;
        
		number = [ prefs objectForKey:kMicroKeyerIILCDLine2 ] ;
		tag = ( number != nil ) ? [ number intValue ] : 1 ;
		[ lcdLine2Setting selectItemWithTag: tag ];

		number = [ prefs objectForKey:kMicroKeyerIILCDClock ] ;
		column = ( number != nil ) ? [ number intValue ] : 2 ;
		[ lcdUTCMatrix selectCellAtRow:0 column:column ] ;
		
		number = [ prefs objectForKey:kMicroKeyerIILCDContrast ] ;
		contrast = ( number != nil ) ? [ number floatValue ] : 5.0 ;
		[ lcdContrast setFloatValue:contrast ] ;
		
		number = [ prefs objectForKey:kMicroKeyerIILCDBrightness ] ;
		brightness = ( number != nil ) ? [ number floatValue ] : 21.0 ;
		[ lcdBrightness setFloatValue:brightness ] ;
		
		string = [ prefs objectForKey:kMicroKeyerIILCDMessage1 ] ;
		if ( string == nil ) string = @"micro KEYER II  " ;
		[ lcdLine1Message setStringValue:string ] ;
		
		string = [ prefs objectForKey:kMicroKeyerIILCDMessage2 ] ;
		if ( string == nil ) string = @"   from microHAM" ;
		[ lcdLine2Message setStringValue:string ] ;
		
		//  event menus
        count = [ eventList count ] ;
        prefEvents = [ prefs objectForKey:kMicroKeyerIIEvents ];
        if ( prefEvents != nil )
        {
            // Read in the old preferences
            [line1EventsSet removeAllIndexes];
            [line2EventsSet removeAllIndexes];
            if ( prefEvents != nil ) {
                count = [ prefEvents count ];
                for ( i = 0; i < count; i++ ) {
                    string = [ prefEvents objectAtIndex:i ] ;
                    if ( [ string isEqualToString:@"Line 1" ])
                    {
                        [ line1EventsSet addIndex: i ];
                    }
                    else if ( [string isEqualToString:@"Line 2"] )
                    {
                        [ line2EventsSet addIndex: i ];
                    }
                }
            }
        }
        else
        {
            // New settings come from the Config string
        }
	}
	else {
		if ( isDK2 ) {	
			//  set GUI up from SETTINGS in Plist
			string = [ prefs objectForKey:kSetupHexString ] ;
			//  v 1.50 check if prior to version 3
			number = [ prefs objectForKey:kPrefVersion ] ;
			if ( string != nil ) [ self changeSettingsToMatchHexString:string length:56 ] ; else [ self changeSettingsToMatchString:factory length:56 ] ;
		}
		else {	
			[ [ forcedKeyerMatrix cellAtRow:0 column:0 ] setEnabled: NO ] ;
			//  set GUI from SETTINGS in Plist
			string = [ prefs objectForKey:kSetupHexString ] ;
			if ( string != nil ) [ self changeSettingsToMatchHexString:string length:12 ] ; else [ self changeSettingsToMatchString:factory length:12 ] ;
		}
	}
}

- (void)sendSettingsToKeyer
{
	if ( isMK2 ) {	
		[ self utcSelectionChanged:self ] ;		//  this updatess UTC and 56 settings string and send to keyer
		[ self updateLCDMessages:NO mask:3 ] ;
	}
	else {
		[ self settingChanged:self ] ;			// this sets up the 12 setting string and send to keyer
	}
}

- (NSMutableDictionary*)settingsPlist
{
	NSMutableDictionary *plist = [ NSMutableDictionary dictionaryWithCapacity:0 ] ;
    NSData *setData;
    NSMutableArray *events;
	NSString *string, *msg1, *msg2 ;
	int i, n, line1, line2, utc, count;
	float contrast, brightness ;
	char hexString[113] ;
	
	[ self makeSettingsString ] ;
	
	for ( i = 0; i < 56; i++ ) {
		n = settingsString[i] ;
		hexString[i*2] = hexFor( n >> 4 ) ;
		hexString[i*2+1] = hexFor( n ) ;
	}	
	hexString[112] = 0 ;
	string = [ NSString stringWithCString:hexString encoding:NSASCIIStringEncoding ] ;
	[ plist setObject:string forKey:kSetupHexString ] ;
	
	//  include LCD prefs
	if ( isMK2 ) {
        line1 = [ lcdLine1Setting selectedTag ];
        line2 = [ lcdLine2Setting selectedTag ];
		utc = [ lcdUTCMatrix selectedColumn ] ;
		contrast = [ lcdContrast floatValue ] ;
		brightness = [ lcdBrightness floatValue ] ;
		msg1 = [ lcdLine1Message stringValue ] ;
		msg2 = [ lcdLine2Message stringValue ] ;
		
		[ plist setObject:[ NSNumber numberWithInt:line1 ] forKey:kMicroKeyerIILCDLine1 ] ;
		[ plist setObject:[ NSNumber numberWithInt:line2 ] forKey:kMicroKeyerIILCDLine2 ] ;
		[ plist setObject:[ NSNumber numberWithInt:utc ] forKey:kMicroKeyerIILCDClock ] ;
		[ plist setObject:[ NSNumber numberWithFloat:contrast ] forKey:kMicroKeyerIILCDContrast ] ;
		[ plist setObject:[ NSNumber numberWithFloat:brightness ] forKey:kMicroKeyerIILCDBrightness ] ;
		[ plist setObject:msg1 forKey:kMicroKeyerIILCDMessage1 ] ;
		[ plist setObject:msg2 forKey:kMicroKeyerIILCDMessage2 ] ;
        
        /* TEB: Works, but isn't human readable */
        /*setData = [NSKeyedArchiver archivedDataWithRootObject: line1Events];
        [ plist setObject: setData forKey:kMicroKeyerIILine1Events ];*/
        
        /*
        count = [ line1Events numberOfRows ];
        if ( count > 0)
        {
			events = [ NSMutableArray arrayWithCapacity:count ] ;
            [[line1Events selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [events addObject: [NSNumber numberWithInt:idx]];
            }];
            [ plist setObject:events forKey: kMicroKeyerIILine1Events];
        }
        
        count = [ line2Events numberOfRows ];
        if ( count > 0)
        {
			events = [ NSMutableArray arrayWithCapacity:count ] ;
            [[line2Events selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [events addObject: [NSNumber numberWithInt:idx]];
            }];
            [ plist setObject:events forKey: kMicroKeyerIILine2Events];
        }*/
        
        
        /* TEB
		count = [ eventsMatrix numberOfRows ] ;
		if ( count > 0 ) {
			events = [ NSMutableArray arrayWithCapacity:count ] ;
			for ( i = 0; i < count; i++ ) {
				event = [ eventsMatrix cellAtRow:i column:0 ] ;
				[ events addObject:[ event titleOfSelectedItem ] ] ;
			}
			[ plist setObject:events forKey:kMicroKeyerIIEvents ] ;
		}
         */
	}
	else {
		line1 = line2 = utc = 0 ;
		contrast = brightness = 0 ;
		msg1 = msg2 = @"" ;
	}

	return plist ;
}

- (NSMutableDictionary*)defaultSettingsPlist
{
	NSMutableDictionary *plist = [ NSMutableDictionary dictionaryWithCapacity:0 ] ;
	
	//  empty plist
	return plist ;
}

- (void)shutdown
{
	if ( utcSelection != 0 ) {
		unsigned char msg[] = { 0x2d, 0, 0xad } ;
		msg[1] = utcSelection-1 ;
		[ router sendControl:msg length:3 ] ;
	}
}

- (void)setFactoryLCDSetting
{
	if ( isMK2 ) {
		[ lcdLine1Setting selectItemWithTag: 1 ];
		[ lcdLine2Setting selectItemWithTag: 1 ];
		[ lcdLine1Message setStringValue:@"micro KEYER II  " ] ;
		[ lcdLine2Message setStringValue:@"   from microHAM" ] ;
	}
}

- (IBAction)storeSettings:(id)utcselection
{
	[ self makeSettingsString ] ;
	[ self setSettingAndStore:YES ] ;
}

- (IBAction)resetEEPROM:(id)sender
{
	if ( isDK2 == NO ) {
		[ self setFactoryLCDSetting ] ;
		[ self updateLCDMessages:YES mask:3 ] ;
		[ self changeSettingsToMatchString:factory length:( (isMK2) ? 56 : 12 ) ] ;
		[ self lcdSettingsChanged ] ;
	}
	[ self makeSettingsString ] ;
	[ self setSettingAndStore:YES ] ;
}

//  -------  LCDpanel -----------------------------------


//  This updates the display in the microKeyer II
- (void)microKeyerIIClock:(NSTimer*)timer
{
	time_t t ;
	struct tm gmt ;
	int line, x15 ;
	unsigned char msg[22] ;
	NSTextField *field ;
	NSString *str ;

	t = time( nil ) ;
	gmt = *gmtime( &t ) ;
	
	line = ( utcSelection-1 )&1 ;
	
	//  send UTC
	msg[0] = 0x2c ;
	msg[1] = line ;
	sprintf( (char*)&msg[2], "%02d/%02d   %02d:%02d:%02d", gmt.tm_mday, gmt.tm_mon+1, gmt.tm_hour, gmt.tm_min, gmt.tm_sec ) ;
	msg[18] = msg[19] = 0 ;
	msg[20] = 0xac ;
	msg[21] = 0 ;
		
	[ router sendControl:msg length:21 ] ;
	
	if ( utcRefreshCycle++ > 5 ) {
		utcRefreshCycle = 0 ;
		line ^= 1 ;
		//  refresh other line, but only if X15 or X16 is not selected to use host message
		x15 = ( line == 0 ) ? 15 : 16 ;
		if ( settingsString[x15] == 0x01 ) {
			field = ( line == 0 ) ? lcdLine1Message : lcdLine2Message ;
			str = [ field stringValue ] ;
			if ( str && [ str length ] <= 16 ) {
				msg[0] = 0x2c ;
				msg[1] = line ;
				memset( &msg[2], ' ', 16 ) ;
				strncpy( (char*)&msg[2], [ str cString ], [ str length ] ) ;
				msg[18] = msg[19] = 0 ;
				msg[20] = 0xac ;
				[ router sendControl:msg length:21 ] ;
			}
		}
	}
}

- (void)lcdSettingsChanged
{
	[ self makeSettingsString ] ;
	[ self setSettingAndStore:NO ] ;
}

- (void)utcSelectionChanged:(id)sender
{
	int previous ;
	
	previous = utcSelection ;
	//  start/stop microKeyer II clock display
	utcSelection = [ lcdUTCMatrix selectedColumn ] ;

	if ( utcSelection == 0 ) {
		if ( utcTimer ) {
			[ utcTimer invalidate ] ;
			utcTimer = nil ;
		}
		if ( previous != 0 ) {
			unsigned char cancel[] = { 0x2d, 0, 0xad } ;
			cancel[1] = previous-1 ;
			[ router sendControl:cancel length:3 ] ;
		}
	}
	else {
		if ( utcTimer ) [ utcTimer invalidate ] ;
		[ self microKeyerIIClock:nil ] ;
		utcRefreshCycle = 6 ;
		[ self microKeyerIIClock:nil ] ;	//  case an immediate refresh of both lines
		utcTimer = [ NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(microKeyerIIClock:) userInfo:self repeats:YES ] ;
	}
	[ router setInt:[ lcdUTCMatrix selectedColumn ] forKey:kMicroKeyerIILCDClock ] ;
	
	//  update the display lines
	[ self lcdSettingsChanged ] ;
	[ self updateHostStrings ] ;
}

//  backdoors
- (void)setFSKInvert:(Boolean)state
{
	if ( isDK2 == NO ) {
		[ self setMatrix:fskMatrix row:0 mask:( state ) ? 1 : 0 ] ;
	}
	else {
		[ self setMatrix:d2FskMatrix row:0 mask:( state ) ? 1 : 0 ] ;
	}
	
	[ self makeBasicSettingsString ] ;
	[ self setSettingAndStore:NO count:12 ] ;
}

//  v1.61  X7 bits
//	v1.62 -- added digiKeyer 2 interface
- (void)setRouting:(int)index
{
	int d2Row ;
	
		
	if ( isDK2 == NO ) {
		if ( index > 5 ) return ;
		[ forcedKeyerMatrix selectCellAtRow:index column:0 ] ;
	}
	else {
		if ( index == 3 || index > 5 ) return ;
		d2Row = ( index < 3 ) ? index : index-1 ;
		[ d2ForcedKeyerMatrix selectCellAtRow:d2Row column:0 ] ;
	}
	[ self makeBasicSettingsString ] ;
	[ self setSettingAndStore:NO count:12 ] ;
}

//  v1.62  X28 bits in digiKeyer 2
- (void)setOOK:(int)index state:(int)state
{
	if ( isDK2 == NO ) return ;
	
	switch ( index ){
	case 0:
		[ self setMatrix:d2CwMatrix row:5 mask:( state ) ? 1 : 0 ] ;
		break ;
	case 1:
		[ self setMatrix:d2FskMatrix row:3 mask:( state ) ? 1 : 0 ] ;
		break ;
	}
	[ self makeBasicSettingsString ] ;
	[ self setSettingAndStore:NO count:56 ] ;
}

-(NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return [eventList count];
}

- (id) tableView:(NSTableView *)updateTable objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSMutableIndexSet *set;
    if ( [[updateTable identifier] isEqualToString:@"Line1"])
    {
        set = line1EventsSet;
    }
    else
    {
        set = line2EventsSet;
    }
    if ( [ [ tableColumn identifier ] isEqualToString:@"check" ] )
    {
        return [NSNumber numberWithBool:[set containsIndex:row]];
    }
    else
    {
        return [ eventList objectAtIndex: row ];
    }
    
}

- (void)    tableView:(NSTableView*) tv setObjectValue:(id) val
       forTableColumn:(NSTableColumn*) aTableColumn row:(NSInteger) rowIndex
{
    NSMutableIndexSet *set;
    if ( [[tv identifier] isEqualToString:@"Line1"])
    {
        set = line1EventsSet;
    }
    else
    {
        set = line2EventsSet;
    }
    if([[aTableColumn identifier] isEqualToString:@"check"])
    {
        BOOL selected = [val boolValue];
        
        // add or remove the object from the selection set
        
        if( selected )
            [set addIndex: rowIndex];
        else
            [set removeIndex: rowIndex];
    }
	[ self settingChanged:self ] ;
}

@end
