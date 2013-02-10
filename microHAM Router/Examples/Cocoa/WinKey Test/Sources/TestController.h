//
//  TestController.h
//  RouterTest
//
//  Created by Kok Chen on 5/25/06.

#ifndef _TESTCONTROLLER_H_
	#define _TESTCONTROLLER_H_

	#import <Cocoa/Cocoa.h>
	#include "KeyerTest.h"


	@interface TestController : NSObject {
		IBOutlet id tabView ;
		
		KeyerTest *microKeyer ;
		KeyerTest *cwKeyer ;
		KeyerTest *digiKeyer ;
	}

	@end

#endif
