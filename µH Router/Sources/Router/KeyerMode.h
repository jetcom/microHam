//
//  KeyerMode.h
//  µH Router
//
//  Created by Kok Chen on 3/14/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller ;
@class Router ;

@interface KeyerMode : NSObject {
	IBOutlet id controlView ;
	IBOutlet id modeMatrix ;

	Controller *controller ;
	Router *router ;

	NSTabViewItem *tabItem ;
	NSTabView *controllingTabView ;
}

- (id)initIntoTabView:(NSTabView*)tabview name:(NSString*)keyerName router:(Router*)inRuter controller:(Controller*)inController ;
- (void)updateState:(int)state ;
- (void)updateMatrix:(int)state ;

@end
