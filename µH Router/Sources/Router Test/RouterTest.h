//
//  RouterTest.h
//  uH Router
//
//  Created by Kok Chen on 5/26/06.


#ifndef _ROUTERTEST_H_
	#define _ROUTERTEST_H_

	#import <Cocoa/Cocoa.h>
	#include "KeyerTest.h"
	#include "Router.h"

	@interface RouterTest : NSObject {
		IBOutlet id tabView ;
		
		KeyerTest *microKeyer ;
		KeyerTest *cwKeyer ;
		KeyerTest *digiKeyer ;
		
		NSWindow *window ;
		Router **router ;
		int routers ;
	}
	
	- (id)initWithRouters:(Router**)routerList count:(int)count ;
	- (void)openPanel ;

	@end

#endif
