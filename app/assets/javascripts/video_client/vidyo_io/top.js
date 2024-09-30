vidyo_ui_top_init = function(){
    autostartBinds(".inCallButtonAutostart-wrapp");
    playButtonBinds('#inCallButtonStartStreaming');
    fullScreenButton('#inCallButtonFullpage');
    pipScreenButton('#inCallButtonPip');
    exitButton('#inCallButtonStopStreaming');
    initTimer();
    IOpingPong();
    brb();
};

function brb(){
    $('#inCallButtonBrbOn')
        .click(function (e) {
            e.preventDefault();
            $.post('/lobbies/' + VidyoData.room_info.id + '/be_right_back_on', {}).success(function (response) {
                $('#inCallButtonBrbOn').hide();
                $('#inCallButtonBrbOff').show();
                $('.MainVideoButton').removeClass('PlayINTR').addClass('PauseINTR');
                $("#inCallButtonMuteVideo").click();
                $("#inCallButtonMuteMicrophone").click();
            }).error(function (response) {
                $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
            });
        });

    $('#inCallButtonBrbOff')
        .click(function (e) {
            e.preventDefault();
            $.post('/lobbies/' + VidyoData.room_info.id + '/be_right_back_off', {}).success(function (response) {
                $('#inCallButtonBrbOff').hide();
                $('.MainVideoButton').addClass('PlayINTR').removeClass('PauseINTR');
                $('#inCallButtonBrbOn').show();
                $("#inCallButtonMuteVideo").click();
                $("#inCallButtonMuteMicrophone").click();
            }).error(function (response) {
                $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
            });
        });
}

function exitButton(elem){
    $(elem).click(function (e) {
            e.preventDefault();
            var scope = VidyoData.room_info.abstract_session_type.toLowerCase();
            var msg = I18n.t("video.organizer_stop_conference", {model: I18n.t("activerecord.models")[scope]});
            if (confirm(msg)) {
                $.post('/lobbies/' + VidyoData.room_info.id + '/stop_streaming', {}).success(function (response) {
                    window.close()
                }).error(function (response) {
                    $.showFlashMessage(I18n.t('video.stop_streaming_error_message'), {type: 'error', timeout: 3000});
                });
            }
        });

}

function initTimer() {
    var $startBtn;
    if (VidyoData.current_user_presenter) {
        $startBtn = $('#inCallButtonStartStreaming');
        if (VidyoData.room_info.active) {
            $startBtn.parents('.MainVideoButton').removeAttr('disabled').removeAttr('title');
        }
    } else {
        $startBtn = $('#inCallButtonDisconnect');
    }

    var seconds, log, $timeToStart, $timeLeft;
    $timeToStart = $('.time-start');
    $timeLeft = $('.time-left');

    var update_timer = function () {
        if (window.UpdateTimer) {
            var timer = window.UpdateTimer;
            window.UpdateTimer = null;
            return timer
        } else {
            return false
        }
    };

    if (!VidyoData.room_info.active) {
        seconds = parseInt($startBtn.data('timer'));
        log = function (text) {
            if (VidyoData.room_info.active) {
                $timeToStart.hide();
            } else {
                $timeToStart.show();
            }

            if (text != 'countEnd') {
                $timeToStart.html(text);
            } else {
                $timeToStart.hide();
                VidyoData.room_info.active = true;
                if (VidyoData.current_user_presenter) {
                    $startBtn.parents('.MainVideoButton').removeAttr('disabled').removeAttr('title');
                }
            }
        };
        offsetLoop(seconds, log, update_timer);
    }

    seconds = parseInt($timeLeft.text());

    log = function (text) {
        if (VidyoData.room_info.active && VidyoData.inConference) {
            if (!window.dontForgotMessageShow) {
                window.dontForgotMessageShow = true;
                setTimeout(function () {
                    if ($('#inCallButtonStartStreaming').is(':visible')) {
                        $.showFlashMessage('Please, do not forget to start the session, when you ready.', {
                            type: 'info',
                            timeout: 7000
                        });
                    }
                }, 20000);
            }
            $timeLeft.show();
        } else {
            $timeLeft.hide();
            // $timeLeft.show();
        }

        if (text != 'countEnd') {
            $timeLeft.html(text);
            if (parseInt(text.split(':')[1]) < 6 && parseInt(text.split(':')[0]) == 0) {
                if (!$timeLeft.hasClass('notified')) {
                    var sound = $("#Warning5minute")[0];
                    try {
                        sound.load();
                        sound.play();
                    } catch (e) {
                    }
                    $.showFlashMessage(' You have 5 minutes left in a session.', {type: 'info', timeout: 7000});
                }
                $timeLeft.addClass('notified');
                $timeLeft.find('span').css('color', 'red');
            }
        } else {
            $timeLeft.html('');
        }
    };

    offsetLoop(seconds, log, update_timer);
};

function fullScreenButton(elem){
    $(elem).click(function () {
            self.isFullpage = !self.isFullpage;
            if (self.isFullpage) {
                self.isFullscreen = false;
                $('body').removeClass('has-ribbon');
                uiFullscreenSet($('body')[0]);
                $(this).find('i').attr('class', '').addClass('VideoClientIcon-restore');
            } else {
                uiFullscreenCancel();
                $(this).find('i').attr('class', '').addClass('VideoClientIcon-expand2');
            }
        });

}

