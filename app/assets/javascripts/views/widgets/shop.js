//= require jquery2
//= require underscore
//= require backbone
//= require views/widgets/_playlist_dependencies/client
//= require_self

$(function () {
    var immerssClient = new ImmerssClient(),
    currentUrl,
    $list = $('.list-item');
    immerssClient.on('connected', function(){
        immerssClient.on('playlist.trackChanged playlist.currentTrackRequest', function(data){
            if(currentUrl !== data.eventData.shopUrl){
                var timeStamp = new Date().getTime().toString();
                currentUrl = data.eventData.shopUrl;
                $.get(currentUrl + '?part=' + timeStamp).success(function(response){
                    $list.html(response);
                });
            }
        });
        immerssClient.sendMessage('playlist.currentTrackRequest');
    });
});
