// requires jQuery
// requires backbonejs
//= require views/widgets/_playlist_dependencies/library
//= require views/widgets/_playlist_dependencies/server
//= require views/widgets/_playlist_dependencies/client

+function(window){
    "use strict";

    var ImmerssPlaylist = function(options){
        if(!_.isObject(options))
            options = {};
        this.options = _.extend({
            playerContainer: document.getElementById('player')
        }, options);
        this.library           = new Library();
        this.id                = _.uniqueId('ImmerssPlaylist-' + new Date().getTime().toString() + '-');
        this.player            = null;
        this.playlistServer    = new ImmerssServer();
        this.builtInPlaylist   = new BuildInPlaylistView({
            collection: this.library,
            playlistControl: this,
            tagName: 'div',
            className: 'tile_list_slider',
            region: 'main'
        });
        _.extend(this, Backbone.Events);
        this.bindEvents();
    };
    ImmerssPlaylist.prototype.bindEvents = function(){
        this.library.on('sync', this.playNextTrack, this);
        window.loginView.on('signedIn', function () {
          this.playlistServer.sendMessageToAllClients('playlist.signedIn', { user: Immerss.user });
        }, this);
        this.playlistServer.on('playlist.showLoginForm', function(data){
          window.loginView.toggle();
        }, this);
        this.playlistServer.on('playlist.sync', function(data){
            this.playlistServer.sendMessage(
                'playlist.sync',
                _.extend({ library: this.library.toJSON() }, { clientId: data.clientId })
            );
        }, this);
        this.library.on('change', function(item){
            this.playlistServer.sendMessageToAllClients('playlist.changed', { item: item.attributes, changed: item.changed });
        }, this);
        this.library.on('add', function(item){
            this.playlistServer.sendMessageToAllClients('playlist.added', { item: item.attributes });
        }, this);
        this.library.on('remove', function(item){
            this.playlistServer.sendMessageToAllClients('playlist.removed', { item: item.attributes });
            if(this.library.currentTrack().uniqId() === item.uniqId()){
                this.playNextTrack();
            }
        }, this);
        this.library.on('trackChanged', function(item){
            this.playlistServer.sendMessageToAllClients(
                'playlist.trackChanged',
                { trackUniqId: item.uniqId(), shopUrl: item.shopUrl() }
            );
        }, this);
        this.library.on('sync', function(){
            this.playlistServer.sendMessageToAllClients('playlist.sync', { library: this.library.toJSON() });
        }, this);
        this.playlistServer.on('playlist.trackChanged', function(data){
                this.changeTrack(data.eventData.trackUniqId);
        }, this);
        this.playlistServer.on('playlist.currentTrackRequest', function(data){
            this.playlistServer.sendMessage(
                'playlist.currentTrackRequest',
                _.extend(
                    { trackUniqId: this.library.currentTrack().uniqId(), shopUrl: this.library.currentTrack().shopUrl() },
                    { clientId: data.clientId }
                )
            );
        }, this);
    };
    ImmerssPlaylist.prototype.initPlayer = function(){
        var ButtonComponent, ImmerssButton, BuiltInPlaylistButton, that = this;
        this.player = new THEOplayer.Player(this.options.playerContainer, {
            license: window.ConfigFrontend.services.theo_player.license,
            libraryLocation: location.origin + "/javascripts/theo/",
            ui: {
                width: '100%',
                height: '100%',
                language: 'en',
                languages: {
                    "en": {
                        "The content will play in": "Starts in"
                    }
                }
            },
            isEmbeddable: true
        });
        var frameIndex = Object.keys(parent.frames).filter(i => Number.isInteger(+i))
        setInterval(() => {
            frameIndex.forEach(index => {
                if(parent.frames[index]) { // cors error if have frame[0]
                    if(!parent.frames[index][0] && parent.frames[index].spaMode) {
                        parent.frames[index].postMessage({
                            type: "playerTime",
                            data: this.player.ads.playing ? 0 : this.player.currentTime
                        })
                    }
                }
            })
        }, 1000)
        function customizeContextMenu(container) {
            var contextMenuLink = container.querySelector('.theo-context-menu-a');
            // change context menu href
            contextMenuLink.href = ConfigGlobal.host
            contextMenuLink.innerHTML = I18n.t('assets.javascripts.powered');
        }
        var element = document.querySelector('.videoContainer');
        customizeContextMenu(element);

        this.player.autoplay = false;
        this.player.muted = true;
        THEOplayer_UI_Hotkeys(this.player);
        THEOplayer_UI_Events(this.player);
        ButtonComponent = THEOplayer.videojs.getComponent('Button');
        BuiltInPlaylistButton = THEOplayer.videojs.extend(ButtonComponent, {
            constructor: function() {
                ButtonComponent.apply(this, arguments);
            },
            handleClick: function() {
                that.builtInPlaylist.toggle();
            },
            buildCSSClass: function () {
                return 'built-in-playlist'; // insert all class names here
            }
        });
        ImmerssButton = THEOplayer.videojs.extend(ButtonComponent, {
            constructor: function() {
                ButtonComponent.apply(this, arguments);
            },
            handleClick: function() {
                window.open(that.library.currentTrack().get('absolute_path') , '_blank');
            },
            buildCSSClass: function () {
                return 'logo'; // insert all class names here
            }
        });
        THEOplayer.videojs.registerComponent('ImmerssButton', ImmerssButton);
        THEOplayer.videojs.registerComponent('BuiltInPlaylistButton', BuiltInPlaylistButton);
        this.player.ui.getChild('controlBar').addChild('immerssButton', {});
        this.player.ui.getChild('controlBar').addChild('BuiltInPlaylistButton', {});
        this.player.addEventListener('ended', this.playNextTrack.bind(this));

        // http://demo.theoplayer.com/keeping-track-of-currenttime-timeupdate
        this.player.addEventListener('timeupdate', this.playTimeUpdated.bind(this));
        this.player.addEventListener('seeking', this.playSeeking.bind(this));

        this.player.addEventListener('error', function(e){
            var timeout =
                setTimeout(function(){
                    that.library.off(null, clearTimeoutCallback);
                    that.setPlayerSource(that.library.currentTrack());
                }, 10000),
                clearTimeoutCallback =
                    function(){
                        clearTimeout(timeout);
                    },
                currentTrack = that.library.currentTrack(),
                errorMessage;

            that.library.once('trackChanged', clearTimeoutCallback);

            errorMessage = that.player.element.parentNode.querySelector('.vjs-error-display .vjs-modal-dialog-content');
            if (errorMessage) {
                if(currentTrack){
                    if(currentTrack.isStreaming()){
                        errorMessage.innerText = "Live-stream interrupted. Trying to reconnect.";
                    }else{
                        errorMessage.innerText = "Video playback interrupted. Trying to reconnect.";
                    }
                }else{
                    errorMessage.innerText = "Error occurred during playback. Trying to reconnect.";
                }
            }
        });
        this.player.addEventListener('canplay', function(e) {
            $('.vjs-control-bar').addClass('active');
            setTimeout(function() {
                $('.vjs-control-bar').removeClass('active');
            }, 7000);
        });

        window.player = this.player
        if(window.addUsagePlayerListeners) window.addUsagePlayerListeners();
    };
    ImmerssPlaylist.prototype.playSeeking = function(event){
        if(this.player.ads.playing)
            return;
        this.playlistServer.sendMessageToAllClients(
            'player.seeking',
            { currentTime: this.player.currentTime.toFixed(2) }
        );
    };
    ImmerssPlaylist.prototype.playTimeUpdated = function(event){
        if(this.player.ads.playing)
            return;
        this.playlistServer.sendMessageToAllClients(
            'player.timeUpdated',
            { currentTime: this.player.currentTime.toFixed(2) }
        );
    };
    ImmerssPlaylist.prototype.playTimeUpdated = _.throttle(ImmerssPlaylist.prototype.playTimeUpdated, 1000);
    ImmerssPlaylist.prototype.playSeeking = _.throttle(ImmerssPlaylist.prototype.playSeeking, 1000);

    ImmerssPlaylist.prototype.playNextTrack = function(){
        this.player.currentTime = 0;
        this.setPlayerSource(this.library.nextTrack());
    };
    ImmerssPlaylist.prototype.playPrevTrack = function(){
        this.player.currentTime = 0;
        this.setPlayerSource(this.library.prevTrack());
    };
    ImmerssPlaylist.prototype.changeTrack = function(trackUniqId, options){
        this.setPlayerSource(this.library.setTrack(trackUniqId, options));
        if(this.library.currentTrack().isAdsAvailable()){
            this.player.currentTime = this.library.currentTrack().get('commercials_duration');
        } else {
            this.player.currentTime = 0;
        }
    };
    ImmerssPlaylist.prototype.setPlayerSource = function(track){
        if(!_.isNull(this.player)){
            this.player.source = track.toPlayerSource();
        }
    };
    window.ImmerssPlaylist = ImmerssPlaylist;
}(window);
