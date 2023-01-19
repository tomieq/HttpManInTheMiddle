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
    
    incoming(json) {
        console.log("Incoming websocket data: " + json);
        const traffic = JSON.parse(json);
        var id = "details" + traffic.id
        var html = "<tr><td onclick='$(\"#"+id+"\").toggle()'><span style='font-size:12px;' class='btn btn-sm btn-info'>" + traffic.id + "</span></td><td style='font-size:12px;'>" + traffic.method + " " + traffic.path + "</td>";
        html += "<td>" + traffic.responseCode + "</td>";
        html += "</tr>";
        
        var table = "<table class='table table-sm' width='100%'><tbody>";
        table += "<tr>"
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Request headers</h6><pre>" + JSON.stringify(traffic.requestHeaders, null, 2) + "</pre></td>";
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Response headers</h6><pre>" + JSON.stringify(traffic.responseHeaders, null, 2) + "</pre></td>";
        table += "</tr>";
        table += "<tr>"
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Request body</h6><pre style='overflow-x:auto; width:500px;' >" + traffic.requestBody + "</pre></td>";
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Response body</h6><pre style='overflow-x:auto; width:500px;'>" + traffic.responseBody + "</pre></td>";
        table += "</tr>";
        table += "</tbody></table>";
        
        
        html += "<tr style='display: none' id='"+id+"'><td colspan=3>" + table + "</td></tr>";
        $("#trafficTable").append(html);
    }
    
    nl2br(str, is_xhtml) {
        if (typeof str === 'undefined' || str === null) {
            return '';
        }
        var breakTag = (is_xhtml || typeof is_xhtml === 'undefined') ? '<br />' : '<br>';
        return (str + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + breakTag + '$2');
    }
}

