//
//  ABFlyByWireTCPServer.m
//  FlyByWireServer
//
//  Created by Retief Gerber on 2013/11/30.
//  Copyright (c) 2013 abductive. All rights reserved.
//

#import "ABFlyByWireNetworkService.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

enum {
    kDebugOptionMaskStallSend        = 0x01,
    kDebugOptionMaskSendBadChecksum  = 0x02,
    kDebugOptionMaskForceIPv4        = 0x04,
    kDebugOptionMaskAutoAdvanceImage = 0x08
};

@interface ABFlyByWireNetworkService ()

@property (assign, nonatomic) CFSocketRef listeningSocket;

@property (assign, nonatomic) int servicePort;

@property (assign, nonatomic) CGSize localBounds;
@property (assign, nonatomic) CGSize remoteBounds;

@end

@implementation ABFlyByWireNetworkService

@synthesize service = _service;

@synthesize listeningSocket = _listeningSocket;

@synthesize servicePort = _servicePort;

@synthesize ostream = _ostream;
@synthesize istream = _istream;

@synthesize delegate = _delegate;

@synthesize localBounds = _localBounds;
@synthesize remoteBounds = _remoteBounds;

- (id)init
{
    self = [super init];
    if (self) {
        self.localBounds = NSScreen.mainScreen.frame.size;
        NSLog(@"Sceen size %f by %f", self.localBounds.width, self.localBounds.height);
    }
    return self;
}

- (int)startListening
{
    int err;
    int fdForListening;
    socklen_t namelen;
    
    self.servicePort = -1;
    
    struct sockaddr_in  serverAddress;
        
    err = 0;
    fdForListening = socket(AF_INET, SOCK_STREAM, 0);
    if (fdForListening < 0) {
        err = errno;
    }
    
    if (err == 0) {
        memset(&serverAddress, 0, sizeof(serverAddress));
        serverAddress.sin_family = AF_INET;
        serverAddress.sin_len    = sizeof(serverAddress);
        
        err = bind(fdForListening, (const struct sockaddr *) &serverAddress, sizeof(serverAddress));
        if (err < 0) {
            err = errno;
        }
    }
    if (err == 0) {
        namelen = sizeof(serverAddress);
        err = getsockname(fdForListening, (struct sockaddr *) &serverAddress, &namelen);
        if (err < 0) {
            err = errno;
            assert(err != 0);       // quietens static analyser
        } else {
            self.servicePort = ntohs(serverAddress.sin_port);
        }
    }
    
    // Listen for connections on our socket, then create a CFSocket to route any connections
    // to a run loop based callback.
    
    if (err == 0) {
        err = listen(fdForListening, 5);
        if (err < 0) {
            err = errno;
        } else {
            CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            CFRunLoopSourceRef  rls;
            
            self->_listeningSocket = CFSocketCreateWithNative(NULL, fdForListening, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
            if (self->_listeningSocket != NULL) {
                assert( CFSocketGetSocketFlags(self->_listeningSocket) & kCFSocketCloseOnInvalidate );
                fdForListening = -1;        // so that the clean up code doesn't close it
                
                rls = CFSocketCreateRunLoopSource(NULL, self->_listeningSocket, 0);
                assert(rls != NULL);
                
                CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
                
                CFRelease(rls);
            }
        }
    }
    return err;
}


- (void)start
{
    if ([self startListening] != 0) {
        NSLog(@"start error");
        return;
    }
    
    self.service = [[NSNetService alloc] initWithDomain:@"" type:@"_flybywire._tcp" name:@"" port:self.servicePort];
    if(self.service)
    {
        [self.service setDelegate:self];
        [self.service publish];
    }
    else
    {
        NSLog(@"An error occurred initializing the NSNetService object.");
    }

    
}

- (void)stop
{
    if (self.listeningSocket != NULL) {
        CFSocketInvalidate(self.listeningSocket);
        CFRelease(self.listeningSocket);
        self.listeningSocket = NULL;
    }

    [self.istream close];
    [self.ostream close];

    [self.service stop];

}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    NSLog(@"netServiceWillPublish:");
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"netServiceDidPublish:");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"netService:didNotPublish:");
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog(@"netServiceWillResolve:");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"netServiceDidResolveAddress:");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"netService:didNotResolve:");
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog(@"netServiceDidStop:");
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    NSLog(@"netService:didUpdateTXTRecordData:");
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    uint8_t buffer[20];
    NSInteger len;
	
    switch (eventCode) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"NSStreamEventOpenCompleted");
            if (self.delegate && [self.delegate respondsToSelector:@selector(connectionReceived)])
            {
                [self.delegate connectionReceived];
            }
			break;
            
		case NSStreamEventHasBytesAvailable:
            len = [self.istream read:buffer maxLength:sizeof(buffer)];
            if (len > 0)
            {
                NSString *msg = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                [self _handleMessage:msg];
            }
			break;
            
		case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
			break;
            
		case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            if (self.delegate && [self.delegate respondsToSelector:@selector(connectionTerminated)])
            {
                [self.delegate connectionTerminated];
            }
            break;
            
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
            
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
            
		default:
			NSLog(@"Unknown event");
	}
}

