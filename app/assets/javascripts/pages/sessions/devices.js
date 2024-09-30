/*
*  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
*
*  Use of this source code is governed by a BSD-style license
*  that can be found in the LICENSE file in the root of the source
*  tree.
*/

'use strict';
window.devices = function () {
    const videoElement = document.querySelector('video#webrtc_data_contaioner');
    const audioInputSelect = document.querySelector('select#audioSource');
    const audioOutputSelect = document.querySelector('select#audioOutput');
    const videoSelect = document.querySelector('select#videoSource');
    const selectors = [audioInputSelect, audioOutputSelect, videoSelect];

    audioOutputSelect.disabled = !('sinkId' in HTMLMediaElement.prototype);

    function gotDevices(deviceInfos) {
        // Handles being called several times to update labels. Preserve values.
        const values = selectors.map(function(select){return select.value});
        selectors.forEach(function(select){
            while (select.firstChild) {
            select.removeChild(select.firstChild);
        }
        });
        for (var i = 0; i !== deviceInfos.length; ++i) {
            const deviceInfo = deviceInfos[i];
            const option = document.createElement('option');
            option.value = deviceInfo.deviceId;
            if (deviceInfo.kind === 'audioinput') {
                option.text = deviceInfo.label || 'microphone ' + audioInputSelect.length + 1;
                audioInputSelect.appendChild(option);
            } else if (deviceInfo.kind === 'audiooutput') {
                option.text = deviceInfo.label || 'speaker ' + audioOutputSelect.length + 1;
                audioOutputSelect.appendChild(option);
            } else if (deviceInfo.kind === 'videoinput') {
                option.text = deviceInfo.label || 'camera ' + videoSelect.length + 1;
                videoSelect.appendChild(option);
            } else {
                console.log('Some other kind of source/device: ', deviceInfo);
            }
        }
        // selectors.forEach((select, selectorIndex) => {
        //     if (Array.prototype.slice.call(select.childNodes).some(n => n.value === values[selectorIndex])) {
        //     select.value = values[selectorIndex];
        //     }
        // });

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
                $(select).select2("destroy");
                $(select).select2({minimumResultsForSearch: -1});
            }
        });
    }

    navigator.mediaDevices.enumerateDevices().then(gotDevices).catch(handleError);

// Attach audio output device to video element using device/sink ID.
    function attachSinkId(element, sinkId) {
        if (typeof element.sinkId !== 'undefined') {
            element.setSinkId(sinkId)
                .then(function(){
                console.log('Success, audio output device attached: ' + sinkId);
        })
        .catch(function(error) {
                var errorMessage = error;
            if (error.name === 'SecurityError') {
                errorMessage = 'You need to use HTTPS for selecting audio output device: ' + error;
            }
            console.error(errorMessage);
            // Jump back to first output device in the list as it's the default.
            audioOutputSelect.selectedIndex = 0;
        });
        } else {
            console.warn('Browser does not support output device selection.');
        }
    }

    function setCokieW(){
        try {
            $.cookie('webrtcLastInput', audioInputSelect.options[audioInputSelect.selectedIndex].text);
        } catch (err) {}
        try {
            $.cookie('webrtcLastOutput', audioOutputSelect.options[audioOutputSelect.selectedIndex].text);
        } catch (err) {}
        try {
            $.cookie('webrtcLastVideo', videoSelect.options[videoSelect.selectedIndex].text);
        } catch (err) {}

    }
    function changeAudioDestination() {
        setCokieW();
        const audioDestination = audioOutputSelect.value;
        attachSinkId(videoElement, audioDestination);
    }

    function gotStream(stream) {
        window.stream = stream; // make stream available to console
        videoElement.srcObject = stream;
        videoElement.play();
        $('#webrtc_error').hide();
        // Refresh button list in case labels have become available
        return navigator.mediaDevices.enumerateDevices();
    }

    function handleError(error) {
        console.log('navigator.getUserMedia error: ', error);
    }

    var errorCallback = function (error) {
        console.log(error);
    };

    function start() {
        if (window.stream) {
            window.stream.getTracks().forEach(function (track){
                track.stop();
        });
        }
        const audioSource = audioInputSelect.value;
        const videoSource = videoSelect.value;
        const constraints = {};

        // Vseh razdrazhaet eho
        // if (audioInputSelect.value.length) {
        //     constraints.audio = {
        //         deviceId: { exact: audioSource}
        //     }
        // } else {
        //     constraints.audio = false
        // }
        //
        if (videoSelect.value.length) {
            constraints.video = {
                deviceId: { exact: videoSource}
            }
        } else {
            constraints.video = true
        }

        if (navigator && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            navigator.mediaDevices.getUserMedia(constraints).then(gotStream).catch(errorCallback);
        } else if (navigator && navigator.webkitGetUserMedia) {
            navigator.webkitGetUserMedia(constraints).then(gotStream).catch(errorCallback);
        } else {
            console.error("Missing getUserMedia API.");
        }
        setCokieW();
    }

    audioInputSelect.onchange = start;
    audioOutputSelect.onchange = changeAudioDestination;

    videoSelect.onchange = start;

    start();
};
