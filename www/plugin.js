
var exec = require('cordova/exec');

var PLUGIN_NAME = 'CordovaWebsocketPlugin';

var CordovaWebsocketPlugin = {
    wsConnect: function(wsOptions, listener, success, error) {
        if (listener == undefined) {
            var listener = function(data) {
                console.log(data);
            }
        }

        var connectSuccess = function(data) {
            if (success != undefined && typeof success === "function") {
                success(data);
            }
            var flushRecvBuffer = true;
            exec(listener, listener, PLUGIN_NAME, 'wsAddListeners', [data.webSocketId, flushRecvBuffer]);
        }
        exec(connectSuccess, error, PLUGIN_NAME, 'wsConnect', [wsOptions]);
    },
    wsSend: function(wsId, message) {
        exec(null, null, PLUGIN_NAME, 'wsSend', [wsId, message]);
    },
    wsClose: function(wsId, code, reason) {
        exec(null, null, PLUGIN_NAME, 'wsClose', [wsId, code, reason]);
    }
};

module.exports = CordovaWebsocketPlugin;
