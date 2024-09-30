window.applicationBindSubscribeEventsGroup = function (self) {
    /* Subscription events */
    logger.log('info', 'application', 'applicationBindSubscribeEventsGroup()');

    self.cache.$inCallButtonStartStreaming
        .click(function (e) {
            logger.log('info', 'ui', "application::$inCallButtonStartStreaming::click");
            e.preventDefault();
            if ($('.MainVideoButton').attr('disabled')) {
                $.showFlashMessage('Please wait until your session starts', {type: 'info', timeout: 3000});
                return
            } // IMD-79 - do nothing if session not started
            $('.MainVideoButton').attr('disabled', true);
            $('.MainVideoButton').removeClass('INTRdefault').addClass('waitResponse').after('<div class="waitResponseCover"></div>');
            $.post('/lobbies/' + Immerss.roomId + '/start_streaming', {}).success(function (response) {
                logger.log('info', 'ui','portal::StartStreaming - callback success');
                $('.MainVideoButton').removeClass('waitResponse');
                $('.waitResponseCover').remove();
                $('.MainVideoButton').removeAttr('disabled');
                $('.default-pics').hide();
                $('.default-live').show().fadeIn();
                self.cache.$inCallButtonStartStreaming.hide();
                self.cache.$inCallButtonBrbOn.show();
                $('.MainVideoButton').addClass('INTR').addClass('PlayINTR').attr('data-tip', 'Pause');

                self.cache.$inCallButtonStartRecord.removeClass('disabled');
                self.cache.$inCallButtonStopRecord.removeClass('disabled');
                $('#roomState').removeClass('offAir').addClass('live');
                window.Immerss.isStarted = true;
            }).error(function (response) {
                $('.MainVideoButton').removeAttr('disabled');
                $('.MainVideoButton').removeClass('waitResponse');
                $('.waitResponseCover').remove();
                $.showFlashMessage(I18n.t('video.start_streaming_error_message'), {type: 'error', timeout: 3000});
                logger.log('error', 'ui', 'portal::StartStreaming - callback error: ', response);
            });
        });


    $('.addTime, .reduceTheTime')
        .click(function (e) {
            logger.log('info', 'ui', "application::.addTime, .reduceTheTime::click");
            e.preventDefault();
            $(this).attr('disabled', true);
            $.post($(this).data('url'), {}).success(function (response) {
                logger.log('info', 'ui','portal::.addTime, .reduceTheTime - callback success');
                $(this).attr('disabled', false);
            }).error(function (response) {
                $(this).attr('disabled', false);
                $.showFlashMessage(response.responseJSON.errors, {type: 'error', timeout: 3000});
                logger.log('error', 'ui', 'portal::.addTime, .reduceTheTime - callback error: ', response.responseJSON.errors);
            });
        });


    self.cache.$inCallButtonLectureMode
        .click(function (e) {
            logger.log('info', 'ui', "application::$inCallButtonLectureMode::click");
            e.preventDefault();
            if ($(this).hasClass('active')){
                $.post('/lobbies/' + Immerss.roomId + '/stop_lecture_mode', {}).success(function (response) {
                    logger.log('info', 'ui','portal::$inCallButtonLectureMode - callback success');
                    self.cache.$inCallButtonLectureMode.removeClass('active');
                }).error(function (response) {
                    $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
                    logger.log('error', 'ui', 'portal::$inCallButtonLectureMode - callback error: ', response);
                });
            }else{
                $.post('/lobbies/' + Immerss.roomId + '/start_lecture_mode', {}).success(function (response) {
                    logger.log('info', 'ui','portal::$inCallButtonLectureMode - callback success');
                    self.cache.$inCallButtonLectureMode.addClass('active');
                }).error(function (response) {
                    $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
                    logger.log('error', 'ui', 'portal::$inCallButtonLectureMode - callback error: ', response);
                });
            };
        });

    self.cache.$inCallButtonBrbOn
        .click(function (e) {
            logger.log('info', 'ui', "application::$inCallButtonBrbOn::click");
            e.preventDefault();
            $.post('/lobbies/' + Immerss.roomId + '/be_right_back_on', {}).success(function (response) {
                logger.log('info', 'ui','portal::$inCallButtonBrbOn - callback success');
                self.cache.$inCallButtonBrbOn.hide();
                self.cache.$inCallButtonBrbOff.show();
                $('.MainVideoButton').removeClass('PlayINTR').addClass('PauseINTR');
                self.cache.$inCallButtonMuteVideo.click();
                self.cache.$inCallButtonMuteMicrophone.click();
            }).error(function (response) {
                $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
                logger.log('error', 'ui', 'portal::$inCallButtonBrbOn - callback error: ', response);
            });
        });

    self.cache.$inCallButtonBrbOff
        .click(function (e) {
            logger.log('info', 'ui', "application::$inCallButtonBrbOff::click");
            e.preventDefault();
            $.post('/lobbies/' + Immerss.roomId + '/be_right_back_off', {}).success(function (response) {
                logger.log('info', 'ui','portal::$inCallButtonBrbOff - callback success');
                self.cache.$inCallButtonBrbOff.hide();
                $('.MainVideoButton').addClass('PlayINTR').removeClass('PauseINTR');
                self.cache.$inCallButtonBrbOn.show();
                self.cache.$inCallButtonMuteVideo.click();
                self.cache.$inCallButtonMuteMicrophone.click();
            }).error(function (response) {
                $.showFlashMessage('We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
                logger.log('error', 'ui', 'portal::$inCallButtonBrbOff - callback error: ', response);
            });
        });

    $(".inCallButtonAutostart-wrapp")
        .click(function (e) {
            logger.log('info', 'ui', "application::inCallButtonAutostart::click");
            e.preventDefault();
            if (!window.Immerss.isStarted){
                $.post('/lobbies/' + Immerss.roomId + '/switch_autostart', {}).success(function (response) {
                    logger.log('info', 'ui', 'portal::inCallButtonAutostart - callback success');
                    if (response.autostart) {
                        $("#inCallButtonAutostart").addClass('on');
                    }else{
                        $("#inCallButtonAutostart").removeClass('on');
                    }
                }).error(function (response) {
                    $.showFlashMessage('[autostart] We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
                    logger.log('error', 'ui', 'portal::inCallButtonAutostart - callback error: ', response);
                });
            }
        });
    $(".inCallButtonChat-wrapp").click(function (e) {
        logger.log('info', 'ui', "application::inCallButtonChat::click");
        e.preventDefault();
        $.post('/lobbies/' + Immerss.roomId + '/switch_chat', {}).success(function (response) {
            logger.log('info', 'ui', 'portal::inCallButtonChat - callback success');
            if (response.allow_chat) {
                $("#inCallButtonChat").addClass('on');
                $.showFlashMessage(I18n.t('video.chat_enabled'), {type: 'info', timeout: 3000});
            }else{
                $("#inCallButtonChat").removeClass('on');
                $.showFlashMessage(I18n.t('video.chat_disabled'), {type: 'info', timeout: 3000});
            }
        }).error(function (response) {
            $.showFlashMessage('[chat] We\'re sorry, but something went wrong', {type: 'error', timeout: 3000});
            logger.log('error', 'ui', 'portal::inCallButtonChat - callback error: ', response);
        });
    });
    // self.cache.$inCallButtonStartRecord
    //     .click(function (e) {
    //         logger.log('info', 'ui', "application::$inCallButtonStartRecord::click");
    //         e.preventDefault();
    //         self.cache.$inCallButtonStartRecord.attr('disabled', true);
    //         $.post('/lobbies/' + Immerss.roomId + '/start_or_resume_record', {}).success(function (response) {
    //             logger.log('info', 'ui','portal::start_or_resume_record - callback success');
    //             self.cache.$inCallButtonStartRecord.hide();
    //             self.cache.$inCallButtonStopRecord.show();
    //             $('.oneThird .play').addClass('record');
    //         }).error(function (response) {
    //             $.showFlashMessage('Error', {type: 'error', timeout: 3000});
    //             logger.log('error', 'ui', 'portal::start_or_resume_record - callback error: ', response);
    //         }).complete(function(){
    //             self.cache.$inCallButtonStartRecord.attr('disabled', false);
    //         });
    //     });
    //
    // self.cache.$inCallButtonStopRecord
    //     .click(function (e) {
    //         logger.log('info', 'ui', "application::$inCallButtonStopRecord::click");
    //         e.preventDefault();
    //         self.cache.$inCallButtonStopRecord.attr('disabled', true);
    //         $.post('/lobbies/' + Immerss.roomId + '/pause_record', {}).success(function (response) {
    //             self.cache.$inCallButtonStartRecord.show();
    //             self.cache.$inCallButtonStopRecord.hide();
    //             logger.log('info', 'ui','portal::PauseRecord - callback success');
    //         }).error(function (response) {
    //             $.showFlashMessage('Error', {type: 'error', timeout: 3000});
    //             logger.log('error', 'ui', 'portal::PauseRecord - callback error: ', response);
    //         }).complete(function(){
    //             self.cache.$inCallButtonStopRecord.attr('disabled', false);
    //         });
    //     });

    // $('.videoPageInnerWrapper').on('click', self.cache.inCallButtonChat, function (e) {
    //         logger.log('info', 'ui', "application::$inCallButtonChat::click");
    //         e.preventDefault();
    //         if(self.isChatEnabled){
    //             if($('#twitterFeedContainer').is(':visible') || $('#donationsContainer').is(':visible') || $('#groupSettings').is(':visible') || $('#banReasonsContainer').is(':visible') || $("#mediaPlayerContainer").is(':visible')){
    //                 uiHideBanReasons();
    //                 uiHideManageUsers();
    //                 uiHideMediaPlayer();
    //                 uiHideTwitterFeed();
    //                 uiHideDonations();
    //                 uiHidePoll();
    //                 return;
    //             }
    //             $(this).removeClass('active');
    //             self.isChatEnabled = false;
    //             //self.pusherChannel.trigger('client-chat-disabled', {user_id: 'all'});
    //             //$.showFlashMessage(I18n.t('video.chat_disabled'), {type: 'info', timeout: 3000});
    //             self.cache.$pluginAndChatContainer.hide();
    //             $("body").removeClass('OpenChat');
    //             $('body').removeClass('menu-right');
    //         }else{
    //             $(this).addClass('active');
    //             uiHideManageUsers();
    //             uiHideMediaPlayer();
    //             uiHideTwitterFeed();
    //             uiHideDonations();
    //             uiHidePoll();
    //             self.isChatEnabled = true ;
    //             if (Immerss.presenter) {
    //                 self.pusherChannel.trigger('client-chat-enabled', {user_id: 'all'});
    //                 $.showFlashMessage(I18n.t('video.chat_enabled'), {type: 'info', timeout: 3000});
    //             }
    //             self.cache.$pluginAndChatContainer.show();
    //             $("body").addClass('OpenChat');
    //             $('body').addClass('menu-right');
    //         }
    //
    //     });
    // $('.videoPageInnerWrapper').on('click', ".ban_kick", function(e){
    //     logger.log('info', 'ui', "application::.ban_kick::click");
    //     e.preventDefault();
    //     var banReasonsContainer = $('#banReasonsContainer');
    //     if(banReasonsContainer.is(':visible')){
    //         uiHideBanReasons();
    //     }else{
    //         var data = {};
    //         data.url = $(this).data('url');
    //         data.token = $('meta[name="csrf-token"]').attr('content');
    //         banReasonsContainer.html(self.templates.banReasonsTemplate(data));
    //         uiShowBanReasons();
    //         banReasonsContainer.find('form').bind('ajax:success', function(){
    //             banReasonsContainer.html('');
    //             uiHideBanReasons();
    //         });
    //     }
    // });
    // self.cache.$askQuestion.click(function(event){
    //     event.preventDefault();
    //     if(self.hasAskedQuestion){
    //         self.hasAskedQuestion = false;
    //         $(this).removeClass("asked")
    //     }else{
    //         self.hasAskedQuestion = true;
    //         $(this).addClass("asked")
    //     }
    //     $.post('/lobbies/' + Immerss.roomId + '/ask');
    // });
    return self;
};
