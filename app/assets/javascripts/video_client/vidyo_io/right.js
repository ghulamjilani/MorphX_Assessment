//= require video_client/shared/lobby_modal


vidyo_ui_right_init = function(){
    trigger_mute();
    muteCamera();
    muteMic();
    muteSpeaker();
    bind_invite_users('#inCallButtonToggleInvite');
    enable_chat();
    start_share();
    stop_share();
};

function start_share(){
    $('#startSharing').on('click', function(){
        $('#stopSharing').show();
        $(this).hide();

        VidyoData.vidyo_connector.RegisterLocalWindowShareEventListener({
            onAdded: function(localWindowShare) {
                VidyoData.vidyo_connector.SelectLocalWindowShare({localWindowShare:localWindowShare});
            },
            onRemoved:  function(localWindowShare) { console.log('onRemoved', localWindowShare) },
            onSelected: function(localWindowShare) {},
            onStateUpdated: function(localWindowShare, state) {}
        }).then(function() {
            console.log("RegisterLocalWindowShareEventListener Success");
        }).catch(function() {
            console.error("RegisterLocalWindowShareEventListener Failed");
        });
    });
};

function stop_share(){
    $('#stopSharing').on('click', function(){
        $('#startSharing').show();
        $(this).hide();

        VidyoData.vidyo_connector.SelectLocalWindowShare({localWindowShare:null});
    });
};

