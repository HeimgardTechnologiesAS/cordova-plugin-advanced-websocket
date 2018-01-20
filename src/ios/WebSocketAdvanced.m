#import <Cordova/CDV.h>
#import "WebSocketAdvanced.h"

@implementation WebSocketAdvanced

- (instancetype)initWithOptions:(NSDictionary*)wsOptions 
                commandDelegate:(id<CDVCommandDelegate>)commandDelegate
                callbackId:(NSString*)callbackId;
{
    NSString* wsUrl =           [wsOptions valueForKey:@"url"];
    NSNumber* timeout =         [wsOptions valueForKey:@"timeout"];
    NSNumber* pingInterval =    [wsOptions valueForKey:@"pingInterval"];
    NSDictionary* wsHeaders =   [wsOptions valueForKey:@"headers"];
    BOOL acceptAllCerts =       [wsOptions valueForKey:@"acceptAllCerts"];

    NSTimeInterval timeoutInterval = timeout ? (timeout.doubleValue / 1000) : 0;
    _pingInterval = pingInterval ? (pingInterval.doubleValue / 1000) : 0;
    
    self.webSocketId = [[NSUUID UUID] UUIDString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:wsUrl]
                                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:timeoutInterval];

    for(id key in wsHeaders) {
        [request addValue:[wsHeaders objectForKey:key] forHTTPHeaderField:key];
    }

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:request
                                      protocols:nil
                                      allowsUntrustedSSLCertificates:acceptAllCerts];
    
    _webSocket.delegate = self;
    _commandDelegate = commandDelegate;
    _callbackId = callbackId;

    _pingCount = 0;
    _pongCount = 0;

    [_commandDelegate runInBackground:^{
        [_webSocket open];
    }];
    return self;
}

- (void)wsAddListeners:(NSString*)recvCallbackId;
{
    _recvCallbackId = recvCallbackId;
}

- (void)wsSendMessage:(NSString*)message;
{
    if (_webSocket != nil) {
        [_webSocket send:message];
    }
}

- (void)wsClose;
{
    if (_webSocket != nil) {
        [_webSocket close];
    }
}

- (void)wsClose:(NSInteger)code reason:(NSString*)reason;
{
    if (_webSocket != nil) {
        [_webSocket closeWithCode:code reason:reason];
    }
}

- (void)wsSendPing:(NSData*)data;
{
    if (_webSocket != nil) {
        if ((_pingCount - _pongCount) >= 1) {
            NSMutableDictionary* errorResult = [[NSMutableDictionary alloc] init];
            NSNumber* code = [NSNumber numberWithInteger:SRStatusCodeAbnormal];
            NSString* reason = @"Last pong was not received!";
            if (_recvCallbackId != nil) {
                [errorResult setValue:self.webSocketId  forKey:@"webSocketId"];
                [errorResult setValue:code              forKey:@"code"];
                [errorResult setValue:reason            forKey:@"exception"];
                [errorResult setValue:@"onFail"         forKey:@"callbackMethod"];
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorResult];
                [pluginResult setKeepCallbackAsBool:YES];
                [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];
            }
            if (_pingTimer != nil) {
                [_pingTimer invalidate];
                _pingTimer = nil;
            }
            _webSocket = nil;
            return;
        }
        _pingCount++;
        [_webSocket sendPing:data];
        NSLog(@"Sent ping #%ld", _pingCount);
    }
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket*)webSocket;
{
    NSMutableDictionary* successResult = [[NSMutableDictionary alloc] init];
    NSNumber* code = [NSNumber numberWithInteger:SRStatusCodeNormal];

    [successResult setValue:self.webSocketId forKey:@"webSocketId"];
    [successResult setValue:code             forKey:@"code"];

    CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:successResult];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];

    if (_pingInterval > 0) {
        _pingTimer = [NSTimer scheduledTimerWithTimeInterval:_pingInterval
                              repeats:YES
                              block: ^(NSTimer *timer) {
                                  [self wsSendPing:nil]; 
                              }];
    }
}

- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error;
{
    NSMutableDictionary* errorResult = [[NSMutableDictionary alloc] init];
    NSNumber* code = [NSNumber numberWithInteger:SRStatusCodeAbnormal];
    
    [errorResult setValue:self.webSocketId           forKey:@"webSocketId"];
    [errorResult setValue:code                       forKey:@"code"];
    [errorResult setValue:error.localizedDescription forKey:@"exception"];

    @try {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorResult];
        [_commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    }
    @catch (NSException *exception) {
        // Swallow exception
    }

    if (_recvCallbackId != nil) {
        [errorResult setValue:@"onFail" forKey:@"callbackMethod"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorResult];
        [pluginResult setKeepCallbackAsBool:YES];
        [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];
    }

    _webSocket = nil;

    if (_pingTimer != nil) {
        [_pingTimer invalidate];
        _pingTimer = nil;
    }
}

- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(id)message;
{
    NSMutableDictionary* callbackResult = [[NSMutableDictionary alloc] init];
    [callbackResult setValue:@"onMessage"     forKey:@"callbackMethod"];
    [callbackResult setValue:self.webSocketId forKey:@"webSocketId"];
    [callbackResult setValue:message          forKey:@"message"];

    if (_recvCallbackId != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:callbackResult];
        [pluginResult setKeepCallbackAsBool:YES];
        [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];
    }
}

- (void)webSocket:(SRWebSocket*)webSocket didCloseWithCode:(NSInteger)code reason:(NSString*)reason wasClean:(BOOL)wasClean;
{
    NSMutableDictionary* callbackResult = [[NSMutableDictionary alloc] init];
    NSNumber* c = [NSNumber numberWithInteger:code];

    [callbackResult setValue:self.webSocketId forKey:@"webSocketId"];
    [callbackResult setValue:c                forKey:@"code"];
    [callbackResult setValue:reason           forKey:@"reason"];

    @try {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:callbackResult];
        [_commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    }
    @catch (NSException *exception) {
        // Swallow exception
    }
    
    if (_recvCallbackId != nil) {
        [callbackResult setValue:@"onClose" forKey:@"callbackMethod"];
        CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:callbackResult];
        [pluginResult setKeepCallbackAsBool:YES];
        [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];
    }

    _webSocket = nil;

    if (_pingTimer != nil) {
        [_pingTimer invalidate];
        _pingTimer = nil;
    }
}

- (void)webSocket:(SRWebSocket*)webSocket didReceivePong:(nullable NSData*)pongData;
{
    _pongCount++;
    NSLog(@"Received pong #%ld", _pongCount);
}

- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket*)webSocket;
{
    return YES;
}

@end
