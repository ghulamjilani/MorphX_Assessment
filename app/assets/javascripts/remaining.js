var Remaining = {};

Remaining.dashboard = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).removeClass('btn-grey-solid').html(resultText).removeAttr('disabled');
        },

        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        updateJoinTimerContent: function (elem, value) {
            $(elem).html('<span>Begins in:</span>' + value);
        }
    }
};

Remaining.sessionshow = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).html('Join');
            $(elem).addClass('btn-green').removeClass('btn-borderred-grey');
            $(elem).removeAttr('disabled');
        },
        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        updateJoinTimerContent: function (elem, value) {
            $(elem).addClass('btn-green').removeClass('mainButton').attr('disabled', true);
            $(elem).html('Starting In ' + value);
        }
    }
};

Remaining.sessionshowbeginsin = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).html('In progress');
        },
        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        updateJoinTimerContent: function (elem, value) {
            $(elem).html(value);
        }
    }
};

Remaining.usershow = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).removeClass('btn-grey-solid').html(resultText).removeAttr('disabled');
        },
        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        updateJoinTimerContent: function (elem, value) {
            $(elem).html('<span>Begins in:</span>' + value);
        }
    }
};

Remaining.thankyou = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).removeClass('btn-grey-solid').html(resultText);
        },

        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        updateJoinTimerContent: function (elem, value) {
            $(elem).html('<span>Begins in:</span>' + value);
        }
    }
};

Remaining.headernextsession = function () {
    return {
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).html('<span>' + resultText + '</span>');

            if (resultText == 'Join') {
                $(elem).removeAttr('disabled');
            }
        },
        updateJoinTimerContent: function (elem, value) {
            $(elem).html('Next session: <span>' + value + '</span>');
        }
    }
};

Remaining.playeroverlay = function () {
    return {
        activateJoinTimerAsButton: function (elem, resultText) {
            $(elem).html('<span>' + resultText + '</span>');

            if (resultText == 'Join') {
                $(elem).removeAttr('disabled');
            }
        },
        updateJoinTimerContent: function (elem, value) {
            $(elem).html(value);
        }
    }
};

Remaining.previewpurchase = function () {
    return {
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        activateJoinTimerAsButton: function (elem, resultText) {
            //NOTE - resultText is never "Join" here because
            //before it is purchased
            //can?(:join_as_participant, session)
            //can?(:join_as_presenter, session)
            //can?(:join_as_co_presenter, session)
            //can?(:join_as_livestreamer, session)
            //all return false(which sets resultText as "In progress" rather than "Join")
            //see join_room.html_link helper method

            $(elem).html(resultText).css('width', 88);

            $('.sessiontimer').html($('.sessiontimer').children()); // removes "Begins in:" text that is displayed along with "In progress" A tag
        },

        // NOTE: custom updater function is used because counter/join room link section
        // has special special layout on this page(not like any other counter/join counters - preview_purchase, dashboard etc)
        // html layout on sessin
        // @param elem - jquery element, A tag
        // @param resultText - "Join" or "In progress" string
        updateJoinTimerContent: function (elem, value) {
            $(elem).html(value);
            $('.sessiontimer').show();
        }
    }
};

function offsetLoop(timerEndAtInSeconds, log, update_timer) {
    if (typeof (update_timer) == 'function') {
        timer = update_timer();
        if (timer) {
            timerEndAtInSeconds = timer
        }
    }
    var secondsLeft = timerEndAtInSeconds - window.serverDate.nowInSecondsI()
    if (secondsLeft >= 0) {
        var secondsRemaining = (secondsLeft * 1000) / 1000;
        var hour = parseInt(secondsRemaining / 3600);
        secondsRemaining -= hour * 3600;

        var minute = parseInt(secondsRemaining / 60);
        secondsRemaining -= minute * 60;
        secondsRemaining = parseInt(secondsRemaining % 60, 10);

        var formattedTime = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute) + ":" + (secondsRemaining < 10 ? "0" + secondsRemaining : secondsRemaining);

        log(formattedTime);
        setTimeout(function () {
            offsetLoop(timerEndAtInSeconds, log, update_timer);
        }, 1000);
    } else {
        if (secondsLeft < 0) {
            log('countEnd');
        }
    }
}



$(function () {
    $('#inCallButtonStartStreaming').each(function (i, elem) {
        $(elem).attr('disabled', 'disabled');
        var timerEndAtInSeconds = parseInt($(elem).data('timer-end-at-in-seconds'));
        var log = function (text) {
            if (text == 'countEnd') {
                $(elem).removeAttr('disabled');
            }
        };
        offsetLoop(timerEndAtInSeconds, log);
    });
});

var beginsInFromSeconds = function (seconds) {
    if (seconds < 86400) {
        throw new Error('seconds has to be less than 86400, got instead:' + seconds);
    }
    var hoursNum = parseInt(seconds / 3600, 10);

    if (hoursNum <= 48) {
        return hoursNum + '+ hrs';
    }

    return parseInt(hoursNum / 24, 10) + ' days';
};

window.initializeJoinTimer = function () {
    $('.join-timer:not([timer-init])').each(function (i, elem) {
        // add this attribute to processed buttons so we can call this method again without processing
        $(elem).addClass('timerToSession');
        $(elem).attr('timer-init', true);
        $(elem).attr('disabled', true);

        // set in join_room.html_link as default link title
        // could be "Join" or "In progress"
        resultText = $(elem).html();

        var seconds = parseInt($(elem).data('start-at')) - window.serverDate.nowInSecondsI();
        var timerEndAtInSeconds = parseInt($(elem).data('start-at'))
        if (seconds > 24 * 3600) {
            var hoursNum = parseInt(seconds / 3600, 10);

            var initializationType = $(elem).data('initialization-type');
            Remaining[initializationType]().updateJoinTimerContent(elem, beginsInFromSeconds(seconds));

            $(elem).show();
        } else {
            var log = function (text) {
                var initializationType = $(elem).data('initialization-type');
                if (text != 'countEnd') {
                    Remaining[initializationType]().updateJoinTimerContent(elem, text);
                } else {
                    Remaining[initializationType]().activateJoinTimerAsButton(elem, resultText);

                    if (resultText == 'Join') {
                        $(elem).removeClass('timerToSession');
                        $(elem).removeAttr('disabled');
                    }
                }
                $(elem).show();
            };

            var updateTimer = function () {
                return parseInt($(elem).data('start-at'));
            };
            offsetLoop(timerEndAtInSeconds, log, updateTimer);
        }
    });
};
