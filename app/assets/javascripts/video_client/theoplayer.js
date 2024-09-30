window.initTheOplayer = function(url, append) {
    var element, player;
    if (append == null) {
        append = '#jwplayer_data_contaioner';
    }
    element = document.createElement('div');
    element.className = 'video-js theoplayer-skin theo-seekbar-above-controls';
    $(append).html(element);
    player = new THEOplayer.Player(element, {
        license: window.ConfigFrontend.services.theo_player.license,
        libraryLocation: location.origin + "/javascripts/theo/",
        ui: {
            width: '100%',
            height: '100%',
            fluid: true,
            fullscreen: {
                fullscreenOptions: {
                    navigationUI: "auto"
                }
            }
        }
    });
    player.autoplay = true;
    player.muted = true;
    THEOplayer_UI_Hotkeys(player);
    THEOplayer_UI_Events(player);

    // // chaanges for context menu
    // function customizeContextMenu(container) {
    //     var contextMenuLink = container.querySelector('.theo-context-menu-a');
    //     // change context menu href
    //     contextMenuLink.href = 'https://unite.live';
    //     contextMenuLink.innerHTML = "Powered by UNITE";
    // }
    // var element = document.querySelector('.videoContainer');
    // customizeContextMenu(element);

    return player
};
