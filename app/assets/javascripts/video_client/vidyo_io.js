//= require video_client/vidyo_io/vidyo_data
//= require video_client/shared/required_applications
//= require video_client/vidyo_io/elements_bind

//= require_self
onVidyoClientLoaded = function (status) {
    console.log(status);
    switch (status.state) {
        case "READY":    // The library is operating normally
            // After the VidyoClient/VidyoConnector is successfully initialized,
            // a global VC object will become available.
            //
            // Load the rest of the application here


            /* JavaScript Example: */
            /* Assume that the DOM has a div with id="renderer" where the preview and the live conference should be rendered */
            /* After the VidyoClient is successfully initialized a global VC object will become available  */
            VC.CreateVidyoConnector({
                viewId: "VidyoArea",                            // Div ID where the composited video will be rendered, see VidyoConnector.html
                viewStyle: "VIDYO_CONNECTORVIEWSTYLE_Default", // Visual style of the composited renderer
                remoteParticipants: 15,                        // Maximum number of participants
                logFileFilter: "warning all@VidyoConnector info@VidyoClient",
                logFileName:"",
                userData:""
            }).then(function(vidyoConnector) {
                VidyoData.load_vidyo_lib(vidyoConnector);
                start(vidyoConnector)

            });


            break;
        case "RETRYING":     // The library operating is temporarily paused
            break;
        case "FAILED":       // The library operating has stopped
            break;
        case "FAILEDVERSION":// The version of the Javascript library does not match the plugin
            status.plugInVersion; // The Version of the plugin currently installed
            status.jsVersion;     // The Version of the Javascript library loaded
            break;
        case "NOTAVAILABLE": // The library is not available
            break;
    }
    status.downloadType;                       // Available download types with possible values of "MOBILE" "PLUGIN" "APP"
    status.downloadPathApp;                    // Path to the application installer for the app which could be invoked with a protocol handler
    status.downloadPathPlugIn;                 // Path to the Plugin that can be installed
    status.downloadPathWebRTCExtensionChrome;  // Path to the optional Chrome extension required for Screen Sharing in WebRTC
    status.downloadPathWebRTCExtensionFirefox; // Path to the optional Firefox extension required for Screen Sharing in WebRTC
    return true; // Return true to reload the plugins if not available
};

function start(vidyoConnecter){
    registerDeviceListeners(vidyoConnecter, {}, {}, {})
    bind_participants(vidyoConnecter);
    if (VidyoData.loaded){
        connect(vidyoConnecter);
    }else{
        document.addEventListener("vidyo_data_loaded", function(e) {
            connect(vidyoConnecter);
        });
    }


}
function connect(vidyoConnector){
    vidyoConnector.Connect({
        host: VidyoData.vidyo_credentials.host,
        token: VidyoData.vidyo_credentials.token,
        displayName: VidyoData.vidyo_credentials.displayName,
        resourceId: VidyoData.vidyo_credentials.resourceId,
        // Define handlers for connection events.
        onSuccess: function()            {console.log('success');},
        onFailure: function(reason)      {/* Failed */},
        onDisconnected: function(reason) {/* Disconnected */}
    }).then(function(status) {
        if (status) {
            VidyoData.events.vidyoConnected();
            console.log("ConnectCall Success");
        } else {
            console.error("ConnectCall Failed");
        }
    }).catch(function(e) {
        console.error("ConnectCall Failed");
    });
}

function handleDeviceChange(vidyoConnector, cameras, microphones, speakers) {
    // Hook up camera selector functions for each of the available cameras
    $("#videoSource").change(function() {
        // Camera selected from the drop-down menu
        $("#videoSource option:selected").each(function() {
            camera = cameras[$(this).val()];
            vidyoConnector.SelectLocalCamera({
                localCamera: camera
            }).then(function() {
                console.log("SelectCamera Success");
            }).catch(function() {
                console.error("SelectCamera Failed");
            });
        });
    });

    // Hook up microphone selector functions for each of the available microphones
    $("#audioSource").change(function() {
        // Microphone selected from the drop-down menu
        $("#audioSource option:selected").each(function() {
            microphone = microphones[$(this).val()];
            vidyoConnector.SelectLocalMicrophone({
                localMicrophone: microphone
            }).then(function() {
                console.log("SelectMicrophone Success");
            }).catch(function() {
                console.error("SelectMicrophone Failed");
            });
        });
    });

    // Hook up speaker selector functions for each of the available speakers
    $("#audioOutput").change(function() {
        // Speaker selected from the drop-down menu
        $("#audioOutput option:selected").each(function() {
            speaker = speakers[$(this).val()];
            vidyoConnector.SelectLocalSpeaker({
                localSpeaker: speaker
            }).then(function() {
                console.log("SelectSpeaker Success");
            }).catch(function() {
                console.error("SelectSpeaker Failed");
            });
        });
    });
}

