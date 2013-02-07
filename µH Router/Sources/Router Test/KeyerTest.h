//
//  KeyerTest.h
//  RouterTest
//
//  Created by Kok Chen on 5/25/06.

#ifndef _KEYERTEST_H_
	#define _KEYERTEST_H_

	#import <Cocoa/Cocoa.h>

	@interface KeyerTest : NSObject {
	
		IBOutlet id view ;
		IBOutlet id pttButton ;
		IBOutlet id cwButton ;
		IBOutlet id winkeyButton ;
		IBOutlet id winkeyMessage ;
		IBOutlet id fskButton ;
		IBOutlet id	fskMessage ;
		
		IBOutlet id radioModes ;
		IBOutlet id getVFO ;
		IBOutlet id mainVFO ;
		IBOutlet id subVFO ;
		
		IBOutlet id k3RadioModes ;
		IBOutlet id k3GetVFO ;
		IBOutlet id k3MainVFO ;
		IBOutlet id k3SubVFO ;
		
		//  file descriptors
		int keyerRead, keyerWrite ;
		
		int pttRead, pttWrite ;
		int cwRead, cwWrite ;
		int winkeyRead, winkeyWrite ;
		int fskRead, fskWrite ;
		int controlRead, controlWrite ;
		int radioRead, radioWrite ;
		
		Boolean radioParamsSet ;
		Boolean parseVFO ;
		Boolean parseK3VFO ;
		NSLock *radioBusy ;
		
		//  VFO request from radio
		int encodedVFO ;
		int radioParserSequence ;
		NSTimer *looping ;
		
		char k3String[32] ;
	}
	
	- (id)initIntoTabView:(NSTabViewItem*)tabviewItem read:(int)readDiscriptor write:(int)writeDiscriptor ;

	- (void)handleRadioData:(int)byte ;
	- (void)stopPollingKeyer ;

	@end

#endif
