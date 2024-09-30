(VidyoData = {
    loaded: false,
    inConference: false,
    room_info: null,
    vidyo_credentials: null,
    vidyo_connector: null,
    current_user: null,
    room_info_loaded: false,
    vidyo_lib_loaded: false,
    current_user_presenter: function () { return (VidyoData.current_user && VidyoData.current_user.role == 'presenter')},
    current_user_guest: function () {return VidyoData.current_user && (VidyoData.current_user.role == 'co_presenter' || VidyoData.current_user.role == 'participant')},
    check_full_load: function(){
        if (VidyoData.room_info_loaded && VidyoData.vidyo_lib_loaded){
            VidyoData.loaded = true;
            VidyoData.events.loaded();
        }
    },
    load_vidyo_lib: function(vc){
        VidyoData.vidyo_connector = vc;
        VidyoData.vidyo_lib_loaded = true;
        VidyoData.check_full_load();
     },
    load_room_info: function() {
        $.get('/rooms/' + Immerss.roomId, {}).success(function (response) {
            if (VidyoData.room_info_loaded == false){
                VidyoData.room_info = response.public_info;
                VidyoData.vidyo_credentials = response.vidyo || {};
                VidyoData.current_user = response.current_user;
                VidyoData.room_info_loaded = !!response.vidyo;
                VidyoData.check_full_load();
            }
        }).error(function () {
            $.showFlashMessage('Can\'t load room info', {type: 'error', timeout: 3000});
        });
    },
    events: {
        send: function(event_name){
            var event = new CustomEvent(event_name);
            document.dispatchEvent(event);
            console.log(event_name);
        },
        loaded: function () {
            VidyoData.events.send("vidyo_data_loaded")
        },
        vidyoConnected: function () {
            VidyoData.inConference = true;
            VidyoData.events.send("vidyo_connected")
        }
    }
}).load_room_info();
