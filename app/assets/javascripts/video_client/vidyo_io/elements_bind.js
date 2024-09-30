//= require video_client/vidyo_io/top
//= require video_client/vidyo_io/right
//= require video_client/websocket_events
websocket_events = function () {
    self = {};
    initWebsocketAndWait(self);
};


if (VidyoData.loaded){
    vidyo_ui_top_init();
    vidyo_ui_right_init();
    websocket_events();
}else{
    document.addEventListener("vidyo_data_loaded", function(e) {
        vidyo_ui_top_init();
        vidyo_ui_right_init();
        websocket_events();
    });
}

document.addEventListener("vidyo_connected", function(e) {
    show_main();
});



function show_main(){
    $('body').addClass('showVideo');
    $('#pluginWrap').css("width", "100%");
    $('#pluginWrap').css("height", "100%");
}


