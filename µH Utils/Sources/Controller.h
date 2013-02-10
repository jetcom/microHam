//
//  Controller.h
//  µH Utils
//
//  Created by Kok Chen on 7/21/06.

#ifndef _CONTROLLER_H_
	#define _CONTROLLER_H_

	#import <Cocoa/Cocoa.h>
	#include "Utility.h"

	@interface Controller : NSObject {
		IBOutlet id window ;
		IBOutlet id tab ;
		IBOutlet id deviceMenu ;
		IBOutlet id connectButton ;
		IBOutlet id downloadButton ;
		IBOutlet id bootloadButton ;
		IBOutlet id versionField ;
		
		IBOutlet id downloader ;
		
		NSLock *downloadLock ;
		
		Version app ;
		Version bootloader ;
		
		Boolean debug ;
		int devices ;
		NSString *stream[8] ;
		NSString *path[8] ;
		NSString *bundleFolder ;
		int fd ;
		unsigned char ring[4096] ;
		long producer, consumer ;
		
		Boolean hasFirmware ;
	}

	- (void)pickupMicroHamDevices ;
	- (int)buflen ;
	- (void)resetBuffer ;
	- (int)read:(unsigned char*)buf length:(int)len ;
	- (void)outputMessage:(NSString*)msg ;
	
	@end

#endif
