//
//  MobotAppDelegate.h
//  Mobot
//
//  Created by Joachim Bengtsson on 2011-08-06.
//  Copyright 2011 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MobotAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    IBOutlet NSTextField *inputField;
    IBOutlet NSTextField *baudRateDescription;
    IBOutlet NSSlider *baudRateSlider;
    IBOutlet NSTextField *charDetail;
    IBOutlet NSTextField *bits;
    IBOutlet NSTextField *highlightedBits;
}

@property (strong) IBOutlet NSWindow *window;
- (IBAction)playText:(id)sender;
- (IBAction)changeBaudRate:(NSSlider*)sender;

@end
