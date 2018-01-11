#import <SocketRocket/SocketRocket.h>

@interface WebSocketAdvanced: NSObject <SRWebSocketDelegate>
{
    SRWebSocket* _webSocket;
    id<CDVCommandDelegate> _commandDelegate;
    NSString* _callbackId;
    NSString* _recvCallbackId;
}
@property NSString* webSocketId;

- (instancetype)initWithOptions:(NSDictionary*)wsOptions 
                commandDelegate:(id<CDVCommandDelegate>)commandDelegate
                callbackId:(NSString*)callbackId;
- (void)wsAddListeners:(NSString*)recvCallbackId;
- (void)wsSendMessage:(NSString*)message;
- (void)wsClose;
- (void)wsClose:(NSInteger)code reason:(NSString*)reason;

@end