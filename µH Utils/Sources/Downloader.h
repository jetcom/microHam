//
//  Downloader.h
//  µDownloader
//
//  Created by Kok Chen on 7/21/06.


#ifndef _DOWNLOADER_H_
	#define _DOWNLOADER_H_

	#import <Cocoa/Cocoa.h>
	#include "Utility.h"
	
	typedef struct {
		int length ;
		unsigned char data[160] ;
	} FlashBlock ;
	
	@interface Downloader : Utility {
	
		IBOutlet id progressBar ;
		IBOutlet id progressField ;
		
		unsigned char bootloaderVersion[16], fileVersion[16] ;
		FlashBlock flash[1024] ;
		int flashBlocks ;
		Boolean fileChecked ;
	}

	- (Boolean)loadFile:(NSString*)folder ;
	- (int)downloadTo:(int)fd client:(Controller*)inClient ;
	- (int)bootloadTo:(int)fd client:(Controller*)inClient ;

	- (void)controlResponse:(unsigned char*)str length:(int)length ;
	
	@end
	

#endif
