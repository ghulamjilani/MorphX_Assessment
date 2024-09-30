//= require views/widgets/_playlist_dependencies/ads_helper
//= require views/widgets/_playlist_dependencies/purchase_tmpl_helper

+function(window){
    "use strict";

    var Session = Backbone.Model.extend({
        initialize: function(){
            this._isPlaying = false;
        },
        toPlayerSource: function(){
            this.addPurchaseTmpl();
            if(this.isStreaming()){
                return {
                    poster: this.get('poster_url'),
                    sources: [
                        {
                            src: this.get('livestream_url'),
                            type: 'application/x-mpegurl'
                        }
                    ],
                    ads: [{
                        sources: this.adsUrl(),
                        timeOffset: 'start'
                    }]
                };
            }else{
                return {
                    poster: this.get('poster_url'),
                    sources: [
                        {
                            src: this.get('playback_url')
                        }
                    ]
                };
            }
        },
        isFinished: function(){
            return this.get('is_finished');
        },
        isStarted: function(){
            return this.get('start_at') <= new Date();
        },
        isPlayable: function(){
            //return this.isStreaming() || _.isString(this.get('playback_url'));
            return true;
        },
        isStreaming: function(){
            return this.isStarted() && !this.isFinished() && this.get('is_room_active');
        },
        isUpcoming: function(){
            return !this.isFinished() && !this.get('is_room_active');
        },
        parse: function(data, options){
            data.start_at = new Date(data.start_at);
            return data;
        },
        uniqId: function(){
            return Library.prototype.modelId(this.attributes);
        },
        isPlaying: function(){
            return this._isPlaying;
        },
        setPlaying: function(){
            this._isPlaying = true;
        },
        unsetPlaying: function(){
            this._isPlaying = false;
        },
        shopUrl: function(){
            return "/widgets/" + this.get('id') + "/session/shop";
        },
        isAdsAvailable: function(){
            return _.isString(this.get('commercials_url')) && _.isString(this.get('commercials_mime_type'))
                && _.isNumber(this.get('commercials_duration'));
        },
        adsUrl: function(){
            if(this.isAdsAvailable()){
                return window.getAdsUrl(_.clone(this.attributes));
            }
        },
        addPurchaseTmpl: function () {
            window.putPurchaseTmpl(this.attributes)
        }

    });
    var Video = Backbone.Model.extend({
        initialize: function(){
            this._isPlaying = false;
        },
        toPlayerSource: function(){
            this.addPurchaseTmpl();
            return {
                poster: this.get('poster_url'),
                sources: [
                    {
                        src: this.get('playback_url')
                    }
                ],
                ads: [{
                    sources: this.adsUrl(),
                    timeOffset: 'start'
                }]
            };

        },
        isPlayable: function(){
            return true;
        },
        parse: function(data, options){
            data.created_at = new Date(data.created_at);
            return data;
        },
        uniqId: function(){
            return Library.prototype.modelId(this.attributes);
        },
        isPlaying: function(){
            return this._isPlaying;
        },
        setPlaying: function(){
            this._isPlaying = true;
        },
        unsetPlaying: function(){
            this._isPlaying = false;
        },
        isStreaming: function(){
            return false;
        },
        isUpcoming: function(){
            return false;
        },
        isStarted: function(){
            return true;
        },
        isFinished: function(){
            return false;
        },
        shopUrl: function(){
            return "/widgets/" + this.get('id') + "/" + this.get('type') + "/shop";
        },
        isAdsAvailable: function(){
            return _.isString(this.get('commercials_url')) && _.isString(this.get('commercials_mime_type'))
                && _.isNumber(this.get('commercials_duration'));
        },
        adsUrl: function(){
            if(this.isAdsAvailable()){
                return window.getAdsUrl(_.clone(this.attributes));
            }
        },
        addPurchaseTmpl: function () {
            window.putPurchaseTmpl(this.attributes)
        }
    });
    var DummyVideo = Backbone.Model.extend({
        initialize: function(){
            this._isPlaying = false;
        },
        toPlayerSource: function(){
            return void(0);
        },
        isPlayable: function(){
            return true;
        },
        uniqId: function(){
            return 'dummyVideo';
        },
        isPlaying: function(){
            return this._isPlaying;
        },
        setPlaying: function(){
            this._isPlaying = true;
        },
        unsetPlaying: function(){
            this._isPlaying = false;
        },
        isStreaming: function(){
            return false;
        },
        isUpcoming: function(){
            return false
        },
        shopUrl: function(){
            return '';
        }
    });
    var Library = Backbone.Collection.extend({
        url: Immerss.playlistUrl,
        comparator: 'position',
        // comparator: function(item){
        //     return -item.get('position');
        // },
        initialize: function(){
            this.on('change:start_at change:created_at', this.sort);
            this._currentTrack = new DummyVideo();
        },
        model: function(attrs, options){
            switch(attrs.type) {
                case 'session':
                    return new Session(attrs, { parse: true });
                case 'video':
                    return new Video(attrs, { parse: true });
                case 'recording':
                    return new Video(attrs, { parse: true });
                default:
                    throw "Don't know how to handle Library record with type " + attrs.type;
            }
        },
        modelId: function(attrs){
            return attrs.type + attrs.id;
        },
        nextTrack: function(){
            var that = this,
                nextTrack;
            // check if this is initial(dummy) video and force first track finder
            if(this._currentTrack.uniqId() == 'dummyVideo') {
                return this.setFirstTrack();
            }else{
                nextTrack = this.find(function(item){
                    return item.isPlayable() && that.indexOf(item) > that.indexOf(that._currentTrack);
                });
            }
            if(nextTrack){
                return this.setTrack(nextTrack.uniqId());
            }else{
                return this.setFirstTrack();
            }
        },
        currentTrack: function(){
            return this._currentTrack;
        },
        prevTrack: function(){
            var that = this,
                prevTrack;
            prevTrack = this.find(function(item){
                return item.isPlayable() && that.indexOf(item) < that.indexOf(that._currentTrack);
            });
            if(prevTrack){
                return this.setTrack(prevTrack.uniqId());
            }else{
                return this.setFirstTrack();
            }
        },
        setFirstTrack: function(){
            var firstTrack;
            // Try to find active stream and always play it
            firstTrack = this.find(function(item){
                return item.isPlayable() ;
            });
            // if(!firstTrack) {
            //     firstTrack = this.find(function (item) {
            //         return item.isPlayable() && item.isStreaming();
            //     });
            // }
            if(firstTrack){
                return this.setTrack(firstTrack.uniqId());
            }
            return this._currentTrack;
        },
        setTrack: function(trackUniqId, options){
            if(!options)
                options = { trigger: true };
            this._currentTrack.unsetPlaying();
            if(options.trigger)
                this.trigger('trackStoppedPlaying', this._currentTrack);
            this._currentTrack = this.get(trackUniqId) || this._currentTrack;
            this._currentTrack.setPlaying();
            if(options.trigger)
                this.trigger('trackChanged', this._currentTrack);
            return this._currentTrack;
        },
        upcomingStream: function(){
            return this.find(function(item){
                return item.isUpcoming();
            });
        }
    });

    window.Library = Library;

    var LiveLibrary = Library.extend({
        comparator: function(item){
            return item.get('position');
        }
    });
    window.LiveLibrary = LiveLibrary;

}(window);
