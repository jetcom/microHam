/*
 *  RouterPlist.h
 *  µH Router
 *
 *  Created by Kok Chen on 5/2/06.
 *
 */

#ifndef _ROUTERPLIST_H_
    #define _ROUTERPLIST_H_

    // keys
    
    #define    kPrefVersion                @"Pref version"

    #define kWindowPosition                @"WindowPosition"
    #define kMasterPorts                   @"Ports"
    
    #define kStayAlive                     @"Stay Alive"
    
    
    //  NSArray
    #define    kDeviceSetups                @"Keyer Setups"
    
    //  stream ID (includes serial number)
    #define    kKeyerID                     @"Keyer ID"
    //  content of NSArray
    #define    kSetupHexString              @"Hex Setup String"    
    #define    kAggregateTimeout            @"Radio Aggregate Timeout"
    #define    kKeyerEnabled                @"Enabled"

    //  microKeyer II setup
    #define    kMicroKeyerIILCDLine1        @"microKeyer II LCD Line 1"
    #define    kMicroKeyerIILCDLine2        @"microKeyer II LCD Line 2"
    #define    kMicroKeyerIILCDMessage1     @"microKeyer II LCD Message 1"
    #define    kMicroKeyerIILCDMessage2     @"microKeyer II LCD Message 2"
    #define    kMicroKeyerIILCDClock        @"microKeyer II LCD Clock"
    #define    kMicroKeyerIILCDContrast     @"microKeyer II LCD Contrast"
    #define    kMicroKeyerIILCDBrightness   @"microKeyer II LCD Brightness"
    #define    kMicroKeyerIIEvents          @"microKeyer II Events"
    #define    kMicroKeyerIILine1Events     @"microKeyer II Line 1 Events"
    #define    kMicroKeyerIILine2Events     @"microKeyer II Line 2 Events"
    #define    kMicrokeyerIIEnableModeOverride          @"microKeyer II Enable Mode Override"

    // default
    #define kPlistDirectory "~/Library/Preferences/"

#endif
