//
//  Keyer.h
//  µH Router
//
//  Created by Kok Chen on 5/2/06.

#ifndef _KEYER_H_
	#define	_KEYER_H_
	
	#import <Cocoa/Cocoa.h>
	#include <termios.h>

	@class Router ;
	
	@interface Keyer : NSObject {	
		int fd ;
		int errorCode ;
		struct termios originalTTYAttrs ;
		NSString *stream ;
		NSString *path ;
		Router *router ;
		NSTimer *heartbeat ;
		NSLock *writeLock ;
		int byteOrderInFrame ;
		Boolean debug ;
		Boolean reopenOnWakeup ;
	}

	- (id)initFromRouter:(Router*)client writeLock:(NSLock*)lock ;
	
	- (Boolean)debug ;
	- (void)setDebug:(Boolean)state ;

	- (Boolean)openSerialDevice ;
	- (void)closeSerialDevice ;
	
	- (void)writeFrames:(unsigned char*)array length:(int)length ;
	- (void)writeFrame:(unsigned char*)array ;
	
	- (void)startHeartbeat ;
	- (void)stopHeartbeat ;

	- (Boolean)opened ;
	- (int)errorCode ;
	- (void)setStream:(NSString*)name ;
	- (void)setPath:(NSString*)name ;
	- (NSString*)path ;

	- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info ;
	
	- (void)aboutToSleep ;
	- (void)wakeFromSleep ;

	@end

#endif
