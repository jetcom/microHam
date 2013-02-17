//
//  WinKeyer.m
//  microHAM Router
//
//  Created by Travis E. Brown on 2/16/13.
//
//

#import "WinKeyer.h"
#import "Router.h"

@implementation WinKeyer

- (id)initIntoWindow:(NSWindow*)inSettingsWindow router:(Router*)inRouter
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
        settingsWindow = inSettingsWindow ;
        if ( [ NSBundle loadNibNamed:@"WinKeyer" owner:self ] ) {
            if ( settingsView )
            {
                [ settingsWindow setContentView:settingsView ] ;
            }
        }
    }
    return self;
}

@end
