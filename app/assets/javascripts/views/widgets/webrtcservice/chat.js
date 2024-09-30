//= require webrtcservice/webrtcservice-chat
//= require cable
//= require i18n/translations

// Requires: backbonejs, chaplinjs, jquery, underscore, handlebars
// Gon dependencies:
// A current_user's id. Number
// - Immerss.user.id
// - Immerss.user.public_display_name
// - Immerss.user.avatar_url
// An id of presenter of session that a chat is running for. Number
// - Immerss.presenterId
// An url of sprite with emoji
// - Immerss.emojiImgUrl
// Whether viewing chat from mobile. Boolean
// - Immerss.isMobile

+function (window) {
    "use strict";
    var Immerss = window.Immerss,
        userId = null,
        userType = null,
        presenterId = null,
        MESSAGES_HISTORY_LIMIT = 50;
    var AVAILABLE_EMOJIES = window.getEmojies().available;
    var EMOJI_ALTERNATIVES = window.getEmojies().alternatives;
    var MAX_MESSAGE_LENGTH = 200;
    var EMOJI_SIZE_IN_MESSAGE = 2; // Set a value which determines how to resolve size of each emoji code in message

    if (Immerss && Immerss.user && _.isNumber(Immerss.user.id)) {
        userId = Immerss.user.id;
        userType = 'User';
    } else if (Immerss && Immerss.chat_member) {
        userId = Immerss.chat_member.id;
        userType = 'ChatMember';
    }
    if (Immerss && _.isNumber(Immerss.presenterId)) {
        presenterId = Immerss.presenterId;
    }
    var getUserId = function () {
        if (Immerss && Immerss.user && _.isNumber(Immerss.user.id)) {
            return Immerss.user.id;
        } else if (Immerss && Immerss.chat_member) {
            return Immerss.chat_member.id;
        }
    };
    var getUserType = function () {
        if (Immerss && Immerss.user && _.isNumber(Immerss.user.id)) {
            return 'User';
        } else if (Immerss && Immerss.chat_member) {
            return 'ChatMember';
        }
    };
    // Escape dangerous smiles. Webrtcservice already does this on its side. So e.g. ":>" smile will be replaced with ":&gt;".
    // So to replace smiles codes in, received from webrtcservice, message correctly - we need to do the same.
    +function () {
        _.each(EMOJI_ALTERNATIVES, function (alternatives, emojiCode) {
            EMOJI_ALTERNATIVES[emojiCode] = _.map(alternatives, function (alternativeCode) {
                var str = alternativeCode + "<br>";
                str = DOMPurify.sanitize(str, {ALLOWED_TAGS: ["br"]});
                str = str.replace("<br>", "");
                return str;
            });
        })
    }();
    Object.freeze(AVAILABLE_EMOJIES);
    Object.freeze(EMOJI_ALTERNATIVES);

    var sanitizeHtml = function (string) {
        return DOMPurify.sanitize(String(string), {ALLOWED_TAGS: ['br']});
    };

    // Escaping user input that is to be treated as a literal string within a regular expression
    var escapeRegExp = function (string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
    };

    var beforeSendMessageWrapper = function (htmlString) {
        var message = {};
        if (Immerss.user) {
            message.authorName = Immerss.user.public_display_name;
            message.authorAvatarUrl = Immerss.user.avatar_url;
            message.authorType = 'User';
        } else if (Immerss.chat_member) {
            message.authorName = Immerss.chat_member.public_display_name;
            message.authorAvatarUrl = Immerss.chat_member.avatar_url;
            message.authorType = 'ChatMember';
        }
        message.messageBody = beforeSendMessageParser(htmlString);
        return JSON.stringify(message);
    };

    var beforeSendMessageParser = function (htmlString) {
        htmlString = replaceEmojiImagesWithCodes(htmlString);
        htmlString = $.trim(sanitizeHtml(htmlString));
        // Replace more than one consecutive <br> with one <br>
        htmlString = htmlString.replace(/(<br>\s*){2,}/g, '<br>');
        return $.trim(sanitizeHtml(htmlString));
    };

    var replaceEmojiImagesWithCodes = function (string) {
        var $string = $("<div></div>");
        $string.html(string);
        $string.find("img").replaceWith(function () {
            var emojiCode = _(String($(this).attr("src")).split("#")).last();
            if (!_.isString(emojiCode))
                return this.outerHTML;

            if (AVAILABLE_EMOJIES.indexOf(emojiCode) !== -1) {
                return ":" + emojiCode + ":";
            } else {
                return this.outerHTML;
            }
        });
        return $string.html();
    };

    var calcMessageLength = function (htmlString) {
        var stringLength = 0;

        htmlString = beforeSendMessageParser(htmlString);
        // Drop <br> tags so they doesn't affect on length calculation
        htmlString = DOMPurify.sanitize(htmlString, {ALLOWED_TAGS: []});

        htmlString = htmlString.replace(/&nbsp;/g, ' ');

        _.each(AVAILABLE_EMOJIES, function (emojiCode) {
            // Count inclusion of each emoji into given string and remove it from string
            var matchedElements = htmlString.match(new RegExp(":" + emojiCode + ":", "g"));
            if (!matchedElements)
                return;
            stringLength += matchedElements.length * EMOJI_SIZE_IN_MESSAGE;
            htmlString = htmlString.replace(new RegExp(":" + emojiCode + ":", "g"), '');
        });

        // Finally, when all tags and emoji are stripped - take a length of the rest of the string
        stringLength += htmlString.length;
        return stringLength;
    };

    var ChatMessage = chaplin.Model.extend({
        idAttribute: 'sid',
        initialize: function () {
            chaplin.Model.prototype.initialize.apply(this, arguments);
            // Handle SyncMachine states properly
            this.listenTo(this, 'request', this.beginSync);
            this.listenTo(this, 'error', this.unsync);
            this.listenTo(this, 'sync', this.finishSync);
        },
        parse: function (rawAttrs) {
            var attrs, parsedBody;
            attrs = _.pick(rawAttrs.state, 'author', 'body', 'index', 'sid', 'timestamp');
            // Webrtcservice returns value of this attribute as string. It contains id of user.
            attrs.authorId = attrs.author;
            try {
                parsedBody = JSON.parse(attrs.body);
                attrs.authorName = parsedBody.authorName;
                attrs.authorAvatarUrl = parsedBody.authorAvatarUrl;
                attrs.authorType = parsedBody.authorType;
                attrs.messageBody = this.prepareMessageBody(parsedBody.messageBody);
            } catch (e) {
                attrs.authorName = '';
                attrs.authorAvatarUrl = '';
                attrs.messageBody = '';
                attrs.authorType = '';
            }
            return attrs;
        },
        prepareMessageBody: function (string) {
            // Order is important
            string = sanitizeHtml(string);
            string = this.parseEmojiCodes(string);
            string = this.parseAlternativeEmojiCodes(string);
            return this.extractLinks(string);
        },
        extractLinks: function (string) {
            return anchorme(
                string,
                {
                    truncate: [26, 15],
                    attributes: [
                        function (urlObj) {
                            if (urlObj.reason === 'url') {
                                return {
                                    name: 'target',
                                    value: '_blank'
                                };
                            }
                        },
                        function (urlObj) {
                            if (urlObj.reason === 'url')
                                return {
                                    name: 'rel',
                                    value: 'nofollow'
                                };
                        }
                    ]
                }
            );
        },
        parseEmojiCodes: function (string) {
            _.each(AVAILABLE_EMOJIES, function (emojiCode) {
                string = string.replace(
                    new RegExp(":" + emojiCode + ":", "g"),
                    this.getImageByEmojiCode(emojiCode)
                );
            }.bind(this));
            return string;
        },
        parseAlternativeEmojiCodes: function (string) {
            var that = this;
            _.each(EMOJI_ALTERNATIVES, function (alternatives, emojiCode) {
                _.each(alternatives, function (alternativeCode) {
                    string = string.replace(
                        new RegExp(escapeRegExp(alternativeCode), "g"),
                        that.getImageByEmojiCode(emojiCode)
                    );
                });
            });
            return string;
        },
        getImageByEmojiCode: function (emojiCode) {
            return '<img src="' + Immerss.emojiImgUrl + '#' + emojiCode + '">';
        }
    });
    _.extend(ChatMessage.prototype, chaplin.SyncMachine);

    var ChatMessages = chaplin.Collection.extend({
        model: ChatMessage,
        initialize: function () {
            chaplin.Collection.prototype.initialize.apply(this, arguments);
            // Handle SyncMachine states properly
            this.listenTo(this, 'request', this.beginSync);
            this.listenTo(this, 'error', this.unsync);
            this.listenTo(this, 'sync', this.finishSync);
        }
    });
    _.extend(ChatMessages.prototype, chaplin.SyncMachine);
    // In case if chat is viewed from mobile device - display messages from bottom to top(newest appears on the top).
    if (Immerss.isMobile) {
        ChatMessages.prototype.comparator = function (model1, model2) {
            return model2.get('index') - model1.get('index');
        }
    } else {
        ChatMessages.prototype.comparator = 'index';
    }

    var Authorization = chaplin.Model.extend({
        url: '/webrtcservice/authorizations',
        defaults: {
            identity: function () {
                getUserId()
            },
            user_type: function () {
                getUserType()
            }
        },
        initialize: function () {
            chaplin.Model.prototype.initialize.apply(this, arguments);
            // Handle SyncMachine states properly
            this.listenTo(this, 'request', this.beginSync);
            this.listenTo(this, 'error', this.unsync);
            this.listenTo(this, 'sync', this.finishSync);
        },
        isAuthorized: function () {
            return _.isString(this.get('token'));
        },
        authorize: function (track) {
            this.set({token: null}, {silent: true});
            return this.save();
        }
    });
    _.extend(Authorization.prototype, chaplin.SyncMachine);

    var MessageView = chaplin.View.extend({
        autoRender: true,
        autoAttach: true,
        tagName: 'li',
        events: {
            'click .ban': 'banAuthor'
        },
        initialize: function (options) {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#immerssMessageTmpl').text());
        },
        getTemplateFunction: function () {
            return this.template;
        },
        addZero: function (i) {
            if (i < 10) {
              i = "0" + i
            }
            return i;
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            data.authorClasses = this.authorClasses();
            data.isRegularUser = this.model.get('authorType') === 'User';
            data.canBan = userId === presenterId;
            data.isPresenter = +this.model.get('authorId') === +presenterId;
            data.timestamp = `${data.timestamp.getHours()}:${this.addZero(data.timestamp.getMinutes())}`;
            return data;
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            return this;
        },
        dispose: function () {
            if (this.disposed)
                return;
            delete this.template;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        },
        authorClasses: function () {
            var authorClasses = [];
            if (userId === this.model.get('authorId')) {
                authorClasses.push('owner');
            }
            if (presenterId === this.model.get('authorId')) {
                authorClasses.push('presenter');
            }
            return authorClasses.join(' ');
        },
        banAuthor: function (e) {
            var r = confirm("Are you sure want to ban this user?");
            if (r == true) {
                var that = this;
                this.$el.css('opacity', 0.5);
                console.log('ban', this.model);
                $.ajax({
                    url: '/webrtcservice/bans',
                    type: 'POST',
                    dataType: 'json',
                    data: {
                        author_id: that.model.get('authorId'),
                        author_type: that.model.get('authorType'),
                        channel_id: that.model.collection.channelId,
                    },
                    success: function (resp) {
                        console.log(resp);
                    }
                });
            }
            return false;
        }
    });

    var MessagesCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        listSelector: '.messages',
        loadingSelector: '.loading',
        itemView: MessageView,
        optionNames: chaplin.CollectionView.prototype.optionNames.concat(['channelId', 'authorization']),
        events: {
            "keypress .new-message": "trackPressedKey",
            "click .send-msg-btn": "sendMessageBtnClicked",
            "input .new-message": "updateVisualMessageLength",
            "paste .new-message": "updateVisualMessageLength",
            "click .toggle-emoji-box": "toggleEmojiBox",
            "click .emojiBox img": "addEmojiToMessage",
            "focusin .new-message": "trackSelection",
            "focusout .new-message": "stopSelectionTrack"
        },
        initialize: function () {
            this.collection = new ChatMessages();
            this.collection.channelId = this.channelId;
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#immerssMessagesTmpl').text());
            this.webrtcserviceClient = new Webrtcservice.Chat.Client(String(this.authorization.get('token')));
            this.currentChannel = null;
            this.selectionInternal = null;
            this.messageRange = null;
            this.$messageInput = null;
            this.$emojiBox = null;
            this.$counter = null;
            this.disableAutoscroll = false;
            this.initChat();
            this.bindEvents();
        },
        getTemplateData: function () {
            var data = {};
            data.isMac = (/mac/i).test(window.navigator.userAgent) ;
            data.emojies = AVAILABLE_EMOJIES;
            data.emojiImgUrl = Immerss.emojiImgUrl;
            data.maxMessageLength = MAX_MESSAGE_LENGTH;
            return data;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        render: function () {
            chaplin.CollectionView.prototype.render.apply(this, arguments);
            this.$messageInput = this.$el.find('.new-message');
            this.$emojiBox = this.$el.find('.emojiBox');
            this.$counter = this.$el.find('.current-length');
            this.$el.find('.messages').scroll(this.toggleAutoscroll.bind(this));
            return this;
        },
        dispose: function () {
            if (this.disposed)
                return;
            if (this.currentChannel) {
                var client = this.webrtcserviceClient;
                var callbackFunc = function () {
                    client.shutdown()
                };
                this.currentChannel.leave().then(callbackFunc, callbackFunc);
            } else {
                this.webrtcserviceClient.shutdown();
            }

            $(window).off('resize.chat');
            $(window).off('click.emoji_box');

            this.stopSelectionTrack();
            delete this.currentChannel;
            delete this.webrtcserviceClient;
            delete this.template;
            delete this.$messageInput;
            delete this.$emojiBox;
            delete this.$counter;
            return chaplin.CollectionView.prototype.dispose.apply(this, arguments);
        },
        bindEvents: function () {
            this.webrtcserviceClient.on('tokenExpired', this.requestNewToken.bind(this));
            this.listenTo(this, 'chat_member_banned', function (data) {
                console.log('chat_member_banned', data);
                var that = this;
                if (getUserId() == data.user_id && getUserType() == data.user_type) {
                    this.remove();
                }
                _.each(this.collection.where({authorId: data.user_id, authorType: data.user_type}), function (msg) {
                    that.collection.remove(msg);
                });
            });
            this.listenTo(this.authorization, 'sync', this.setNewToken);
            this.listenTo(this.collection, 'reset add', this.scrollContainer);
            $(window).on('click.emoji_box', function (e) {
                // Prevent conflicts with a button that toggles emoji box visibility
                if (this.emojiBoxLocked)
                    return;
                // Close emoji box if user is clicking outside of the emoji box
                if (e.target !== this.$emojiBox.get(0) && this.$emojiBox.has(e.target).length === 0) {
                    this.$el.removeClass('emoji_active');
                }
            }.bind(this));
            $(window).on('resize.chat', this.scrollContainer.bind(this));
        },
        requestNewToken: function () {
            this.authorization.authorize();
        },
        setNewToken: function () {
            this.webrtcserviceClient.updateToken(this.authorization.get('token'));
        },
        loadMessages: function () {
            this.currentChannel.getMessages(MESSAGES_HISTORY_LIMIT).then(function (messages) {
                if (this.disposed)
                    return;
                this.collection.reset(messages.items, {parse: true});
                return false;
            }.bind(this)).catch(function (e) {
                console.log('Could not fetch messages');
                console.log(e);
            });
        },
        bindChannelEvents: function () {
            this.currentChannel.on('messageAdded', this.messageAdded.bind(this));
        },
        trackPressedKey: function (e) {
            var shouldSubmit = e.keyCode === 13 && !e.ctrlKey && !e.shiftKey && !e.altKey;
            // Close emoji box whether user types anything in message field or presses enter
            if (this.$el.hasClass('emoji_active'))
                this.$el.removeClass('emoji_active');

            if (shouldSubmit) {
                var messageLength = calcMessageLength(this.$messageInput.html());
                if (messageLength > 0 && messageLength <= MAX_MESSAGE_LENGTH)
                    this.sendMessage();
                e.preventDefault();
                e.stopPropagation();
            }
        },
        sendMessageBtnClicked: function (e) {
            e.preventDefault();
            var messageLength = calcMessageLength(this.$messageInput.html());
            if (messageLength > 0 && messageLength <= MAX_MESSAGE_LENGTH)
                this.sendMessage();
        },
        sendMessage: function () {
            this.currentChannel.sendMessage(beforeSendMessageWrapper(this.$messageInput.html()));
            // A little trick to let an event on contenteditable div to finish and only then clear innerHTML
            setTimeout(function () {
                this.$messageInput.html('');
                this.updateVisualMessageLength();
            }.bind(this), 0);
        },
        updateVisualMessageLength: function () {
            // This is intentional and needed to calculate message length properly
            setTimeout(function () {
                var messageLength = calcMessageLength(this.$messageInput.html());
                this.$counter.text(messageLength);
                if (messageLength > MAX_MESSAGE_LENGTH) {
                    this.$counter.addClass('red');
                    let msgInput = this.$messageInput.html()
                    msgInput = beforeSendMessageParser(msgInput);
                    msgInput = DOMPurify.sanitize(msgInput, {ALLOWED_TAGS: []});
                    msgInput = msgInput.replace(/&nbsp;/g, ' ');
                    var cutLenght = 0
                    _.each(AVAILABLE_EMOJIES, function (emojiCode) {
                        if (msgInput.endsWith(":" + emojiCode + ":")) {
                            cutLenght = (":" + emojiCode + ":").length;
                        }
                    })
                    if (cutLenght > 0) {
                        msgInput = msgInput.slice(0, msgInput.length-cutLenght-(messageLength-EMOJI_SIZE_IN_MESSAGE-MAX_MESSAGE_LENGTH))
                    } else {
                        msgInput = msgInput.slice(0, msgInput.length-(messageLength-MAX_MESSAGE_LENGTH))
                    }
                    _.each(AVAILABLE_EMOJIES, function (emojiCode) {
                        msgInput = msgInput.replace(
                            new RegExp(":" + emojiCode + ":", "g"),
                            '<img src="' + Immerss.emojiImgUrl + '#' + emojiCode + '">'
                        );
                    });
                    this.$messageInput.html(msgInput);
                }
                setTimeout(function () {
                    let messageLength = calcMessageLength(this.$messageInput.html());
                    this.$counter.text(messageLength);
                    if (messageLength >= MAX_MESSAGE_LENGTH) {
                        this.$counter.addClass('red');
                    } else {
                        this.$counter.removeClass('red');
                    }
                }.bind(this), 1);
            }.bind(this), 0);
        },
        messageAdded: function (message) {
            this.collection.add(message, {parse: true});
        },
        toggleEmojiBox: function (e) {
            this.toggleVideoSectionForResponive(true)
            e.preventDefault();
            this.emojiBoxLocked = true;
            setTimeout(function () {
                this.emojiBoxLocked = false;
            }.bind(this), 0);
            this.$el.toggleClass('emoji_active');
            if (this.$el.hasClass('emoji_active'))
                this.scrollContainer();
        },
        addEmojiToMessage: function (e) {
            var selection;
            e.preventDefault();
            var emojiToAppend = e.currentTarget.cloneNode();
            this.initRange();
            this.messageRange.insertNode(emojiToAppend);
            this.messageRange.setStartAfter(emojiToAppend);
            //These three lines of code is needed to bring back cursor into message's input field after smile is
            // inserted.
            selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(this.messageRange);

            this.updateVisualMessageLength();
        },
        initRange: function () {
            if (this.messageRange)
                return;
            this.messageRange = new Range();
            var el = document.createTextNode(' ');
            this.$messageInput.append(el);
            this.messageRange.setStart(el, 0);
            setTimeout(function () {
                el.remove();
            }, 0);
        },
        trackSelection: function () {
            if (this.selectionInternal)
                return;
            var handler = function () {
                var selection = window.getSelection();
                if (selection.getRangeAt && selection.rangeCount) {
                    this.messageRange = selection.getRangeAt(0);
                }
            }.bind(this);
            this.selectionInternal = setInterval(handler, 200);
            this.toggleVideoSectionForResponive(true)
        },
        stopSelectionTrack: function () {
            clearInterval(this.selectionInternal);
            this.selectionInternal = null;
            this.toggleVideoSectionForResponive(false)
        },
        toggleVideoSectionForResponive: function (bullet) {
            const body = document.body;
            if (bullet){
                $(window.parent.$("body")[0]).addClass('ChatActive');
            }else{
                $(body).removeClass('ChatActive');
                $(window.parent.$("body")[0]).removeClass('ChatActive');
            }
        },
        initChat: function () {
            this.collection.beginSync();
            this.webrtcserviceClient.initialize().then(function () {
                if (this.disposed)
                    return;
                this.webrtcserviceClient.getChannelBySid(this.channelId).then(function (channel) {
                    if (this.disposed)
                        return;
                    this.currentChannel = channel;
                    var onConnectedToChannel = function () {
                        if (this.disposed)
                            return;
                        this.bindChannelEvents();
                        this.loadMessages();
                        this.collection.finishSync();
                    }.bind(this);

                    this.currentChannel.join()
                        .then(onConnectedToChannel)
                        .catch(function (e) {
                            // This means that user is already on a channel
                            if (e.code === 50404)
                                onConnectedToChannel();
                            return false;
                        });
                    return false;
                }.bind(this)).catch(function (e) {
                    console.log('Could not get channel by SID ', this.channelId);
                    console.log(e);
                }.bind(this));
            }.bind(this)).catch(function (e) {
                console.log('Could not initialize webrtcservice client;');
                console.log(e);
            });
        }
    });
    // Prevents spamming with messages
    MessagesCollectionView.prototype.sendMessage = _.throttle(MessagesCollectionView.prototype.sendMessage, 1500);
    // This function is bound to two events - "paste" and "input". In most cases they will be firing together, but for
    // X-browser compatibility, we need both of them - in some cases only one of them will be fired. So, when both events
    // are firing - prevent double executing of this function.
    MessagesCollectionView.prototype.updateVisualMessageLength = _.throttle(MessagesCollectionView.prototype.updateVisualMessageLength, 100);
    // In case if viewing from mobile, a newest messages appear on the top. So be should scroll to top.
    // Otherwise - scroll to bottom.
    if (Immerss.isMobile) {
        MessagesCollectionView.prototype.scrollContainer = function () {
            if (this.disableAutoscroll)
                return;
            var $messages = this.$el.find('.messages');
            // $messages.scrollTop(0);
        };
        MessagesCollectionView.prototype.toggleAutoscroll = function (e) {
            this.disableAutoscroll = e.currentTarget.scrollTop > 0;
        };
    } else {
        MessagesCollectionView.prototype.scrollContainer = function () {
            if (this.disableAutoscroll)
                return;
            var $messages = this.$el.find('.messages');
            // $messages.scrollTop($messages.get(0).scrollHeight);
        };
        MessagesCollectionView.prototype.toggleAutoscroll = function (e) {
            this.disableAutoscroll = $(e.currentTarget).outerHeight() + e.currentTarget.scrollTop - e.currentTarget.scrollHeight !== 0;
        };
    }

    var AuthorizationView = chaplin.View.extend({
        events: {
            "submit #create_member": "createMember"
        },
        optionNames: chaplin.View.prototype.optionNames.concat(['channelId', 'track']),
        initialize: function () {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.autoRender = !(this.model.isSynced() && this.model.isAuthorized());
            this.template = Handlebars.compile($('#immerssChatAuthTmpl').text());
        },
        createMember: function () {
            var that = this;
            $.ajax({
                url: this.$('#create_member').attr('action'),
                type: 'POST',
                dataType: 'json',
                data: this.$('#create_member').serialize(),
                success: function (resp) {
                    window.Immerss.chat_member = resp.member;
                    userId = Immerss.chat_member.id;
                    userType = 'ChatMember';
                    that.trigger('chatMemberAuthorized');
                },
                error: function (resp, msg) {
                    console.log('BANNED', resp, msg);
                    that.$('.error_message').text(resp.responseJSON.message);
                }
            });
            return false;
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            if (!this.model.isSyncing()) {
                this.loadCaptcha();
            }
        },
        getTemplateData: function () {
            var data = {};
            data.isSyncing = this.model.isSyncing();
            data.channelId = this.channelId;
            data.isEmbed = !!this.track;
            if (this.track) {
                data.isFreeSession = this.track.get('type') == 'session' && this.track.get('livestream_purchase_price') == 0;
            } else {
                data.isFreeSession = false;
            }
            return data;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        dispose: function () {
            if (this.disposed)
                return;
            delete this.template;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        },
        loadCaptcha: function () {
            if (!this.$('form#create_member').length)
                return;
            var self = this;
            var getRecaptchaResponse = function (response) {
                self.captchaResponse = response;
            };

            window.renderCaptcha = function () {
                self.captchaWidgetId = grecaptcha.render('recaptcha', {
                    sitekey: Immerss.captchaKey,
                    callback: getRecaptchaResponse
                });
            };

            $.getScript('https://www.google.com/recaptcha/api.js?onload=renderCaptcha&render=explicit', function () {
            });
        },
    });

    var ImmerssChatView = chaplin.View.extend({
        regions: {
            messagesContainer: '.messages-container',
            authorizationContainer: '.authorization'
        },
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['channelId', 'track']),
        initialize: function () {
            $(window).unload(this.dispose.bind(this));
            this.authorization = new Authorization({identity: getUserId(), user_type: getUserType()});
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#immerssChatTmpl').text());
            this.initCable();
            this.bindEvents();
        },
        initCable: function () {
            this.publicSessionsChannel = initSessionsChannel();
            this.publicSessionsChannel.bind(sessionsChannelEvents.chatMemberBanned, this.onChatMemberBanned.bind(this));
        },
        onChatMemberBanned: function (data) {
            this.subview('messages').trigger('chat_member_banned', data);
        },
        getTemplateData: function () {
            var data = {};

            return data;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            return this;
        },
        bindEvents: function () {
            this.listenTo(this.authorization, 'sync request error', this.initAuthView);
            this.listenToOnce(this.authorization, 'sync', function () {
                this.initMessagesView();
            });
            this.listenTo(this, 'addedToDOM', function () {
                this.authorization.authorize();
            });
        },
        initAuthView: function () {
            this.$('.authorization').show();
            this.subview(
                'authorization',
                new AuthorizationView({
                    region: 'authorizationContainer',
                    model: this.authorization,
                    track: this.track,
                    channelId: String(this.channelId)
                })
            );
            this.listenTo(this.subview('authorization'), 'chatMemberAuthorized', function () {
                console.log('chatMemberAuthorized');
                this.authorization.set({identity: getUserId(), user_type: getUserType()}, {silent: true});
                this.authorization.authorize();
            });

        },
        initMessagesView: function () {
            this.$('.authorization').hide();
            this.subview(
                'messages',
                new MessagesCollectionView(
                    {
                        region: 'messagesContainer',
                        channelId: String(this.channelId),
                        authorization: this.authorization
                    }
                )
            );
        },
        dispose: function () {
            if (this.disposed)
                return;
            delete this.authorization;
            delete this.template;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        }
    });
    window.ImmerssChatView = ImmerssChatView;
}(window);
