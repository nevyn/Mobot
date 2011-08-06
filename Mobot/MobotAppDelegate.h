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
}

@property (strong) IBOutlet NSWindow *window;

@end
