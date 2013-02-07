//
//  KeyerMode.m
//  µH Router
//
//  Created by Kok Chen on 3/14/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "KeyerMode.h"
#import "Router.h"


@implementation KeyerMode

//  v1.40  For changing keyer mode.

- (id)initIntoTabView:(NSTabView*)tabview name:(NSString*)keyerName router:(Router*)inRouter controller:(Controller*)inController
{	
	self = [ super init ] ;
	if ( self ) {
		controller = inController ;
		router = inRouter ;
		
		if ( [ NSBundle loadNibNamed:@"KeyerMode" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( controlView && tabview ) {
				//  create a new TabViewItem for keyer mode and place an instance of the Nib in the tab item
				tabItem = [ [ NSTabViewItem alloc ] init ] ;
				[ tabItem setView:controlView ] ;
				[ tabItem setLabel:keyerName ] ;
				//  and insert as tabView item at head of the tabs
				controllingTabView = tabview ;
				[ controllingTabView addTabViewItem:tabItem ] ;

				return self ;
			}
		}
	}
	return nil ;
}

- (void)updateMatrix:(int)state
{
	if ( [ router connected ] ) {
		[ modeMatrix selectCellAtRow:state column:0 ] ;
	}
}

//  update matrix and router keyer mode
- (void)updateState:(int)state
{
	unsigned char control[] = { 0x0a, 0x00, 0x8a } ;
	
	if ( [ router connected ] ) {
		if ( state == 2 ) state = 3 ;
		[ modeMatrix setAction:@selector( modeChanged: ) ] ;
		[ modeMatrix setTarget:self ] ;
		control[1] = state ;
		[ router sendControl:control length:3 ] ;
		[ modeMatrix selectCellAtRow:state column:0 ] ;
	}
	else [ modeMatrix setEnabled:NO ] ;
}

- (void)modeChanged:(id)sender
{
	unsigned char control[] = { 0x0a, 0x00, 0x8a } ;
	int state ;
	
	state = [ sender selectedRow ] ;
	if ( state == 2 ) state = 3 ;
	control[1] = state ;
	[ router sendControl:control length:3 ] ;
}

@end