static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// The CFSocket callback associated with _listeningSocket.  This is called when
// a new connection arrives.  It routes the connection to the -connectionReceived:
// method.
{
    ABFlyByWireNetworkService *   obj;
    int             fd;
    
    obj = (__bridge ABFlyByWireNetworkService *) info;
    assert([obj isKindOfClass:[ABFlyByWireNetworkService class]]);
    
    assert(s == obj->_listeningSocket);
#pragma unused(s)
    assert(type == kCFSocketAcceptCallBack);
#pragma unused(type)
    assert(address != NULL);
#pragma unused(address)
    assert(data != nil);
    
    fd = * (const int *) data;
    assert(fd >= 0);
    [obj connectionReceived:fd];
}

- (void)connectionReceived:(int)fd
// Called when a connection is received.  We respond by creating and running a
// FileSendOperation that sends the current picture down the connection.
{
    // TODO: Prevent multiple connections
    NSLog(@"Connection received");
    
    CFWriteStreamRef    writeStream;
    CFReadStreamRef     readStream;

    CFStreamCreatePairWithSocket(NULL, fd, &readStream, &writeStream);
    
    self.istream = (NSInputStream *)CFBridgingRelease(readStream);
    self.ostream = (NSOutputStream *)CFBridgingRelease(writeStream);

    [self.istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    self.istream.delegate = self;
    self.ostream.delegate = self;

    [self.istream open];
    [self.ostream open];
    
    CFRelease(writeStream);
    CFRelease(readStream);
}

- (void)threadedSendMessage:(NSString *)msg
{
    NSData *data = [[NSData alloc] initWithData:[msg dataUsingEncoding:NSASCIIStringEncoding]];
    [self.ostream write:[data bytes]  maxLength:[data length]];
    
}
- (void)sendMessage:(NSString *)msg
{
    // This will ensure the send messages while handling a received message does not block
    // TODO: Figure out if there is a better way to do this
    // TODO: Make use of NSOperation queues
    [self performSelectorInBackground:@selector(threadedSendMessage:) withObject:msg];
}

- (void)_handleBounds:(NSString *)msg
{
    NSInteger boundsVal;
    NSInteger deviceVal;
    NSInteger width, height;
    
    NSScanner *scanner = [NSScanner scannerWithString:msg];
    if ([scanner scanString:@"B" intoString:NULL] &&
        [scanner scanInteger:&boundsVal] &&
        [scanner scanString:@":D" intoString:NULL] &&
        [scanner scanInteger:&deviceVal] &&
        [scanner scanString:@":W" intoString:NULL] &&
        [scanner scanInteger:&width] &&
        [scanner scanString:@":H" intoString:NULL] &&
        [scanner scanInteger:&height] &&
        [scanner scanString:@"." intoString:NULL])
    {
        NSLog(@"Bounds %ld %ld %ld %ld", boundsVal, deviceVal, width, height);
        self.remoteBounds = CGSizeMake((CGFloat)width, (CGFloat)height);
        [self sendMessage:@"ACK"];
        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceIdentified:)])
        {
            [self.delegate deviceIdentified:deviceVal];
        }
    }
    else
    {
        NSLog(@"Scanner error while parsing device bounds.");
        [self sendMessage:@"ERR"];
    }
}

- (void)_handleTouch:(NSString *)msg
{
    NSInteger touchType;
    NSInteger mouseButton;
    NSInteger x, y;
    
    NSScanner *scanner = [NSScanner scannerWithString:msg];
    if ([scanner scanString:@"T" intoString:NULL] &&
        [scanner scanInteger:&touchType] &&
        [scanner scanString:@":B" intoString:NULL] &&
        [scanner scanInteger:&mouseButton] &&
        [scanner scanString:@":X" intoString:NULL] &&
        [scanner scanInteger:&x] &&
        [scanner scanString:@":Y" intoString:NULL] &&
        [scanner scanInteger:&y] &&
        [scanner scanString:@"." intoString:NULL])
    {
        x = x/self.remoteBounds.width*self.localBounds.width;
        y = y/self.remoteBounds.height*self.localBounds.height;
        // NOTE: This logging can be turned on, BUT it adds substancial load on event handing that could make it less responsive
        //NSLog(@"Touch %ld %ld %ld %ld", touchType, mouseButton, x, y);
        [self _mouseMoveX:x Y:y button:kCGMouseButtonLeft];
    }
    else
    {
        NSLog(@"Scanner error while parsing touch event.");
        [self sendMessage:@"ERR"];
    }
}

- (void)_handleMessage:(NSString *)msg
{
    switch ([msg characterAtIndex:0])
    {
        case 'B':
            [self _handleBounds:msg];
            break;
        
        case 'T':
            [self _handleTouch:msg];
            break;
            
        default:
            NSLog(@"Command not supported %c", [msg characterAtIndex:0]);
    }
}

- (void)_createMouseEventType:(CGEventType)type button:(CGMouseButton)button position:(CGPoint)point
{
    CGEventRef event = CGEventCreateMouseEvent(nil, type, point, button);
    CGEventPost(kCGHIDEventTap, event);
}

- (void)_mouseMoveX:(CGFloat)x Y:(CGFloat)y button:(CGMouseButton)button
{
    [self _createMouseEventType:kCGEventMouseMoved button:button position:CGPointMake(x, y)];
}

@end
