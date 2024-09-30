window.uiTimeLeft = function (self) {
    var $startBtn;
    if (Immerss.presenter) {
        $startBtn = self.cache.$inCallButtonStartStreaming;
        if (window.Immerss.isStarted) {
            $startBtn.parents('.MainVideoButton').removeAttr('disabled').removeAttr('title');
        }
    } else {
        $startBtn = self.cache.$inCallButtonDisconnect;
    }

    var timerEndAtInSeconds, log, $timeToStart, $timeLeft;
    $timeToStart = $('.time-start');
    $timeLeft = $('.time-left');
    window.stopLobbyTimer = false;

    var update_timer = function () {
        if (window.UpdateTimer) {
            var timer = window.UpdateTimer;
            window.UpdateTimer = null;
            return timer
        } else {
            return false
        }
    };

    if (!window.Immerss.isStarted) {
        timerEndAtInSeconds = parseInt($startBtn.data('timer-end-at-in-seconds'));
        log = function (text) {
            if (window.Immerss.isStarted) {
                $timeToStart.hide();
            } else {
                $timeToStart.show();
                // $timeToStart.hide();
            }

            if (text != 'countEnd') {
                $timeToStart.html(text);
            } else {
                $timeToStart.hide();
                window.Immerss.isStarted = true;
                if (Immerss.presenter) {
                    $startBtn.parents('.MainVideoButton').removeAttr('disabled').removeAttr('title');
                }
            }
        };
        offsetLoop(timerEndAtInSeconds, log, update_timer);
    }

    timerEndAtInSeconds = parseInt($timeLeft.data('timer-end-at-in-seconds'));

    log = function (text) {
        if (window.Immerss.isStarted && self.inConference) {
            if (!window.dontForgotMessageShow) {
                window.dontForgotMessageShow = true;
                setTimeout(function () {
                    if (self.cache.$inCallButtonStartStreaming.is(':visible')) {
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

    offsetLoop(timerEndAtInSeconds, log, update_timer);
};