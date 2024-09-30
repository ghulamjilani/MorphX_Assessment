window.THEOplayer_UI_Hotkeys = function(player) {
    var togglePlay = function () {
            if (player.paused) {
                player.play();
            } else {
                player.pause();
            }
        },
        toggleMute = function () {
            player.muted = !player.muted;
        },
        toggleFullScreen = function () {
            if (player.presentationMode = 'fullscreen') {
                player.presentationMode = 'inline';
            }  else {
                player.presentationMode = 'fullscreen';
            }
        },
        rewind = function () {
            player.currentTime -= 5;
        },
        forward = function () {
            player.currentTime += 5;
        },
        increaseVolume = function () {
            player.volume = Math.min(player.volume + 0.05, 1);
        },
        decreaseVolume = function () {
            player.volume = Math.max(player.volume - 0.05, 0);
        },
        preventStandardHotKeyActions = function (event) {
            event.stopPropagation();
            event.preventDefault();
            return false;
        },
        charCodeMap = {
            32: togglePlay,         // spacebar
            37: rewind,             // left
            38: increaseVolume,     // up
            39: forward,            // right
            40: decreaseVolume,     // down
            70: toggleFullScreen,   // f
            77: toggleMute         // m
        },
        isTHEOplayerFocused = function (keyCode) {
            if ([37, 38, 39, 40].includes(keyCode)){
                return true
            }

            var node = document.activeElement;
            while (node !== null) {
                if (player.element === node) {
                    return true;
                }
                node = node.parentNode;
            }
            return false;
        },
        processKeyEvent = function (event) {
            var action;

            if (!event) {
                event = window.event;
            }

            action = charCodeMap[event.keyCode];

            if (action && !event.altKey && !event.ctrlKey && !event.shiftKey && isTHEOplayerFocused(event.keyCode)) {
                action();
                return preventStandardHotKeyActions(event);
            }
        },
        load = function () {
            player.element.tabIndex = 1;
            document.addEventListener('keydown', processKeyEvent);
        };

    load();
};