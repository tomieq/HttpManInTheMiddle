//
//  notificications.js
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

function uiShowError(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'error',
        timeout: duration
    }).show();
    
}

function uiShowWarning(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'warning',
        timeout: duration
    }).show();
}

function uiShowSuccess(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'success',
        timeout: duration
    }).show();
}

function uiShowInfo(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'info',
        timeout: duration
    }).show();
}
