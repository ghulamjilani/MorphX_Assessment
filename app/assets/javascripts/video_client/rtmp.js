window.bindEventsStreamButtons = function () {
    window.check_immerss_active = function(){
        if ($('#start_immerss').length){
            if($('#start_immerss').hasClass('active')){
                $('#platformsCover').removeClass('WaitStreamStart');
                return true
            }else{
                //$.showFlashMessage('Please start immerss stream before.',{type: 'error', timeout: 3000})
                $('#platformsCover').addClass('WaitStreamStart');
                return false
            }
        }else{
            $('#platformsCover').removeClass('WaitStreamStart');
            return true
        }
    };
    check_immerss_active();

    if (Immerss.presenter){
        // window.setInterval(function () {
        //     if (!$('#start_youtube').hasClass('error')){
        //         $.post('/lobbies/' + Immerss.roomId + '/stream_alive', {provider: 'youtube'}).success(function (response) {
        //             $('#start_youtube').addClass('active');
        //             $('#start_youtube').html('Stop Sharing');
        //         }).error(function (response) {
        //             $('#start_youtube').removeClass('active');
        //             $('#start_youtube').html('Start Sharing');
        //         });
        //     }
        //     setTimeout(function() {
        //         $.post('/lobbies/' + Immerss.roomId + '/stream_alive', {provider: 'facebook'}).success(function (response) {
        //             $('#start_facebook').addClass('active');
        //             $('#start_facebook').html('Stop Sharing');
        //         }).error(function (response) {
        //             $('#start_facebook').removeClass('active');
        //             $('#start_facebook').html('Start Sharing');
        //         });
        //     }, 1000);
        //     setTimeout(function() {
        //         $.post('/lobbies/' + Immerss.roomId + '/stream_alive', {provider: 'immerss'}).success(function (response) {
        //             $('#start_immerss').addClass('active');
        //             $('#start_immerss').html('Stop Stream');
        //             check_immerss_active();
        //         }).error(function (response) {
        //             $('#start_immerss').removeClass('active')
        //             $('#start_immerss').html('Start Stream');
        //         });
        //     }, 2000);
        // }, 10000);

        $(document).on("click", "#start_youtube", function (e) {
            e.preventDefault();
            var $this = $(this);
            if (!check_immerss_active()){
                return true
            }
            var $loadtag = $this.parents('.row:first');
            if ($loadtag.hasClass('Connecting')) {
                return true
            }
            $loadtag.addClass('Connecting');


            if ($this.hasClass('active')) {
                $.post('/lobbies/' + Immerss.roomId + '/stop_stream', {provider: 'youtube'}).success(function (response) {
                    $this.removeClass('active');
                    $this.html('Start Sharing');
                }).error(function () {
                    $this.html('Stop Sharing');
                }).complete(function () {
                    $loadtag.removeClass('Connecting');
                });
            } else if ($this.hasClass('error')) {
                $loadtag.removeClass('Connecting');
                var win = window.open('/users/auth/gplus?youtube', '', 'width=1020, height=600')
                var timer = setInterval(function() {
                    if(win.closed) {
                        clearInterval(timer);
                        $.post('/lobbies/' + Immerss.roomId + '/has_youtube_access', {}).success(function (response) {
                            $this.removeClass('error');
                            $this.html('Start Sharing');
                        });
                    }
                }, 1000);
            } else {
                $.post('/lobbies/' + Immerss.roomId + '/start_youtube_stream', {}).success(function (response) {
                    $this.addClass('active');
                    $this.html('Stop Sharing');
                }).error(function () {
                    $this.html('Start Sharing');
                }).complete(function () {
                    $loadtag.removeClass('Connecting');
                });
            }
        });


        $(document).on("click", "#start_immerss", function (e) {
            e.preventDefault();

            var $this = $(this);
            var $loadtag = $this.parents('.row:first');
            if ($loadtag.hasClass('Connecting')) {
                return true
            }
            $loadtag.addClass('Connecting');


            if ($this.hasClass('active')) {
                $.post('/lobbies/' + Immerss.roomId + '/stop_stream', {provider: 'immerss'}).success(function (response) {
                    $this.removeClass('active');
                    $this.html('Start Stream');
                }).error(function () {
                    $this.html('Stop Stream');
                }).complete(function () {
                    $loadtag.removeClass('Connecting');
                    check_immerss_active();
                });
            } else if ($this.hasClass('error')) {
                $loadtag.removeClass('Connecting');
                $.showFlashMessage('You can do that', {type: 'info', timeout: 7000});
            } else {
                $.post('/lobbies/' + Immerss.roomId + '/start_immerss_stream', {}).success(function (response) {
                    $this.addClass('active');
                    $this.html('Stop Stream');
                    $('.noActiveStream .loadSpin').removeClass('hide');
                }).error(function () {
                    $this.html('Start Stream');
                }).complete(function () {
                    $loadtag.removeClass('Connecting');
                    check_immerss_active();
                });
            }
        });


        $(document).on("click", "#start_facebook", function (e) {
            e.preventDefault();

            if (!check_immerss_active()){
                return true
            }

            var $this = $(this);

            var $loadtag = $this.parents('.row:first');
            if ($loadtag.hasClass('Connecting')) {
                return true
            }
            $loadtag.addClass('Connecting');

            if ($this.hasClass('active')) {
                $.post('/lobbies/' + Immerss.roomId + '/stop_stream', {provider: 'facebook'}).success(function (response) {
                    $this.removeClass('active')
                    $this.html('Start Sharing');
                }).error(function (response) {
                    $this.html('Stop Sharing');
                }).complete(function () {
                    $loadtag.removeClass('Connecting');
                });
            } else {
                FB.ui({
                    display: 'popup',
                    method: 'live_broadcast',
                    phase: 'create',
                }, function (response) {
                    if (!response.id) {
                        $loadtag.removeClass('Connecting');
                        return;
                    }
                    $.post('/lobbies/' + Immerss.roomId + '/start_fb_stream', {url: response.secure_stream_url});
                    FB.ui({
                        display: 'popup',
                        method: 'live_broadcast',
                        phase: 'publish',
                        broadcast_data: response,
                    }, function (response) {
                        $this.addClass('active');
                        $loadtag.removeClass('Connecting');
                        $this.html('Stop Sharing');
                    });
                });

            }
        });
    }

};