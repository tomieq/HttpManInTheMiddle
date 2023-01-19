//
//  loader.js
//  
//
//  Created by Tomasz Kucharski on 28/11/2022.
//

var osRequestCounter = 0;

function requestStarted() {
    osRequestCounter++;
}

function setWindowLoading() {
}
function setWindowLoaded() {
}

function uiShowError(html) {
    console.log(html)
}

function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function addTimestampToPath(path) {
    var modifiedPath = addArgumentToPath(path, "r", getRandomInt(99,999));
    return modifiedPath;
}

function addArgumentToPath(path, argumentName, argumentValue) {
    var pathWithArgument = path;

    // add argument if not present
    if(path.indexOf(argumentName + "=") == -1) {
        if(path.indexOf("?") !== -1) {
            pathWithArgument += '&';
        } else {
            pathWithArgument += '?';
        }
        pathWithArgument += argumentName + "=" + argumentValue;
    }
    return pathWithArgument;
}