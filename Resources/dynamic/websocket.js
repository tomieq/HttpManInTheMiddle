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
        var html = "<tr><td onclick='$(\"#"+id+"\").toggle()'><span style='font-size:12px;' class='btn btn-sm btn-info'>" + traffic.id + "</span></td><td style='font-size:12px;'>" + traffic.method + " " + traffic.path + "<br><span style='font-size:10px;'>" + new Date().timeNow() + "</span></td>";
        html += "<td>" + traffic.responseCode + "</td>";
        html += "</tr>";
        
        var table = "<table class='table table-sm' width='100%'><tbody>";
        table += "<tr>"
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Request headers</h6><pre>" + JSON.stringify(traffic.requestHeaders, null, 2) + "</pre></td>";
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Response headers</h6><pre>" + JSON.stringify(traffic.responseHeaders, null, 2) + "</pre></td>";
        table += "</tr>";
        table += "<tr>"
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Request body</h6><pre style='overflow-x:auto; width:500px;' >" + traffic.requestBody.escape() + "</pre></td>";
        table += "<td class='w-50 align-top' style='font-size:10px;'><h6>Response body</h6><pre style='overflow-x:auto; width:500px;'>" + traffic.responseBody.escape() + "</pre></td>";
        table += "</tr>";
        table += "</tbody></table>";
        
        
        html += "<tr style='display: none' id='"+id+"'><td colspan=3>" + table + "</td></tr>";
        $("#trafficTable").append(html);
    }
}

String.prototype.escape = function() {
    var tagsToReplace = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;'
    };
    return this.replace(/[&<>]/g, function(tag) {
        return tagsToReplace[tag] || tag;
    });
};

Date.prototype.timeNow = function () {
     return ((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds();
}
