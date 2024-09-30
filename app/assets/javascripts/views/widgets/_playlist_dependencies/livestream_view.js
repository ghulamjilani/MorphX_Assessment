+function (window) {
    "use strict";

    var OverlayView = Backbone.View.extend({
        tagName: 'div',
        region: '.overlay-container',
        id: 'playerCover',
        events: {
            'click .viewPlaylistBtn': 'toggleBuiltInPlaylist',
            'click .showLoginForm': 'toggleLoginView'
        },
        initialize: function () {
            this.template = Handlebars.compile($('#livestreamOverlayTmpl').text());
            this.isMinified = false;
            this.$region = $(this.region);
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            data.isStarted = this.model.isStarted();
            data.isFinished = this.model.isFinished();
            data.formattedStartAt = moment(this.model.get('start_at')).format('MMMM D, h:mm a');
            if(Immerss && Immerss.user && _.isNumber(Immerss.user.id)){
                data.userId = Immerss.user.id;
            }
            return data;
        },
        render: function () {
            var data = this.getTemplateData();
            this.$region.html(this.$el);
            this.$el.html(this.template(data));
            if (this.isMinified) {
                $('body').addClass('overlay-minified');
            } else {
                $('body').removeClass('overlay-minified');
            }
            this.initCountdown();
            return this;
        },
        renderWithModel: function (model, options) {
            if (_.isObject(options)) {
                this.isMinified = options.isMinified || false;
            } else {
                this.isMinified = false;
            }

            this.model = model;
            this.render();
            this.delegateEvents();
            $('.tile_list_slider').toggle($('.built-in-playlist-container').is(':visible'));
        },
        initCountdown: function () {
            clearInterval(this.interval);
            delete this.interval;

            var currentTime = new Date().getTime(),
                startAtTime = this.model.get('start_at'),
                duration = moment.duration(startAtTime - currentTime, 'milliseconds'),
                countDownFunc, formatCount;

            if(duration < 0) {
                return;
            }
            // if(duration.days() === 0) {
            //     this.$el.find('.days-left').remove();
            // }else{
            //     this.$el.find('.seconds-left').remove();
            // }
            countDownFunc = function(){
                duration = moment.duration(duration - 1000, 'milliseconds');
                if(duration < 0) {
                    clearInterval(this.interval);
                    delete this.interval;
                    this.render();
                }else{
                    this.$el.find('.count .days-left').text(formatCount(duration.days()));
                    this.$el.find('.count .hours-left').text(formatCount(duration.hours()));
                    this.$el.find('.count .minutes-left').text(formatCount(duration.minutes()));
                    this.$el.find('.count .seconds-left').text(formatCount(duration.seconds()));
                }
            }.bind(this);
            formatCount = function(number){
                if(number < 10){
                    return "0" + number
                }
                return number
            };
            countDownFunc();
            this.interval = setInterval(countDownFunc, 1000);
        },
        toggleBuiltInPlaylist: function () {
            $('.built-in-playlist-container, .tile_list_slider').toggle();
        },
        toggleLoginView: function (e) {
          e.preventDefault();
          this.trigger('toggleLoginView');
        }
    });

    var LivestreamView = function (playlist) {
        this.playlist = playlist;
        this.library = playlist.library;
        this.overlayView = new OverlayView();
        this.bindEvents();
    };
    LivestreamView.prototype.bindEvents = function () {
        this.library.on('trackChanged remove', function (item) {
            item = this.library.get(item.uniqId());
            if (item && (item.get('type') !== 'video' && (item.isUpcoming() || !item.get('livestream_url')))) {
                this.showUpcomingOverlay(item);
            } else {
                // Only show a minified overlay of upcoming stream if current track is not a live stream that is
                // in progress now and this is not replay
                if (this.library.upcomingStream() && item && item.get('type') !== 'video' && !this.library.currentTrack().isStreaming()) {
                    this.showUpcomingOverlay(this.library.upcomingStream(), { isMinified: true });
                } else {
                    this.overlayView.remove();
                }
            }
        }, this);
        this.library.on('change:start_at', function (item) {
            item = this.library.get(item.uniqId());
            if(item && this.overlayView.model){
                if(item.uniqId() === this.overlayView.model.uniqId()){
                    this.showUpcomingOverlay(item, { isMinified: this.overlayView.isMinified });
                }
            }
        }, this);
        this.library.on('change:livestream_up', function (item) {
            item = this.library.get(item.uniqId());
            if(item && item.get('is_purchased') && item.get('livestream_up') && this.overlayView.model){
                if(item.uniqId() === this.overlayView.model.uniqId()){
                    this.overlayView.remove();
                }
            }
        }, this);
        this.overlayView.on('toggleLoginView', function () {
          window.loginView.toggle();
        }, this);
    };
    LivestreamView.prototype.showUpcomingOverlay = function (item, options) {
        this.overlayView.renderWithModel(item, options);
    };

    window.LivestreamView = LivestreamView;
}(window);