function enable_chat(){
    $(".inCallButtonChat-wrapp").click(function (e) {
        logger.log('info', 'ui', "application::inCallButtonChat::click");
        e.preventDefault();
        $.post('/lobbies/' + Immerss.roomId + '/switch_chat', {}).success(function (response) {
            logger.log('info', 'ui', 'portal::inCallButtonChat - callback success');
            if (response.allow_chat) {
                $("#inCallButtonChat").addClass('on');
                $.showFlashMessage(I18n.t('video.chat_enabled'), {type: 'info', timeout: 3000});
            }else{
                $("#inCallButtonChat").removeClass('on');
                $.showFlashMessage(I18n.t('video.chat_disabled'), {type: 'info', timeout: 3000});
            }
        }).error(function (response) {
            $.showFlashMessage('[chat] We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
        });
    });

}

function trigger_mute(){
    $('#inCallButtonPanel').on('mute', function (e, isMuted) {
        if (isMuted) {
            $(e.target).addClass($(e.target).data('mute'));
            $(e.target).removeClass($(e.target).data('unmute'));
        } else {
            $(e.target).removeClass($(e.target).data('mute'));
            $(e.target).addClass($(e.target).data('unmute'));
        }
    });
}

var cameraPrivacy = false;
function muteCamera(){
    $("#inCallButtonMuteVideo").click(function() {
        cameraPrivacy = !cameraPrivacy;
        VidyoData.vidyo_connector.SetCameraPrivacy({
            privacy: cameraPrivacy
        }).then(function() {
            if (cameraPrivacy) {
                // Hide the local camera preview, which is in slot 0
                $("#inCallButtonMuteVideo").trigger('mute', !!cameraPrivacy);
                vidyoConnector.HideView({ viewId: "renderer0" }).then(function() {
                    console.log("HideView Success");
                }).catch(function(e) {
                    console.log("HideView Failed");
                });
            } else {
                // Show the local camera preview, which is in slot 0
                $("#inCallButtonMuteVideo").trigger('mute', !!cameraPrivacy);
                vidyoConnector.AssignViewToLocalCamera({
                    viewId: "renderer0",
                    localCamera: selectedLocalCamera.camera,
                    displayCropped: configParams.localCameraDisplayCropped,
                    allowZoom: false
                }).then(function() {
                    console.log("AssignViewToLocalCamera Success");
                    ShowRenderer(vidyoConnector, "renderer0");
                }).catch(function(e) {
                    console.log("AssignViewToLocalCamera Failed");
                });
            }
            console.log("SetCameraPrivacy Success");
        }).catch(function(e) {
            console.error(e);
        });
    });
}

var microphonePrivacy = false;
function muteMic(){
// Handle the microphone mute button, toggle between mute and unmute audio.
    $("#inCallButtonMuteMicrophone").click(function() {
        // MicrophonePrivacy button clicked
        microphonePrivacy = !microphonePrivacy;
        VidyoData.vidyo_connector.SetMicrophonePrivacy({
            privacy: microphonePrivacy
        }).then(function() {
            $("#inCallButtonMuteMicrophone").trigger('mute', !!microphonePrivacy);
            console.log("SetMicrophonePrivacy Success");
        }).catch(function() {
            console.error("SetMicrophonePrivacy Failed");
        });
    });
}

var speakerPrivacy = false;
function muteSpeaker(){
// Handle the microphone mute button, toggle between mute and unmute audio.
    $("#inCallButtonMuteSpeaker").click(function() {
        // MicrophonePrivacy button clicked
        speakerPrivacy = !speakerPrivacy;
        VidyoData.vidyo_connector.SetSpeakerPrivacy({
            privacy: speakerPrivacy
        }).then(function() {
            $("#inCallButtonMuteSpeaker").trigger('mute', !!speakerPrivacy);
            console.log("SetMicrophonePrivacy Success");
        }).catch(function() {
            console.error("SetMicrophonePrivacy Failed");
        });
    });
}

function bind_invite_users(elem){
        $(elem).on('click', function () {
            refresh_invite_modal();
        });

     function refresh_invite_modal() {
        $('#InviteParticipantsWrapp').addClass('Connecting');
        return $.get($('#inCallButtonToggleInvite').data('url')).success(function(response) {
            $('#InviteParticipants').html(window.modalBody);
            return console.log(window);
        });
    };

    $(document).on('click', '.instant-invite-contact-from-video', function(event) {
        var modelId, state, url;
        event.preventDefault();
        if (typeof ($(this).data('session-id')) !== 'undefined') {
            url = "/sessions/:id/instant_invite_user_from_video";
            modelId = $(this).data('session-id');
        } else {
            throw new Error("can not get model id");
        }
        state = $(this).parents('.list-group-item').find('.current-state-status').data('state');
        if (typeof state === 'undefined') {
            state = $(this).data('state');
        }
        if (!$(this).data("disable")) {
            $(this).data("disable", true);
            return $.ajax({
                type: "POST",
                url: url.replace(':id', modelId),
                data: 'email=' + $(this).data('email') + '&state=' + state,
                success: function(data, textStatus, jqXHR) {
                    return refresh_invite_modal();
                }
            });
        }
    });

    $(document).on('click', '.instant-remove-invited-user-from-video', function(event) {
        var modelId, url;
        event.preventDefault();
        if (typeof ($(this).data('session-id')) !== 'undefined') {
            url = "/sessions/:id/instant_remove_invited_user_from_video";
            modelId = $(this).data('session-id');
        } else {
            throw new Error("can not get model id");
        }
        return $.ajax({
            type: "POST",
            url: url.replace(':id', modelId),
            data: 'email=' + $(this).data('email'),
            success: function(data, textStatus, jqXHR) {
                return refresh_invite_modal();
            },
            error: function(jqXHR, textStatus, errorThrown) {}
        });
    });

    $(document).on('ajax:before', '.live-participant-form', function(event) {
        return $('#InviteParticipantsWrapp').addClass('Connecting');
    });

    $(document).on('ajax:success', '.live-participant-form', function(event) {
        return refresh_invite_modal();
    });

    $(document).on('keyup', '.live-participant-form input[name=email]', function(event) {
        if ($.trim($(this).val()) === '') {
            return $(".live-participant-form .invite_btn").attr("disabled", "disabled");
        } else {
            if (event.keyCode !== 13) {
                return $(".live-participant-form .invite_btn").removeAttr("disabled");
            }
        }
    });

    $(document).on('ajax:before', '.live-participant-form', function(event) {
        return $(this).find('.liveInviteSubmitButtonVideo').attr("disabled", "disabled");
    });

    $(document).on('keyup', '.live-participant-form input[name=email]', function(event) {
        if ($.trim($(this).val()) === '') {
            return $(".live-participant-form .liveInviteSubmitButtonVideo").attr("disabled", "disabled");
        } else {
            if (event.keyCode !== 13) {
                return $(".live-participant-form .liveInviteSubmitButtonVideo").removeAttr("disabled");
            }
        }
    });

    $(document).on('click', '.addUserToContacts', function(event) {
        var $checkbox;
        event.preventDefault();
        $checkbox = $(this);
        $checkbox.prop('checked', true);
        return $.ajax({
            url: $(this).data('url'),
            type: 'POST',
            dataType: 'html',
            error: function(jqXHR, textStatus, errorThrown) {
                return $checkbox.prop('checked', false);
            },
            success: function(data, textStatus, jqXHR) {
                $checkbox.parents('.addToContacts').slideUp();
                return setTimeout((function() {
                    $checkbox.parents('.addToContacts').remove();
                }), 500);
            }
        });
    });
};