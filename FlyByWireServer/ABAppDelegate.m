//
//  ABAppDelegate.m
//  FlyByWireServer
//
//  Created by NioCAD on 2013/11/27.
//  Copyright (c) 2013 Retief Gerber. All rights reserved.
//

#import "ABAppDelegate.h"

@implementation ABAppDelegate

@synthesize running = _running;
@synthesize statusItem = _statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.running = NO;
    // Insert code here to initialize your application
}

-(void)awakeFromNib{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setTitle:@"Status"];
    [_statusItem setHighlightMode:YES];
}

- (IBAction)startStopAction:(id)sender {
    self.running = !self.running;
    if (self.running)
        self.startStopMenuItem.title = @"Stop";
    else
        self.startStopMenuItem.title = @"Start";
}

- (IBAction)quitAction:(id)sender {
    [NSApp terminate:self];
}

@end
