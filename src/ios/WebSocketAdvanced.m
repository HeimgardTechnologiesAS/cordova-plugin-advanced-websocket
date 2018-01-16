#import <Cordova/CDV.h>
#import "WebSocketAdvanced.h"

@implementation WebSocketAdvanced

- (instancetype)initWithOptions:(NSDictionary*)wsOptions 
                commandDelegate:(id<CDVCommandDelegate>)commandDelegate
                callbackId:(NSString*)callbackId;
{
    NSString* wsUrl =           [wsOptions valueForKey:@"url"];
    NSNumber* timeout =         [wsOptions valueForKey:@"timeout"];
    NSDictionary* wsHeaders =   [wsOptions valueForKey:@"headers"];
    BOOL acceptAllCerts =       [wsOptions valueForKey:@"acceptAllCerts"];

    self.webSocketId = [[NSUUID UUID] UUIDString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:wsUrl]
                                                        cachePolicy: NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval: timeout.integerValue];

    for(id key in wsHeaders) {
        [request addValue:[wsHeaders objectForKey:key] forHTTPHeaderField:key];
    }

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:request
                                        protocols:nil
                                        allowsUntrustedSSLCertificates:acceptAllCerts];
    
    _webSocket.delegate = self;
    _commandDelegate = commandDelegate;
    _callbackId = callbackId;

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
    if (_webSocket == nil) {
        return;
    }
    [_webSocket send:message];
}

- (void)wsClose;
{
    if (_webSocket == nil) {
        return;
    }
    [_webSocket close];
}

- (void)wsClose:(NSInteger)code reason:(NSString*)reason;
{
    if (_webSocket == nil) {
        return;
    }
    [_webSocket closeWithCode:code reason:reason];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket*)webSocket;
{
    NSMutableDictionary* successResult = [[NSMutableDictionary alloc] init];
    [successResult setValue:self.webSocketId                                forKey:@"webSocketId"];
    [successResult setValue:[NSNumber numberWithInteger:SRStatusCodeNormal] forKey:@"code"];

    CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:successResult];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error;
{
    NSMutableDictionary* errorResult = [[NSMutableDictionary alloc] init];
    [errorResult setValue:self.webSocketId  forKey:@"webSocketId"];
    [errorResult setValue:error.domain      forKey:@"exception"];

    CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorResult];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];

    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(id)message;
{
    NSMutableDictionary* callbackResult = [[NSMutableDictionary alloc] init];
    [callbackResult setValue:@"onMessage"      forKey:@"callbackMethod"];
    [callbackResult setValue:self.webSocketId  forKey:@"webSocketId"];
    [callbackResult setValue:message           forKey:@"message"];

    CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:callbackResult];
    [pluginResult setKeepCallbackAsBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];
}

- (void)webSocket:(SRWebSocket*)webSocket didCloseWithCode:(NSInteger)code reason:(NSString*)reason wasClean:(BOOL)wasClean;
{
    NSMutableDictionary* callbackResult = [[NSMutableDictionary alloc] init];
    [callbackResult setValue:@"onClose"                        forKey:@"callbackMethod"];
    [callbackResult setValue:self.webSocketId                  forKey:@"webSocketId"];
    [callbackResult setValue:[NSNumber numberWithInteger:code] forKey:@"code"];
    [callbackResult setValue:reason                            forKey:@"reason"];

    CDVPluginResult* pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:callbackResult];
    [pluginResult setKeepCallbackAsBool:YES];
    [_commandDelegate sendPluginResult:pluginResult callbackId:_recvCallbackId];

    @try {
        NSMutableDictionary* errorResult = [[NSMutableDictionary alloc] init];

        [errorResult setValue:self.webSocketId                                forKey:@"webSocketId"];
        [errorResult setValue:[NSNumber numberWithInteger:SRStatusCodeNormal] forKey:@"code"];
        [errorResult setValue:reason                                          forKey:@"reason"];
        
        CDVPluginResult* pluginErrorResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorResult];
        [_commandDelegate sendPluginResult:pluginErrorResult callbackId:_callbackId];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }

    _webSocket = nil;
}

- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket;
{
    return YES;
}

@end