//= require_self
//= require video_client/shared/required_applications

//= require video_page/main.config
//= require 'video_page/webrtc84/vidyo.client.messages.js'
//= require 'video_page/webrtc84/vidyo.client.private.messages.js'
//= require 'video_page/webrtc84/vidyo.client.js'
//= require 'video_page/webrtc84/libs/github.adapter.js'
//= require 'video_page/webrtc84/libs/github.common.js'
//= require 'video_page/webrtc84/libs/github.videopipe.js'
//= require 'video_page/webrtc84/libs/github.main.js'
//= require 'video_page/webrtc84/libs/vidyo.plugin.js'

var application = function (config) {

    var handlebars = {default: Handlebars};
    var self = {};
    self.config = config;
    self.closeWindow = true;
    self.config.vidyoLib = {};
    self.cache = {};
    self.isChatEnabled = false;
    self.events = {};
    self.loginInfo = {};
    self.guestLoginInfo = {};
    self.templates = {};
    self.currentRequestId = 1;
    self.users = {
        favNum: "",
        fav: [],
        userNum: "",
        user: []
    };
    self.lastUsers = self.users;
    self.isGuestLogin = Immerss.guest;
    self.hasControl = (!!Immerss.hasControl || !!Immerss.presenter);
    self.currentPreviewMode = self.config.defaultPreviewMode;
    self.isMutedMic = false;
    self.isMutedSpeaker = false;
    self.isMutedVideo = false;
    self.isFullscreen = false;
    self.isFullpage = false;
    self.numPreferred = 0;
    if (Immerss.presenter) {
        self.myAccount = {
            displayName: 'Presenter'
        };
    } else {
        self.myAccount = {
            displayName: 'Participant'
        };
    }
    self.currentShareId = undefined;
    self.isShareScreenActive = false;
    self.inConference = false;
    self.isJoining = false;
    self.isShowingParticipantList = true;
    self.currentParticipants = [];
    self.currentMember = undefined;
    self.logConfig = {};
    self.hasAskedQuestion = false;
    self.usersQuestionsList = window.Immerss.usersQuestionsList;
    self.manageUsersShown = false;
    self.twitterFeedShown = false;
    self.donationsShown = false;


  /* IE 8 tweek for array */
    if (!Array.indexOf) {
        Array.indexOf = function (val) {
            var i;
            for (i = 0; i < this.length; i++) {
                if (this[i] === val) {
                    return i;
                }
            }
            return -1;
        };
    }

    logger.log('debug', 'application', 'Loaded main');
    logger.log('debug', 'application', 'Browser supports: ', $.support);

  applicationBuildCache = function () {
      logger.log('log', 'application', 'applicationBuildCache()');

      self.cache.$configurationContainer = $(self.config.configurationContainer);
      self.cache.$inCallButtonStartStreaming = $(self.config.inCallButtonStartStreaming);
      self.cache.$inCallButtonStopStreaming = $(self.config.inCallButtonStopStreaming);
      self.cache.$inCallButtonBrbOn         = $('#inCallButtonBrbOn');
      self.cache.$inCallButtonBrbOff         = $('#inCallButtonBrbOff');
      self.cache.$inCallButtonStartLectureMode    = $('#inCallButtonStartLectureMode');
      self.cache.$inCallButtonStopLectureMode     = $('#inCallButtonStopLectureMode');
      self.cache.$inCallButtonLectureMode         = $('#inCallButtonLectureMode');
      self.cache.inCallButtonChat = self.config.inCallButtonChat;
      self.cache.inCallButtonBan  = self.config.inCallButtonBan;
      self.cache.$inCallButtonStartRecord = $(self.config.inCallButtonStartRecord);
      self.cache.$inCallButtonStopRecord = $(self.config.inCallButtonStopRecord);
      self.cache.$inCallButtonDisconnect = $(self.config.inCallButtonDisconnect);
      self.cache.$inCallButtonFullpage = $(self.config.inCallButtonFullpage);
      self.cache.$inCallButtonFullscreen = $(self.config.inCallButtonFullscreen);
      self.cache.$inCallButtonMuteMicrophone = $(self.config.inCallButtonMuteMicrophone);
      self.cache.$inCallButtonMuteSpeaker = $(self.config.inCallButtonMuteSpeaker);
      self.cache.$inCallButtonMuteVideo = $(self.config.inCallButtonMuteVideo);
      self.cache.$inCallButtonPanel = $(self.config.inCallButtonPanel);
      self.cache.$inCallButtonShare = $(self.config.inCallButtonShare);
      self.cache.$inCallButtonLocalShare = $(self.config.inCallButtonLocalShare);
      self.cache.$inCallButtonToggleConfig = $(self.config.inCallButtonToggleConfig);
      self.cache.$inCallButtonToggleInvite = $(self.config.inCallButtonToggleInvite);
      self.cache.inCallButtonToggleMember = self.config.inCallButtonToggleMember;
      self.cache.$inCallButtonToggleLayout = $(self.config.inCallButtonToggleLayout);
      self.cache.$inCallButtonTogglePreview = $(self.config.inCallButtonTogglePreview);
      self.cache.$inCallContainer = $(self.config.inCallContainer);
      self.cache.$inCallLocalShareList = $(self.config.inCallLocalShareList);
      self.cache.$inCallShareList = $(self.config.inCallShareList);
      self.cache.$pluginAndChatContainer = $(self.config.pluginAndChatContainer);
      self.cache.$pluginContainer = $(self.config.pluginContainer);
      self.cache.$plugin = $(self.config.pluginContainer).children(":first"); //Firefox quirk
      self.cache.$preCallImage = $(self.config.preCallImage);
      self.cache.pingImageUrl = self.config.pingImageUrl;
      self.cache.$askQuestion = $(self.config.askQuestion);
      return self;
  };

    applicationBuildTemplates = function () {
        self.templates.pluginTemplate = handlebars['default'].compile(self.config.pluginTemplate);
        //self.templates.configurationTemplateWebrtc = handlebars['default'].compile(self.config.configurationTemplateWebrtc);
        self.templates.inCallParticipantTemplate = handlebars['default'].compile(self.config.inCallParticipantTemplate);
        self.templates.inCallSharesTemplate = handlebars['default'].compile(self.config.inCallSharesTemplate);
        self.templates.inCallLocalSharesTemplate = handlebars['default'].compile(self.config.inCallLocalSharesTemplate);
        self.templates.pluginEnableInstructionsTemplate = handlebars['default'].compile(self.config.pluginEnableInstructionsTemplate);
        self.templates.userWebsocketTemplate = handlebars['default'].compile(self.config.userWebsocketTemplate);
        self.templates.banReasonsTemplate = HandlebarsTemplates['application/ban_reasons'];
        return self;
    };

    applicationAddPlugin = function () {
        logger.log('log', 'application', 'applicationAddPlugin()');
        var pluginContainer = $(self.config.pluginContainer);

        var htmlData = self.templates.pluginTemplate({
            id: self.config.pluginIdName,
            mimeType: self.config.pluginMimeType
        });

        pluginContainer.html(htmlData);
        return self;
    };

    applicationCallCleanup = function () {
        logger.log('log', 'application', 'applicationCallCleanup()');
        helperConferenceUpdateTimerStop();
        self.inConference = false;
        self.isJoining = false;
        return self;
    };

    applicationBuildSubscribeEvents = function () {
        self.events.pluginPreloadEvent = $.Deferred();
        self.events.pluginLoadedEvent = $({
            type: "pluginLoadedEvent"
        });

        self.events.configurationUpdateEvent = $({
            type: "configurationUpdateEvent"
        });

        /* Login state control */
        self.events.loginEvent = $({
            type: "loginEvent"
        });
        self.events.logoutEvent = $({
            type: "logoutEvent"
        });

        /* Call state control */
        self.events.disconnectEvent = $({
            type: "disconnectEvent"
        });
        self.events.connectEvent = $({
            type: "connectEvent"
        });

        /* In call events */
        self.events.participantUpdateEvent = $({
            type: "participantUpdateEvent"
        });
        self.events.shareUpdateEvent = $({
            type: "shareUpdateEvent"
        });
        self.events.muteUpdateEvent = $({
            type: "muteUpdateEvent"
        });
        self.events.chatUpdateEvent = $({
            type: "chatUpdateEvent"
        });

        /* Conference control events */
        self.events.recorderEvent = $({
            type: "recorderEvent"
        });
        self.events.portalParticipantUpdateEvent = $({
            type: "portalParticipantUpdateEvent"
        });
        /* Fullscreen */
        self.events.fullscreenEvent = $({
            type: "fullscreenEvent"
        });

        return self;
    };

    applicationBindSubscribeEvents = function () {
      applicationBindSubscribeEventsGroup(self);
        /* Subscription events */
        logger.log('info', 'application', 'applicationBindSubscribeEvents()');

        /* Occurred when plugin is really ready  */
        self.events.pluginLoadedEvent
            .on('done', function () {
                logger.log('info', 'plugin', 'pluginLoadedEvent::done');
                loginParticipantAndWait();
            })
            .on('fail', function (event, error) {
                logger.log('warning', 'plugin', 'pluginLoadedEvent::fail', event, error);
                uiReportError('', error);
            })
            .on('info', function (event, message) {
                logger.log('info', 'plugin', 'pluginLoadedEvent::info', event, message);
                uiReportInfo(message.message, message.details);
            });
        /* Occurs when Vidyo library configuration is updated */
        self.events.configurationUpdateEvent
            .on('done', function (event, newConfig) {
                logger.log('info', 'configuration', 'configurationUpdateEvent::done', event);
                var data = {
                    camera: [],
                    speaker: [],
                    microphone: []
                };

                $.each(newConfig.cameras, function (i, name) {
                    data.camera.push({
                        name: name,
                        id: i,
                        isSelected: (i === newConfig.currentCamera)
                    });
                });


                $.each(newConfig.speakers, function (i, name) {
                    data.speaker.push({
                        name: name,
                        id: i,
                        isSelected: (i === newConfig.currentSpeaker)
                    });
                });

                $.each(newConfig.microphones, function (i, name) {
                    data.microphone.push({
                        name: name,
                        id: i,
                        isSelected: (i === newConfig.currentMicrophone)
                    });
                });

                data.selfViewLoopbackPolicy = [
                    {
                        name: "Show",
                        value: 0,
                        isSelected: newConfig.selfViewLoopbackPolicy === 0
                    },
                    {
                        name: "Hide",
                        value: 1,
                        isSelected: newConfig.selfViewLoopbackPolicy === 1
                    },
                    {
                        name: "Show when only participant",
                        value: 2,
                        isSelected: newConfig.selfViewLoopbackPolicy === 2
                    }
                ];
                /* From VidyoClientParameters.h */
                var PROXY_VIDYO_FORCE = 1,
                    PROXY_WEB_ENABLE = (1 << 3),
                    PROXY_WEB_IE = (1 << 4);

                data.alwaysProxy = !!(newConfig.proxySettings & PROXY_VIDYO_FORCE);
                data.useWebProxy = ( !!(newConfig.proxySettings & PROXY_WEB_ENABLE) && !!(newConfig.proxySettings & PROXY_WEB_IE));

                data.hideParticipants = !newConfig.enableShowConfParticipantName;
                data.muteMicrophone = !!newConfig.enableMuteMicrophoneOnJoin;
                data.hideCamera = !!newConfig.enableHideCameraOnJoin;
                data.echoCancel = !!newConfig.enableEchoCancellation;
                data.echoDetect = !!newConfig.enableEchoDetection;
                data.autoGain = !!newConfig.enableAudioAGC;

                data.logsApplication = self.logConfig.enableAppLogs;
                data.logsJS = self.logConfig.enableVidyoPluginLogs;
                data.logsClient = self.logConfig.enableVidyoClientLogs;
                data.logLevelsAndCategories = self.logConfig.logLevelsAndCategories;

                logger.log('debug', 'configuration', 'configurationUpdateEvent::done - Devices detected', data);
                uiConfigurationUpdateWithData(data);
            });
        self.events.loginEvent
            .on('done', function () {
                logger.log('info', 'login', 'loginEvent::done');
                $.post('/lobbies/' + Immerss.roomId + '/auth_callback', {source_id: Immerss.sourceId}).success(function (response) {
                    logger.log('info', 'portal', 'portal::loginEvent - callback success: ', response);
                }).error(function (response) {
                    logger.log('error', 'portal', 'portal::loginEvent - callback error: ', response);
                    uiReportError('Portal callback error', '')
                });
                self.isLoggedIn = true;
            })
            .on('fail', function (event, error) {
                self.isLoggedIn = false;
                uiReportError("Failed to login - " + error);
            })
            .on('progress', function (event, percent) {
                logger.log('debug', 'login', 'loginEvent::progress - percent: ', percent, event);
            });

        self.events.connectEvent
            .on('done', function () {
                logger.log('info', 'call', 'connectEvent::done');
                uiInCallShow(true, false);
                clientMicrophoneMute(false);

                $.post('/lobbies/' + Immerss.roomId + '/after_join', {source_id: Immerss.sourceId}).success(function (response) {
                }).error(function (response) {
                    uiReportError('Portal callback error', '')
                });
                self.inConference = true;
                self.isJoining = false;
                uiLocalShareReset();
                var recState = clientRecordAndLivestreamStateGet();
                if (recState && recState.recording) {
                    self.events.recorderEvent.trigger("start");
                } else {
                    self.events.recorderEvent.trigger("stop");
                }

            })
            .on('fail', function (event, error) {
                logger.log('error', 'call', 'connectEvent::fail - error: ', error, event);
                self.inConference = false;
                self.isJoining = false;
                if (self.isGuestLogin) {
                    logger.log('error', 'call', 'Failed to connect as guest');

                    self.isGuestLogin = false;
                    //uiReportGuestLoginError("<h3>Failed to connect</h3>" + "<p>" + error.error + "</p>");
                } else {
                    logger.log('error', 'call', 'Failed to connect as user');
                    //uiReportError("Failed to connect", error.error);
                }
                helperConferenceUpdateTimerStop();
            })
            .on('progress', function (event, percent) {
                logger.log('debug', 'call', 'connectEvent::progress - percent: ', percent, event);
            })
            .on('crash', function (event, error) {
                $.showFlashMessage('<h3>' + error + '</h3>', {type: 'error', timeout: 6000});
                if (!self.isGuestLogin) {
                    loginParticipantAndWait();
                } else {
                    $.post('/lobbies/' + Immerss.roomId + '/auth_callback', {source_id: Immerss.sourceId}).error(function (response) {
                        uiReportError('Portal callback error', '')
                    });
                }
            });

        self.events.logoutEvent
            .on('done', function () {
                logger.log('info', 'login', 'logoutEvent::done');
                self.isLoggedIn = false;
            })
            .on('fail', function (e, error) {
                logger.log('error', 'login', 'logoutEvent::fail - error: ', error, e);
                uiReportError("Failed to logout", error);
                self.isLoggedIn = false;
            });

        self.events.disconnectEvent
            .on('done', function () {
                logger.log('info', 'call', 'disconnectEvent::done');
                uiCallCleanup();
                applicationCallCleanup();
            })
            .on('fail', function (event, error) {
                logger.log('error', 'call', 'disconnectEvent::fail - error: ', error, event);
                uiReportError("Failed to disconnect", error);
                uiCallCleanup();
                applicationCallCleanup();
            });

        self.events.muteUpdateEvent
            .on('done', function (e, muteInfo) {
                logger.log('info', 'configuration', 'muteUpdateEvent::done', e);

                if (muteInfo.device === "speaker") {
                    uiSetSpeakerMuted(muteInfo.mute);
                } else if (muteInfo.device === "microphone") {
                    uiSetMicMuted(muteInfo.mute);
                } else if (muteInfo.device === "video") {
                    uiSetVideoMuted(muteInfo.mute);
                } else {
                    logger.log('warning', 'configuration', 'self.events.muteUpdateEvent::done', "unknown device type");

                }
            });
        self.events.fullscreenEvent
            .on('done', function () {
                logger.log('info', 'ui', 'fullscreenEvent::done');
                uiInCallShow(true, true);
            })
            .on('cancel', function (event, error) {
                uiInCallShow(true, false);
                $('body').addClass('has-ribbon');
                logger.log('info', 'ui', 'fullscreenEvent::cancel ', error || "", event);
            });

        self.events.portalParticipantUpdateEvent
            .on('done', function (event, participants) {
                logger.log('info', 'portal', 'portalParticipantUpdateEvent::done ', participants, event);
            });

        self.events.participantUpdateEvent
            .on('done', function (event, participants) {
                /* Apply handlebars template to data */
                //logger.log('info', 'call', 'participantUpdateEvent::done', participants, event);
                var transformedParticipants = {
                    participants: participants
                };

                transformedParticipants.sessionDisplayText = "Conference";

                $.each(transformedParticipants.participants, function (p) {
                    p.isChatEnabled = self.isChatEnabled;
                });

                uiParticipantsUpdateWithData(transformedParticipants);

                self.currentParticipants = participants;
            });

        self.events.shareUpdateEvent
            .on('done', function (event, shares) {
                logger.log('info', 'call', 'shareUpdateEvent::done', event);
                var transformedShares = {
                    shares: []
                };
                var i;
                for (i = 0; i < shares.numApp; i++) {
                    transformedShares.shares.push({
                        name: shares.remoteAppName[i],
                        id: i,
                        highlight: ((shares.numApp - 1) === i) ? true : false
                    });
                }

                uiSharesUpdateWithData(transformedShares);
                /* Select last available share */
                if (shares.numApp) {
                    clientSharesSetCurrent(shares.numApp - 1);
                }
            });

        self.events.recorderEvent
            .on('start', function () {
                logger.log('info', 'portal', 'recorderEvent::start');
                self.cache.$inCallButtonStartRecord.hide();
                self.cache.$inCallButtonStopRecord.show();
                $('span.recordIcon').addClass('active');
            })
            .on('startFail', function (error, details) {
                logger.log('error', 'portal', 'recorderEvent::startFail', error, details);
                self.cache.$inCallButtonStartRecord.show();
                self.cache.$inCallButtonStopRecord.hide();
                $('span.recordIcon').removeClass('active');
                uiReportError('Failed to start record', '')
            })
            .on('stop', function () {
                logger.log('info', 'portal', 'recorderEvent::stop');
                self.cache.$inCallButtonStartRecord.show();
                self.cache.$inCallButtonStopRecord.hide();
                $('span.recordIcon').removeClass('active');
            })
            .on('stopFail', function () {
                logger.log('error', 'plugin', 'recorderEvent::stopFail');
                self.cache.$inCallButtonStartRecord.hide();
                self.cache.$inCallButtonStopRecord.show();
                $('span.recordIcon').addClass('active');
            });

        $('.addTime, .reduceTheTime')
            .click(function (e) {
                logger.log('info', 'ui', "application::.addTime, .reduceTheTime::click");
                e.preventDefault();
                $(this).attr('disabled', true);
                $.post($(this).data('url'), {}).success(function (response) {
                    logger.log('info', 'ui', 'portal::.addTime, .reduceTheTime - callback success');
                    $(this).attr('disabled', false);
                }).error(function (response) {
                    $(this).attr('disabled', false);
                    $.showFlashMessage(response.responseJSON.errors, {type: 'error', timeout: 3000});
                    logger.log('error', 'ui', 'portal::.addTime, .reduceTheTime - callback error: ', response.responseJSON.errors);
                });
            });


        self.cache.$inCallButtonStopStreaming
            .click(function (e) {
                logger.log('info', 'ui', "application::$inCallButtonStopStreaming::click");
                e.preventDefault();
                var scope = window.Immerss.conferenceType.toLowerCase();
                var msg = I18n.t("video.organizer_stop_conference", {model: I18n.t("activerecord.models")[scope]});
                if (confirm(msg)) {
                    $.post('/lobbies/' + Immerss.roomId + '/stop_streaming', {}).success(function (response) {
                        logger.log('info', 'ui', 'portal::StopStreaming - callback success');
                        window.close();
                    }).error(function (response) {
                        $.showFlashMessage(I18n.t('video.stop_streaming_error_message'), {
                            type: 'error',
                            timeout: 3000
                        });
                        logger.log('error', 'ui', 'portal::StopStreaming - callback error: ', response);
                    });
                }
            });

        return self;
    };

    applicationBindUIEvents = function () {

        logger.log('info', 'application', 'applicationBindUIEvents()');

//
//        $('#configModal').on('click', 'a.refresh', function (event) {
//            event.preventDefault();
//            var conf = clientConfigurationGet();
//            var updatedConf = clientConfigurationBootstrap(conf);
//            self.events.configurationUpdateEvent.trigger("done", updatedConf);
//        });

//        $('#social-modal').on('click', 'a.refresh', function (event) {
//            event.preventDefault();
//            $.get($(self.cache.$inCallButtonToggleInvite).data('url')).success(function (response) {
//                $('#social-modal').html(window.modalBody)
//            })
//        });
//
//        $('#shareModal').on('click', 'a.refresh', function (event) {
//            setShareUI()
//        });

        $(window).bind("beforeunload", function () {
                logger.log('info', 'call', "reload  or close page");
                self.closeWindow = false;
                sendLeaveEvent();
            }
        );

        self.cache.$inCallButtonToggleConfig
            .on('click', function () {
                logger.log('info', 'ui', "inCallButtonToggleConfig::click");
                jQuery('.vi-active').removeClass('vi-active');
//                if (toggleRiddleMenu(this)) {
//                    self.cache.$inCallButtonToggleConfig.addClass('vi-active');
//                } else {
//                    self.cache.$inCallButtonToggleConfig.removeClass('vi-active');
//                }

            });

        $('.videoPageInnerWrapper').on('click', '.user-control', function (event) {
            event.preventDefault();
            toggleRiddleMenu(this, 'menu-right');
            uiHideBanReasons();
        });

      self.cache.$inCallButtonToggleInvite
          .on('click', function () {
            logger.log('info', 'ui', "inCallButtonToggleInvite::click");

            refresh_invite_modal();
          });



        self.cache.$plugin
            .ready(function () {
                logger.log('info', 'plugin', "plugin::ready");
                /* Resolve deferred variable */
                self.events.pluginPreloadEvent.resolve();
            });


        self.cache.$plugin
            .on('error', function () {
                logger.log('warning', 'plugin', "plugin::error");
                /* Reject deferred variable */
                self.events.pluginPreloadEvent.reject("Failed to load");
            });

        /* In call buttons events */

        /* Prevent UI jumping */
        self.cache.$inCallContainer
            .click(function (e) {
                e.preventDefault();
            });

        self.cache.$inCallButtonMuteVideo
            .click(function () {
                logger.log('info', 'ui', "inCallButtonMuteVideo::click");
                self.isMutedVideo = !self.isMutedVideo;
                clientVideoMute(self.isMutedVideo);
            });

        self.cache.$inCallButtonMuteSpeaker
            .click(function () {
                logger.log('info', 'ui', "inCallButtonMuteSpeaker::click");
                self.isMutedSpeaker = !self.isMutedSpeaker;
                clientSpeakerMute(self.isMutedSpeaker);
            });

        self.cache.$inCallButtonMuteMicrophone
            .click(function () {
                logger.log('info', 'ui', "inCallButtonMuteMicrophone::click");
                self.isMutedMic = !self.isMutedMic;
                clientMicrophoneMute(self.isMutedMic);
            });

        self.cache.$inCallButtonShare
            .click(function () {
                logger.log('info', 'ui', "inCallButtonShare::click");
            });

        self.cache.$inCallButtonLocalShare
            .click(function (e) {
                if (!extensionInstalled){
                  successCallback = function(e){
                    console.log(e)
                  };
                   errorCallback = function(e){
                     if (e == 'Inline installs can only be initiated for Chrome Web Store items that have one or more verified sites.'){
                       window.open('https://chrome.google.com/webstore/detail/jbagnbabffebnloeajochhpipcjhpamb', '', 'width=1020, height=300')
                     }
                  };
                  chrome.webstore.install('https://chrome.google.com/webstore/detail/jbagnbabffebnloeajochhpipcjhpamb',successCallback,  errorCallback);
                }
                setShareUI()
            });

        self.cache.$inCallButtonToggleLayout
            .click(function () {
                logger.log('info', 'ui', "inCallButtonToggleLayout::click");
                clientLayoutToggle();
            });

        self.cache.$inCallButtonFullscreen
            .click(function () {
                logger.log('info', 'ui', "inCallButtonFullscreen::click");
                self.isFullscreen = !self.isFullscreen;
                if (self.isFullscreen) {
                    self.isFullpage = false;
                    uiFullscreenSet(self.cache.$inCallContainer.get()[0]);
                } else {
                    uiFullscreenCancel();
                }
            });

        self.cache.$inCallButtonFullpage
            .click(function () {
                logger.log('info', 'ui', "inCallButtonFullscreen::click");
                self.isFullpage = !self.isFullpage;
                if (self.isFullpage) {
                    self.isFullscreen = false;
                    $('body').removeClass('has-ribbon');
                    uiFullscreenSet($('body')[0]);
                    $(this).find('i').attr('class', '').addClass('VideoClientIcon-restore');
                } else {
                    uiFullscreenCancel();
                    $(this).find('i').attr('class', '').addClass('VideoClientIcon-expand2');
                }
            });

        self.cache.$inCallButtonTogglePreview
            .click(function (e) {
                logger.log('info', 'ui', "inCallButtonTogglePreview::click");
                e.preventDefault();
                //clientPreviewModeToggle()
                //clientPreviewModeSet($(e.target).data("mode"));

                if($('.VideoArea-type-1').length == 1){
                    $('.VideoArea-type-1').removeClass('VideoArea-type-1').addClass('VideoArea-type-2');
                }else{
                    $('.VideoArea-type-2').removeClass('VideoArea-type-2').addClass('VideoArea-type-1');
                }
            });

        self.cache.$inCallButtonDisconnect
            .click(function () {
                logger.log('info', 'ui', "inCallButtonDisconnect::click");
                var scope = window.Immerss.conferenceType.toLowerCase();
                var msg = I18n.t("video.nonorganizer_leave_conference", {model: I18n.t("activerecord.models")[scope]});
                if (confirm(msg)) {
                    clientConferenceLeave();
                    window.close()
                }
            });

        /* Optimize mute event. Use one mute event for the whole button panel. */
        self.cache.$inCallButtonPanel
            .on('mute', function (e, isMuted) {
                logger.log('info', 'ui', "inCallButtonTogglePreview::mute");
                if (isMuted) {
                    $(e.target).addClass($(e.target).data('mute'));
                    $(e.target).removeClass($(e.target).data('unmute'));
                } else {
                    $(e.target).removeClass($(e.target).data('mute'));
                    $(e.target).addClass($(e.target).data('unmute'));
                }
            });

        self.cache.$inCallShareList
            .click(function (event) {
                logger.log('info', 'ui', "inCallShareList::click");
                var target = $(event.target);
                var id = target.data('id');
                clientSharesSetCurrent(id);
                uiShareSelect(target);
            });

        self.cache.$inCallLocalShareList.on("change", "input[role='sharedisplay']", function (event) {
            logger.log('info', 'ui', "inCallLocalShareList::click");
            self.currentShareId = $(this).data('id');
            if (self.isShareScreenActive)
                clientLocalShareStart(self.currentShareId);
        });

        self.cache.$inCallLocalShareList.on("click", ".shareskrinnswither input", function (e) {
            $(this).parent().find("a").removeClass("active");
            $(this).addClass("active");
            if ($(this).hasClass("enable-share")) {
                self.isShareScreenActive = true;
                if (self.currentShareId)
                    clientLocalShareStart(self.currentShareId);
            } else {
                self.isShareScreenActive = false;
                clientLocalShareStop();
            }

        });

        /* Handle selection of different input device */
        self.cache.$configurationContainer
            .on("change", function (event, obj) {
                logger.log('info', 'ui', "configurationContainer::change", event, obj);
                var target = $(event.target),
                    selection = target.val(),
                    isChecked = target.prop("checked") ? 1 : 0;

                var conf = clientConfigurationGet();
                /* From VidyoClientParameters.h */
                var PROXY_VIDYO_FORCE = 1,
                    PROXY_WEB_ENABLE = (1 << 3),
                    PROXY_WEB_IE = (1 << 4);


                if (target.attr("name") === "Speaker") {
                    conf.currentSpeaker = selection;
                } else if (target.attr("name") === "Camera") {
                    conf.currentCamera = selection;
                } else if (target.attr("name") === "Microphone") {
                    conf.currentMicrophone = selection;
                } else if (target.attr("name") === "SelfViewLoopbackPolicy") {
                    conf.selfViewLoopbackPolicy = selection;
                } else if (target.attr("name") === "EchoCancel") {
                    conf.enableEchoCancellation = isChecked;
                } else if (target.attr("name") === "EchoDetect") {
                    conf.enableEchoDetection = isChecked;
                } else if (target.attr("name") === "AutoGain") {
                    conf.enableAudioAGC = isChecked;
                } else if (target.attr("name") === "AlwaysProxy") {
                    /* Set or unset bits in the bit mask */
                    if (isChecked) {
                        conf.proxySettings |= PROXY_VIDYO_FORCE;
                    } else {
                        conf.proxySettings &= ~PROXY_VIDYO_FORCE;
                    }
                } else if (target.attr("name") === "UseWebProxy") {
                    /* Set or unset bits in the bit mask */
                    if (isChecked) {
                        conf.proxySettings |= (PROXY_WEB_ENABLE | PROXY_WEB_IE);
                    } else {
                        conf.proxySettings &= ~(PROXY_WEB_ENABLE | PROXY_WEB_IE);
                    }
                } else if (target.attr("name") === "HideParticipants") {
                    conf.enableShowConfParticipantName = isChecked ? 0 : 1;
                } else if (target.attr("name") === "MuteMicrophone") {
                    conf.enableMuteMicrophoneOnJoin = isChecked;
                } else if (target.attr("name") === "HideCamera") {
                    conf.enableHideCameraOnJoin = isChecked;
                }
                clientConfigurationSet(conf);
                //if (target.attr("name") === "SelfViewLoopbackPolicy") {
                //    //twitching_operator();
                //}
            });
        $(document).on('ajax:before', '.users-group-video, .users-group-mic, .users-group-backstage', function () {
            $(this).attr("disabled", "disabled");
        });

        $(document).on('ajax:complete', '.users-group-video, .users-group-mic, .users-group-backstage', function () {
            $(this).removeAttr("disabled");
        });
        /* Detect fullscreen mode change
         * Not all browsers fully support this.
         * Standard is not yet approved so browser specific events are used.
         */
        $(document)
            .on("mozfullscreenchange", function () {
                logger.log('info', 'ui', "document.mozfullscreenchange");
                if (!document.mozFullScreen) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            })
            .on("webkitfullscreenchange", function () {
                logger.log('info', 'ui', "document.webkitfullscreenchange");
                if (!document.webkitFullscreenElement) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            })
            .on("msfullscreenchange", function () {
                logger.log('info', 'ui', "document.msfullscreenchange");
                if (!document.msFullscreenElement) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            })
            .on("oldmsfullscreenchange", function () {
                logger.log('info', 'ui', "document.oldmsfullscreenchange");
                if (!self.isFullscreen || !self.isFullpage) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            })
            .on("fullscreenchange", function () {
                logger.log('info', 'ui', "document.fullscreenchange");
                if (!document.fullscreenElement) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            })
            .on("MSFullscreenChange", function () {
                logger.log('info', 'ui', "document.MSFullscreenChange");
                if (!document.msFullscreenElement) {
                    self.events.fullscreenEvent.trigger("cancel");
                } else {
                    self.events.fullscreenEvent.trigger("done");
                }
            });

        $(document).on("click", "#media-player-btn", function (e) {
            e.preventDefault();
            if ($('#mediaPlayerContainer').is(":visible")) {
                uiHideMediaPlayer();
            } else {
                uiShowMediaPlayer();
                if (!window.Immerss.guest) {
                    self.websocketChannel.trigger('client-media-player-start', {});
                }
            }
        });

        return self;
    };

    /**
     * Master function to bind all asynchronous events
     * @return {Object} Application object
     */
    applicationBindEvents = function () {
        logger.log('info', 'application', 'applicationBindEvents()');

        applicationBindUIEvents();
        applicationBindSubscribeEvents();

        return self;
    };


    uiStart = function () {
        logger.log('info', 'ui', 'uiStart()');
        uiShowInCallContainerMinimizedAndWithPlugin();
        return self;
    };

    setShareUI = function () {
        logger.log('info', 'ui', "inCallButtonLocalShare::click");
        var transformedData = {
            windows: [{
                id: 'screen',
                name: 'Screen',
                highlight: false
            },{
                id: 'window',
                name: 'Window',
                highlight: false
            }],
            desktops: [],
            sharing: (self.currentShareId === undefined) ? false : true
        };
        uiLocalSharesUpdateWithData(transformedData);
        return self;
    };


    uiConfigurationUpdateWithData = function (data) {
        logger.log('info', 'ui', 'uiConfigurationUpdateWithData()');
//        var htmlData = self.templates.configurationTemplateWebrtc(data);
        //self.cache.$configurationContainer.html(htmlData);
        navigator.mediaDevices.enumerateDevices().then(gotDevices).catch(handleError);
        return self;
    };

    uiSetMicMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetMicMuted()');
        self.cache.$inCallButtonMuteMicrophone.trigger('mute', mute);
        return self;
    };

    uiSetSpeakerMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetSpeakerMuted()');
        self.cache.$inCallButtonMuteSpeaker.trigger('mute', mute);
        return self;
    };

    uiSetVideoMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetVideoMuted()');
        self.cache.$inCallButtonMuteVideo.trigger('mute', mute);
        return self;
    };

    uiReportGuestLoginError = function (error) {
        logger.log('info', 'ui', 'uiReportGuestLoginError()');

        $.showFlashMessage(error, {type: 'error', timeout: 3000});
        return self;
    };

    uiReportUserLoginError = function (error) {
        logger.log('info', 'ui', 'uiReportUserLoginError()');

        $.showFlashMessage(error, {type: 'error', timeout: 3000});
        return self;
    };

    uiCallCleanup = function () {
        logger.log('info', 'ui', 'uiCallCleanup()');
        if (self.isFullscreen || self.isFullpage) {
            uiFullscreenCancel();
        }
        if (self.isGuestLogin || self.isLoggedIn) {
            uiInCallShow(false);
        }
        return self;
    };

    uiShowInCallContainerMinimizedAndWithPlugin = function () {
        logger.log('info', 'ui', 'uiShowInCallContainerMinimizedAndWithPlugin()');

        /* We need to make sure about:
         * 1. Plugin is loaded
         * 2. Plugin is visible
         * So when we make plugin visible then we start it after deferred
         * variable for plugin ready event is resolved.
         */
        //self.cache.$inCallContainer.show(function () {

        self.events.pluginPreloadEvent
            .done(function () {
                logger.log('info', 'ui', "uiShowInCallContainerMinimizedAndWithPlugin - plugin is ready and visible initializing");
                //initWebRTC();
            })
            .fail(function () {
                logger.log('warning', 'ui', "uiShowInCallContainerMinimizedAndWithPlugin - Failed to load plugin");
            });
        //});

        return self;
    };

    uiShareSelect = function (target) {
        logger.log('info', 'ui', 'uiShareSelect(', target, ')');
        /* Remove highlight from previously highlighted items */
        /*jslint unparam: true*/
        $.each($("." + self.config.inCallSelectedShareClass), function (i, obj) {
            $(obj).removeClass(self.config.inCallSelectedShareClass);
        });
        /*jslint unparam: false*/
        /* Add highlight on a clicked item */
        target.addClass(self.config.inCallSelectedShareClass);
        return self;
    };

    uiSharesUpdateWithData = function (data) {
        logger.log('info', 'ui', 'uiSharesUpdateWithData(', data, ')');
        var htmlData = self.templates.inCallSharesTemplate(data);
        /* Show new data */
        self.cache.$inCallShareList.html(htmlData);
        /* Disable shares button if no shares available */
        if (data.shares.length) {
            self.cache.$inCallButtonShare.removeClass('disabled');
        } else {
            self.cache.$inCallButtonShare.addClass('disabled');
        }
        return self;
    };

    uiLocalShareReset = function () {
        logger.log('info', 'ui', 'uiLocalShareReset()');
        self.currentShareId = undefined;
    };

    uiLocalSharesUpdateWithData = function (data) {
        logger.log('info', 'ui', 'uiLocalSharesUpdateWithData(', data, ')');
        data.isShareScreenActive = self.isShareScreenActive;
        var htmlData = self.templates.inCallLocalSharesTemplate(data);
        /* Show new data */
        self.cache.$inCallLocalShareList.html(htmlData);
        $('#inCallLocalShareList').html(htmlData);
        return self;
    };

    uiParticipantsUpdateWithData = function (data) {
        //logger.log('info', 'ui', 'uiParticipantsUpdateWithData(', data, ')');
        if (self.currentMember !== undefined) {
            var participant = undefined;
            $.each(data.participants, function (i, res) {
                if (res.name == self.currentMember.displayName) {
                    participant = res;
                    return true;
                }
            });
            if (participant !== undefined) {
                participant.isOwner = Immerss.presenter;
                participant.isChatEnabled = self.isChatEnabled;
                participant.role = self.currentMember.role;
                participant.VideoDisabled = self.currentMember.VideoDisabled;
                participant.MicDisabled = self.currentMember.MicDisabled;
                participant.userId = self.currentMember.id;
                participant.hasControl = self.hasControl;
                participant.controlStatus = self.currentMember.hasControl;
                participant.isPresenter = (self.currentMember.role == 'presenter');
                participant.isCoPresenter = (self.currentMember.role == 'co_presenter');
                participant.urlAllowControl = '/lobbies/' + Immerss.roomId + '/allow_control?co_presenter_id=' + self.currentMember.id;
                participant.urlDisableControlUrl = '/lobbies/' + Immerss.roomId + '/disable_control?co_presenter_id=' + self.currentMember.id;
                participant.urlMuteSound = '/lobbies/' + Immerss.roomId + '/mute?member_id=' + self.currentMember.id;
                participant.urlUnMuteSound = '/lobbies/' + Immerss.roomId + '/unmute?member_id=' + self.currentMember.id;
                participant.urlMuteVideo = '/lobbies/' + Immerss.roomId + '/stop_video?member_id=' + self.currentMember.id;
                participant.urlBanKick = '/lobbies/' + Immerss.roomId + '/ban_kick?banned_id=' + self.currentMember.id;
                participant.urlUnMuteVideo = '/lobbies/' + Immerss.roomId + '/start_video?member_id=' + self.currentMember.id;
                participant.urlAnswerQuestion = '/lobbies/' + Immerss.roomId + '/answer?member_id=' + self.currentMember.id;
                participant.hasQuestion = $.inArray(parseInt(self.currentMember.id), self.usersQuestionsList) != -1;
                participant.urlMuteAllSound = '/lobbies/' + Immerss.roomId + '/mute_all';
                participant.urlUnMuteAllSound = '/lobbies/' + Immerss.roomId + '/unmute_all';
                participant.urlMuteAllVideo = '/lobbies/' + Immerss.roomId + '/stop_all_videos';
                participant.urlUnMuteAllVideo = '/lobbies/' + Immerss.roomId + '/start_all_videos';
                participant.urlEnableBackstage = '/lobbies/' + Immerss.roomId + '/enable_backstage?member_id=' + self.currentMember.id;
                participant.urlDisableBackstage = '/lobbies/' + Immerss.roomId + '/disable_backstage?member_id=' + self.currentMember.id;
                participant.urlEnableAllBackstage = '/lobbies/' + Immerss.roomId + '/enable_all_backstage';
                participant.urlDisableAllBackstage = '/lobbies/' + Immerss.roomId + '/disable_all_backstage';
                var htmlData = self.templates.inCallParticipantTemplate(participant);
                $('#memberBody').html(htmlData);
            }
        }
        return self;
    };

    uiInCallShow = function (show, inFullpage) {
        logger.log('info', 'ui', 'uiInCallShow(', show, inFullpage, ')');
        if (show) {
          $('body').addClass('showVideo');intoduceInit();
          self.cache.$plugin.css("width", "100%");
          self.cache.$plugin.css("height", "100%");
            if (inFullpage) { // Configure for full page
            }
            else {
            }
        } else {
        }
        return self;
    };

    self.uiInCallShowApp = uiInCallShow;

    uiReportError = function (error, details) {
        logger.log('info', 'ui', 'uiReportError(', error, ", ", details, ')');

        $.showFlashMessage(error + details, {type: 'error', timeout: 3000});
        return self;
    };

    uiReportInfo = function (title, details) {
        logger.log('info', 'ui', 'uiReportInfo(', title, ", ", details, ')');

        $.showFlashMessage(title + details, {type: 'instructions', timeout: 999999999});
        return self;
    };

        window.count_camera = -1;
        window.count_mic = -1;
        window.count_speaker = -1;
        window.numberOfShares = 0;
        window.participantsCount = 1;

        var clientSharesGet = function () {
            var that = {};
            that.type = "RequestGetWindowShares";

            // public properties for created object,
            // initial values of which are potentially passed
            // into this factory function
            that.requestType = "";// params && params.requestType || "";
            that.remoteAppUri = [""];//params && params.remoteAppUri || [""];
            that.remoteAppName = [""];// params && params.remoteAppName || [""];
            that.numApp = 0;// params && params.numApp || 0;
            that.currApp = 0;// params && params.currApp || 0;
            that.eventUri = "";// params && params.eventUri || "";
            that.newApp = 0;//params && params.newApp || 0;

            var msg;
            if (self.client.sendRequest(that)) {
                msg = 'VidyoWebRTC' + " sent " + that.type + " request successfully";
            } else {
                msg = 'VidyoWebRTC' + " did not send " + that.type + " request successfully!";
            }
            return that;
        };

        window.client_restart = true
        // declarations for functions, wired to plugin events
        window.onOutEvent = function (event) {
            event = event || {};
            logger.log('info', 'ui', "Received out event with type of " + event.type, event);
            if (event.type == 'OutEventPluginConnectionSuccess') {
                self.events.pluginLoadedEvent.trigger('done');

            } else if (event.type == 'OutEventSignIn') {
                if (parseInt(event.activeEid, 10) === 0) {
                    var licenseEvent = {
                        'type': "InEventLicense"
                    };
                    self.client.sendEvent(licenseEvent);
                }
            } else if (event.type == 'OutEventConferenceActive') {
                logger.log('info', 'callback', "OutEventConferenceActive()");

                /* Enforce preview mode to current */
                clientPreviewModeSet(self.currentPreviewMode);
                /* Query for participants */
                self.events.connectEvent.trigger('done');
            } else if (event.type == 'OutEventConferenceEnded') {
                self.client.stop();
                self.events.disconnectEvent.trigger('done');

                if (window.client_restart){
                  self.client.start();
                }
            } else if (event.type == 'OutEventJoinProgress') {
                //does not occur in WebRTC
            } else if (event.type == 'OutEventAddShare') {
                clientSharesSetCurrent(event.URI);
            } else if (event.type == 'OutEventRemoveShare') {
                clientSharesSetCurrent();
            } else if (event.type == 'OutEventVideoStreamsChanged') {
                participantsCount = event.streamCount;
                adjustLayout();
            } else if (event.type == 'OutEventMutedVideo') {
                uiSetVideoMuted(event.isMuted)
            } else if (event.type == 'OutEventMutedServerVideo') {
                uiSetVideoMuted(event.isMuted)
            } else if (event.type == 'OutEventMutedAudioIn') {
                uiSetMicMuted(event.isMuted)
            } else if (event.type == 'OutEventMutedAudioOut') {
                uiSetSpeakerMuted(event.isMuted)
            } else if (event.type == 'OutEventGroupChat') {
                    logger.log('info', 'callback', "OutEventGroupChat()", event);
            } else if (event.type == 'OutEventPrivateChat') {
                    logger.log('info', 'callback', "OutEventPrivateChat()", event);
            } else if (event.type == 'callState') {
              if(event.error  == 500){
                  setTimeout(function () {
                      $.showFlashMessage((event.fault + '. Trying to reconnect'), {type: 'error', timeout: 3000});
                      self.client.start();
                  }, 10000);
              }
            }

        };

        var sendLeaveEvent = function () {
            var inEvent = {
                'type': "InEventLeave"
            };
            var msg;

            if (self.client.sendEvent(inEvent)) {
                msg = 'VidyoWebRTC' + " sent leave event successfully";
            } else {
                msg = 'VidyoWebRTC' + " not in a call!";
            }
            logger.log('info', 'VidyoWebRTC', msg);

        };

        var sendMuteMicEvent = function () {
            var inEvent = {
                'type': "InEventMuteAudioIn",
                'willMute': true
            };
            var msg;
            if (self.client.sendEvent(inEvent)) {
                msg = 'VidyoWebRTC' + " sent Mute Mic successfully";
            } else {
                msg = 'VidyoWebRTC' + " could not send Mute Mic successfully!";
            }
            logger.log('info', 'VidyoWebRTC', msg);
        };

        var sendUnmuteMicEvent = function () {
            var inEvent = {
                'type': "InEventMuteAudioIn",
                'willMute': false
            };
            var msg;
            if (self.client.sendEvent(inEvent)) {
                msg = 'VidyoWebRTC' + " sent Mute Mic successfully";
            } else {
                msg = 'VidyoWebRTC' + " could not send Mute Mic successfully!";
            }
            logger.log('info', 'VidyoWebRTC', msg);
        };

        var adjustLayout = function () {
            $(window.audioOutputSelect.options).each(function(k,v) {
              if($.cookie('webrtcLastOutput') == this.text){
                window.audioOutputSelect.selectedIndex = k
              }
            });
            changeAudioDestination();


            if (numberOfShares) {
                allScreenCount  = participantsCount + 1; // + Self view + share view
                $('#shareVideoTile').show();
                if(!$('.ShareFix').length >= 1){
                    $('.videoContainer-tileList').prepend('<div class="tile ShareFix"></div>');
                }

            } else {
                $('#shareVideoTile').hide();
                $('.ShareFix').remove();
                allScreenCount  = participantsCount;
            }
            var el= $("div[class*='VT-C']")[0]
            el.className = el.className.replace(/\bVT-C-.*\b/g, 'VT-C-' + allScreenCount );

        };

        var stop = function () {
            var msg;
            if (self.client.stop()) {
                msg = 'VidyoWebRTC' + " stopped successfully";
            } else {
                msg = 'VidyoWebRTC' + " did not stop successfully!";
                alert(msg);
            }
            log(msg);
        };

    uiDesktopNotification = function (title, message, timeout, onClick) {
        logger.log('info', 'ui', 'uiDesktopNotification(', title, message, timeout, ')');
        var notification;
        if (!self.config.enableDesktopNotifications) {
            return undefined;
        }

        if (timeout === undefined) {
            timeout = 5000;
        }
        if (window.webkitNotifications) {
            logger.log('info', 'ui', 'uiDesktopNotification() - supported webkit');
            if (window.webkitNotifications.checkPermission() === 0) { // 0 is PERMISSION_ALLOWED
                notification = window.webkitNotifications.createNotification(
                    'favicon.ico', title, message);
                notification.message = message;

                notification.onclick = function () {
                    window.focus();
                    notification.cancel();
                    if (onClick) {
                        onClick();
                    }
                };

                notification.show();

                if (timeout > 0) {
                    setTimeout(function () {
                        notification.cancel();
                    }, timeout);
                }
            } else {
                logger.log('warning', 'ui', 'uiDesktopNotification() - don\'t have permissions for webkit');
            }
        } else if (window.Notification) {
            logger.log('info', 'ui', 'uiDesktopNotification() - supported HTML5');
            if (window.Notification.permission.toLowerCase() === "granted") {
                notification = window.Notification(title, {
                    icon: 'favicon.ico',
                    body: message
                });
                notification.message = message;

                notification.onclick = function () {
                    window.focus();
                    notification.close();
                    if (onClick) {
                        onClick();
                    }
                };

                if (timeout > 0) {
                    setTimeout(function () {
                        notification.close();
                    }, timeout);
                }
            } else {
                logger.log('warning', 'ui', 'uiDesktopNotification() - don\'t have permissions for HTML5');
            }
        } else {
            logger.log('info', 'ui', 'uiDesktopNotification() - not supported');
        }
        return notification;
    };

    uiFullscreenSet = function (elem) {
        logger.log('info', 'ui', "uiFullscreenSet()");
        /* WARNING: It is a known problem in Safari that Safari does not support keyboard input in the full screen mode. */

        /* We need to detect what full screen approach to make as full screen API is not yet standardized */

        function requestFullScreen(element) {
            logger.log('info', 'ui', "uiFullscreenSet()::requestFullScreen()");

            // Supports most browsers and their versions.
            var requestMethod = element.requestFullScreen || element.webkitRequestFullscreen || element.mozRequestFullScreen || element.msRequestFullScreen || element.msRequestFullscreen;

            if (requestMethod) { // Native full screen.
                requestMethod.call(element);
            } else if (window.ActiveXObject !== undefined) { // IE fallback.
                try {
                    var wscript = new ActiveXObject("WScript.Shell");
                    if (wscript !== null) {
                        wscript.SendKeys("{F11}");

                    }
                } catch (e) {
                    logger.log('warning', 'ui', 'uiFullscreenSet() - IE security level prevented going to full screen');
                    uiReportError('Fullscreen error. ', 'IE security level prevented going to full screen');
                }

                $(document).trigger("oldmsfullscreenchange");
            }
        }

        requestFullScreen(elem);
        return self;
    };

    uiFullscreenCancel = function () {
        logger.log('info', 'ui', "uiFullscreenCancel()");
        self.isFullscreen = false;
        self.isFullpage = false;
        /* We need to detect what full screen approach to make as full screen API is not yet standardized */

        function requestCancelFullScreen() {
            logger.log('info', 'ui', "uiFullscreenCancel()::requestCancelFullScreen()");

            // Supports most browsers and their versions.
            var requestMethod = document.cancelFullScreen || document.webkitCancelFullScreen || document.mozCancelFullScreen || document.msCancelFullScreen || document.msExitFullscreen;

            if (requestMethod) { // Native full screen.
                requestMethod.call(document);
            } else if (window.ActiveXObject !== undefined) { // Older IE.
                try {
                    var wscript = new ActiveXObject("WScript.Shell");
                    if (wscript !== null) {
                        wscript.SendKeys("{F11}");
                    }
                } catch (e) {
                    logger.log('warning', 'ui', 'uiFullscreenSet() - IE security level prevented leaving full screen');
                }
                $(document).trigger("oldmsfullscreenchange");
            }
        }

        /* Will trigger fullscreenchange event */
        requestCancelFullScreen();
        return self;
    };

    clientUserLogin = function (inEventLoginParams) {
        logger.log('info', 'login', 'clientUserLogin()');

        var inEvent = vidyoClientMessages.inEventLogin(inEventLoginParams);

        if (!self.client.sendEvent(inEvent)) {
            self.events.loginEvent.trigger('fail', "Failed to send inEvent");
            return undefined;
        }
        return self;
    };


    clientGuestLoginAndJoin = function (inEventLoginParams) {
        logger.log('info', 'login', 'clientGuestLoginAndJoin(', inEventLoginParams, ')');
        navigator.mediaDevices.enumerateDevices().then(gotDevices).catch(handleError);
        //fullURI: "http://wava.sandboxga.vidyo.com/flex.html?roomdirect.html&key=NlL1cTBfOdi7cK2VRprsYDfss3s", portalUri: "http://wava.sandboxga.vidyo.com/", roomKey: "NlL1cTBfOdi7cK2VRprsYDfss3s", guestName: "Gürhard last-name-1", pin: undefined} )
        var inEvent = {
            'type': "PrivateInEventVcsoapGuestLink",
            'typeRequest': "GuestLink",
            'requestId': 1234,
            'portalUri': inEventLoginParams.portalUri,
            'roomKey': inEventLoginParams.roomKey,
            'pin': '',
            'guestName': inEventLoginParams.guestName
        };
        if (self.client.sendEvent(inEvent)) {
            msg = '' + " ";
            logger.log('info', 'VidyoWebRTC', 'sent guest login event successfully');
        } else {
            logger.log('error', 'VidyoWebRTC', 'not sent guest login event successfully!');
            self.events.connectEvent.trigger('fail', {error: "Participant join error"});
        }
        return self;
    };

    clientConferenceLeave = function () {
        logger.log('info', 'call', "clientConferenceLeave()");

        var inEvent = vidyoClientMessages.inEventLeave();
        if (!self.client.sendEvent(inEvent)) {
            self.events.disconnectEvent.trigger('fail', "Failed to send leave event");
        } else {
            self.events.disconnectEvent.trigger('done');
        }
        return self;
    };

    clientSpeakerMute = function (mute) {
        logger.log('info', 'call', 'clientSpeakerMute()');
        var params = {}, inEvent, msg;
        params.willMute = mute;
        inEvent = vidyoClientMessages.inEventMuteAudioOut(params);
        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientSpeakerMute(): " + msg);

        return self;
    };

    clientMicrophoneMute = function (mute) {
        logger.log('info', 'call', 'clientMicrophoneMute()');
        if (mute) {
            sendMuteMicEvent();
        } else {
            sendUnmuteMicEvent();
        }
        return self;
    };

    clientVideoMute = function (mute) {
        logger.log('info', 'call', 'clientVideoMute()');
        var params = {}, inEvent, msg;
        params.willMute = mute;
        inEvent = vidyoClientMessages.inEventMuteVideo(params);
        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientVideoMute(): " + msg);

        return self;
    };

    clientRecordAndLivestreamStateGet = function () {
        logger.log('info', 'call', 'clientRecordAndLivestreamStateGet()');
        var request = vidyoClientMessages.requestGetConferenceInfo({});
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'call', "clientRecordAndLivestreamStateGet(): " + msg, request);

        return request;
    };

    clientCurrentUserGet = function () {
        //logger.log('info', 'configuration', 'clientCurrentUserGet()');
        var request = vidyoClientMessages.requestGetCurrentUser({});
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        //logger.log('info', 'configuration', "requestGetCurrentUser(): " + msg, request);

        return request;
    };

    clientSharesGet = function () {
        logger.log('info', 'call', 'clientSharesGet()');
        var request = vidyoClientMessages.requestGetWindowShares({});
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'call', "clientSharesGet(): " + msg, request);

        return request;
    };

    clientSharesSetCurrent = function (newURI) {
      logger.log('info', 'portal', 'clientSharesSetCurrent');
      var request = clientSharesGet();
      var shares = request.numApp;
      if (newURI) {
        for (i = 0; i < request.numApp; i++) {
          if (request.remoteAppUri[i] == newURI) {
            request.newApp = i + 1;
            break;
          }
        }
      } else {
        request.newApp = request.numApp;
      }
      request.type = "RequestSetWindowShares";
      request.requestType = "ChangeSharingWindow";

      var msg;

      if (self.client.sendRequest(request)) {
        msg = 'VidyoWebRTC' + " sent " + request.type + " request successfully";
      } else {
        msg = 'VidyoWebRTC' + " did not send " + request.type + " request successfully!";
      }
      numberOfShares = request.newApp;
      adjustLayout();

      return shares;
    };

    clientPreviewModeToggle = function () {
        logger.log('info', 'call', "clientPreviewModeToggle()");

        var previewMode;

        if (self.currentPreviewMode.localeCompare("None") === 0) {
            previewMode = "PIP";
        } else if (self.currentPreviewMode.localeCompare("PIP") === 0) {
            previewMode = "Dock";
        } else { // "Dock"
            previewMode = "None";
        }

        self.currentPreviewMode = previewMode;

        clientPreviewModeSet(previewMode);

        /* Save for next session */
        //helperPersistentStorageSetValue('previewMode', previewMode);
        return self;
    };

    clientPreviewModeSet = function (previewMode) {
        logger.log('info', 'call', "clientPreviewModeSet('" + previewMode + "')");

        var params = {}, inEvent, msg;
        params.previewMode = previewMode;

        inEvent = vidyoClientMessages.eventPreview(params);
        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientPreviewModeSet(): " + msg);

        return self;
    };

    clientLayoutToggle = function () {
        logger.log('info', 'call', "clientLayoutToggle()");
        self.numPreferred = self.numPreferred ? 0 : 1;
        return clientLayoutSet(self.numPreferred);
    };

    clientLayoutSet = function (numPreferred) {
        logger.log('info', 'call', "clientLayoutSet(", numPreferred, ")");
        var params = {}, inEvent, msg;
        params.numPreferred = numPreferred;

        inEvent = vidyoClientMessages.inEventLayout(params);
        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        self.numPreferred = params.numPreferred;
        logger.log('info', 'call', "clientLayoutSet(): " + msg);

        return self;
    };

    clientLocalMediaInfo = function () {
        //logger.log('info', 'call', 'clientLocalMediaInfo()');
        var output = {};
        var requestGetEncodeResolution = vidyoClientMessages.requestGetEncodeResolution();
        var requestGetVideoFrameRateInfo = vidyoClientMessages.requestGetVideoFrameRateInfo();
        var requestGetMediaInfo = vidyoClientMessages.requestGetMediaInfo();
        var msg;
        if (self.client.sendRequest(requestGetEncodeResolution) &&
            self.client.sendRequest(requestGetVideoFrameRateInfo) &&
            self.client.sendRequest(requestGetMediaInfo)) {
            msg = "VidyoWeb sent all requests successfully";
            output = $.extend(output, requestGetVideoFrameRateInfo, requestGetMediaInfo, requestGetEncodeResolution);
        } else {
            msg = "VidyoWeb did not send requests successfully!";
        }
        //logger.log('info', 'call', "clientLocalMediaInfo(): " + msg, output);
        return output;
    };



    clientConfigurationGet = function () {
        logger.log('info', 'configuration', 'clientConfigurationGet()');
        var request = vidyoClientMessages.requestGetConfiguration({});
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'configuration', "clientConfigurationGet(): " + msg, request);

        return request;
    };

    clientConfigurationSet = function (vidyoConfig) {
        logger.log('info', 'configuration', 'clientConfigurationGet(', vidyoConfig, ')');
        var request = vidyoClientMessages.requestSetConfiguration(vidyoConfig);
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'configuration', "clientConfigurationSet(): " + msg, request);

        return request;
    };

    clientLocalSharesGet = function () {
        logger.log('info', 'call', 'clientDesktopsAndWindowsGet()');
        var request = vidyoClientMessages.requestGetWindowsAndDesktops({});
        var msg;
        if (self.client.sendRequest(request)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'call', "clientDesktopsAndWindowsGet(): " + msg, request);

        return request;
    };

    clientLocalShareStart = function (shareId) {
        logger.log('info', 'call', "clientLocalShareStart('", shareId, "')");

        var inEvent, msg;
        if (shareId === undefined) {
          inEvent = vidyoClientMessages.inEventUnshare();
        } else {
          inEvent = vidyoClientMessages.inEventShare({
            window: shareId
          });
        }
        if (self.client.sendEvent(inEvent)) {
          msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
          msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientLocalShareStart(): " + msg);


        return self;
    };

    clientLocalShareStop = function () {
        logger.log('info', 'call', "clientLocalShareStop()");

        var inEvent, msg;
        inEvent = vidyoClientMessages.inEventUnshare();

        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientLocalShareStop(): " + msg);

        return self;
    };

    clientConfigurationBootstrap = function (conf) {
        logger.log('info', 'call', "clientConfigurationBootstrap()");

        conf.enableAutoStart = 0;
        conf.enableShowConfParticipantName = true;
        conf.userID = "";
        conf.password = "";
        conf.serverAddress = "";
        conf.serverPort = "";
        conf.portalAddress = "";

        return clientConfigurationSet(conf);
    };

    initWebRTC = function(){
        self.config.vidyoConfig = $.extend({}, self.config.vidyoConfig, config);
        self.client = vidyoClient();
        self.client.setDefaultOutEventCallbackMethod(onOutEvent);
        self.client.setOutEventCallbackObject(this);
        self.client.setLogCallback(logger.log);
        self.client.setSessionManager(Immerss.vidyoWebrtcDomain);
        if (self.client.start()) {
            logger.log('info', 'login', ('VidyoWebRTC' + 'started successfully'));
        } else {
            logger.log('info', 'login', ('VidyoWebRTC' + 'did not start successfully!'));
            self.events.connectEvent.trigger('fail', {error: msg});
            return undefined;
        }
    };

    loginParticipantAndWait = function (skip_websocket) {
        if(!skip_websocket){
            initWebsocketAndWait(self)
        }
        if (Immerss.presenter) {
            var inEventLoginParams = {};
            inEventLoginParams.fullURI = Immerss.guestUri + Immerss.presenterKey;


            fullURIArray = inEventLoginParams.fullURI.split('flex.html?roomdirect.html&key=');
            inEventLoginParams.portalUri = fullURIArray[0];
            inEventLoginParams.roomKey = fullURIArray[1];

            inEventLoginParams.guestName = 'Presenter';
            inEventLoginParams.pin = 0;
            self.myAccount = {
                displayName: inEventLoginParams.guestName
            };
            if (clientGuestLoginAndJoin(inEventLoginParams) !== undefined) {
                logger.log('info', 'portal','application::guestLoginButton::click - sent guest login request');
                self.loginInfo = $.extend({}, self.loginInfo, inEventLoginParams);
            }
        }
    };


    helperConferenceUpdateTimerStart = function (timeout) {
        logger.log('info', 'application', "helperConferenceUpdateTimerStart()");
        var refreshFunction = function () {
            var participants = clientParticipantsGet();
            self.events.participantUpdateEvent.trigger('done', [participants]);
        };
        refreshFunction();
        if (self.participantRefreshTimer) {
            window.clearInterval(self.participantRefreshTimer);
            self.participantRefreshTimer = 0;
        }
        self.participantRefreshTimer = window.setInterval(refreshFunction, timeout);
        return self;
    };

    helperConferenceUpdateTimerStop = function () {
        logger.log('info', 'application', "helperConferenceUpdateTimerStop()");
        window.clearInterval(self.participantRefreshTimer);
        self.participantRefreshTimer = 0;
        return self;
    };



    var detectExtension = function (extensionId, callback) {
      if ($('#immersswebrtcscreenshareIsInstalled').length){
          console.log('Chrome Extension detected');
          callback(true);
      }else{
          console.log('Chrome Extension not detected');
          callback(false);
      }
    };

  window.extensionInstalled = !Immerss.isChrome;

    var detectExtensionAndContinue = function() {
      if (!Immerss.isChrome){return true}

      detectExtension('jbagnbabffebnloeajochhpipcjhpamb', function (extensionInstalled) {
        if (extensionInstalled) {
            window.extensionInstalled = true;
            $('#extInstallBut').hide();
            $('#inCallLocalShareList').show();
        } else {
            $('#extInstallBut').show();
            $('#inCallLocalShareList').hide();
            setTimeout(detectExtensionAndContinue, 5000);
        }
      });
    };

  var main = function () {
        if (!Immerss.roomRtmp) {
          initWebRTC();
        }
        detectExtensionAndContinue();
        applicationBuildTemplates();

        if (Immerss.roomRtmp){
          initWebsocketAndWait(self)
        }else{
          applicationAddPlugin();
        }
        applicationBuildCache();
        applicationBuildSubscribeEvents();
        if (Immerss.roomRtmp){
          $('body').addClass('showVideo');intoduceInit();
        }else{
          uiStart();
        }
        applicationBindEvents();
        uiTimeLeft(self);
        pingPong(self);
        bindEventsStreamButtons();
        return self;
    };

    self.main = main;
    self.application = application;
    return self;

};


$(function () {
    logger.enable(vidyoConfig.enableAppLogs); // Don't show logs if configuration prohibits
    logger.enableStackTrace(vidyoConfig.enableStackTrace);
    logger.setLevelsCategories(vidyoConfig.applicationLevelsCategories);

    logger.log('info', 'application', 'domReady::DOM is loaded');

    app = application(vidyoConfig);
    app.main();

    if (!vidyoConfig.envProduction) {
        window.app = app; // use this as a hook for debugging
    }
});

