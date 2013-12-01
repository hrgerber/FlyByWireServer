//
//  ABAppDelegate.h
//  FlyByWireServer
//
//  Created by Retief Gerber on 2013/11/30.
//  Copyright (c) 2013 abductive. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ABFlyByWireNetworkService.h"

@interface ABAppDelegate : NSObject <NSApplicationDelegate, ABFlyByWireNetworkServiceDelegate>

@property (strong, nonatomic) ABFlyByWireNetworkService *service;

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *startStopMenuItem;

@property (assign) IBOutlet NSWindow *window;



@end
