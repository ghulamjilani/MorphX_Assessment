//= require jquery2
//= require jquery-ui
//= require underscore
//= require js-routes
//= require backbone
//= require chaplin
//= require handlebars
//= require moment
//= require theoplayer/THEOplayer_lib
//= require theoplayer/bind_ui_buttons
//= require theoplayer/event_logs
//= require theoplayer/usage_logs
//= require views/widgets/_playlist_dependencies/build_in_playlist_view
//= require views/widgets/playlist
//= require views/widgets/_playlist_dependencies/playlist_cable_bindings
//= require views/widgets/_playlist_dependencies/livestream_view
//= require views/widgets/_playlist_dependencies/item_info_view
//= require cable
//= require i18n/translations
//= require plugins/owl.carousel
//= require_self

$(function(){
    "use strict";
    Handlebars.registerHelper({
        eq: function(v1, v2) {
            return v1 === v2;
        },
        ne: function(v1, v2) {
            return v1 !== v2;
        },
        lt: function(v1, v2) {
            return v1 < v2;
        },
        gt: function(v1, v2) {
            return v1 > v2;
        },
        lte: function(v1, v2) {
            return v1 <= v2;
        },
        gte: function(v1, v2) {
            return v1 >= v2;
        },
        and: function(v1, v2) {
            return v1 && v2;
        },
        or: function(v1, v2) {
            return v1 || v2;
        },
        not: function(v1) {
            return !v1;
        }
    });

    window.loginView = new LoginView();
    var playlist = new ImmerssPlaylist();
    if(Immerss.isLive){
        new PlaylistCableBindings(playlist);
        new LivestreamView(playlist);
    }
    new ItemInfoView(playlist);
    playlist.initPlayer();
    playlist.library.fetch({ reset: true });
    window.immerssPlaylistInstance = playlist;
});