function pipScreenButton(elem){
    if(!document.pictureInPictureEnabled){
        $(elem).hide();
    }
    $(elem).click(function () {
        $('.video-wrapper > video:first')[0].requestPictureInPicture();
    });
}

function playButtonBinds(elem) {
    $(elem).click(function (e) {
        e.preventDefault();
        if ($('.MainVideoButton').attr('disabled')) {
            $.showFlashMessage('Please wait until your session starts', {type: 'info', timeout: 3000});
            return
        }
        $('.MainVideoButton').attr('disabled', true);
        $('.MainVideoButton').removeClass('INTRdefault').addClass('waitResponse').after('<div class="waitResponseCover"></div>');
        $.post('/lobbies/' + Immerss.roomId + '/start_streaming', {}).success(function (response) {
            $('.MainVideoButton').removeClass('waitResponse');
            $('.waitResponseCover').remove();
            $('.MainVideoButton').removeAttr('disabled');
            $('.default-pics').hide();
            $('.default-live').show().fadeIn();
            $('#inCallButtonStartStreaming').hide();
            $('#inCallButtonBrbOn').show();
            $('.MainVideoButton').addClass('INTR').addClass('PlayINTR').attr('data-tip', 'Pause');

            $('#inCallButtonStartRecord').removeClass('disabled');
            $('#inCallButtonStopRecord').removeClass('disabled');
            $('#roomState').removeClass('offAir').addClass('live');
            VidyoData.room_info.active = true;
        }).error(function (response) {
            $('.MainVideoButton').removeAttr('disabled');
            $('.MainVideoButton').removeClass('waitResponse');
            $('.waitResponseCover').remove();
            $.showFlashMessage(I18n.t('video.start_streaming_error_message'), {type: 'error', timeout: 3000});
        });
    });
}

function autostartBinds(elem) {
    $(elem).click(function (e) {
        e.preventDefault();
        if (!VidyoData.room_info.active) {
            $.post('/lobbies/' + Immerss.roomId + '/switch_autostart', {}).success(function (response) {
                if (response.autostart) {
                    $("#inCallButtonAutostart").addClass('on');
                } else {
                    $("#inCallButtonAutostart").removeClass('on');
                }
            }).error(function (response) {
                $.showFlashMessage('[autostart] We\'re sorry, but something went wrong', {
                    type: 'error',
                    timeout: 3000
                });
            });
        }
    });

}
function IOPingService(url, callback) {
    if (!this.inUse) {
        this.status = 'unchecked';
        this.inUse = true;
        this.callback = callback;
        var _that = this;
        this.img = new Image();
        this.img.onload = function () {
            var ms = new Date().getTime() - _that.start
            _that.inUse = false;
            _that.callback(ms);

        };
        this.img.onerror = function (e) {
            if (_that.inUse) {
                _that.inUse = false;
                _that.callback(1500);
            }

        };
        this.start = new Date().getTime();
        this.img.src = url;
        this.timer = setTimeout(function () {
            if (_that.inUse) {
                _that.inUse = false;
                _that.callback(1500);
            }
        }, 1500);
    }
};

function IOpingPong() {
    setInterval(function(){
        var clear_cache = new Date().getTime();
        //#FIXME I added temporary url and if you have the time please change it
        IOPingService('https://3x4bkb1hvq9p3un0px44wnhs-wpengine.netdna-ssl.com/wp-content/uploads/2016/10/Vidyo-io-Logo.png?clear_cache='+ clear_cache, function(ms){
            var $ping = $('.SignalLevel');
            $ping.removeAttr('class').addClass('SignalLevel');
            if(ms < 300){
                $ping.addClass('level-3');
            }else if (ms < 1000){
                $ping.addClass('level-2');
            }else if (ms < 1500){
                $ping.addClass('level-1');
            }else{
                $ping.addClass('level-0');
            }
        });
    },3000);
};

function uiFullscreenSet (elem) {
    function requestFullScreen(element) {
        var requestMethod = element.requestFullScreen || element.webkitRequestFullscreen || element.mozRequestFullScreen || element.msRequestFullScreen || element.msRequestFullscreen;
        if (requestMethod) { // Native full screen.
            requestMethod.call(element);
        } else if (window.ActiveXObject !== undefined) { // IE fallback.
            try {
                var wscript = new ActiveXObject("WScript.Shell");
                if (wscript !== null) {
                    wscript.SendKeys("{F11}");

                }
            } catch (e) {
            }
            $(document).trigger("oldmsfullscreenchange");
        }
    }
    requestFullScreen(elem);
}

function uiFullscreenCancel() {
    self.isFullscreen = false;
    self.isFullpage = false;
    function requestCancelFullScreen() {
        var requestMethod = document.cancelFullScreen || document.webkitCancelFullScreen || document.mozCancelFullScreen || document.msCancelFullScreen || document.msExitFullscreen;

        if (requestMethod) { // Native full screen.
            requestMethod.call(document);
        } else if (window.ActiveXObject !== undefined) { // Older IE.
            try {
                var wscript = new ActiveXObject("WScript.Shell");
                if (wscript !== null) {
                    wscript.SendKeys("{F11}");
                }
            } catch (e) {
            }
            $(document).trigger("oldmsfullscreenchange");
        }
    }
    requestCancelFullScreen();
}
