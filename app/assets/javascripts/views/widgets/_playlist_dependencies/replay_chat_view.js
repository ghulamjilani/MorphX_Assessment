// Requires: backbonejs, chaplinjs, jquery, underscore, handlebars
// Gon dependencies:
// - Immerss.emojiImgUrl
// Whether viewing chat from mobile. Boolean
// - Immerss.isMobile
// A current_user's id. Number
// - Immerss.user.id

+function(){
    "use strict";
    // Determines how often messages will be loaded(in seconds).
    // Be sure that ChatMessagesController::LOAD_STEP has the same value
    var userId;
    var LOAD_STEP = 10;
    var Immerss = window.Immerss;
    var AVAILABLE_EMOJIES = window.getEmojies().available;
    var EMOJI_ALTERNATIVES = window.getEmojies().alternatives;

    if(Immerss && Immerss.user && _.isNumber(Immerss.user.id)){
        userId = Immerss.user.id;
    }

    // Escape dangerous smiles. Webrtcservice already does this on its side. So e.g. ":>" smile will be replaced with ":&gt;".
    // So to replace smiles codes in, received from webrtcservice, message correctly - we need to do the same.
    +function(){
        _.each(EMOJI_ALTERNATIVES, function(alternatives, emojiCode){
            EMOJI_ALTERNATIVES[emojiCode] = _.map(alternatives, function(alternativeCode){
                var str = alternativeCode + "<br>";
                str = DOMPurify.sanitize(str, { ALLOWED_TAGS: ["br"] });
                str = str.replace("<br>", "");
                return str;
            });
        })
    }();
    Object.freeze(AVAILABLE_EMOJIES);
    Object.freeze(EMOJI_ALTERNATIVES);

    var sanitizeHtml = function(string){
        return DOMPurify.sanitize(String(string), { ALLOWED_TAGS: ['br'] });
    };

    // Escaping user input that is to be treated as a literal string within a regular expression
    var escapeRegExp = function(string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
    };

    var ChatMessage = chaplin.Model.extend({
        initialize: function(){
            chaplin.Model.prototype.initialize.apply(this, arguments);
            // Handle SyncMachine states properly
            this.listenTo(this, 'request', this.beginSync);
            this.listenTo(this, 'error', this.unsync);
            this.listenTo(this, 'sync', this.finishSync);
        },
        parse: function(attrs){
            var parsedBody;
            attrs.created_at = new Date(attrs.created_at);
            try {
                parsedBody = JSON.parse(attrs.body);
                attrs.authorName = parsedBody.authorName;
                attrs.authorAvatarUrl = parsedBody.authorAvatarUrl;
                attrs.messageBody = this.prepareMessageBody(parsedBody.messageBody);
            }catch(e){
                attrs.authorName = '';
                attrs.authorAvatarUrl = '';
                attrs.messageBody = '';
            }
            return attrs;
        },
        prepareMessageBody: function(string){
            // Order is important
            string = sanitizeHtml(string);
            string = this.parseEmojiCodes(string);
            string = this.parseAlternativeEmojiCodes(string);
            return this.extractLinks(string);
        },
        extractLinks: function(string){
            return anchorme(
                string,
                {
                    truncate:[ 26, 15 ],
                    attributes: [
                        function(urlObj){
                            if(urlObj.reason === 'url'){
                                return {
                                    name: 'target',
                                    value: '_blank'
                                };
                            }
                        },
                        function(urlObj){
                            if(urlObj.reason === 'url')
                                return {
                                    name: 'rel',
                                    value: 'nofollow'
                                };
                        }
                    ]
                }
            );
        },
        parseEmojiCodes: function(string){
            _.each(AVAILABLE_EMOJIES, function(emojiCode){
                string = string.replace(
                    new RegExp(":" + emojiCode + ":", "g"),
                    this.getImageByEmojiCode(emojiCode)
                );
            }.bind(this));
            return string;
        },
        parseAlternativeEmojiCodes: function(string){
            var that = this;
            _.each(EMOJI_ALTERNATIVES, function(alternatives, emojiCode){
                _.each(alternatives, function(alternativeCode){
                    string = string.replace(
                        new RegExp(escapeRegExp(alternativeCode), "g"),
                        that.getImageByEmojiCode(emojiCode)
                    );
                });
            });
            return string;
        },
        getImageByEmojiCode: function(emojiCode){
            return '<img src="' + Immerss.emojiImgUrl + '#' + emojiCode + '">';
        }
    });
    _.extend(ChatMessage.prototype, chaplin.SyncMachine);

    var ChatMessages = chaplin.Collection.extend({
        model: ChatMessage,
        url: function(){
            return ""
            // var baseUrl = '/chat_channels/:chat_channel_id/chat_messages'.replace(':chat_channel_id', this.chatChannelId);
            // return baseUrl + '?chunk=' + this.currentChunk + '&needsPrevious=' + this.needsPrevious;
        },
        initialize: function(models, opts){
            chaplin.Collection.prototype.initialize.apply(this, arguments);
            // Handle SyncMachine states properly
            this.currentChunk = 0;
            // When loading messages first time or when user navigates through video time - this flag needs to be set
            // to `true` to load more(previous, relative to the current playback time) messages to show
            this.needsPrevious = true;
            this.listenTo(this, 'request', this.beginSync);
            this.listenTo(this, 'error', this.unsync);
            this.listenTo(this, 'sync', this.finishSync);
        }
    });
    _.extend(ChatMessages.prototype, chaplin.SyncMachine);
    // In case if chat is viewed from mobile device - display messages from bottom to top(newest appears on the top).
    if(Immerss.isMobile){
        ChatMessages.prototype.comparator = function(model1, model2){
            return model2.get('position') - model1.get('position');
        }
    }else{
        ChatMessages.prototype.comparator = 'position';
    }

    var MessageView = chaplin.View.extend({
        autoRender: true,
        autoAttach: true,
        tagName: 'li',
        className: 'hidden',
        optionNames: chaplin.View.prototype.optionNames.concat(['presenterId']),
        initialize: function(options){
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#immerssReplayMessageTmpl').text());
        },
        getTemplateFunction: function(){
            return this.template;
        },
        getTemplateData: function(){
            var data = this.model.toJSON();
            data.authorClasses = this.authorClasses();
            data.timestamp = this.calcTimestamp();
            return data;
        },
        render: function(){
            chaplin.View.prototype.render.apply(this, arguments);
            return this;
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.template;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        },
        authorClasses: function(){
            var authorClasses = [];
            if(userId === this.model.get('user_id')){
                authorClasses.push('owner');
            }
            if(this.presenterId === this.model.get('user_id')){
                authorClasses.push('presenter');
            }
            return authorClasses.join(' ');
        },
        calcTimestamp: function(){
            var seconds, hours, minutes,
                offset = this.model.get('offset'),
                result = [];
            hours = parseInt(offset  / (60 * 60));
            minutes = parseInt((offset - hours * 60 * 60) / 60);
            seconds = parseInt(offset - hours * 60 * 60 - minutes * 60);
            if(hours !== 0){
                result.push(hours);
                if(minutes < 10) {
                    minutes = '0' + minutes.toString();
                }
                result.push(minutes);
            }else{
                result.push(minutes);
            }
            if(seconds < 10) {
                seconds = '0' + seconds.toString();
            }
            result.push(seconds);
            return result.join(':');
        }
    });

    var MessagesCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        listSelector: '.messages',
        itemView: MessageView,
        optionNames: chaplin.CollectionView.prototype.optionNames.concat(['presenterId', 'client', 'chatChannelId']),
        initialize: function(){
            this.collection = new ChatMessages();
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.currentChunk = -1;
            this.collection.chatChannelId = this.chatChannelId;
            this.template = Handlebars.compile($('#immerssReplayMessagesTmpl').text());
            this.disableAutoscroll = false;
            this.bindEvents();
        },
        getTemplateData: function(){
            var data = {};
            return data;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        render: function(){
            chaplin.CollectionView.prototype.render.apply(this, arguments);
            this.$el.find('.messages').scroll(this.toggleAutoscroll.bind(this));
            return this;
        },
        initItemView: function(model){
            return new this.itemView({ autoRender: false, presenterId: this.presenterId, model: model });
        },
        dispose: function(){
            if(this.disposed)
                return;
            $(window).off('resize.chat');

            delete this.client;
            delete this.template;
            return chaplin.CollectionView.prototype.dispose.apply(this, arguments);
        },
        bindEvents: function(){
            $(window).on('resize.chat', this.scrollContainer.bind(this));
            this.listenTo(this.client, 'player.seeking', function(){
                this.collection.reset();
                this.collection.needsPrevious = true;
            });
            this.listenTo(this.client, 'player.timeUpdated', this.fetchMessages);
            this.listenTo(this.client, 'player.timeUpdated', this.showMessages);
        },
        fetchMessages: function(data){
            // this.currentTime = parseFloat(data.eventData.currentTime);
            // var chunk = Math.floor(this.currentTime / LOAD_STEP);

            // if(this.currentChunk !== chunk) {
            //     this.collection.currentChunk = chunk;
            //     this.currentChunk = chunk;
            //     this.collection.fetch({remove: false});
            //     this.collection.needsPrevious = false;
            // }
        },
        showMessages: function(){
            var messagesToShow;
            messagesToShow = this.collection.filter(function(chat_message){
                return chat_message.get('offset') <= this.currentTime;
            }.bind(this));
            _.each(messagesToShow, function(message){
                this.subview("itemView:"+ message.cid).$el.removeClass('hidden');
            }.bind(this));
            this.scrollContainer();
        }
    });
    // In case if viewing from mobile, a newest messages appear on the top. So be should scroll to top.
    // Otherwise - scroll to bottom.
    if(Immerss.isMobile){
        MessagesCollectionView.prototype.scrollContainer = function(){
            if(this.disableAutoscroll)
                return;
            var $messages = this.$el.find('.messages');
            // $messages.scrollTop(0);
        };
        MessagesCollectionView.prototype.toggleAutoscroll = function(e){
            this.disableAutoscroll = e.currentTarget.scrollTop > 0;
        };
    }else{
        MessagesCollectionView.prototype.scrollContainer = function(){
            if(this.disableAutoscroll)
                return;
            var $messages = this.$el.find('.messages');
            // $messages.scrollTop($messages.get(0).scrollHeight);
        };
        MessagesCollectionView.prototype.toggleAutoscroll = function(e){
            this.disableAutoscroll = $(e.currentTarget).outerHeight() + e.currentTarget.scrollTop - e.currentTarget.scrollHeight !== 0;
        };
    }

    var ImmerssReplayChatView = chaplin.View.extend({
        regions: {
            messagesContainer: '.messages-container'
        },
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['presenterId', 'client', 'chatChannelId']),
        initialize: function(){
            $(window).unload(this.dispose.bind(this));
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#immerssReplayChatTmpl').text());
        },
        getTemplateData: function(){
            var data = {};

            return data;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        render: function(){
            chaplin.View.prototype.render.apply(this, arguments);
            this.initMessagesView();
            return this;
        },
        initMessagesView: function(){
            this.subview(
                'messages',
                new MessagesCollectionView(
                    {
                        region: 'messagesContainer',
                        client: this.client,
                        chatChannelId: this.chatChannelId,
                        presenterId: this.presenterId
                    }
                )
            );
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.template;
            delete this.client;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        }
    });
    window.ImmerssReplayChatView = ImmerssReplayChatView;
}();
