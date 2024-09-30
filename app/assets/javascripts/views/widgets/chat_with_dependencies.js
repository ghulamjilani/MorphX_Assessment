//= require jquery2
//= require underscore
//= require backbone
//= require chaplin
//= require handlebars
//= require dom_purify
//= require anchorme
//= require views/widgets/webrtcservice/emojies
//= require views/widgets/webrtcservice/chat
//= require_self

$(function(){
    "use strict";
    var Layout = chaplin.Layout.extend({
        regions: {
            'chatPlaceholder': '.standalone-chat'
        }
    });
    new Layout();
    new ImmerssChatView(
        {
            region: 'chatPlaceholder',
            channelId: Immerss.webrtcserviceChannelId
        }
    )

    $(document).on('click', '.standalone-chat .authorization .showLoginForm', function(e) {
        e.preventDefault();
        window.parent.postMessage({type: 'openLoginPopup'}, '*');
    });
});
