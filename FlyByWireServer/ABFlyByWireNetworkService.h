//
//  ABFlyByWireTCPServer.h
//  FlyByWireServer
//
//  Created by Retief Gerber on 2013/11/30.
//  Copyright (c) 2013 abductive. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ABRemoteDeviceType) {
    ABRemoteDeviceTypeUnknown,
    ABRemoteDeviceTypeiPhone,
    ABRemoteDeviceTypeiPad
};

@protocol ABFlyByWireNetworkServiceDelegate <NSObject>

@optional
- (void)connectionReceived;
- (void)connectionTerminated;
- (void)deviceIdentified:(ABRemoteDeviceType)device;

@end

@interface ABFlyByWireNetworkService : NSObject <NSNetServiceDelegate, NSStreamDelegate>

@property (strong, nonatomic) NSNetService *service;

@property (strong, nonatomic) NSInputStream *istream;
@property (strong, nonatomic) NSOutputStream *ostream;

@property (assign, nonatomic) id<ABFlyByWireNetworkServiceDelegate> delegate;

- (void)start;
- (void)stop;

@end
