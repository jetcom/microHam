//
//  WinKeyer.h
//  microHAM Router
//
//  Created by Travis E. Brown on 2/16/13.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface WinKeyer : NSObject
{
    IBOutlet id settingsView;
    
    IBOutlet id minWPMStepper;
    IBOutlet id maxWPMStepper;
    IBOutlet id farnsworthStepper;
    IBOutlet id DITDAHStepper;
    IBOutlet id firstExtensionStepper;
    IBOutlet id weightingStepper;
    IBOutlet id keyingCompensationStepper;
    
    IBOutlet id minWPMField;
    IBOutlet id maxWPMField;
    IBOutlet id farnsworthField;
    IBOutlet id DITDAHField;
    IBOutlet id firstExtensionField;
    IBOutlet id weightingField;
    IBOutlet id keyingCompensationField;
    
    IBOutlet id enableFarnsworth;
    IBOutlet id farnsworthLabel;
    IBOutlet id farnsnwothSuffix;
    
    IBOutlet id paddleMode;
    IBOutlet id paddlePriorityDit;
    IBOutlet id paddlePriorityDah;
    
    IBOutlet id paddleSetpointField;
    IBOutlet id paddleSetpointStepper;
    
    IBOutlet id swapPaddles;
    IBOutlet id disablePaddleMemory;
    IBOutlet id autoSpace;
    IBOutlet id ctSpace;
    
    
    
    
    IBOutlet id test;
    
	NSWindow *settingsWindow ;
}

- (void)syncFields ;

@end
