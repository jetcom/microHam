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

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoWindow:(NSWindow*)inSettingsWindow router:(Router*)inRouter
{
	
	self = [ super init ] ;
	if ( self ) {
        settingsWindow = inSettingsWindow ;
        if ( [ NSBundle loadNibNamed:@"WinKeyer" owner:self ] ) {
            if ( settingsView )
            {
                [ settingsWindow setContentView:settingsView ] ;
                
				[ self setInterface:minWPMStepper to:@selector(minWPMChanged:) ] ;
                [ self setInterface:minWPMField to:@selector(minWPMChanged:)];
				[ self setInterface:maxWPMStepper to:@selector(maxWPMChanged:) ] ;
                [ self setInterface:maxWPMField to:@selector(maxWPMChanged:)];
				[ self setInterface:farnsworthStepper to:@selector(farnsworthChanged:) ] ;
				[ self setInterface:farnsworthField to:@selector(farnsworthChanged:) ] ;
				[ self setInterface:DITDAHStepper to:@selector(DITDAHChanged:) ] ;
				[ self setInterface:DITDAHField to:@selector(DITDAHChanged:) ] ;
				[ self setInterface:firstExtensionStepper to:@selector(firstExtensionChanged:) ] ;
				[ self setInterface:firstExtensionField to:@selector(firstExtensionChanged:) ] ;
				[ self setInterface:weightingStepper to:@selector(weightingFieldChanged:) ] ;
				[ self setInterface:weightingField to:@selector(weightingFieldChanged:) ] ;
				[ self setInterface:keyingCompensationStepper to:@selector(keyingCompensationChanged:) ] ;
				[ self setInterface:keyingCompensationField to:@selector(keyingCompensationChanged:) ] ;
                [ self setInterface:enableFarnsworth to:@selector(farnsworthEnabled:) ];
                [ self setInterface:test to:@selector(submit:)];
                
                [ self setInterface:paddleMode to:@selector(paddleModeChanged:) ];
                
                [self setInterface:paddlePriorityDit to:@selector(paddlePriorityChanged:) ];
                [self setInterface:paddlePriorityDah to:@selector(paddlePriorityChanged:) ];
                [self setInterface:swapPaddles to:@selector(settingsChanged:) ];
                [self setInterface:disablePaddleMemory to:@selector(settingsChanged:) ];
                [self setInterface:autoSpace to:@selector(settingsChanged:) ];
                [self setInterface:ctSpace to:@selector(settingsChanged:) ];
                
            
                [self setInterface:paddleSetpointField to:@selector(paddleSetpointChanged:)];
                [self setInterface:paddleSetpointStepper to:@selector(paddleSetpointChanged:)];
            }
    
            
            [ self syncFields ];
        }
    }
    return self;
}

- (void)paddlePriorityChanged: (id)sender
{
    //bool s = [ sender state ] == NSOnState;
        
    if ( [[sender title] isEqualToString:@"dit"] )
    {
        [ paddlePriorityDah setState:NSOffState ];
    }
    else
    {
        [ paddlePriorityDit setState:NSOffState ];
    }
}

- (void)settingsChanged: (id)sender
{
}

- (void)paddleModeChanged: (id)sender
{
    if ( [ sender indexOfSelectedItem] == 2 )
    {
        [ paddlePriorityDit setEnabled: true ];
        [ paddlePriorityDah setEnabled: true ];
    }
    else
    {
        [ paddlePriorityDit setEnabled: false ];
        [ paddlePriorityDah setEnabled: false ];
    }
}

- (void)syncFields
{
	[ minWPMField setIntValue:[ minWPMStepper intValue ] ] ;
	[ maxWPMField setIntValue:[ maxWPMStepper intValue ] ] ;
	[ farnsworthField setIntValue:[ farnsworthStepper intValue ] ] ;
	[ DITDAHField setIntValue:[ DITDAHStepper intValue ] ] ;
	[ firstExtensionField setIntValue:[ firstExtensionStepper intValue ] ] ;
	[ weightingField setIntValue:[ weightingStepper intValue ] ] ;
	[ keyingCompensationField setIntValue:[ keyingCompensationStepper intValue ] ] ;
	[ paddleSetpointField setIntValue:[ paddleSetpointStepper intValue ] ] ;
}

- (void)paddleSetpointChanged:(id)sender
{
    [ paddleSetpointStepper setIntValue:[sender intValue]];
    [ paddleSetpointField setIntValue:[paddleSetpointStepper intValue] ];
}

- (void)minWPMChanged:(id)sender
{
    // minWPM has to be less than or equal to maxWPM
    int i = [sender intValue];
    if ( i > [ maxWPMStepper intValue] )
    {
        i = [ maxWPMStepper intValue];
    }
    [ minWPMStepper setIntValue:i ];
    [ minWPMField setIntValue:[minWPMStepper intValue] ];
}

- (void)maxWPMChanged:(id)sender
{
    // maxWPM has to be greater than or equal to minWPM
    int i = [sender intValue];
    if ( i < [ minWPMStepper intValue] )
    {
        i = [ minWPMStepper intValue];
    }
    [ maxWPMStepper setIntValue:i ];
    [ maxWPMField setIntValue:[maxWPMStepper intValue] ];
}

- (void)farnsworthEnabled:(id)sender
{
    if ([sender state] == NSOnState )
    {
        [ farnsworthField setEnabled: TRUE ];
        [ farnsworthStepper setEnabled: TRUE ];
    }
    else
    {
        [ farnsworthField setEnabled: FALSE ];
        [ farnsworthStepper setEnabled: FALSE ];
    }
}

- (void)farnsworthChanged:(id)sender
{
    int i = [ sender intValue];
    if ( i < [ minWPMStepper intValue] )
    {
        i = [ minWPMField intValue ];
    }
    [ farnsworthStepper setIntValue:i ];
    [ farnsworthField setIntValue:[farnsworthStepper intValue] ];
}

- (void)DITDAHChanged:(id)sender
{
    [ DITDAHStepper setIntValue:[sender intValue]];
    [ DITDAHField setIntValue:[DITDAHStepper intValue] ];
}

- (void)firstExtensionChanged:(id)sender
{
    [ firstExtensionStepper setIntValue:[sender intValue]];
    [ firstExtensionField setIntValue:[firstExtensionStepper intValue] ];
}

- (void)weightingFieldChanged:(id)sender
{
    [ weightingStepper setIntValue:[sender intValue]];
    [ weightingField setIntValue:[weightingStepper intValue] ];
}

- (void)keyingCompensationChanged:(id)sender
{
    [ keyingCompensationStepper setIntValue:[sender intValue]];
    [ keyingCompensationField setIntValue:[keyingCompensationStepper intValue] ];
}

- (void)submit: (id)sender
{
    NSLog(@"WPM: Field: %d   Stepper: %d", [ minWPMField intValue ], [minWPMStepper intValue] );
}



@end