function registerDeviceListeners(vidyoConnector, cameras, microphones, speakers) {
    // Map the "None" option (whose value is 0) in the camera, microphone, and speaker drop-down menus to null since
    // a null argument to SelectLocalCamera, SelectLocalMicrophone, and SelectLocalSpeaker releases the resource.
    cameras[0]     = null;
    microphones[0] = null;
    speakers[0]    = null;

    // Handle appearance and disappearance of camera devices in the system
    vidyoConnector.RegisterLocalCameraEventListener({
        onAdded: function(localCamera) {
            // New camera is available
            $("#videoSource").append("<option value='" + window.btoa(localCamera.id) + "'>" + localCamera.name + "</option>");
            cameras[window.btoa(localCamera.id)] = localCamera;
        },
        onRemoved: function(localCamera) {
            // Existing camera became unavailable
            $("#videoSource option[value='" + window.btoa(localCamera.id) + "']").remove();
            delete cameras[window.btoa(localCamera.id)];
        },
        onSelected: function(localCamera) {
            // Camera was selected/unselected by you or automatically
            console.log(localCamera);
            if(localCamera) {
                $("#videoSource option[value='" + window.btoa(localCamera.id) + "']").prop('selected', true);
            }
        },
        onStateUpdated: function(localCamera, state) {
            console.log(state)
            // Camera state was updated
        }
    }).then(function() {
        console.log("RegisterLocalCameraEventListener Success");
    }).catch(function() {
        console.error("RegisterLocalCameraEventListener Failed");
    });

    // Handle appearance and disappearance of microphone devices in the system
    vidyoConnector.RegisterLocalMicrophoneEventListener({
        onAdded: function(localMicrophone) {
            // New microphone is available
            $("#audioSource").append("<option value='" + window.btoa(localMicrophone.id) + "'>" + localMicrophone.name + "</option>");
            microphones[window.btoa(localMicrophone.id)] = localMicrophone;
        },
        onRemoved: function(localMicrophone) {
            // Existing microphone became unavailable
            $("#audioSource option[value='" + window.btoa(localMicrophone.id) + "']").remove();
            delete microphones[window.btoa(localMicrophone.id)];
        },
        onSelected: function(localMicrophone) {
            // Microphone was selected/unselected by you or automatically
            if(localMicrophone)
                $("#audioSource option[value='" + window.btoa(localMicrophone.id) + "']").prop('selected', true);
        },
        onStateUpdated: function(localMicrophone, state) {
            // Microphone state was updated
        }
    }).then(function() {
        console.log("RegisterLocalMicrophoneEventListener Success");
    }).catch(function() {
        console.error("RegisterLocalMicrophoneEventListener Failed");
    });

    // Handle appearance and disappearance of speaker devices in the system
    vidyoConnector.RegisterLocalSpeakerEventListener({
        onAdded: function(localSpeaker) {
            // New speaker is available
            $("#audioOutput").append("<option value='" + window.btoa(localSpeaker.id) + "'>" + localSpeaker.name + "</option>");
            speakers[window.btoa(localSpeaker.id)] = localSpeaker;
        },
        onRemoved: function(localSpeaker) {
            // Existing speaker became unavailable
            $("#audioOutput option[value='" + window.btoa(localSpeaker.id) + "']").remove();
            delete speakers[window.btoa(localSpeaker.id)];
        },
        onSelected: function(localSpeaker) {
            // Speaker was selected/unselected by you or automatically
            if(localSpeaker)
                $("#audioOutput option[value='" + window.btoa(localSpeaker.id) + "']").prop('selected', true);
        },
        onStateUpdated: function(localSpeaker, state) {
            // Speaker state was updated
        }
    }).then(function() {
        console.log("RegisterLocalSpeakerEventListener Success");
    }).catch(function() {
        console.error("RegisterLocalSpeakerEventListener Failed");
    });

    handleDeviceChange(vidyoConnector, cameras, microphones, speakers);
}

window.participants = null;

function bind_participants(vidyoConnector){
    vidyoConnector.RegisterParticipantEventListener(
        {
            onJoined: function(participant) { console.log('onJoined', participant)},
            onLeft: function(participant)   { console.log('onLeft', participant) },
            onDynamicChanged: function(participants) { window.participants  = participants },
            onLoudestChanged: function(participant, audioOnly) { console.log('onDynamicChanged', participant, audioOnly) }
        }).then(function() {
        console.log("RegisterParticipantEventListener Success");
    }).catch(function() {
        console.err("RegisterParticipantEventListener Failed");
    });
};
