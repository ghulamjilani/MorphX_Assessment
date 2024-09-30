+function () {
    "use strict";

    window.getEmojies = function () {
        return {
            available: [
                "grinning", "grinning-with-big-eyes", "beaming-with-smiling-eyes", "grinning-squinting-face", "grinning-face-with-sweat", 
                "face-with-tears-of-joy", "slightly-smiling-face", "winking", "smiling-face-with-smiling-eyes", "smiling-face-with-halo",
                "smiling-face-with-hearts", "smiling-face-with-heart-eyes", "star-struck", "smiling-face", "face-savoring-food", "face-with-tongue",
                "face-blowing-a-kiss", "kissing-face", "kissing-face-with-closed-eyes", "grimacing-face",
                "winking-face-with-tongue", "zany-face", "squinting-face-with-tongue", "squinting-face-with-tongue-2", "smirking-face-with-tongue", 
                "face-with-raised-eyebrow", "expressionless-face", "face-with-raised-eyebrow-2", "smirking-face", "unamused-face", "relieved-face",
                "sleepy-face", "sleeping-face", "face-with-rolling-eyes", "frowning-face", "face-with-open-mouth", "hushed-face", "astonished-face", 
                "flushed-face", "worried-face", "crying-face", "downcast-face-with-sweat", "angry-face", "frowning-face-with-open-mouth", 
                "confused-face", "sad-but-relieved-face", "cold-face", "pouting-face", "hot-face", "face-with-symbols-on-mouth"
            ],
            // Order of alternatives is not the same as original array.
            alternatives: {
                "grinning": ["xD"],
                "grinning-with-big-eyes": [],
                "beaming-with-smiling-eyes": [],
                "grinning-squinting-face": [':D', ':-D'],
                "grinning-face-with-sweat": [';)', ';-)'],
                "face-with-tears-of-joy": ['^-^'],
                "slightly-smiling-face": [],
                "winking": [':*', ':-*'],
                "smiling-face-with-smiling-eyes": [],
                "smiling-face-with-halo": [':@', ':-@'],
                "smiling-face-with-hearts": [],
                "smiling-face-with-heart-eyes": ['|)', '|-)'],
                "star-struck": ['|:O', '|:-O'],
                "smiling-face": [':O', ':-O'],
                "face-savoring-food": [':o', ':-o'],
                "face-with-tongue": ['<_<'],
                "face-blowing-a-kiss": [':!', ':-!'],
                "kissing-face": ['O_o'],
                "kissing-face-with-closed-eyes": [':|', ':-|'],
                "grimacing-face": [':~O', ':~-O'],
                "winking-face-with-tongue": [':~(', ':~-('],
                "zany-face": [':C', ':-C'],
                "squinting-face-with-tongue": ['8)', '8-)'],
                "squinting-face-with-tongue-2": [],
                "smirking-face-with-tongue": [':X', ':-X'],
                "face-with-raised-eyebrow": [':(', ':-('],
                "expressionless-face": [],
                "face-with-raised-eyebrow-2": [']:)', ']:-)'],
                "smirking-face": [':)', ':-)'],
                "unamused-face": ['O_O'],
                "relieved-face": [],
                "sleepy-face": [],
                "sleeping-face": [':P', ':-P'],
                "face-with-rolling-eyes": [],
                "frowning-face": [":'(", ":'-("],
                "face-with-open-mouth": [],
                "hushed-face": [],
                "astonished-face": [],
                "flushed-face": [],
                "worried-face": [],
                "crying-face": [],
                "downcast-face-with-sweat": [],
                "angry-face": [],
                "frowning-face-with-open-mouth": [],
                "confused-face": [],
                "sad-but-relieved-face": [],
                "cold-face": [],
                "pouting-face": [],
                "hot-face": [],
                "face-with-symbols-on-mouth": []
            }
        };
    };
}();
