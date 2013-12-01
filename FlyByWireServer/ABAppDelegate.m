//
//  ABAppDelegate.m
//  FlyByWireServer
//
//  Created by Retief Gerber on 2013/11/30.
//  Copyright (c) 2013 abductive. All rights reserved.
//

#import "ABAppDelegate.h"


@interface ABAppDelegate ()

@property (assign, nonatomic) BOOL running;

@end

@implementation ABAppDelegate

@synthesize service = _service;

@synthesize running = _running;
@synthesize statusItem = _statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.service = [[ABFlyByWireNetworkService alloc] init];
    self.service.delegate = self;
    [self.service start];
    self.running = YES;
}

-(void)awakeFromNib{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    [self.statusItem setMenu:_statusMenu];
    [self.statusItem setImage:[NSImage imageNamed:@"screen-active.png"]];
    [self.statusItem setHighlightMode:YES];
}

- (IBAction)pauseResumeAction:(id)sender {
    if (self.running) {
        [self.service stop];
        [self.statusItem setImage:[NSImage imageNamed:@"screen-inactive.png"]];
        self.startStopMenuItem.title = @"Resume";
    } else {
        [self.service start];
        [self.statusItem setImage:[NSImage imageNamed:@"screen-active.png"]];
        self.startStopMenuItem.title = @"Pause";
    }
    self.running = !self.running;
}

- (IBAction)preferencesAction:(id)sender {
    //TODO: Implement password protection
}

- (void)connectionReceived
{
    [self.statusItem setImage:[NSImage imageNamed:@"loopback.png"]];    
}

- (void)connectionTerminated
{
    [self.statusItem setImage:[NSImage imageNamed:@"screen-active.png"]];
}

- (void)deviceIdentified:(ABRemoteDeviceType)device
{
    switch (device) {
        case ABRemoteDeviceTypeUnknown:
            [self.statusItem setImage:[NSImage imageNamed:@"controller.png"]];
            break;
            
        case ABRemoteDeviceTypeiPhone:
            [self.statusItem setImage:[NSImage imageNamed:@"iphone.png"]];
            break;

        case ABRemoteDeviceTypeiPad:
            [self.statusItem setImage:[NSImage imageNamed:@"ipad.png"]];
            break;

        default:
            break;
    }
}


- (IBAction)quitAction:(id)sender {
    [NSApp terminate:self];
}

@end
