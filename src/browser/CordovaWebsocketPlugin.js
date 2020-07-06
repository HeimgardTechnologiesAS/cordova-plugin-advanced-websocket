const WS_ABNORMAL_CODE = 1006;

const connections = {};

const createId = function() {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};

const wsAddListeners = function(webSocketId, success, error) {
    const webSocket = connections[webSocketId];

    webSocket.onmessage = function(event) {
        success({
            webSocketId: webSocketId,
            message: event.data,
            callbackMethod: "onMessage"
        });
    };

    webSocket.onclose = function(event) {
        error({
            webSocketId: webSocketId,
            code: event.code,
            reason: event.reason,
            callbackMethod: "onClose"
        });
        wsRemoveListeners(webSocketId);
    };
};

const wsRemoveListeners = function(webSocketId) {
    const webSocket = connections[webSocketId];
    webSocket.onmessage = undefined;
    webSocket.onclose = undefined
    connections[webSocketId] = undefined;
};

const CordovaWebsocketPlugin = {
    wsConnect: function(wsOptions, listener, success, error) {
        const webSocketId = createId();
        const webSocket = new WebSocket(wsOptions.url);

        let timeoutHandler;
        if (wsOptions.timeout && wsOptions.timeout > 0) {
            timeoutHandler = setTimeout(function() {
                webSocket.close();
            }, wsOptions.timeout);
        }

        webSocket.onopen = function() {
            if (timeoutHandler) {
                clearTimeout(timeoutHandler);
            }
            connections[webSocketId] = webSocket;
            wsAddListeners(webSocketId, listener, listener);
            success({ webSocketId: webSocketId, code: 0 });
        };

        webSocket.onerror = function() {
            error({
                webSocketId: webSocketId,
                code: WS_ABNORMAL_CODE,
                reason: "Error connecting to " + wsOptions.url,
                callbackMethod: "onFail"
            });
        }

    },
    wsSend: function(webSocketId, message) {
        const webSocket = connections[webSocketId];
        if (webSocket) {
            webSocket.send(message);
        }
    },
    wsClose: function(webSocketId, code, reason) {
        const webSocket = connections[webSocketId];
        if (webSocket) {
            webSocket.close(code, reason);
            wsRemoveListeners(webSocketId);
        }
    }
};

module.exports = CordovaWebsocketPlugin;
