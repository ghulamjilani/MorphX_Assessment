+function(window){
    "use strict";
    var LIVE_STREAMS_TO_SHOW = 5;
    var Layout = chaplin.Layout.extend({
        regions: {
            'main': '.main-content'
        }
    });

    var ImmerssPlaylistReplayItemView = chaplin.View.extend({
        tagName: 'div',
        events: {
            "click .tile-list": "changeTrack"
        },
        autoRender: true,
        initialize: function(){
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#playlistReplayItemTmpl').text());
        },
        getTemplateData: function(){
            var data = this.model.toJSON();
            data.isPlaying = this.model.isPlaying();
            data.ratingClasses = [];
            data.formattedStartAt = moment(this.model.get('start_at')).format('MMMM D, h:mm a');
            _.each([1,2,3,4,5], function (i) {
                if(data.rating >= i){
                    data.ratingClasses.push('embed_fontstar');
                }else{
                    if(data.rating >= i - 0.5){
                        data.ratingClasses.push('embed_fontstar-half-alt');
                    }else{
                        data.ratingClasses.push('embed_fontstar-empty');
                    }
                }
            });
            return data;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        changeTrack: function(e){
            this.client.sendMessage('playlist.trackChanged', { trackUniqId: this.model.uniqId() })
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.client;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        }
    });

    var ImmerssPlaylistStreamItemView = chaplin.View.extend({
        tagName: 'div',
        events: {
            "click .tile-list": "changeTrack"
        },
        autoRender: true,
        initialize: function(){
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#playlistStreamItemTmpl').text());
            this.bindEvents();
        },
        bindEvents: function(){
            this.listenTo(this.model, 'change:views_count', function(data){
                this.render();
            });
        },
        getTemplateData: function(){
            var data = this.model.toJSON();
            data.isPlaying = this.model.isPlaying();
            data.formattedStartAt = moment(this.model.get('start_at')).format('MMMM D, h:mm a');
            data.ratingClasses = [];
            _.each([1,2,3,4,5], function (i) {
                if(data.rating >= i){
                    data.ratingClasses.push('embed_fontstar');
                }else{
                    if(data.rating >= i - 0.5){
                        data.ratingClasses.push('embed_fontstar-half-alt');
                    }else{
                        data.ratingClasses.push('embed_fontstar-empty');
                    }
                }
            });
            return data;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        changeTrack: function(e){
            this.client.sendMessage('playlist.trackChanged', { trackUniqId: this.model.uniqId() })
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.client;
            return chaplin.View.prototype.dispose.apply(this, arguments);
        }
    });

    var ImmerssReplaysCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        itemView: ImmerssPlaylistReplayItemView,
        optionNames: chaplin.CollectionView.prototype.optionNames.concat(['client']),
        listSelector: '.tracks',
        fallbackSelector: '.fallback',
        initialize: function(options){
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#replaysCollectionTmpl').text());
            this.bindEvents();
        },
        filterer: function(item, index){
            return !(item.isStreaming() || item.isUpcoming());
        },
        initItemView: function(){
            var itemView;
            itemView = chaplin.CollectionView.prototype.initItemView.apply(this, arguments);
            itemView.client = this.client;
            return itemView;
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.client;
            return chaplin.CollectionView.prototype.dispose.apply(this, arguments);
        },
        getTemplateFunction: function(){
            return this.template;
        },
        getTemplateData: function(){
            var data = {}
            return data
        },
        render: function(){
            chaplin.CollectionView.prototype.render.apply(this, arguments);
            // Hide view by default
            this.toggleVisibility([]);
            return this;
        },
        bindEvents: function(){
            this.listenTo(this.collection, 'trackChanged trackStoppedPlaying', this.renderItem);
            this.listenTo(this, 'visibilityChange', this.toggleVisibility);
        },
        toggleVisibility: function(visibleItems){
            if(visibleItems.length > 0){
                this.$el.show()
            }else{
                this.$el.hide()
            }
        }
    });

    var ShowMoreView = chaplin.View.extend({
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['parentView']),
        events: {
            "click .toggle-items": "toggleShowMoreBtns"
        },
        initialize: function(){
           chaplin.View.prototype.initialize.apply(this, arguments);
           this.template = Handlebars.compile($('#showMoreTmpl').text());
           this.showMore = false;
           this.bindEvents();
        },
        getTemplateFunction: function(){
            return this.template;
        },
        dispose: function(){
           if(this.disposed)
               return;
           delete this.parentView;
           return chaplin.View.prototype.dispose.apply(this, arguments);
        },
        bindEvents: function(){
           this.listenToOnce(this.parentView, 'visibilityChange', this.render);
           this.listenTo(this.parentView, 'visibilityChange', this.resetShowMoreBtns);
           this.listenTo(this.parentView, 'visibilityChange', this.toggleItemsVisibility);
        },
        resetShowMoreBtns: function(visibleItems){
            if(visibleItems.length <= LIVE_STREAMS_TO_SHOW){
                this.$el.hide();
                this.showMore = false;
            }else{
                this.$el.show();
                this.$el.find('.more').toggle(!this.showMore);
                this.$el.find('.less').toggle(this.showMore);
            }
        },
        toggleItemsVisibility: function(visibleItems){
            var view;
            if(visibleItems.length <= LIVE_STREAMS_TO_SHOW){
                _.each(visibleItems, function(item){
                    view = this.parentView.subview("itemView:" + item.cid);
                    view.$el.show();
                }.bind(this));

            }else{
                _.each(visibleItems, function(item, index){
                    view = this.parentView.subview("itemView:" + item.cid);
                    if(index < LIVE_STREAMS_TO_SHOW){
                        view.$el.show();
                    }else{
                        view.$el.toggle(this.showMore);
                    }
                }.bind(this));
            }
        },
        toggleShowMoreBtns: function(e){
            e.preventDefault();
            this.showMore = !this.showMore;
            this.$el.find('.more').toggle(!this.showMore);
            this.$el.find('.less').toggle(this.showMore);
            this.toggleItemsVisibility(this.parentView.visibleItems);
        }
    });

    var ImmerssStreamsCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        itemView: ImmerssPlaylistStreamItemView,
        optionNames: chaplin.CollectionView.prototype.optionNames.concat(['client']),
        listSelector: '.tracks',
        regions: {
            "showMore": ".show-more-container"
        },
        initialize: function(options){
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#streamsCollectionTmpl').text());
            this.showMore = false;
            this.bindEvents();
        },
        filterer: function(item, index){
            return item.isStreaming() || item.isUpcoming();
        },
        initItemView: function(){
            var itemView;
            itemView = chaplin.CollectionView.prototype.initItemView.apply(this, arguments);
            itemView.client = this.client;
            return itemView;
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.client;
            return chaplin.CollectionView.prototype.dispose.apply(this, arguments);
        },
        render: function(){
            chaplin.CollectionView.prototype.render.apply(this, arguments);
            // Hide view by default
            this.toggleVisibility([]);
            this.subview('showMore', new ShowMoreView({ parentView: this, region: 'showMore' }));
            return this;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        getTemplateData: function(){
            var data = {};
            data.lenth = this.collection.length;
            return data;
        },
        bindEvents: function(){
            this.listenTo(this.collection, 'trackChanged trackStoppedPlaying', this.renderItem);
            this.listenTo(this, 'visibilityChange', this.toggleVisibility);
        },
        toggleVisibility: function(visibleItems){
            if(visibleItems.length > 0){
                this.$el.show()
            }else{
                this.$el.hide()
            }
        }
    });

    var ImmerssPlaylistView = chaplin.View.extend({
        autoRender: true,
        regions: {
            'chatPlaceholder': '.additions_tabs_chat',
            'replayTracks': '.replays-container',
            'streamTracks': '.streams-container'
        },
        events: {
            'click .showLoginForm': 'showLoginForm'
        },
        initialize: function(options){
            this.layout = new Layout();
            this.collection = new Library();
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.client = new ImmerssClient();
            this.template = Handlebars.compile($('#playlistTmpl').text());
            this.bindEvents();
        },
        render: function(){
            chaplin.View.prototype.render.apply(this, arguments);
            if(Boolean(Immerss.hasExternalPlaylist)){
                this.subview(
                    'replays',
                    new ImmerssReplaysCollectionView(
                        {
                            region: 'replayTracks',
                            collection: this.collection,
                            client: this.client
                        }
                    )
                );
                this.subview(
                    'streams',
                    new ImmerssStreamsCollectionView(
                        {
                            region: 'streamTracks',
                            // collection: this.collection,
                            collection: new LiveLibrary(this.collection.models),
                            client: this.client
                        }
                    )
                );
                var that = this;
                this.collection.on('all', function(event, item){
                    that.subview('streams').collection.trigger(event, item);
                });
                this.collection.on('reset', function(data, item){
                    that.subview('streams').collection.reset(data.models);
                });
            }
            return this;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        getTemplateData: function(){
            var data = {};
            data.hasExternalPlaylist = Boolean(Immerss.hasExternalPlaylist);
            return data;
        },
        isChatAvailable: function(){
            var currentTrack = this.collection.currentTrack();
            return currentTrack.isStarted() && currentTrack.get('is_purchased') && !currentTrack.isFinished() && currentTrack.get('has_chat') && Immerss.hasChat;
        },
        isChatVisible: function(){
            var currentTrack = this.collection.currentTrack();
            return currentTrack.get('has_chat') && Immerss.hasChat;
        },
        isReplayChatAvailable: function(){
            var currentTrack = this.collection.currentTrack();
            return currentTrack.get('is_chat_available');
        },
        showLoginForm: function(e) {
          e.preventDefault();
          this.client.sendMessage('playlist.showLoginForm');
        },
        bindEvents: function(){
            this.listenTo(this.client, 'playlist.signedIn', function(data){
                window.location.reload();
            });
            this.listenTo(this.client, 'connected', function(){
                this.client.sendMessage('playlist.sync');
            });
            this.listenTo(this.client, 'playlist.sync', function(data){
                this.collection.reset(data.eventData.library);
                this.client.sendMessage('playlist.currentTrackRequest');
            });
            this.listenTo(this.client, 'playlist.changed', function(data){
                var id = Library.prototype.modelId(data.eventData.item);
                this.collection.get(id).set(data.eventData.changed);
            });
            this.listenTo(this.client, 'playlist.added', function(data){
                this.collection.add(data.eventData.item);
            });
            this.listenTo(this.client, 'playlist.removed', function(data){
                var id = Library.prototype.modelId(data.eventData.item);
                this.collection.remove(id);
            });
            this.listenTo(this.client, 'playlist.trackChanged playlist.currentTrackRequest', function(data){
                this.collection.setTrack(data.eventData.trackUniqId);
            });
            this.listenTo(this.collection, 'trackChanged', this.toggleChatVisibility);
        },
        toggleChatVisibility: function(){
            console.log('toggleChatVisibility');
            if (this.isChatVisible()) {
                // if chat is active(replay or running session)
                if (this.isChatAvailable()) {
                    // make chat tab active by default
                    this.$el.find('.cssTAb').addClass('active');
                    this.$el.find('.chatCover').hide();
                    this.$el.find('#tab-two').prop("checked", true);
                    if (Boolean(Immerss.hasExternalPlaylist)) {
                        // show toggle icon
                        this.$el.find('label[for="tab-one"] i, label[for="tab-two"] i').removeClass('hidden');
                    }
                    this.subview(
                        'chat',
                        new ImmerssChatView(
                            {
                                region: 'chatPlaceholder',
                                channelId: this.collection.currentTrack().get('webrtcservice_channel_id'),
                                track: this.collection.currentTrack()
                            }
                        )
                    );
                } else {
                    // if playlist present
                    if (Boolean(Immerss.hasExternalPlaylist)) {
                        // make playlist tab active by default and hide chat
                        this.$el.find('.cssTAb').removeClass('active');
                        this.$el.find('#tab-one').prop("checked", true);
                        this.$el.find('label[for="tab-one"] i').addClass('hidden');
                    } else {
                        // hide icon arrow and make chat active if no playlist
                        this.$el.find('.cssTAb').addClass('active');
                        this.$el.find('label[for="tab-two"] i').addClass('hidden');
                        this.$el.find('#tab-two').prop("checked", true);
                    }
                }
                if (!Boolean(Immerss.hasExternalPlaylist) && !this.isChatAvailable()) {
                  this.$el.find('.chatCover').show();
                }
            } else {
                this.removeSubview('chat');
                if (this.isReplayChatAvailable()) {
                    this.$el.find('.cssTAb').addClass('active');
                    this.$el.find('.chatCover').hide();
                    if (Boolean(Immerss.hasExternalPlaylist)) {
                      this.$el.find('label[for="tab-one"] i, label[for="tab-two"] i').removeClass('hidden');
                    }
                    this.$el.find('#tab-two').prop("checked", true);
                    this.subview(
                        'replay-chat',
                        new ImmerssReplayChatView(
                            {
                                region: 'chatPlaceholder',
                                chatChannelId: this.collection.currentTrack().get('chat_channel_id'),
                                client: this.client,
                                presenterId: this.collection.currentTrack().get('presenter_id')
                            }
                        )
                    );
                } else {
                    if (Boolean(Immerss.hasExternalPlaylist)) {
                        // make playlist tab active by default and hide icon arrow
                        this.$el.find('.cssTAb').removeClass('active');
                        this.$el.find('#tab-one').prop("checked", true);
                        this.$el.find('label[for="tab-one"] i').addClass('hidden');
                    }
                }
            }
        },
        dispose: function(){
            if(this.disposed)
                return;
            delete this.client;
            return chaplin.CollectionView.prototype.dispose.apply(this, arguments);
        }
    });

    window.ImmerssPlaylistView = ImmerssPlaylistView;
}(window);
