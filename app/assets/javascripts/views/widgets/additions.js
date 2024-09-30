//= require jquery2
//= require underscore
//= require backbone
//= require chaplin
//= require handlebars
//= require dom_purify
//= require anchorme
//= require moment
//= require views/widgets/webrtcservice/emojies
//= require views/widgets/webrtcservice/chat
//= require views/widgets/_playlist_dependencies/client
//= require views/widgets/_playlist_dependencies/library
//= require views/widgets/_playlist_dependencies/replay_chat_view
//= require views/widgets/_playlist_dependencies/playlist_view
//= require_self

$(function(){
    "use strict";
    new ImmerssPlaylistView({tagName: 'div', className: 'tile-cake-list', region: 'main'});
});
