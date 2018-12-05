Cordova Plugin for using WebSockets
======
[![npm version](https://badge.fury.io/js/cordova-plugin-advanced-websocket.svg)](https://badge.fury.io/js/cordova-plugin-advanced-websocket)
[![downloads](https://img.shields.io/npm/dt/cordova-plugin-advanced-websocket.svg)](https://www.npmjs.com/package/cordova-plugin-advanced-websocket)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.png)](https://opensource.org/licenses/mit-license.php)

WebSocket plugin that supports custom headers, self-signed certificates, periodical sending of pings (ping-pong to keep connection alive and detect sudden connection loss when no closing frame is received).

## Supported Platforms

* Android (uses [OkHttp](https://github.com/square/okhttp) as underlaying library)
* iOS (uses [SocketRocket](https://github.com/facebook/SocketRocket) as underlaying library)

### Android

OkHttp library is included as maven dependency with version 3.10.0

### iOS

SocketRocket is included as CocoaPod library with version 0.5.1

To use it, you will need to install CocoaPods on your Mac:
```
sudo gem install cocoapods
pod setup --verbose
```

# Installing

### Cordova

    $ cordova plugin add cordova-plugin-advanced-websocket

# API

## Methods

- [CordovaWebsocketPlugin.wsConnect](#wsconnect)
- [CordovaWebsocketPlugin.wsSend](#wscend)
- [CordovaWebsocketPlugin.wsClose](#wsclose)

## wsConnect

Connecto to WebSocket using options
```js
CordovaWebsocketPlugin.wsConnect(options, receiveCallback, successCallback, failureCallback);
```

### Parameters

- __options__: Object containing WebSocket url and other properties needed for opening WebSocket:
    - __url__: _string_; Url of WebSocket you want to connect to. This is the only mandatory property in __options__.
    - __timeout?__: _number_; Request timeout in milliseconds. (optional, defaults to 0)
    - __pingInterval?__: _number_; Ping interval in milliseconds if you want to keep WebSocket open and detect automatically dead WebSocket when Pongs stop returning. If you set it to 0, Pings won't be sent. (optional, defaults to 0)
    - __headers?__: _object_; Object containing custom request headers you want to send when opening WebSocket. Object keys are used as Header names, and values are used as Header values. (optional)
    - __acceptAllCerts?__: _boolean_; Set this to true if you are using secure version of WebSocket (url starts with "wss://") and you want to accept all certificates regardles of their validity. Useful when your WebSocket is using self-signed certificates. (optional, defaults to false)
- __receiveCallback__: Receive callback function that is invoked with every message received through WebSocket and also when WebSocket is closed.
- __successCallback__: Success callback function that is invoked with successfull connect to WebSocket.
- __failureCallback__: Error callback function, invoked when connecting to WebSocket failed for whatever reason.

### Callbacks

All three callback functions will get one object containing property __webSocketId__ and some other properties depending on callback. __successCallback__ and __failureCallback__ callbacks will also get properties _code_ and _reason_. Those two callback methods will be called only once and just one of them will be called depending on success of the outcome.

__receiveCallback__ callback will be called multiple times during lifetime of the WebSocket. It will get object that will, appart from __webSocketID__ property, contain also property __callbackMethod__ so we know what type of callback is received from plugin. Possible values for __callbackMethod__ are: _onMessage_, _onClose_, _onFail_.
If __callbackMethod__ has value _onMessage_ you will also get property __message__ which is the actual received message.
If __callbackMethod__ has value _onClose_ you will get properties _code_ and _reason_ or _exception_.
If __callbackMethod__ has value _onFail_ you will get properties _code_ and _exception_.

__webSocketId__ is unique reference to your WebSocket which is needed for later calls to [wsSend](#wsSend) and [wsClose](#wsClose).

### Quick Example

```js
var accessToken = "abcdefghiklmnopqrstuvwxyz";
var wsOptions = {
    url: "wss://echo.websocket.org",
    timeout: 5000,
    pingInterval: 10000,
    headers: {"Authorization": "Bearer " + accessToken},
    acceptAllCerts: false
}

CordovaWebsocketPlugin.wsConnect(wsOptions,
                function(recvEvent) {
                    console.log("Received callback from WebSocket: "+recvEvent["callbackMethod"]);
                },
                function(success) {
                    console.log("Connected to WebSocket with id: " + success.webSocketId);
                },
                function(error) {
                    console.log("Failed to connect to WebSocket: "+
                                "code: "+error["code"]+
                                ", reason: "+error["reason"]+
                                ", exception: "+error["exception"]);
                }
            );
```

## wsSend

Send message to WebSocket using __webSocketId__ as a reference.
```js
CordovaWebsocketPlugin.wsSend(webSocketId, message);
```

### Parameters

- __webSocketId__: Unique reference of your WebSocket.
- __message__: Message that you want to send as a string.

### Quick Example

```js
CordovaWebsocketPlugin.wsSend(webSocketId, "Hello World!");
```

## wsClose

Close WebSocket using __webSocketId__ as a reference, specifying closing code and reason.
```js
CordovaWebsocketPlugin.wsClose(webSocketId, code, reason);
```

### Parameters

- __webSocketId__: Unique reference of your WebSocket.
- __code__: WebSocket closing code, see [RFC6455](https://tools.ietf.org/html/rfc6455#section-7.4.1). (optional, defaults to 1000)
- __reason__: WebSocket closing reason. (optional)

### Quick Example

```js
CordovaWebsocketPlugin.wsClose(webSocketId, 1000, "I'm done!");
```
