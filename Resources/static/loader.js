//
//  loader.js
//  
//
//  Created by Tomasz Kucharski on 19/03/2021.
//

var osLoadedJS = [];
var osLoadedCSS = [];

function loadCssAndJsAndHtmlThenRunScripts(cssFilePaths, jsFilePaths, htmlPath, scriptPaths, htmlSelector) {
    
    var pathsToLoad = [];
    for (var i = 0; i < cssFilePaths.length; i++) {
        var cssFilePath = cssFilePaths[i];
        if(!osLoadedCSS.contains(cssFilePath)) {
            osLoadedCSS.push(cssFilePath);
            pathsToLoad.push(cssFilePath);
        }
    }
    

    if(pathsToLoad.length > 0 ) {
        var countDown = pathsToLoad.length;
        setWindowLoading();
        for (var i = 0; i < pathsToLoad.length; i++) {

            requestStarted();
            var pathWithIndex = pathsToLoad[i];
            $.get(pathWithIndex, function(response) {

                var randomID = getRandomInt(1000, 9999);
                $('head').append('<style id="loadedTheme' + randomID +'"></style>');
                $('#loadedTheme' + randomID).text(response);
                countDown--;
                if(countDown == 0) {
                    setWindowLoaded();
                    loadJsAndHtmlThenRunScripts(jsFilePaths, htmlPath, scriptPaths, htmlSelector);
                }
             }).fail(function( jqxhr, settings, exception ) {
                    uiShowError( 'Error while loading CSS<br>' + exception);
              })
        }
    } else {
        loadJsAndHtmlThenRunScripts(jsFilePaths, htmlPath, scriptPaths, htmlSelector);
    }
}

function loadJsAndHtmlThenRunScripts(jsFilePaths, htmlPath, scriptPaths, htmlSelector) {

    var pathsToLoad = [];
    for (var i = 0; i < jsFilePaths.length; i++) {
        var jsFilePath = jsFilePaths[i];
        if(!osLoadedJS.contains(jsFilePath)) {
            osLoadedJS.push(jsFilePath);
            pathsToLoad.push(jsFilePath);
        }
    }
    
    if(pathsToLoad.length > 0 ) {
        var countDown = pathsToLoad.length;
        setWindowLoading();
        for (var i = 0; i < pathsToLoad.length; i++) {
            var script = document.createElement('script');
            script.onload = function () {
                //do stuff with the script
                countDown--;
                if(countDown == 0 ){
                    setWindowLoaded();
                    loadHtmlThenRunScripts(htmlPath, scriptPaths, htmlSelector);
                }
            };
            requestStarted();
            var jsFilePath = addTimestampToPath(pathsToLoad[i]);
            script.src = jsFilePath;
            document.head.appendChild(script);
        }
    } else {
        loadHtmlThenRunScripts(htmlPath, scriptPaths, htmlSelector);
    }
}

function loadHtmlThenRunScripts(htmlPath, scriptPaths, htmlSelector) {
    if( typeof htmlPath == 'string') {
        if(htmlSelector.length > 0) {
            var selector = htmlSelector;
        } else {
            var selector = "#mainContent";
        }
        requestStarted();
        var htmlPath = addTimestampToPath(htmlPath);
        $(selector).empty();
        setWindowLoading();
        $(selector).load( htmlPath, function(response, status, xhr) {
            setWindowLoaded();
            if ( status == "error" ) {
                uiShowError('Error while loading HTML: ' +  + xhr.status + " " + response );
            } else {
                runScripts(scriptPaths);
            }
        });
    } else {
        runScripts(scriptPaths);
        
    }
}

function runScripts(scriptPaths) {
    var countDown = scriptPaths.length;
    if(countDown > 0) {
        setWindowLoading();
        for (var i = 0; i < scriptPaths.length; i++) {
            console.log('GET ' + scriptPaths[i]);
            requestStarted();
            var pathWithIndex = addTimestampToPath(scriptPaths[i]);
            $.getScript(pathWithIndex)
              .done(function( script, textStatus ) {
              })
              .fail(function( jqxhr, settings, exception ) {
                    uiShowError( 'Error while loading script '+this.url+'<br>' + exception);
              }).always(function() {
                countDown--;
                if(countDown == 0) {
                     setWindowLoaded();
                }
              });
        }
    }
}

function formSubmit(submitUrl, form) {
    setWindowLoading();
    var pathWithIndex = addTimestampToPath(submitUrl);
    var formData = $(form);
    $.ajax({
          type: "POST",
          url: pathWithIndex,
          data: formData.serialize(),
          dataType: "script"
        }).fail(function( jqxhr, settings, exception ) {
            uiShowError( 'Error while posting form '+this.url+'<br>' + exception);
        }).always(function() {
            setWindowLoaded();
        });
    return false;
}

Array.prototype.contains = function(obj) {
    var i = this.length;
    while (i--) {
        if (this[i] === obj) {
            return true;
        }
    }
    return false;
}
