//
//  ABAppDelegate.h
//  FlyByWireServer
//
//  Created by NioCAD on 2013/11/27.
//  Copyright (c) 2013 Retief Gerber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ABAppDelegate : NSObject <NSApplicationDelegate>


@property (assign, nonatomic) BOOL running;

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *startStopMenuItem;

@property (assign) IBOutlet NSWindow *window;

@end
