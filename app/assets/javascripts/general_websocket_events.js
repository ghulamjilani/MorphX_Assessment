//= require websocket_paypal_donation_listener
//= require_self


(function () {
    var disabledSessionsChannelChannel, homePageChannel, privateChannel,
        startAtUpdatesChannel, usersWithConfirmedEmailsChannel;

    var usersChannel, roomsChannel;

    if (window.Immerss.currentUserId) {
        privateChannel = initUsersChannel();
        privateChannel.bind(usersChannelEvents.newNotification, function (data) {
            var $notificationsPopup, template;
            $('.notification_count').attr('data-count', data.count).addClass('blink_me');
            $('#notificationsPopup .NT-header > p > span').html(data.count);
            $notificationsPopup = $('#notificationsPopup');
            $notificationsPopup.find('.fallback').remove();
            template = HandlebarsTemplates['application/newest_notification'];
            $notificationsPopup.find('ul').prepend(template(data));
            $notificationsPopup.find('.timeago:first').timeago();
        });
        privateChannel.bind(usersChannelEvents.newFlashbox, function (data) {
            if (data.flashbox) {
                $('.unobtrusive-flash-container').html(data.flashbox);
                $('.FlashBox:first-child').show();
                $('.FlashBox:first-child a[data-remote]').css('visibility', 'visible');
            }
        });
        privateChannel.bind(usersChannelEvents.backstageUpdateJoin, function (data) {
            console.log('asdasdasdasdas------');
            $.showFlashMessage(data.message, {
                type: 'info',
                timeout: 5000
            });
            $(".join-timer[data-roomid='" + data.room_id + "']").data('now', data.now).data('start-at', data.start_at);
            $(".time-to-start[data-roomid='" + data.room_id + "']").data('now', data.now).data('seconds', data.start_at);
        });
    }
    /*TODO: BUG HERE! next 'if' never true because of window.liveGuideView is undefined at this moment */
    if ($('body').hasClass('home-index') && window.liveGuideView) {
        window.sessionsChannel = initSessionsChannel();
        window.sessionsChannel.bind(sessionsChannelEvents.liveGuideForceRefresh, (data) => {
            liveGuideView.collection.fetchByDate(liveGuideView.options.dateString);
        });
    }

    roomsChannel = initRoomsChannel();
    roomsChannel.bind(roomsChannelEvents.update, function (data) {
        $(".join-timer[data-roomid='" + data.room_id + "']").data('now', data.now).data('start-at', data.start_at);
        window.initializeJoinTimer();
    });
    roomsChannel.bind(roomsChannelEvents.disable, function (data) {
        $(".join-timer[data-roomid='" + data.room_id + "']").fadeOut();
    });

    usersChannel = initUsersChannel();
    usersChannel.bind(usersChannelEvents.confirmed, function (data) {
        if (Immerss.currentUserId === data.user_id) {
            window.previewPurchaseMissingConfirmedEmailView.emailHasBeenConfirmed();
        }
    });

    var sessionId = null;
    if (window.Immerss && window.Immerss.session) {
        sessionId = window.Immerss.session.id;
    }
    window.publicSessionsChannel = initSessionsChannel(sessionId);
    window.publicSessionsChannel.bind(sessionsChannelEvents.livestreamMembersCount, function (data) {
        var $playlist_tile, $tile, viewers;
        console.log('Session: ' + data.session_id + ' --- livestream_members_count: ' + data.count);
        $tile = $("#session_tile_" + data.session_id);
        viewers = data.count || 0;
        $tile.find('.sessionStatus .liveViewers').html("<i class=\"VideoClientIcon-Views\"></i> " + viewers);
        if ($('body').hasClass('session_or_replay_or_recording') && Immerss.sessionId === data.session_id) {
            $('#main_panel_head .viewsCount').html("<i class=\"VideoClientIcon-Views\"></i> " + data.count);
        }
        $playlist_tile = $("#MV_Upcoming .tile-cake-sidebarrr.session-tile[data-id=" + data.session_id + "]");
        if ($playlist_tile) {
            $playlist_tile.find('.participants').html("<i class=\"VideoClientIcon-Views fs-20 vertical-sub\"></i> " + data.count);
        }
    });
    window.publicSessionsChannel.bind(sessionsChannelEvents.livestreamUp, function (data) {
        var $playlist_tile, $tile;
        console.log(['livestream-up', data]);
        $tile = $("#session_tile_" + data.session_id);
        if ($tile) {
            $tile.find('.sessionStatus .sessionStatus-red').removeClass('hidden');
            $tile.find('.sessionStatus span').text('Live');
            $tile.find('.timer').addClass('hidden');
        }
        $playlist_tile = $("#MV_Upcoming .tile-cake-sidebarrr.session-tile[data-id=" + data.session_id + "]");
        if ($playlist_tile) {
            $playlist_tile.find('.tileStatus.timer').addClass('tileStatus-red').html('LIVE');
            $playlist_tile.find('.tileStatus.timer').show();
            $playlist_tile.find('.time.tileTimeStatus-now').show();
            $playlist_tile.find('.time.date_text').hide();
        }
    });

    /*
        Changes the status on the session tiles (home page, search, channel, playlist, etc.) when the session started.
    */
    window.publicSessionsChannel.bind(sessionsChannelEvents.sessionStarted, function (data) {
        var $btn, $playlist_tile, $tile, session_id;
        console.log(['session-started', data]);
        session_id = data.session_id;
        $tile = $("#session_tile_" + session_id);
        if ($tile) {
            $tile.find('.timer').addClass('hidden');
            $tile.find('.remind_me').remove();
            $btn = $tile.find('.tile-btns > a');
            if ($btn) {
                $.ajax({
                    type: 'GET',
                    url: Routes.get_join_button_session_path(session_id),
                    dataType: 'json',
                    contentType: 'application/json',
                    success: function (data) {
                        var attrs, btn_text;
                        attrs = data.url_attributes;
                        btn_text = (attrs.status === 'running' || attrs.status === 'started') && attrs.type === 'immersive' ? 'Join' : attrs.text;
                        $btn.html(btn_text);
                        if (attrs.status === 'running' || attrs.status === 'started' && attrs.presenter) {
                            $btn.attr('onclick', attrs.onclick);
                            $btn.attr('data-href', $btn.attr('href'));
                            $btn.attr('href', '#');
                            $btn.removeAttr('disabled');
                            $btn.removeClass('btn-borderred-grey');
                        } else if (attrs.status === 'cancelled') {
                            $btn.removeClass('btn-borderred-grey').addClass('btn-red');
                        } else if (attrs.status === 'completed') {
                            $btn.removeClass('btn-borderred-grey').addClass('btn-green');
                        }
                        $tile.find('.sessionStatus-red').removeClass('hidden').find('span').text('Live');
                        $tile.find('.tile-type').remove();
                        $tile.find('.timer').addClass('hidden');
                    }
                });
            }
        }
        $playlist_tile = $("#MV_Upcoming .tile-cake-sidebarrr.session-tile[data-id=" + session_id + "]");
        if ($playlist_tile) {
            $playlist_tile.find('.tileStatus').hide();
            $playlist_tile.find('.time.tileTimeStatus-now').show();
            $playlist_tile.find('.time.date_text').hide();
        }
    });

    /*
        Changes the status on the session tiles (home page, search, channel, playlist, etc.) when the session stopped.
    */
    window.publicSessionsChannel.bind(sessionsChannelEvents.sessionStopped, function (data) {
        var $playlist_tile, $tile, session_id;
        console.log(['session-stopped', data]);
        session_id = data.session_id;
        $tile = $("#session_tile_" + session_id);
        if ($tile) {
            $tile.find('.joinbtn, .remind_me, .timeCount.timer').remove();
            $tile.find('.tile-type').remove();
            $tile.find('.sessionStatus').removeClass('hidden').removeClass('sessionStatus-red').addClass('session-white').find('span').text('Completed');
            $tile.find('.sessionStatus .liveViewers').addClass('hidden');
        }
        $playlist_tile = $("#MV_Upcoming .tile-cake-sidebarrr.session-tile[data-id=" + session_id + "]");
        if ($playlist_tile) {
            $playlist_tile.find('.tileStatus .tileStatus-red').remove();
            $playlist_tile.find('.tileStatus .tileStatus-status').html('Completed');
            $playlist_tile.find('.time.tileTimeStatus-now').hide();
            $playlist_tile.find('.time.date_text').show();
        }
    });
    window.publicSessionsChannel.bind(sessionsChannelEvents.sessionCancelled, function (data) {
        var $playlist_tile, $tile, session_id;
        console.log(['session-cancelled', data]);
        session_id = data.session_id;
        $tile = $("#session_tile_" + session_id);
        if ($tile) {
            $tile.find('.joinbtn, .remind_me, .timeCount.timer').remove();
            $tile.find('.sessionStatus').removeClass('hidden');
            $tile.find('.sessionStatus').html('<span>Cancelled</span>');
        }
        $playlist_tile = $("#MV_Upcoming .tile-cake-sidebarrr.session-tile[data-id=" + session_id + "]");
        if ($playlist_tile) {
            $playlist_tile.find('.tileStatus .tileStatus-red').remove();
            $playlist_tile.find('.tileStatus .tileStatus-timer').remove();
            $playlist_tile.find('.tileStatus .tileStatus-status').html('Cancelled');
            $playlist_tile.find('.time.tileTimeStatus-now').hide();
            $playlist_tile.find('.time.date_text').show();
        }
    });
}).call(this);
