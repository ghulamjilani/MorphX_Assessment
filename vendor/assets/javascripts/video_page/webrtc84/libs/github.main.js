/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

$(function () {

    window.audioInputSelect = document.querySelector('select#audioSource');
    window.audioOutputSelect = document.querySelector('select#audioOutput');
    window.videoSelect = document.querySelector('select#videoSource');
    window.selectors = [audioInputSelect, audioOutputSelect, videoSelect];

    navigator.mediaDevices.enumerateDevices().then(gotDevices).catch(handleError);

    function reload_page() {
        try {
            $.cookie('webrtcLastInput', window.audioInputSelect.options[window.audioInputSelect.selectedIndex].text);
        } catch (err) {}
        try {
            $.cookie('webrtcLastOutput', window.audioOutputSelect.options[window.audioOutputSelect.selectedIndex].text);
        } catch (err) {}
        try {
            $.cookie('webrtcLastVideo', window.videoSelect.options[window.videoSelect.selectedIndex].text);
        } catch (err) {}
        window.location.reload();
    }

    function apply_output() {
        $.cookie('webrtcLastOutput', window.audioOutputSelect.options[window.audioOutputSelect.selectedIndex].text);
        changeAudioDestination()
    }

    audioInputSelect.onchange = reload_page;
    audioOutputSelect.onchange = apply_output;
    videoSelect.onchange = reload_page;

    $(document).on('change', '#audioSource', function () {
        window.audioInputSelect = document.querySelector('select#audioSource');
        reload_page();
    });
    $(document).on('change', '#audioOutput', function () {
        window.audioOutputSelect = document.querySelector('select#audioOutput');
        apply_output();
    });
    $(document).on('change', '#videoSource', function () {
        window.videoSelect = document.querySelector('select#videoSource');
        reload_page();
    });

});


// Attach audio output device to video element using device/sink ID.
function attachSinkId(element, sinkId) {
    if (typeof element.sinkId !== 'undefined') {
        element.setSinkId(sinkId)
            .then(function () {
                console.log('Success, audio output device attached: ' + sinkId);
            })
            .catch(function (error) {
                var errorMessage = error;
                if (error.name === 'SecurityError') {
                    errorMessage = 'You need to use HTTPS for selecting audio output ' +
                        'device: ' + error;
                }
                console.error(errorMessage);
                // Jump back to first output device in the list as it's the default.
                audioOutputSelect.selectedIndex = 0;
            });
    } else {
        console.warn('Browser does not support output device selection.');
    }
}

window.changeAudioDestination = function () {
    $('video[src!=""][src]').each(function () {
        attachSinkId(this, audioOutputSelect.value);
    });
};

window.handleError = function(error) {
    console.log('navigator.getUserMedia error: ', error);
};

window.gotDevices = function(deviceInfos) {
    try {
        $(window.audioOutputSelect.options).each(function(k,v) {
            if($.cookie('webrtcLastOutput') == this.text){
                window.audioOutputSelect.selectedIndex = k
            }
        });
        changeAudioDestination();
    } catch (err) {}

    // Handles being called several times to update labels. Preserve values.
    var values = selectors.map(function (select) {
        return select.value;
    });
    selectors.forEach(function (select) {
        while (select.firstChild) {
            select.removeChild(select.firstChild);
        }
    });
    for (var i = 0; i !== deviceInfos.length; ++i) {
        var deviceInfo = deviceInfos[i];
        var option = document.createElement('option');
        if (deviceInfo.kind === 'audioinput') {
            option.value = audioInputSelect.length;
            option.text = deviceInfo.label ||
                'microphone ' + (audioInputSelect.length + 1);
            audioInputSelect.appendChild(option);
        } else if (deviceInfo.kind === 'audiooutput') {
            option.value = deviceInfo.deviceId;
            option.text = deviceInfo.label || 'speaker ' +
                (audioOutputSelect.length + 1);
            audioOutputSelect.appendChild(option);
        } else if (deviceInfo.kind === 'videoinput') {
            option.value = videoSelect.length;
            option.text = deviceInfo.label || 'camera ' + (videoSelect.length + 1);
            if(option.text != 'WebPluginVirtualCamera'){
                videoSelect.appendChild(option);
            }
        } else {
            console.log('Some other kind of source/device: ', deviceInfo);
        }
    }
    selectors.forEach(function (select, selectorIndex) {
        if (Array.prototype.slice.call(select.childNodes).some(function (n) {
                if(n.value === values[selectorIndex]){
                    $(n).attr('selected', 'selected');
                    return true
                }else{
                   return false
                }

            })) {
            select.value = values[selectorIndex];
        }
    });
};

