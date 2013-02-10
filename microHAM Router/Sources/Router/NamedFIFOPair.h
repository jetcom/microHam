//
//  NamedFIFOPair.h
//  µH Router
//
//  Created by Kok Chen on 5/20/06.

#ifndef _NAMEDFIFOPAIR_H_
	#define	_NAMEDFIFOPAIR_H_

	#import <Cocoa/Cocoa.h>

	@interface NamedFIFOPair : NSObject {
		char *baseName ;
		int inputFileDescriptor ;
		int outputFileDescriptor ;
	}
	
	- (id)initWithPipeName:(const char*)fifoName ;
	
	- (int)createFIFO:(char*)type ;
	- (void)stopPipe ;

	- (const char*)name ;
	- (int)inputFileDescriptor ;
	- (int)outputFileDescriptor ;
	
	@end

#endif
