#import "CordovaWebsocketPlugin.h"
#import "WebSocketAdvanced.h"


@implementation CordovaWebsocketPlugin

- (void)pluginInitialize;
{
    webSockets = [[NSMutableDictionary alloc] init];
}

- (void)wsConnect:(CDVInvokedUrlCommand*)command;
{
    NSDictionary* wsOptions = [command argumentAtIndex:0];
    WebSocketAdvanced* ws = [[WebSocketAdvanced alloc] initWithOptions:wsOptions
                                                       commandDelegate:self.commandDelegate
                                                       callbackId:command.callbackId];
    [webSockets setObject:ws forKey:ws.webSocketId];
}

- (void)wsAddListeners:(CDVInvokedUrlCommand*)command;
{
    NSString* webSocketId = [command argumentAtIndex:0];
    BOOL flushRecvBuffer = [command argumentAtIndex:1];
    WebSocketAdvanced* ws = [webSockets valueForKey:webSocketId];
    if (ws != nil) {
        [ws wsAddListeners:command.callbackId flushRecvBuffer:flushRecvBuffer];
    }
}

- (void)wsSend:(CDVInvokedUrlCommand*)command;
{
    NSString* webSocketId = [command argumentAtIndex:0];
    NSString* message = [command argumentAtIndex:1];
    WebSocketAdvanced* ws = [webSockets valueForKey:webSocketId];
    if (ws != nil) {
        [ws wsSendMessage:message];
    }
}

- (void)wsClose:(CDVInvokedUrlCommand*)command;
{
    NSString* webSocketId = [command argumentAtIndex:0];
    NSNumber* code = [command argumentAtIndex:1];
    NSString* reason = [command argumentAtIndex:2];
    WebSocketAdvanced* ws = [webSockets valueForKey:webSocketId];
    if (ws != nil) {
        [ws wsClose:code.integerValue reason:reason];
    }
}

- (void)dealloc;
{
    [self _closeAllSockets];
}

- (void)onReset;
{
    [super onReset];
}

- (void)_closeAllSockets;
{
    for(id wsId in webSockets) {
        WebSocketAdvanced* ws = [webSockets objectForKey:wsId];
        [ws wsClose];
    }
    [webSockets removeAllObjects];
}

@end
