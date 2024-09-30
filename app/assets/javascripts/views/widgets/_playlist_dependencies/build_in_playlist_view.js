+function(){
    "use strict";
    var Layout = chaplin.Layout.extend({
        regions: {
            'main': '.built-in-playlist-container'
        }
    });
    var BuildInPlaylistItemView = chaplin.View.extend({
        tagName: 'div',
        events: {
            "click .tile": "changeTrack"
        },
        autoRender: true,
        autoAttach: true,
        initialize: function(options){
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#builtInPlaylistItemTmpl').text());
        },
        getTemplateFunction: function(){
            return this.template;
        },
        getTemplateData: function(){
            var data = this.model.toJSON();
            data.isPlaying = this.model.isPlaying();
            return data;
        },
        changeTrack: function(e){
            e.preventDefault();
            this.playlistControl.changeTrack(this.model.uniqId());
        }
    });

    var BuildInPlaylistCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        listSelector: '.tile_list_slider_body',
        itemView: BuildInPlaylistItemView,
        events: {
            "click .closePlaylistBtn": "toggle"
        },
        initialize: function(options){
            this.layout = new Layout();
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.playlistControl = options.playlistControl;
            this.bindEvents();
            this.template = Handlebars.compile($('#builtInPlaylistCollectionTmpl').text());
            this.isVisible = false;
        },
        render: function(){
            chaplin.CollectionView.prototype.render.apply(this, arguments);
        },
        getTemplateData: function(){
            var data = {};
            return data;
        },
        getTemplateFunction: function(){
            return this.template;
        },
        bindEvents: function(){
            this.listenTo(this.collection, 'trackChanged trackStoppedPlaying', this.renderItem);
            this.listenTo(this.collection, 'trackChanged', this.refreshCarouselPosition);
            this.listenTo(this.collection, 'reset sort', this.initCarousel);
            this.listenTo(this.collection, 'trackChanged', this.changeVisibility);
        },
        changeVisibility: function(){
            this.$el.toggle($('.built-in-playlist-container').is(':visible'));
        },
        toggle: function(){
            $('.built-in-playlist-container').toggle();
            this.$el.toggle();
            this.isVisible = $('.built-in-playlist-container').is(':visible');
        },
        initItemView: function(){
            var itemView;
            itemView = chaplin.CollectionView.prototype.initItemView.apply(this, arguments);
            itemView.playlistControl = this.playlistControl;
            return itemView;
        },
        initCarousel: function () {
            this.$el.find('.tile_list_slider_body').trigger('destroy.owl.carousel');
            this.$el.find('.tile_list_slider_body').owlCarousel({
                loop: false,
                margin: 11,
                nav: true,
                navText: '',
                center: false,
                responsive:{
                    0: {
                        items: 2
                    },
                    500: {
                        items: 4
                    },
                    1000: {
                        items: 6
                    }
                }
            });
            this.refreshCarouselPosition();
        },
        refreshCarouselPosition: function () {
            var index = this.collection.models.indexOf(this.collection.currentTrack());

            if(index === -1)
                index = 0;

            this.$el.find('.tile_list_slider_body').trigger(
                'to.owl.carousel',
                [index, 300, true]
            );
        }
    });
    window.BuildInPlaylistView = BuildInPlaylistCollectionView;
}();
