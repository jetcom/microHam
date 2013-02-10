//
//  ReplyBuf.h
//  µH Router
//
//  Created by Kok Chen on 6/3/06.

#ifndef _REPLYBUF_H_
	#define _REPLYBUF_H_

	#import <Cocoa/Cocoa.h>

	@interface ReplyBuf : NSObject {
		char buffer[1024] ;
		char temp[1025] ;
		int producer ;
		int consumer ;
		NSLock *dataLock ;
	}
	
	- (NSString*)get ;
	- (void)append:(int)byte ;
	- (void)appendInvalid:(int)byte ;
	- (void)reset ;
	
	@end

#endif
