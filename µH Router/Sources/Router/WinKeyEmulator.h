//
//  WinKeyEmulator.h
//  µH Router
//
//  Created by Kok Chen on 7/3/06.

#ifndef _WINKEYEMULATOR_H_
	#define _WINKEYEMULATOR_H_
	
	#import <Cocoa/Cocoa.h>
	#include "Router.h"

	@interface WinKeyEmulator : NSObject {
		Router *router ;
		char *ascii[256] ;
		Boolean immediateCommand[256] ;
		float dit ;
		float dash ;
		float wpm ;
		float farns ;
		float weight ;
		float interElement ;
		float interCharacter ;
		float keyComp, extension ;
		float ratio ;
		int fd ; 
		Boolean pause ;
		Boolean mergeLetters ;
		int immediate ;
	}
	
	- (id)initWithRouter:(Router*)client ;
	- (void)sendWinkey:(int)byte ;
	- (void)setSpeed ;
	- (void)reset ;
	
	@end
#endif
