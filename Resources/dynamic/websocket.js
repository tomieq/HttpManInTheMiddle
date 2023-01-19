var webSocket = 0;
var websocketHandler;

$( document ).ready(function() {
    webSocket = new WebSocket("{url}");
    websocketHandler = new WebSocketHandler();
    
    webSocket.onopen = function (event) {
        console.log("[webSocket] Connection established");
    };
    webSocket.onmessage = function (event) {
        websocketHandler.incoming(event.data);
    }
    webSocket.onclose = function(event) {
        if (event.wasClean) {
            console.log("[webSocket] [close] Connection closed cleanly, code="+event.code + " reason=" + event.reason);
        } else {
        // e.g. server process killed or network down
        // event.code is usually 1006 in this case

        }
    };

    webSocket.onerror = function(error) {
        console.log("'[webSocket] [error]" + error.message);
    };
});

class WebSocketHandler {
    construct() {
    }
    
    incoming(text) {
        console.log("Incoming websocket data: " + text);
        $("#sensor").append("<img src='"+text+"' class='img-fluid img-thumbnail' style='max-width:250px;'/>")
    }
}

