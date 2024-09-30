if (typeof VidyoData === 'undefined') {
    VidyoData = {
        room_info: {},
        current_user_guest: function () {false},
        current_user_presenter: function () {false},
    }
}

var addNewMember = function(member_id, doesHaveToShow){
    var imm_room_id = Immerss.roomId || VidyoData.room_info.id;
    if ($('.offline_' + member_id).length == 0) {
        refreshManagerPanel();
        $.get("/lobbies/" + imm_room_id + "/add_member.json?member_id=" + member_id, function(response) {
            var template = response.template;

            switch (response.role) {
                case("presenter"):
                    $(".presenterBox").append(template);
                    break;
                case("co_presenter"):
                    $(".CopresenterBox").show();
                    $(".CopresenterBox").append(template);
                    break;
                default:
                    $(".participantBox ul.slides").append(template);
            }
            if(doesHaveToShow)
                $('.offline_' + member_id).hide();
        });
    }else{
        $('.offline_' + member_id).hide();
    }
};


 function refreshManagerPanel(){
    var imm_role_presenter = Immerss.presenter || VidyoData.current_user_presenter();
    var imm_room_id = Immerss.roomId || VidyoData.room_info.id;
    console.log(VidyoData.current_user_presenter());
    if(imm_role_presenter){
        return $.get("/lobbies/" + imm_room_id + "/refresh_manager_panel");
    }
};
window.initWebsocketAndWait = function (self) {
    var imm_role_presenter = Immerss.presenter || VidyoData.current_user_presenter();
    var imm_role_guest = Immerss.guest || VidyoData.current_user_guest();
    var imm_room_id = Immerss.roomId || VidyoData.room_info.id;
    var channel_name  = Immerss.channelName || 'presence-immersive-room'
    var current_user_id = Immerss.currentUserId || VidyoData.current_user.id;

    /*
        PresenceImmersiveRoomsChannel
        presence-immersive-room- + id

        and
        presence-source-room- + room.id
    */

    self.websocketChannel = channel_name.includes('presence-source') ? initPresenceSourceRoomsChannel(imm_room_id) : initPresenceImmersiveRoomsChannel(imm_room_id)

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.remoteControl, function (data) {
        if (current_user_id == data.user_id) {
            switch (data.button) {
                case 'mute':
                    self.cache.$inCallButtonMuteMicrophone.trigger('click');
                    break;
                case 'unmute':
                    self.cache.$inCallButtonMuteMicrophone.trigger('click');
                    break;
                case 'start_video':
                    self.cache.$inCallButtonMuteVideo.trigger('click');
                    break;
                case 'stop_video':
                    self.cache.$inCallButtonMuteVideo.trigger('click');
                    break;
                case 'full_screen':
                    self.cache.$inCallButtonFullscreen.trigger('click');
                    break;
                default:
                    logger.log('error', 'ui','unknown button:', button);
            }
        }
    });
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.allowControl, function (data) {
        logger.log('info', 'cable','trigger:allow_control');
        if (current_user_id == data.user_id) {
            var usersList = $(".CopresenterBox .member, .participantBox .member");
            usersList.find(".user-control").removeClass("disabled");
            usersList.find(".control-list").show();
        }
    });
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.livestreamMembersCount, function (data) {

        var count = self.websocketChannel.listenersCount;
        $('.immersiveIcon').html(count);

        logger.log('info', 'cable','trigger:livestream_members_count');
        $('.livestreamIcon').html(data.count);
        clearTimeout(window.memberCountTimeoutId);
        window.memberCountTimeoutId = setTimeout(function(){
            $('.livestreamIcon').html(0);
        }, 40000)
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.disableControl, function (data) {
        logger.log('info', 'cable','trigger:allow_control');
        if (current_user_id == data.user_id) {
            var usersList = $(".CopresenterBox .member, .participantBox .member");
            usersList.find(".user-control").addClass("disabled");
            usersList.find(".control-list").hide();
        }
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.micChanged, function (data) {
        $.each(data.users, function(index, user_id){
            var userContainer = $("#member-" + user_id + ",#member-source-" + user_id);
            if(data.status == 'disabled'){
                userContainer.find('.microphone-on').attr('disabled', false).show();
                userContainer.find('.microphone-off').attr('disabled', false).hide();
            }else{
                userContainer.find('.microphone-on').attr('disabled', false).hide();
                userContainer.find('.microphone-off').attr('disabled', false).show();
            }
            if (current_user_id == user_id) {
                $.showFlashMessage(I18n.t('video.mic_'+ data.status), {type: 'info', timeout: 3000})
            }
        });
        var urlMuteAllSound = '/lobbies/' + imm_room_id + '/mute_all';
        var urlUnMuteAllSound = '/lobbies/' + imm_room_id + '/unmute_all';
        if (data.all && imm_role_presenter){
            if(data.status == 'disabled'){
                $('#groupSettings .users-group .users-group-mic').removeClass('groupSettings-Vol-off').addClass('groupSettings-Vol-on').attr("href", urlUnMuteAllSound);
            }else{
                $('#groupSettings .users-group .users-group-mic').addClass('groupSettings-Vol-off').removeClass('groupSettings-Vol-on').attr("href", urlMuteAllSound);
            }
        }
        refreshManagerPanel();
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.videoChanged, function (data) {
        $.each(data.users, function(index, user_id){
            var userContainer = $("#member-" + user_id + ",#member-source-" + user_id);
            if(data.status == 'disabled'){
                userContainer.find('.video-on').attr('disabled', false).show();
                userContainer.find('.video-off').attr('disabled', false).hide();
            }else{
                userContainer.find('.video-on').attr('disabled', false).hide();
                userContainer.find('.video-off').attr('disabled', false).show();
            }
            if (current_user_id == user_id) {
                $.showFlashMessage(I18n.t('video.cam_'+ data.status), {type: 'info', timeout: 3000})
            }
        });

        var urlMuteAllVideo = '/lobbies/' + imm_room_id + '/stop_all_videos';
        var urlUnMuteAllVideo = '/lobbies/' + imm_room_id + '/start_all_videos';

        if (data.all && imm_role_presenter){
            if(data.status == 'disabled'){
                $('#groupSettings .users-group .users-group-video').removeClass('groupSettings-Vid-off').addClass('groupSettings-Vid-on').attr("href", urlUnMuteAllVideo);
            }else{
                $('#groupSettings .users-group .users-group-video').addClass('groupSettings-Vid-off').removeClass('groupSettings-Vid-on').attr("href", urlMuteAllVideo);
            }
        }
        refreshManagerPanel();
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.backstageChanged, function (data) {
        $.each(data.users, function(index, user_id){
            var userContainer = $("#member-" + user_id);
            if(data.status == 'disabled'){
                userContainer.find('.backstage-on').attr('disabled', false).show();
                userContainer.find('.backstage-off').attr('disabled', false).hide();
            }else{
                userContainer.find('.backstage-on').attr('disabled', false).hide();
                userContainer.find('.backstage-off').attr('disabled', false).show();
            }
            if (current_user_id == user_id) {
                $.showFlashMessage(I18n.t('video.cam_'+ data.status), {type: 'info', timeout: 3000})
            }
        });

        var urlDisableAllBackstage = '/lobbies/' + imm_room_id + '/disable_all_backstage';
        var urlEnableAllBackstage = '/lobbies/' + imm_room_id + '/enable_all_backstage';

        if (data.all && imm_role_presenter){
            if(data.status == 'disabled'){
                $('#groupSettings .users-group .users-group-video, .users-group-backstage').removeClass('groupSettings-Backstage-off').addClass('groupSettings-Backstage-on').attr("href", urlEnableAllBackstage);
            }else{
                $('#groupSettings .users-group .users-group-video, .users-group-backstage').addClass('groupSettings-Backstage-off').removeClass('groupSettings-Backstage-on').attr("href", urlDisableAllBackstage);
            }
        }
        refreshManagerPanel();
    });


    if (imm_role_presenter) {
        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.roomActive, function () {
            $('.MainVideoButton').removeClass('waitResponse');
            $('.waitResponseCover').remove();
            $('.MainVideoButton').removeAttr('disabled');
            $('.default-pics').hide();
            $('.default-live').show().fadeIn();
            self.cache.$inCallButtonStartStreaming.hide();
            self.cache.$inCallButtonBrbOn.show();
            $('.MainVideoButton').addClass('INTR').addClass('PlayINTR');
            self.cache.$inCallButtonStartRecord.removeClass('disabled');
            self.cache.$inCallButtonStopRecord.removeClass('disabled');
            $('#roomState').removeClass('offAir').addClass('live');
        });

        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.join, function (data) {
            logger.log('info', 'cable','triger:join');
            $('#roomState').removeClass('offAir').addClass('live');
            var count = self.websocketChannel.listenersCount;
            $('.immersiveIcon').html(count);

            refreshManagerPanel();
        });

        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.setPresenterMode, function (data) {
            logger.log('info', 'set_presenter_mode','triger:set_presenter_mode');
            self.cache.$inCallButtonStartLectureMode.addClass('active');
            self.cache.$inCallButtonStopLectureMode.removeClass('active');

        });
    }

    if (imm_role_guest) {
        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.join, function (data) {
            logger.log('info', 'cable','triger:join');

            $('#roomState').removeClass('offAir').addClass('live');
            var count = self.websocketChannel.listenersCount;
            $('.immersiveIcon').html(count);

            if ($.inArray(current_user_id, data.users) != -1) {
                VidyoData.load_room_info();

            }
            window.Immerss.isStarted = true;
        });

        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.enableList, function (data) {
            $.showFlashMessage('Shop was enabled by presenter', {type: 'info', timeout: 3000});
            shop_tab = $('a[data-id=shop]');
            if(!shop_tab.hasClass('active')) {
                appendBar(shop_tab);
            }
            $('.list_info').hide();
            $('#shop_info_'+ data.list_id).show();
        });

        self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.disableList, function (data) {
            close_right_panel();
            appendBar($('a[data-id=shop]'));
            $.showFlashMessage('Shop was disabled by presenter', {type: 'info', timeout: 3000});
            $('.list_info').hide();
        });
    }
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.productScanned, function (data) {
        $container = $('#shop_info_'+ data.list.id + ' .prodctTileList');
        if(!$container.length) {
            template = HandlebarsTemplates['lobbies/list_info'];
            $('#select_list').prepend("<option value=\"" + data.list.id + "\">" + data.list.name + "</option>");
            $('#listsArea').append(template(data.list));
        } else {
            tile = "<div class=\"productTile\"><div class=\"productTile-img\" style=\"background-image: url('" + data.product.image_url + "')\"></div>" +
                "<div class=\"productTile-short-description\">" +
                "<a style=\"cursor: pointer;\" target=\"_blank\" onclick=\"window.open('http://', '" + data.product.title + "', 'Toolbar=0, Location=0, Directories=0, Status=0, Menubar=0, Scrollbars=1, Resizable=0, Copyhistory=1, Width=800, Height=600');return false;\" href=\"http://\">" + data.product.title + "</a>" +
                "<div class=\"mt15\"><div class=\"productInfo inlile-block fs10\">" + data.product.description + "</div></div>" +
                "<a href=\"#\" onclick=\"jQuery(this).parents('.productTile').toggleClass('active')\" style=\"cursor: pointer;\">Read More...</a>" +
                "</div><div class=\"productTile-long-description\">" + data.product.specifications + "</div></div>";
            $container.prepend(tile);
        }
        $('#select_list').val(data.list.id);
        $('#select_list').trigger('change', $('#select_list'));
    });
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.activeMembers, function (member_ids) {
        // logger.log('info', 'cable','subscription_succeeded');
        $('.immersiveIcon').html(self.websocketChannel.listenersCount);

        //FIXME this caused an error if role source
        try{
            var count = self.websocketChannel.listenersCount;
            $('.immersiveIcon').html(count);

            member_ids.each(function (id) {
                $('.offline_' + id).hide()
            });
        }catch(e){}

        // if (imm_role_guest) {
        //     $.post('/lobbies/' + imm_room_id + '/auth_callback', {source_id: Immerss.sourceId}).error(function (response) {
        //         uiReportError('Portal callback error', '')
        //     });
        // }
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.memberSubscribed, function (member_id) {
        // logger.log('info', 'cable', 'member_added');

        var count = self.websocketChannel.listenersCount;
        $('.immersiveIcon').html(count);

        addNewMember(member_id, true);
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.memberUnsubscribed, function (member_id) {
        // logger.log('info', 'cable','member_removed');

        var count = self.websocketChannel.listenersCount;
        $('.immersiveIcon').html(count);

        $('.offline_' + member_id).show();
        $('#accordion-' + member_id).find('.user-control').addClass('collapsed');
        try{
            $('#collapseOne-' + member_id).data('bs.collapse').hide();
        }catch(e){}
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.newMember, function (member) {
        // logger.log('info', 'cable','new_member');
        addNewMember(member.id, false);
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.enableChat, function (data) {
        // logger.log('info', 'cable', 'enable-chat');
        if (!imm_role_presenter) {
            $.showFlashMessage('Chat was enabled by presenter', {type: 'info', timeout: 3000});
        }
        $('section#chat .styledScroll').html("<iframe src=\"" + window.location.protocol + "//" + window.location.host + "/widgets/" + data.session_id + "/session/chat?theme=dark\"></iframe>");
        if (!$('.V-toggleBlock_body a.Chat').hasClass('active')) {
            appendBar($('.V-toggleBlock_body a.Chat'));
        }
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.disableChat, function (data) {
        // /logger.log('info', 'cable', 'disable-chat');
        if (!imm_role_presenter) {
            $.showFlashMessage('Chat was disabled by presenter', {type: 'info', timeout: 3000});
            if ($('.V-toggleBlock_body a.Chat').hasClass('active')) {
                appendBar($('.V-toggleBlock_body a.Chat'));
            }
        }
        $('section#chat .styledScroll').html("Chat is disabled by presenter");
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.enablePoll, function (data) {
        // logger.log('info', 'cable', 'enable-poll');
        if (!imm_role_presenter) {
            $.showFlashMessage('Poll was enabled by presenter', {type: 'info', timeout: 3000});
            $('a:not(.active)[data-id=polls]').click();
        }
        $('.Votes-block').addClass('hidden');
        $('#poll_' + data.poll_id).removeClass('hidden');
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.disablePoll, function (data) {
        // logger.log('info', 'cable', 'disable-poll');
        if (!imm_role_presenter) {
            $('a.active[data-id=polls]').click();
            $.showFlashMessage('Poll was disabled by presenter', {type: 'info', timeout: 3000});
        }
        $('.Votes-block').addClass('hidden');
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.addPoll, function (data) {
        // logger.log('info', 'cable', 'add-poll');
        poll = data.poll_data;
        poll.is_voted = !!$.cookie()[poll.id];
        $.each(poll.sides, function( index, value ) {
            poll.sides[index].is_voted = ($.cookie()[poll.id] === value.id);
        });
        if (imm_role_presenter) {
            $('select#select_poll').append("<option value='" + poll.id + "'>" + poll.tagline + "</option>");
        }
        template = HandlebarsTemplates['polls/poll'];
        $('#pollsArea').append(template(poll));
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.votePoll, function (data) {
        // logger.log('info', 'cable', 'vote-poll');
        var poll = data.poll_data;
        cv = $.cookie(poll.id.toString());
        poll.is_voted = !!cv;
        $.each(poll.sides, function( index, value ) {
            poll.sides[index].is_voted = (cv === value.id.toString());
        });
        template = HandlebarsTemplates['polls/vote_poll'];
        $votesB = $('#poll_' + poll.id + ' .Votes-b');
        $votesB.html(template(poll));
        if(poll.is_voted == true) {
            $votesB.addClass('votedIn').removeClass('didNotVote');
        } else {
            $votesB.addClass('didNotVote').removeClass('votedIn');
        }
        $('#poll_' + poll.id + ' .Votes-h h6').html("Poll Results - Total of " + poll.totalVotes + " votes");
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.sessionEnded, function (data) {
        $('body').removeClass('showVideo');
        window.client_restart = false;
        window.close();
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.roomUpdated, function (data) {
        window.UpdateTimer = data.end_at_i;
        window.serverTime = new Date(data.server_time);
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.newQuestion, function(data){
        refreshManagerPanel();
        var users = data.users;
        self.usersQuestionsList = users;
        var participantsWithoutQuestions = [];
        var participantsWithQuestions    = [];
        var container = $(".membersListWrapp").find('ul.slides');
        container.find("a.answer-the-question-user").removeAttr("disabled");
        var insertEl = function(index, el){
            container.append(el);
        };
        container.find("li").each(function(index, el){
            if($.inArray(parseInt($(this).find('.user-control').data('user-id')), users) == -1){
                participantsWithoutQuestions.push($(this).clone(true).removeClass("has-question"));
                $(this).remove();
            }
        });
        $.each(users, function(index, user_id){
            var el = container.find(".user-control[data-user-id=" + user_id +"]").parents("li");
            participantsWithQuestions.push(el.clone(true).addClass("has-question"));
            el.remove();
        });

        $.each(participantsWithQuestions, insertEl);
        $.each(participantsWithoutQuestions, insertEl);
        //Reinit bootstrap collapse
        container.find(".panel-collapse").data('bs.collapse', null);
    });
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.banKick, function(data){
        if (current_user_id == data.user_id) {
            window.client_restart = false;
        }
        refreshManagerPanel();
    });
    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.clientMediaPlayerStart, function (data) {
        if(imm_role_guest) {
            uiShowMediaPlayer()
        }
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.brb, function (data) { // #be_right_back
        $.showFlashMessage(I18n.t('video.be_right_back'), {type: 'info', timeout: 3000})
    });

    self.websocketChannel.bind(presenceImmersiveRoomsChannelEvents.brbOff, function (data) { // #be_right_back
        $.showFlashMessage(I18n.t('video.be_right_back_off'), {type: 'info', timeout: 3000})
    });

    if(imm_role_presenter){
        var userChannel   = initUsersChannel();
    }
};
window.videoPlacePlayer;
window.videoPlace2Player;
