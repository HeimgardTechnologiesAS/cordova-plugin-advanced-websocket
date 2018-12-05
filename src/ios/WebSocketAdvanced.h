#import <SocketRocket/SocketRocket.h>

@interface WebSocketAdvanced: NSObject <SRWebSocketDelegate>
{
    SRWebSocket* _webSocket;
    id<CDVCommandDelegate> _commandDelegate;
    NSString* _callbackId;
    NSString* _recvCallbackId;
    NSTimer* _pingTimer;
    NSTimeInterval _pingInterval;
    NSInteger _pingCount;
    NSInteger _pongCount;
    BOOL _awaitingPong;
    NSMutableArray* _messageBuffer;
}
@property NSString* webSocketId;

- (instancetype)initWithOptions:(NSDictionary*)wsOptions 
                commandDelegate:(id<CDVCommandDelegate>)commandDelegate
                callbackId:(NSString*)callbackId;
- (void)wsAddListeners:(NSString*)recvCallbackId flushRecvBuffer:(BOOL)flushRecvBuffer;
- (void)wsSendMessage:(NSString*)message;
- (void)wsClose;
- (void)wsClose:(NSInteger)code reason:(NSString*)reason;

@end
