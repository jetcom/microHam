//
//  Utility.h
//  µH Utils
//
//  Created by Kok Chen on 7/21/06.


#ifndef _UTILITY_H_
	#define _UTILITY_H_


	#import <Cocoa/Cocoa.h>

	@class Controller ;
	
	typedef struct {
		int major ;
		int minor ;
		int hardware ;
		int mechanical ;
	} Version ;


	@interface Utility : NSObject {
		Controller *client ;
		Boolean debug ;
		//  parser states
		unsigned char *parseHead, *parsePoint ;
		int parseLength ;
		int frameSequence ;
	}

	- (id)initWithClient:(Controller*)inClient ;
	
	- (void)sendControl:(unsigned char*)input length:(int)length to:(int)fd ;
	- (void)sendBytes:(unsigned char*)input length:(int)length to:(int)fd ;

	- (int)waitForBuffer:(unsigned char*)buffer length:(int)bytes timeout:(float)seconds ;
	- (int)parse:(unsigned char*)input length:(int)length intoControl:(unsigned char*)control ;
	
	- (Boolean)getVersion:(Version*)appl bootloader:(Version*)boot from:(int)fd ;
	
	
	@end

	#define	kSuccess				0
	#define	kNoResponseFromKeyer	1
	#define	kCannotStartBootloader	2
	#define	kBootloaderDidNotStart	3
	#define	kBadVersion				4
	#define	kBadDownloadFile		5

#endif
