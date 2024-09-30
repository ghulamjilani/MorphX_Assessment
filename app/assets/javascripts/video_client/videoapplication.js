//= require video_client/shared/required_applications

//= require_self


//= require video_page/vidyo/proxywrapper
//= require video_page/vidyo/vidyo.client.messages
//= require video_page/vidyo/vidyo.client.private.messages
//= require video_page/vidyo/vidyo.client
//= require video_page/main.config


/**
 * Main application module
 * @param  {Object} config Configuration (main.config)
 * @return {Object}        Application rechannel
 */
var application = function (config) {

    var handlebars = {default: Handlebars};
    /**
     * Application rechannel module
     * @type {Object}
     */
    var self = {};

    /**
     * Application configuration
     * @type {Object}
     */
    self.config = config;

    /**
     * Close the window only then session stoped
     * @type {Object}
     */
    self.closeWindow = true
    /**
     * Vidyo library specific configuration
     * @type {Object}
     */
    self.config.vidyoLib = {};
    /**
     * Holds caches DOM
     * @type {Object}
     */
    self.cache = {};

    /**
     * Websocket subscribe
     * @type {Object}
     */
    self.websocketChannel = null;

    /**
     * Chat enabled by default?
     * @type {Object}
     */

    self.isChatEnabled = false;

    /**
     * Holds cached events
     * @type {Object}
     */
    self.events = {};
    /**
     * Data about user login parameters
     * @type {Object}
     */
    self.loginInfo = {};

    /**
     * Data about guest login parameters
     * @type {Object}
     */
    self.guestLoginInfo = {};

    /**
     * Map of handlebars templates
     * @type {Object}
     */
    self.templates = {};

    /**
     * Guest login request sequencer
     * @type {Number}
     */
    self.currentRequestId = 1;

    /**
     * Holds information about contacts and searches users
     * @type {Object}
     */
    self.users = {
        favNum: "",
        fav: [],
        userNum: "",
        user: []
    };
    /**
     * Hold last users variable so we can revert in case
     * when search is canceled
     * @type {Object}
     */
    self.lastUsers = self.users;

    self.hasControl = (!!Immerss.hasControl || !!Immerss.presenter);

    /**
     * Current preview mode. On application start it will be propagated from
     * persistent storage
     * @type {String}
     */
    self.currentPreviewMode = self.config.defaultPreviewMode;

    /**
     * Current mute state of microphone
     * @type {Boolean}
     */
    self.isMutedMic = false;

    /**
     * Current mute state of speaker
     * @type {Boolean}
     */
    self.isMutedSpeaker = false;

    /**
     * Current mute state of video
     * @type {Boolean}
     */
    self.isMutedVideo = false;

    /**
     * True if in fullscreen mode,
     * False otherwise
     * @type {Boolean}
     */
    self.isFullscreen = false;
    self.isFullpage = false;

    self.numPreferred = 0;

    /**
     * Holds information about current user on a portal.
     * Response to myAccount SOAP request to the portal.
     * @type {Object}
     */

    if(Immerss.presenter){
        self.myAccount = {
            displayName: 'Presenter'
        };
    }else{
        self.myAccount = {
            displayName: 'Participant'
        };
    }

    /**
     * Currently shared application id
     * @type {String}
     */
    self.currentShareId = undefined;

    self.isShareScreenActive = false;

    /**
     * Conference status
     * @type {Boolean}
     */
    self.inConference = false;

    /**
     * Is in joining state
     * @type {Boolean}
     */
    self.isJoining = false;

    /**
     * Status of participant list show
     * @type {Boolean}
     */
    self.isShowingParticipantList = true;

    /**
     * List of participants
     * @type {Object}
     */
    self.currentParticipants = [];
    self.currentMember = undefined;

    /* Configuration of log */
    self.logConfig = {};

    //Has participant asked question?
    self.hasAskedQuestion = false;

    //Users with questions
    self.usersQuestionsList = window.Immerss.usersQuestionsList;

    self.manageUsersShown = false;
    self.twitterFeedShown = false;
    self.donationsShown = false;

    /* IE 8 tweek for array */
    if (!Array.prototype.indexOf) {
        Array.prototype.indexOf = function (val) {
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

    /**
     * Cache jQuery DOM objects for performance
     * @return {Object} application object
     */
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
        self.cache.$inCallChatContainer = $(self.config.inCallChatContainer);
        self.cache.$inCallChatTabs = $(self.config.inCallChatTabs);
        self.cache.$inCallChatPanes = $(self.config.inCallChatPanes);
        self.cache.$inCallChatMinimizeLink = $(self.config.inCallChatMinimizeLink);
        self.cache.$inCallChatGroupTabLink = $(self.config.inCallChatGroupTabLink);
        self.cache.$inCallChatForm = $(self.config.inCallChatForm);
        self.cache.$inCallChatTextField = $(self.config.inCallChatTextField);
        self.cache.$inCallChatTextSend = $(self.config.inCallChatTextSend);
        self.cache.$inCallChatGroupPane = $(self.config.inCallChatGroupPane);
        self.cache.$inCallChatGroupTab = $(self.config.inCallChatGroupTab);
        self.cache.$pluginAndChatContainer = $(self.config.pluginAndChatContainer);
        self.cache.$pluginContainer = $(self.config.pluginContainer);
        self.cache.$plugin = $(self.config.pluginContainer).children(":first"); //Firefox quirk
        self.cache.$preCallImage = $(self.config.preCallImage);
        self.cache.pingImageUrl = self.config.pingImageUrl;
        self.cache.$askQuestion = $(self.config.askQuestion);
        return self;
    };

    /**
     * Build handlebars templates
     * @return {Object} Application object
     */
    applicationBuildTemplates = function () {
        self.templates.pluginTemplate = handlebars['default'].compile(self.config.pluginTemplate);
        self.templates.configurationTemplate = handlebars['default'].compile(self.config.configurationTemplate);
        self.templates.inCallParticipantTemplate = handlebars['default'].compile(self.config.inCallParticipantTemplate);
        self.templates.inCallSharesTemplate = handlebars['default'].compile(self.config.inCallSharesTemplate);
        self.templates.inCallLocalSharesTemplate = handlebars['default'].compile(self.config.inCallLocalSharesTemplate);
        self.templates.pluginInstallInstructionsTemplate = handlebars['default'].compile(self.config.pluginInstallInstructionsTemplate);
        self.templates.pluginEnableInstructionsTemplate = handlebars['default'].compile(self.config.pluginEnableInstructionsTemplate);
        self.templates.inCallChatTabTemplate = handlebars['default'].compile(self.config.inCallChatTabTemplate);
        self.templates.inCallChatPaneTemplate = handlebars['default'].compile(self.config.inCallChatPaneTemplate);
        self.templates.inCallChatPaneMessageTemplate = handlebars['default'].compile(self.config.inCallChatPaneMessageTemplate);
        self.templates.userWebsocketTemplate = handlebars['default'].compile(self.config.userWebsocketTemplate);
        //self.templates.banReasonsTemplate = HandlebarsTemplates['application/ban_reasons'];
        return self;
    };

    /**
     * Add plugin object to DOM
     * @return {Object} application object
     */
    applicationAddPlugin = function () {
        logger.log('log', 'application', 'applicationAddPlugin()');
        if(proxyWrapper.isChrome){
            $(self.config.pluginContainer).html('<video autoplay id='+  self.config.pluginIdName +'></video>');
        }else{
            var pluginContainer = $(self.config.pluginContainer);

            var htmlData = self.templates.pluginTemplate({
                id: self.config.pluginIdName,
                mimeType: self.config.pluginMimeType
            });

            pluginContainer.html(htmlData);
        }
        return self;
    };

    /**
     * Update application state to disconnected.
     * @return {Object} Application object
     */
    applicationCallCleanup = function () {
        logger.log('log', 'application', 'applicationCallCleanup()');
        helperConferenceUpdateTimerStop();
        self.inConference = false;
        self.isJoining = false;
        return self;
    };

    /**
     * Build subscription events
     * @return {Object} Application object
     */
    applicationBuildSubscribeEvents = function () {
        /* Build subscription events.
         * They are used to notify application about events from Vidyo
         * library so it can update UI state.
         */

        /* Plugin life-cycle */

        /*
         * Plugin preload happens only once and we may need to delay
         * actions associated with it so use jQuery defer for that instead of regular trigger/on events.
         */
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

    /**
     * Bind Vidyo plugin callbacks.
     * No direct access to UI/cache should be used in Vidyo callbacks.
     * See Vidyo.client.messages JavaScript file for details about events.
     * @return {Object} Application object
     */
    applicationBindVidyoCallbacks = function () {
        /*  Vidyo Library raw Callbacks.
         Will be translated to defers if needed.
         */
        logger.log('log', 'application', 'applicationBindVidyoCallbacks()');

        self.callbacks = {
            /**
             * Notification about log coming from Vidyo library
             * @param {Object} event Logging message details
             */
            PrivateOutEventLog: function (event) {
                if (self.logConfig.enableVidyoClientLogs) {
                    logger.log('debug', 'plugin', event);
                }
            },
            /**
             * Login process
             * @param {Object} event Login parameters used
             */
            OutEventLogin: function (event) {
                logger.log('info', 'callback', "OutEventLogin(", event, ")");
                if (event.error === 0) {
                    self.guestLoginInfo.portalUri = event.portalUri.split('/services/')[0];
                }
            },
            /**
             * Called when sign in process is in progress.
             * Used to initiate licensing procedure if needed.
             * @param {Object} e Event details
             */
            OutEventSignIn: function (e) {
                logger.log('info', 'callback', "OutEventSignIn()");

                /* SignIn is a part of connect process for guest only. */
                if (Immerss.guest) {
                    self.events.connectEvent.trigger('progress');
                } else {
                    self.events.loginEvent.trigger('progress');
                }

                if (parseInt(e.activeEid) === 0) {
                    logger.log('debug', 'callback', "OutEventSignIn(): will start license procedure");

                    var inEvent = vidyoClientMessages.inEventLicense();
                    self.client.sendEvent(inEvent);
                }
            },
            /**
             * Reports joining progress.
             * Good place to notify user about conference joining progress.
             */
            OutEventJoinProgress: function () {
            },
            /**
             * At this stage user is logged in into VidyoPortal.
             */
            OutEventSignedIn: function () {
                logger.log('info', 'callback', "OutEventSignedIn()");

                /*  Will continue connecting when guest;
                 Will be done login in when registered user.
                 */
                if (Immerss.guest) {
                    self.events.connectEvent.trigger('progress');
                } else {
                    self.events.loginEvent.trigger('done');
                }
            },
            /**
             * Vidyo library is successfully started.
             */
            OutEventLogicStarted: function () {
                logger.log('info', 'callback', "OutEventLogicStarted()");

                if(proxyWrapper.isChrome) {
                    chromeClientConfigurationUpdate(true)
                }else{
                    var conf = clientConfigurationGet();
                    /* Update configuration with defaults */
                    var updatedConf = clientConfigurationBootstrap(conf);
                    window.startedConf = updatedConf;
                    self.events.configurationUpdateEvent.trigger("done", updatedConf);

                }
            },
            /**
             * At this stage user is connected to the conference
             */
            OutEventConferenceActive: function () {
                logger.log('info', 'callback', "OutEventConferenceActive()");

                /* Enforce preview mode to current */
                clientPreviewModeSet(self.currentPreviewMode);
                /* Query for participants */
                self.events.connectEvent.trigger('done');
            },
            /**
             * Started to connect to a conference
             */
            OutEventJoining: function () {
                logger.log('info', 'callback', "OutEventJoining()");

            },
            /**
             * Notifies about connecting as guest progress
             * @param {Object} e Event details
             */
            PrivateOutEventVcsoapGuestLink: function (e) {
                logger.log('info', 'callback', "PrivateOutEventVcsoapGuestLink(", e, ")");

                if (e.result === "Failure") {
                    $.showFlashMessage('Connection problem, trying to reconnect.', {type: 'error', timeout: 3000});
                    clientUserLogout();
                    if(Immerss.presenter){
                        loginPesenter();
                    }else{
                        $.post('/lobbies/' + Immerss.roomId + '/auth_callback', {source_id: Immerss.sourceId}).error(function (response) {
                            uiReportError('Portal callback error', '')
                        });
                    }
                }
            },
            /**
             * Microphone mute state changed
             * @param {Object} e Event details
             */
            OutEventMutedAudioIn: function (e) {
                logger.log('info', 'callback', "OutEventMutedAudioIn()", e);

                self.events.muteUpdateEvent.trigger("done", {
                    device: "microphone",
                    mute: e.isMuted
                });
                self.isMutedMic = e.isMuted;
            },
            /**
             * Speaker mute state changed
             * @param {Object} e Event details
             */
            OutEventMutedAudioOut: function (e) {
                logger.log('info', 'callback', "OutEventMutedAudioOut()", e);

                self.events.muteUpdateEvent.trigger("done", {
                    device: "speaker",
                    mute: e.isMuted
                });

                self.isMutedSpeaker = e.isMuted;
            },
            /**
             * Video privacy (mute) state changed
             * @param {Object} e Event details
             */
            OutEventMutedVideo: function (e) {
                logger.log('info', 'callback', "OutEventMutedVideo()", e);

                self.events.muteUpdateEvent.trigger("done", {
                    device: "video",
                    mute: e.isMuted
                });
                self.isMutedVideo = e.isMuted;
            },
            /**
             * Mouse button is pressed
             * @param {Object} e Event details
             */
            OutEventMouseDown: function (e) {
                /* Exit fullscreen on double click */
                if (e.count === 2) {
                    if (self.isFullscreen) {
                        uiFullscreenCancel();
                    } else {
                        uiFullscreenCancel();
                    }
                }
            },
            /**
             * New share was added to the conference
             * @param {Object} e Event details
             */
            OutEventAddShare: function (e) {
                logger.log('info', 'callback', "OutEventAddShare()", e);
                if(proxyWrapper.isChrome) {
                    chromeClientSharesGet(function(shares){
                        self.events.shareUpdateEvent.trigger('done', shares);
                    })
                }else {
                    var shares = clientSharesGet();
                    self.events.shareUpdateEvent.trigger('done', shares);
                }

            },
            /**
             * Share was removed from the conference
             * @param {Object} e Event details
             */
            OutEventRemoveShare: function (e) {
                logger.log('info', 'callback', "OutEventRemoveShare()", e);

                if(proxyWrapper.isChrome) {
                    chromeClientSharesGet(function(shares){
                        self.events.shareUpdateEvent.trigger('done', shares);
                    })
                }else {
                    var shares = clientSharesGet();
                    self.events.shareUpdateEvent.trigger('done', shares);
                }

            },
            /**
             * User logged out from the VidyoPortal
             * @param {Object} e Event details
             */
            OutEventSignedOut: function (e) {
                logger.log('info', 'callback', "OutEventSignedOut()", e);

                if (e.error) {
                    if (e.error == '2002') { // I don't know why
                        $.showFlashMessage('Connection 2002 error, trying to reconnect.', {type: 'error', timeout: 3000});
                        clientUserLogout();
                        if(Immerss.presenter){
                            loginPesenter();
                        }else{
                            $.post('/lobbies/' + Immerss.roomId + '/auth_callback', {source_id: Immerss.sourceId}).error(function (response) {
                                uiReportError('Portal callback error', '')
                            });
                        }
                    } else if (e.error == '408' || e.error == '28'){
                            self.events.connectEvent.trigger('crash', 'Video service unavailable, trying to reconnect.');
                    } else {
                        self.events.connectEvent.trigger("fail", {error: "Error " + e.error});
                    }
                } else {
                    clientConferenceLeave();
                    self.events.logoutEvent.trigger("done");
                }
            },
            /**
             * Current conference was ended
             * @param {Object} e Event details
             */
            OutEventConferenceEnded: function (e) {
                logger.log('info', 'callback', "OutEventConferenceEnded()", e);
                clear_cache = new Date().getTime();
                PingService(self.cache.pingImageUrl+'?clear_cache='+ clear_cache, function(ms){
                    if(ms > 1499){
                        $.showFlashMessage(I18n.t('video.errors.network_connection'), {type: 'info', timeout: 3000})
                    }
                });
            },
            OutEventCallState: function (e) {
                logger.log('info', 'callback', "OutEventCallState()", e);
                /* Remote disconnect */
                if (e.callState === "Idle") {
                    /* Failed to connect */
                    if (self.isJoining) {
                        self.events.connectEvent.trigger('fail', {error: "Disconnected by server"});
                    } else {
                        self.events.disconnectEvent.trigger('done');
                    }
                }
            },
            OutEventIncomingCall: function (e) {
                logger.log('info', 'callback', "OutEventIncomingCall()", e);
            },
            OutEventIncomingCallEnded: function (e) {
                logger.log('info', 'callback', "OutEventIncomingCallEnded()", e);
            },
            OutEventPinParticipantDone: function (e) {
                logger.log('info', 'callback', "OutEventPinParticipantDone()", e);
            },
            OutEventGroupChat: function (e) {
                logger.log('info', 'callback', "OutEventGroupChat()", e);
                if (self.isChatEnabled) {
                    e.isGroup = true;
                    e.isOutgoing = false;
                    self.events.chatUpdateEvent.trigger("done", e);
                }
            },
            OutEventPrivateChat: function (e) {
                logger.log('info', 'callback', "OutEventPrivateChat()", e);
                if (self.isChatEnabled) {
                    e.isGroup = false;
                    e.isOutgoing = false;
                    self.events.chatUpdateEvent.trigger("done", e);
                }
            },
            OutEventConferenceInfoUpdate: function (e) {
                logger.log('info', 'callback', "OutEventConferenceInfoUpdate()", e);
                if (e.event === "Recording") {
                    if (e.eventStatus === true) {
                        self.events.recorderEvent.trigger("start");
                    } else {
                        self.events.recorderEvent.trigger("stop");
                    }
                }
            },
            OutEventDevicesChanged: function (e) {
                logger.log('info', 'callback', "OutEventDevicesChanged()", e);
                if(proxyWrapper.isChrome) {
                    chromeClientConfigurationUpdate()
                }else{
                    var conf = clientConfigurationGet();
                    /* Update configuration with new values */
                    self.events.configurationUpdateEvent.trigger("done", conf);
                }
            },
            extensionMsgClientClosed: function (e) {
                logger.log('info', 'callback', "extensionMsgClientClosed()", e);
                if (e.message === 'Native host has exited.') {
                    logger.log('info', 'callback', "VidyoClientForWeb stopped for some reason", e);
                }else if (e.message === 'Specified native messaging host not found.'){
                    logger.log('info', 'callback', "VidyoClientForWeb not Found or not installed()", e);
                }
            },
            extensionMsgClientStarting: function (e) {
                logger.log('info', 'callback', "extensionMsgClientStarting()", e);
            },
            OutEventNetworkInterfaceChanged: function (e) {
                logger.log('info', 'callback', "OutEventNetworkInterfaceChanged()", e);
            },
            PrivateOutEventNoLoginCredential: function (e) {
                logger.log('info', 'callback', "PrivateOutEventNoLoginCredential()", e);
            },
            OutEventPluginConnectionSuccess: function (e) {
                self.events.pluginLoadedEvent.trigger('done');
                logger.log('info', 'callback', "OutEventPluginConnectionSuccess()", e);
            },
            OutEventSubscribing: function (e) {
                logger.log('info', 'callback', "OutEventSubscribing()", e);
            }
//---------typical OUT EVENTS-------------
        };


        return self;
    };

    /**
     * Binds application events.
     * UI is updated here.
     * @return {Object} Application object
     */
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
                window.currentConfig = newConfig;
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
                    logger.log('info', 'portal','portal::loginEvent - callback success: ', response);
                }).error(function (response) {
                    logger.log('error', 'portal','portal::loginEvent - callback error: ', response);
                    uiReportError('Portal callback error', '')
                });
                self.isLoggedIn = true;
            })
            .on('fail', function (event, error) {
                self.isLoggedIn = false;
                   // uiReportUserLoginError("<h3>Failed to login</h3>" + "<p>" + error + "</p>");
            })
            .on('progress', function (event, percent) {
                logger.log('debug', 'login', 'loginEvent::progress - percent: ', percent, event);
            });

        self.events.connectEvent
            .on('done', function () {
                logger.log('info', 'call', 'connectEvent::done');
                $.post('/lobbies/' + Immerss.roomId + '/after_join', {source_id: Immerss.sourceId}).success(function (response){
                }).error(function (response) {
                    uiReportError('Portal callback error', '')
                });
                uiInCallShow(true, false);
                clientMicrophoneMute(false);
                self.inConference = true;
                self.isJoining = false;
                uiChatViewTabNotifyStop("group");
                uiLocalShareReset();
                //helperConferenceUpdateTimerStart(self.config.participantRefreshTimeout);
                var recState = clientRecordAndLivestreamStateGet();
                if (recState && recState.recording) {
                    self.events.recorderEvent.trigger("start");
                } else {
                    self.events.recorderEvent.trigger("stop");
                }
                if(window.startedConf){
                    clientConfigurationBootstrap(window.startedConf);
                }
            })
            .on('fail', function (event, error) {
                logger.log('error', 'call', 'connectEvent::fail - error: ', error, event);
                self.inConference = false;
                self.isJoining = false;
                uiReportError('Failed to connect..','');
                helperConferenceUpdateTimerStop();
            })
            .on('progress', function (event, percent) {
                logger.log('debug', 'call', 'connectEvent::progress - percent: ', percent, event);
            })
            .on('crash', function (event, error) {
                $.showFlashMessage('<h3>' + error + '</h3>', {type: 'error', timeout: 6000});
                clientUserLogout();
                if (Immerss.presenter) {
                        loginPesenter();
                    } else{
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
                uiInCallShow(true,true);
            })
            .on('cancel', function (event, error) {
                uiInCallShow(true,false);
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
                uiReportError('Failed to start record','')
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

        self.cache.$inCallButtonStopStreaming
            .click(function (e) {
                logger.log('info', 'ui', "application::$inCallButtonStopStreaming::click");
                e.preventDefault();
                var scope = window.Immerss.conferenceType.toLowerCase();
                var msg = I18n.t("video.organizer_stop_conference", {model: I18n.t("activerecord.models")[scope]});
                if (confirm(msg)) {
                    $.post('/lobbies/' + Immerss.roomId + '/stop_streaming', {}).success(function (response) {
                        logger.log('info', 'ui','portal::StopStreaming - callback success');
                        clientUserLogout();
                        window.close()
                    }).error(function (response) {
                        $.showFlashMessage(I18n.t('video.stop_streaming_error_message'), {type: 'error', timeout: 3000});
                        logger.log('error', 'ui', 'portal::StopStreaming - callback error: ', response);
                    });
                }
            });

        return self;
    };

    /**
     * Binds UI events like button press, etc
     * @return {Object} Application object
     */
    applicationBindUIEvents = function () {

        logger.log('info', 'application', 'applicationBindUIEvents()');


        $('.videoPageInnerWrapper').on('click', 'a.control', function (event) {
            event.preventDefault();
            var $this = $(this);
            var url   = $this.data('url');
            var params = $(this).data('params') || {};
            if(url != undefined) {
                $this.attr('disabled', 'disabled');
                $.post(url, params, function (response) {
                    logger.log('info', 'ui', 'portal::Control ' + url + ' callback success');
                    if (!$this.data('dontenable')) {
                        $this.removeAttr('disabled');
                    }
                }).error(function (response) {
                    logger.log('error', 'ui', 'portal::Control ' + url + ' callback success');
                    $this.removeAttr('disabled');
                });
            }
        });

        // $('#configModal').on('click', 'a.refresh', function (event) {
        //     event.preventDefault();
        //     if(proxyWrapper.isChrome) {
        //         chromeClientConfigurationUpdate(true)
        //     }else {
        //         var conf = clientConfigurationGet();
        //         var updatedConf = clientConfigurationBootstrap(conf);
        //         self.events.configurationUpdateEvent.trigger("done", updatedConf);
        //     }
        // });

        // $('#social-modal').on('click', 'a.refresh', function (event) {
        //     event.preventDefault();
        //     $.get($(self.cache.$inCallButtonToggleInvite).data('url')).success(function (response) {
        //         $('#social-modal').html(window.modalBody)
        //     })
        // });

        // $('#shareModal').on('click', 'a.refresh', function (event) {
        //     setShareUI()
        // });


        // $(window).bind("beforeunload", function () {
        //         logger.log('info', 'call', "reload  or close page");
        //         self.closeWindow = false;
        //         clientConferenceLeave();
        //     }
        // );

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
                self.isMutedVideo = !self.isMutedVideo;
                clientVideoMute(self.isMutedVideo);
            });

        self.cache.$inCallButtonMuteSpeaker
            .click(function () {
                self.isMutedSpeaker = !self.isMutedSpeaker;
                clientSpeakerMute(self.isMutedSpeaker);
            });

        self.cache.$inCallButtonMuteMicrophone
            .click(function () {
                self.isMutedMic = !self.isMutedMic;
                clientMicrophoneMute(self.isMutedMic);
            });

        // self.cache.$inCallButtonShare
        //     .click(function () {
        //         logger.log('info', 'ui', "inCallButtonShare::click");
        //     });

        self.cache.$inCallButtonLocalShare
            .click(function (e) {
                self.client.sendRequest(vidyoClientMessages.requestEnableAppShare({isEnable: 1}));
                setShareUI()
                // jQuery('.vi-active').removeClass('vi-active');
                // if(toggleRiddleMenu(this)){
                //     self.cache.$inCallButtonLocalShare.addClass('vi-active');
                // }else{
                //     self.cache.$inCallButtonLocalShare.removeClass('vi-active');
                // }
            });

        $('body').on('click', '#inCallButtonToggleLayout .pinok', function (e) {
                logger.log('info', 'ui', "inCallButtonToggleLayout::click");
                e.preventDefault();
                clientLayoutToggle();
            });

        $('body').on('click', '#inCallButtonToggleLayout .pinnotok', function (e) {
                logger.log('info', 'ui', "inCallButtonToggleLayout::click");
                e.preventDefault();
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
                clientPreviewModeToggle()
                //clientPreviewModeSet($(e.target).data("mode"));
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
                if(self.isShareScreenActive)
                    clientLocalShareStart(self.currentShareId);
        });

        self.cache.$inCallLocalShareList.on("click", ".shareskrinnswither input", function(e){
            // $(this).parent().find("a").removeClass("active");
            // $(this).addClass("active");
            if($(this).hasClass("enable-share")){
                self.isShareScreenActive = true;
                if(self.currentShareId)
                    clientLocalShareStart(self.currentShareId);
            }else{
                self.isShareScreenActive = false;
                clientLocalShareStop();
            }

        });


        conf_attr = function(event, conf){
            var target = $(event.target),
                selection = target.val(),
                isChecked = target.prop("checked") ? 1 : 0;

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
            if (target.attr("name") === "SelfViewLoopbackPolicy") {
                twitching_operator();
            }
            return conf
        };

        /* Handle selection of different input device */
        self.cache.$configurationContainer
            .on("change", function (event, obj) {
                logger.log('info', 'ui', "configurationContainer::change", event, obj);
                if(proxyWrapper.isChrome) {
                    var response = function(conf){
                        conf =  conf_attr(event, conf)
                        clientConfigurationSet(conf);
                    };
                    chromeClientConfigurationGet(response)
                }else {
                    var conf = clientConfigurationGet();
                    /* From VidyoClientParameters.h */
                    conf =  conf_attr(event, conf)
                    clientConfigurationSet(conf);
                }
            });
        $(document).on('ajax:before', '.users-group-video, .users-group-mic, .users-group-backstage', function(){
            $(this).attr("disabled", "disabled");
        });

        $(document).on('ajax:complete', '.users-group-video, .users-group-mic, .users-group-backstage', function(){
            $(this).removeAttr("disabled");
        });
        /* Detect fullscreen mode change
         * Not all browsers fully support this.
         * Standard is not yet approved so browser specific events are used.
         */
        $(document).on('click', '.close-ban-reason', function(e){
            e.preventDefault();
            uiHideBanReasons();
        })
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

        $(document).on("click", "#media-player-btn", function(e){
            e.preventDefault();
            if($('#mediaPlayerContainer').is(":visible")){
                uiHideMediaPlayer();
            }else{
                uiShowMediaPlayer();
                if(Immerss.presenter) {
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
        applicationBindVidyoCallbacks();

        return self;
    };


    var uiShowBanReasons = function(){
        uiHideManageUsers();
        uiHideMediaPlayer();
        uiHideTwitterFeed();
        uiHideDonations();
        uiHidePoll();
        logger.log('info', 'ui', 'uiShowBanReasons()');
        $('#banReasonsContainer').show();
        $('body').addClass('OpenBanReasons');
        $('body').addClass('menu-right');
    };
    var uiHideBanReasons = function(){
        logger.log('info', 'ui', 'uiHideBanReasons()');
        $('#banReasonsContainer').hide();
        $('body').removeClass('OpenBanReasons');
        $('body').removeClass('menu-right');
    };
    var uiShowManageUsers = function(){
        uiHideBanReasons();
        uiHideMediaPlayer();
        uiHideTwitterFeed();
        uiHideDonations();
        uiHidePoll();
        $('.manage-users').addClass('active');
        logger.log('info', 'ui', 'uiShowManageUsers()');
        $('#groupSettings').show();
        $('body').addClass('OpenManageUsers');
        $('body').addClass('menu-right');
        self.manageUsersShown = true;
    };
    var uiHideManageUsers = function(){
        $('.manage-users').removeClass('active');
        logger.log('info', 'ui', 'uiHideManageUsers()');
        $('#groupSettings').hide();
        $('body').removeClass('OpenManageUsers');
        $('body').removeClass('menu-right');
        self.manageUsersShown = false;
    };

    var uiShowTwitterFeed = function(){
        uiHideManageUsers();
        uiHideBanReasons();
        uiHideMediaPlayer();
        uiHideDonations();
        uiHidePoll();
        $('.twitter-feed').addClass('active');
        logger.log('info', 'ui', 'uiShowTwitterFeed()');
        $('#twitterFeedContainer').show();
        $('body').addClass('OpenTwitterFeed');
        $('body').addClass('menu-right');
        self.twitterFeedShown = true;
    };
    var uiHideTwitterFeed = function(){
        $('.twitter-feed').removeClass('active');
        logger.log('info', 'ui', 'uiHideTwitterFeed()');
        $('#twitterFeedContainer').hide();
        $('body').removeClass('OpenTwitterFeed');
        $('body').removeClass('menu-right');
        self.twitterFeedShown = false;
    };

    var uiShowDonations = function(){
        uiHideManageUsers();
        uiHideBanReasons();
        uiHideMediaPlayer();
        uiHideTwitterFeed();
        uiHidePoll();
        $('.donations').addClass('active');
        logger.log('info', 'ui', 'uiShowDonations()');
        $('#donationsContainer').show();
        $('.ContributorsList-b').jScrollPane();
        $('body').addClass('OpenDonations');
        $('body').addClass('menu-right');
        self.donationsShown = true;
    };
    var uiHideDonations = function(){
        $('.donations').removeClass('active');
        logger.log('info', 'ui', 'uiHideDonations()');
        $('#donationsContainer').hide();
        $('body').removeClass('OpenDonations');
        $('body').removeClass('menu-right');
        self.donationsShown = false;
    };

    var uiShowPoll = function(){
        uiHideDonations();
        uiHideManageUsers();
        uiHideBanReasons();
        uiHideMediaPlayer();
        uiHideTwitterFeed();
        $('a.poll').addClass('active');
        $('#pollContainer').show();
        $('body').addClass('OpenPoll');
        $('body').addClass('menu-right');
        self.pollShown = true;
    };
    var uiHidePoll = function(){
        $('a.poll').removeClass('active');
        $('#pollContainer').hide();
        $('body').removeClass('OpenPoll');
        $('body').removeClass('menu-right');
        self.pollShown = false;
    };

    var uiShowMediaPlayer = function(){
        uiHideBanReasons();
        uiHideManageUsers();
        uiHideTwitterFeed();
        uiHideDonations();
        uiHidePoll();
        $('#mediaPlayerContainer').show();
        $('body').addClass('OpenMediaPlayer');
        $('body').addClass('menu-right');
        $('#media-player-btn').addClass('active');
        $(window).trigger("media-player-start");
    };

    var uiHideMediaPlayer = function(){
        $('#mediaPlayerContainer').hide();
        $('body').removeClass('OpenMediaPlayer');
        $('body').removeClass('menu-right');
        $('#media-player-btn').removeClass('active');
        $(window).trigger("media-player-stop");
    };

    var twitching_operator = function(){
        logger.log('twitching_operator');
        self.cache.$plugin.css('width', '1px');
        window.setTimeout(function () { //FIXME  try to remove it  with new plugin version,this fix for "OSX VidyoInc.VidyoWeb_1.0.2.00057"
            self.cache.$plugin.css("width", '100%');
       },100)

    };

    $(window).on("close-player-tab", uiHideMediaPlayer);

    /**
     * Starts UI view
     * @return {Object} Application object
     */
    uiStart = function () {
        logger.log('info', 'ui', 'uiStart()');
        uiShowInCallContainerMinimizedAndWithPlugin();
        return self;
    };

    data_attr = function(data){
        var transformedData = {
            windows: [],
            desktops: [],
            sharing: (self.currentShareId === undefined) ? false : true
        };
        var i,
            name,
            mywindow,
            desktop;
        for (i = 0; i < data.numApplicationWindows; i++) {
            name = (data.appWindowAppName[i] && data.appWindowAppName[i].length) ? data.appWindowAppName[i] : data.appWindowName[i];
            mywindow = {
                id: data.appWindowId[i],
                name: name,
                highlight: (self.currentShareId === data.appWindowId[i]) ? true : false
            };
            transformedData.windows.push(mywindow);
        }

        for (i = 0; i < data.numSystemDesktops; i++) {
            var name = ('DISPLAY' + (i + 1));
            if (data.sysDesktopRect) {
                if (data.sysDesktopRect[i]) {
                    if (data.sysDesktopRect[i].width > 0 && data.sysDesktopRect[i].height > 0) {
                        name += ' (' + data.sysDesktopRect[i].width + 'x' + data.sysDesktopRect[i].height + ')';
                    }
                }
            }

            desktop = {
                id: data.sysDesktopId[i],
                name: name,
                highlight: (self.currentShareId === data.sysDesktopId[i]) ? true : false
            };
            transformedData.desktops.push(desktop);
        }
        return transformedData
    };
    setShareUI = function () {
        logger.log('info', 'ui', "inCallButtonLocalShare::click");
        if(proxyWrapper.isChrome) {
            chromeClientLocalSharesGet(function(data){
                uiLocalSharesUpdateWithData(data_attr(data));
            })
        }else {
            var data = clientLocalSharesGet();
            uiLocalSharesUpdateWithData(data_attr(data));
        }
        return self;
    };
    /**
     * Time left UI view
     * @return {Object} Application object
     */




    /**
     * Update configuration data and make it do appear
     * @param  {Object} data Configuration data
     * @return {Object} Application object
     */
    uiConfigurationUpdateWithData = function (data) {
        logger.log('info', 'ui', 'uiConfigurationUpdateWithData()');
        var htmlData = self.templates.configurationTemplate(data);
        self.cache.$configurationContainer.html(htmlData);
        return self;
    };


    /**
     * Set UI for microphone mute state
     * @param  {Boolean} mute true for mute state and false for not mute state
     * @return {Object}             Application object
     */
    uiSetMicMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetMicMuted()');
        self.cache.$inCallButtonMuteMicrophone.trigger('mute', mute);
        return self;
    };

    /**
     * Set UI for speaker mute state
     * @param  {Boolean} mute true for mute state and false for not mute state
     * @return {Object}             Application object
     */
    uiSetSpeakerMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetSpeakerMuted()');
        self.cache.$inCallButtonMuteSpeaker.trigger('mute', mute);
        return self;
    };

    /**
     * Set UI for camera mute state
     * @param  {Boolean} mute true for mute state and false for not mute state
     * @return {Object}             Application object
     */
    uiSetVideoMuted = function (mute) {
        logger.log('info', 'ui', 'uiSetVideoMuted()');
        self.cache.$inCallButtonMuteVideo.trigger('mute', mute);
        return self;
    };

    /**
     * Report guest login error
     * @param  {String} error Error string
     * @return {Object} Application object
     */
    uiReportGuestLoginError = function (error) {
        logger.log('info', 'ui', 'uiReportGuestLoginError()');

        $.showFlashMessage(error, {type: 'error', timeout: 3000});
        return self;
    };

    /**
     * Report user login error
     * @param  {String} error Error string
     * @return {Object} Application object
     */
    uiReportUserLoginError = function (error) {
        logger.log('info', 'ui', 'uiReportUserLoginError()');

        $.showFlashMessage(error, {type: 'error', timeout: 3000});
        return self;
    };

    /**
     * Update chat view with new message
     * @param  {Object} chatEvent Data with new message
     * @return {Object} Application object
     */
    uiChatUpdateView = function (chatEvent) {
        logger.log('info', 'ui', 'uiChatUpdateView(', chatEvent, ')');
        var participants = clientParticipantsGet();

        /* Get from participant */
        var participantName;
        var chatTargetParticipant;
        var endpointId;
        var puri;

        /* Extract EndpointId */
        if (chatEvent.uri !== "group") {
            endpointId = chatEvent.uri.split("scip:")[1].split(";")[0];
        }
        /* Name for message sender */
        if (chatEvent.isOutgoing) {
            participantName = self.myAccount.displayName;
        }
        /*  Get corresponding participant for a message.
         For a group message just ignore it.
         */
        if (chatEvent.uri !== "group") {
            var i;
            for (i = 0; i < participants.length; i++) {
                if (chatEvent.uri === participants[i].uri) {
                    if (!chatEvent.isOutgoing) {
                        participantName = participants[i].name;
                    }
                    chatTargetParticipant = participants[i];
                    break;
                }
            }
        }

        if (participantName === undefined || (chatEvent.uri !== "group" && chatTargetParticipant === undefined)) {
            logger.log('warning', 'ui', "uiChatUpdateView() - did not find participant with URI ", chatEvent.uri);
        }

        var pane = [];
        var tab = [];

        if (chatEvent.isGroup) {
            pane = self.cache.$inCallChatGroupPane;
            tab = self.cache.$inCallChatGroupTab;
        } else {
            try{
                uiChatViewTabCreateIfNotExists(chatTargetParticipant.uri, participantName);
            }catch(e){
                $.showFlashMessage('We lost connection with chat member.', {type: 'error', timeout: 3000});
            }

            pane = $("#chatPane" + endpointId);
            tab = $("#chatTab" + endpointId);
        }

        for (i = 0; i < participants.length; i++) {
            if (participantName === participants[i].name) {
                puri = participants[i].uri;
                break;
            }
        }
        /* Prepare data structure for templates */
        var data = {
            uri: chatTargetParticipant ? chatTargetParticipant.uri : "group",
            puri: puri,
            endpointId: endpointId,
            name: participantName,
            time: (new Date()).toLocaleTimeString(),
            message: chatEvent.message,
            isOutgoing: chatEvent.isOutgoing
        };
        /* Add message to the pane */
        var $ul = pane.find("ul");
        var htmlMessage = self.templates.inCallChatPaneMessageTemplate(data);
        $ul.append(htmlMessage);
        if (tab.hasClass("active")) {
            if (chatEvent.isOutgoing) {
                tab.data("noscroll", false);
            }
            uiChatViewScrollToPosition();
            if (self.cache.$inCallChatMinimizeLink.data("minimized")) {
                if (chatEvent.isGroup) {
                    uiChatViewTabNotifyStart("group");
                } else {
                    uiChatViewTabNotifyStart(chatTargetParticipant.uri);
                }
            }
        } else {
            uiChatViewTabNotifyStart(chatTargetParticipant.uri);
        }

    };

    /**
     * Create new chat tab and pane if does not exists for a particular user
     * @param  {Object} uri Participant URI to associate with
     * @param  {Object} name Participant name to associate with
     * @return {Object} Application object
     */
    uiChatViewTabCreateIfNotExists = function (uri, name) {
        logger.log('info', 'ui', 'uiChatViewTabCreateIfNotExists(', uri, name, ')');
        var endpointId;
        /* Extract EndpointId */
        if (uri !== "group") {
            endpointId = uri.split("scip:")[1].split(";")[0];
        }

        if (endpointId === undefined) {
            logger.log('warning', 'ui', "uiChatViewTabCreateIfNotExists() - did not create tab for URI ", uri);
            return self;
        }

        var tab = [];

        tab = $("#chatTab" + endpointId);
        /* Prepare data structure for templates */
        var data = {
            uri: uri,
            endpointId: endpointId,
            name: name
        };
        /*  If no tab for a user exist - create one and append to the end of tab list,
         also create a pane.
         */
        if (tab.length === 0) {
            var htmlTab = self.templates.inCallChatTabTemplate(data);
            var htmlPane = self.templates.inCallChatPaneTemplate(data);
            self.cache.$inCallChatTabs.append(htmlTab);
            self.cache.$inCallChatPanes.append(htmlPane);
        }
        return self;
    };

    /**
     * Switch tab to a particular user.
     * @param  {Object} uri Participant URI to associate with
     * @param  {Object} name Participant name to associate with
     * @return {Object} Application object
     */
    uiChatViewTabSwitch = function (uri) {
        logger.log('info', 'ui', 'uiChatViewTabSwitch(', uri, ')');
        var tab;
        if (uri === "group") {
            tab = self.cache.$inCallChatGroupTab;
        } else {
            var endpointId = uri.split("scip:")[1].split(";")[0];
            tab = $("#chatTab" + endpointId);
        }
        tab.find(">a").click();
        self.cache.$inCallChatTextField.focus();
        return self;
    };

    uiChatViewTabNotifyStart = function (uri) {
        logger.log('info', 'ui', 'uiChatViewTabNotifyStart(', uri, ')');

        var endpointId,
            tab;
        /* Extract EndpointId */
        if (uri !== "group") {
            endpointId = uri.split("scip:")[1].split(";")[0];
        } else {
            endpointId = "group";
        }

        if (uri === "group") {
            tab = self.cache.$inCallChatGroupTab;
        } else {
            tab = $("#chatTab" + endpointId);
        }

        /* Add message notification */
        tab = tab.find(">a");
        tab.addClass("notify");
        var missed = parseInt(tab.data("missed"), 10) | 0;
        var badge = tab.find(">.badge");
        missed += 1;
        tab.data("missed", missed);
        badge.html(String(missed));
        badge.show();
        return self;
    };

    uiChatViewTabNotifyStop = function (uri) {
        logger.log('info', 'ui', 'uiChatViewTabNotifyStop(', uri, ')');
        var endpointId;
        if (!uri) {
            return undefined;
        }
        /* Extract EndpointId */
        if (uri !== "group") {
            endpointId = uri.split("scip:")[1].split(";")[0];
        } else {
            endpointId = "group";
        }

        var tab;

        if (uri === "group") {
            tab = self.cache.$inCallChatGroupTab;
        } else {
            tab = $("#chatTab" + endpointId);
        }

        tab = tab.find(">a");
        tab.removeClass("notify");
        tab.data("missed", 0);
        var badge = tab.find(">.badge");
        badge.hide();
        return self;
    };
    /**
     * Scroll chat view to the bottom when chat view is allowed to.
     * @param  {Boolean} isShown If undefined don't change user login popup state. True - show if was hidden. False - hide if was shown.
     * @return {Object} Application object
     */
    uiChatViewScrollToPosition = function () {
        logger.log('info', 'ui', 'uiChatViewScrollToPosition()');

        var $activeTab = self.cache.$inCallChatTabs.find(".active");
        /* Don't apply scrolling when user recently scrolled */
        if (!self.cache.$inCallChatPanes.data("inscroll")) {
            if ($activeTab.data("noscroll") === false) {
                self.cache.$inCallChatPanes.scrollTop(self.cache.$inCallChatPanes[0].scrollHeight);
            } else {
                self.cache.$inCallChatPanes.scrollTop($activeTab.data("noscroll"));
            }
        }
        return self;
    };

    /**
     * Update UI state for conference ended.
     * Update UI elements to a precall state.
     * @return {Object} Application object
     */
    uiCallCleanup = function () {
        logger.log('info', 'ui', 'uiCallCleanup()');
        if (self.isFullscreen || self.isFullpage) {
            uiFullscreenCancel();
        }
        if (!Immerss.presenter || self.isLoggedIn) {
            uiInCallShow(false);

            if (self.isChatEnabled) {
                /* Clean up chat tabs and panes */
                self.cache.$inCallChatTabs.find(".close").click();
                self.cache.$inCallChatGroupPane.find("ul").html("");
            }
        }
        return self;
    };


    /**
     * Shows plugin in minimized form.
     * Browser will not enable plugin if it is not visible,
     * so we show plugin in a view's default minimized state.
     * @return {Object} Application object
     */
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
                    vidyoPluginInitAndStart();
                })
                .fail(function () {
                    logger.log('warning', 'ui', "uiShowInCallContainerMinimizedAndWithPlugin - Failed to load plugin");
                });
        //});

        return self;
    };

    /**
     * Start plugin detection
     *
     * @return None
     */
    uiStartPluginDetection = function (runWhenDetected) {
        logger.log('info', 'ui', 'uiStartPluginDetection(' + runWhenDetected + ')');
        var reloadPage = false;
        /* Check if installed */
        if (vidyoPluginIsInstalled()) {
            /* Check for browser blockade */
            if(!isVidyoPluginWasInstalled){
                window.location.reload();
                return;
            }
            if (runWhenDetected) {
                /* Load plugin into dome */
                vidyoPluginLoad();
                /* Check if loaded. In case it was not loaded it is likely blockaded by browser */
                if (vidyoPluginIsLoaded()) {
                    logger.log('info', 'ui', 'uiStartPluginDetection() -- plugin is found and loaded - reloading page');
                    if (vidyoPluginIsStarted()) { // started already
                        self.events.pluginLoadedEvent.trigger('fail', I18n.t('video.errors.another_instance'));
                    } else { // not started yet
                        if (vidyoPluginStart()) {
                            self.events.pluginLoadedEvent.trigger('done');
                        } else { //failed to start
                            self.events.pluginLoadedEvent.trigger('fail', I18n.t('video.errors.fail_to_start'));
                        }
                    }
                    return;
                }
            } else {
                logger.log('info', 'ui', 'uiStartPluginDetection() -- plugin is found, reloading');
                /* IE and Safari does not like loading plugin in the same page after install so reloading page */
                location.reload();
                return;
            }
        }
        view_other_plugin_install(window.clicked_by_install ? 2:1);
       /* in case of no plugin detected, try again */
        window.setTimeout(function () {
                uiStartPluginDetection(runWhenDetected);
            },
            self.config.pluginDetectionTimeout);
        return;
    };

    /**
     * Highlight selected share
     * @param  {Object} target jQuery object to apply highlighting style
     * @return {Object} Application object
     */
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

    /**
     * Update remote shares list in UI
     * @param  {Object} data Information about shares
     * @return {Object} Application object
     */
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

    /**
     * Resets UI state for local share
     * @return {Object} Application object
     */
    uiLocalShareReset = function () {
        logger.log('info', 'ui', 'uiLocalShareReset()');
        self.currentShareId = undefined;
    };

    /**
     * Update local shares list in UI
     * @param  {Object} data Information about shares
     * @return {Object} Application object
     */
    uiLocalSharesUpdateWithData = function (data) {
        logger.log('info', 'ui', 'uiLocalSharesUpdateWithData(', data, ')');
        data.isShareScreenActive = self.isShareScreenActive;
        var htmlData = self.templates.inCallLocalSharesTemplate(data);
        /* Show new data */
        self.cache.$inCallLocalShareList.html(htmlData);
        $('#inCallLocalShareList').html(htmlData);
        return self;
    };

    toggleRiddleMenu = function (data, pos) {
        if (pos == void(0)){pos = 'menu-left'}
        target = $(data).data('target')

        if (pos  == 'menu-left'){
            $('.ribbon-container-left .menu-out').not(target).removeClass('menu-out')
        }else{
            $('.ribbon-container-right .menu-out').not(target).removeClass('menu-out')
        }

        if ($(target).hasClass('menu-out')) {
            $(target).removeClass('menu-out');
            $('body.videoclient').removeClass(pos);
            return false;
        } else {
            $(target).addClass('menu-out');
            $('body.videoclient').addClass(pos);
            return true;
        }
    };

    open_right_panel = function (){
        window.isRightPanelLocked = false;
        $('.videoclient .btn-HidePanel-toggle.right-btn').click();
    };


    close_right_panel = function (){
        window.isRightPanelLocked = true;
        $('.videoclient .btn-HidePanel-toggle.right-btn').click();
    };

    close_left_panel = function (){
        window.isLeftPanelLocked = true;
        $('.videoclient .btn-HidePanel-toggle.left-btn').click();
    };

    /**
     * Update participant list in UI
     * @param  {Object} data Information about participants
     * @return {Object} Application object
     */
    uiParticipantsUpdateWithData = function (data) {
        //logger.log('info', 'ui', 'uiParticipantsUpdateWithData(', data, ')');
        if (self.currentMember !== undefined){
            var participant = undefined;
            $.each(data.participants,function(i,res){
                if(res.name == self.currentMember.displayName){
                    participant = res;
                    return true;
                }
            });
            if (participant !== undefined){
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

    /**
     * Show and hide in-call elements.
     * @param  {Boolean} show true - show, false - hide
     * @param  {Boolean} inFullpage true - full page, false - fixed page
     * @return {Object} Application object
     */
    uiInCallShow = function (show, inFullpage) {
        logger.log('info', 'ui', 'uiInCallShow(', show, inFullpage, ')');
        if (show) {
            $('body').addClass('showVideo');intoduceInit();
            self.cache.$plugin.css("width", "100%");
            self.cache.$plugin.css("height", "100%");
            if (inFullpage) { // Configure for full page
                // if (self.isFullscreen){
                //     self.cache.$plugin.css("width", screen.width);
                //     self.cache.$plugin.css("height", screen.height);
                // }else if(self.isFullpage){
                //     self.cache.$plugin.css("width", "100%");
                //     self.cache.$plugin.css("height", $(window).height() - 80 + "px");
                //     $('body').css("width", "100%");
                //     $('body').css("height", "100%");
                //     $('body').addClass('FullWidth');
                //     $('body .icon-glyph-4').hide();
                //     $('body .VideoClientIcon-exitFullscrean').show();
                //     $('#inCallButtonFullpage').attr('data-tip', 'Exit full screen');
                //     close_right_panel();
                //     close_left_panel();
                // }
            }
            else { // configure for static size
                // window.setTimeout(function () { //FIXME  try to remove it  with new plugin version,this fix for "OSX VidyoInc.VidyoWeb_1.0.2.00057"
                //     self.cache.$preCallImage.hide();
                //     $('body').removeClass('FullWidth');
                //     view_chrome_plugin_install(0);
                //     view_other_plugin_install(0);
                //     $('#inCallButtonFullpage').attr('data-tip', 'Full screen');
                //     $('body .icon-glyph-4').show();
                //     $('body .VideoClientIcon-exitFullscrean').hide();
                //     self.cache.$plugin.css("width", "100%");
                //     self.cache.$plugin.css("height", $(window).height() - 80 + "px");
                // },2000)
            }
            // self.cache.$inCallButtonPanel.fadeIn();
            // if (window.Immerss.isStarted){
            //     $('.default-pics').hide();
            //     $('.default-live').show().fadeIn();
            // }else{
            //     $('.default-pics').show().fadeIn();
            //     $('.default-live').hide();
            // }
            // $('.Add_ReduceTimeBtn').show().fadeIn();
            //
            // self.cache.$inCallButtonStartStreaming.removeClass('disabled')
            //
            // //self.cache.$inCallButtonStopStreaming.removeClass('disabled')
            // self.cache.$inCallButtonBrbOn.removeClass('disabled')
            //
            // //if (self.cache.$inCallButtonStopStreaming.is(':visible')){
            // if (self.cache.$inCallButtonBrbOn.is(':visible')){
            //     self.cache.$inCallButtonStartRecord.removeClass('disabled')
            //     self.cache.$inCallButtonStopRecord.removeClass('disabled')
            // }
            // $(self.cache.inCallButtonToggleMember).removeClass('disabled')
            // if(self.isChatEnabled){
            //     self.cache.$pluginAndChatContainer.show();
            // }
            // $('body').addClass('VideoOn');
            // $(window).unbind("resize.fix-plugin-height").bind("resize.fix-plugin-height", function() {
            //     self.cache.$plugin.css("height", $(window).height() - 80 + "px");
            // });
        } else {
            // $(window).unbind("resize.fix-plugin-height");
            // self.cache.$inCallButtonPanel.hide();
            // $('.time-left').hide();
            // $('.menu-out').removeClass('menu-out');
            // $('.menu-left').removeClass('menu-left');
            // $('.menu-right').removeClass('menu-right');
            // self.cache.$plugin.css("height", "1px");
            // self.cache.$plugin.css("width", "1px");
            // self.cache.$pluginAndChatContainer.hide();
            // $('body').removeClass('VideoOn');
            // self.cache.$preCallImage.show();
            // self.cache.$preCallImage.find('.wait').hide();
            // $('.default-pics').hide();
            // $('.default-live').hide();
            // $('.reduceTheTime').hide();
            // $('.addTime').hide();
        }
        return self;
    };
    self.uiInCallShowApp = uiInCallShow;
    /**
     * Show error in UI
     * @param  {String} error   Short error description
     * @param  {String} details Details about error
     * @return {Object} Application object
     */
    uiReportError = function (error, details) {
        logger.log('info', 'ui', 'uiReportError(', error, ", ", details, ')');

        $.showFlashMessage(error + details, {type: 'error', timeout: 3000});
        return self;
    };

    /**
     * Show information message in UI
     * @param  {String} title   Short information description
     * @param  {String} details Details
     * @return {Object} Application object
     */
    uiReportInfo = function (title, details) {
        logger.log('info', 'ui', 'uiReportInfo(', title, ", ", details, ')');

        $.showFlashMessage(title + details, {type: 'instructions', timeout: 999999999});
        return self;
    };

    /**
     * Minimizes or maximizes chat view
     * @param  {Boolean} minimize   true - minimize, false - maximize
     * @return {Object} Application object
     */
    uiChatViewMinimize = function (minimize) {
        logger.log('info', 'ui', 'uiChatViewMinimize(', minimize, ')');
        if (minimize) {
            self.cache.$inCallChatContainer.addClass('minimized');
            self.cache.$inCallChatPanes.hide();
            self.cache.$inCallChatForm.hide();
        } else {
            self.cache.$inCallChatContainer.removeClass('minimized');
            self.cache.$inCallChatPanes.show();
            self.cache.$inCallChatForm.show();
        }
        return self;
    };

    /**
     * Post desktop notification.
     * Will focus page on click. Currently works in the latest Chrome, Safari and Firefox only.
     *
     * @param  {String} title Title for notification
     * @param  {String} message   Short notification message
     * @param  {Integer} timeout Dismiss after timeout in ms. 0 - don't dismiss
     * @param  {Function} onClick Function to execute on click
     * @return {Object} Notification object on success, undefined on failure
     */
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

    /**
     * Set elem to full screen
     * @param  {Object} elem DOM element which to show in full screen
     * @return {Object} Application object
     */
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

    /**
     * Return from full screen mode
     * @return {Object} Application object
     */
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

    /**
     * Login user with credentials
     * @param  {Object} inEventLoginParams Credentials
     * @return {Object} Application object
     */
    clientUserLogin = function (inEventLoginParams) {
        logger.log('info', 'login', 'clientUserLogin()');

        var inEvent = vidyoClientMessages.inEventLogin(inEventLoginParams);

        if (!self.client.sendEvent(inEvent)) {
            self.events.loginEvent.trigger('fail', "Failed to send inEvent");
            return undefined;
        }
        return self;
    };

    /**
     * Logout previously logged in user
     * @return {Object} Application object
     */
    clientUserLogout = function () {
        logger.log('info', 'login', 'clientUserLogout()');

        var inEvent = vidyoClientMessages.inEventSignoff({});

        if (!self.client.sendEvent(inEvent)) {
            self.events.loginEvent.trigger('fail', "Failed to send inEvent");
            return undefined;
        }
        return self;
    };

    /**
     * Connect user to VidyoPortal as a guest and join to the conference.
     * @param  {Object} inEventLoginParams Information about portal, room and username
     * @return {Object} Application object
     */
    clientGuestLoginAndJoin = function (inEventLoginParams) {
        logger.log('info', 'login', 'clientGuestLoginAndJoin(', inEventLoginParams, ')');


        var inEvent = vidyoClientPrivateMessages.privateInEventVcsoapGuestLink(inEventLoginParams);
        //inEvent.typeRequest = "GuestLink";
        inEvent.requestId = self.currentRequestId++;

        if (!self.client.sendEvent(inEvent)) {
            self.events.connectEvent.trigger('fail', {error: "Failed to send inEvent"});
            return undefined;
        }
        return self;
    };

    /**
     * Disconnect from a conference
     * @return {Object} Application object
     */
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

    /**
     * Mute local audio output device
     * @param  {Boolean} mute true - mute, false - unmute
     * @return {Object} Application object
     */
    clientSpeakerMute = function (mute) {
        logger.log('info', mute, 'clientSpeakerMute('+mute+')');
        var params = {}, inEvent, msg;
        params.willMute = mute;
        inEvent = vidyoClientMessages.inEventMuteAudioOut(params);
        if(mute == false){
            self.client.sendRequest(vidyoClientMessages.requestSetVolumeAudioOut({volume: 65535}));
        }
        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientSpeakerMute(): " + msg);

        return self;
    };

    setVolumeOn = function(){
        // var new_config = {enableAudioAGC: false};
        // clientConfigurationSet(new_config);
        self.client.sendRequest(vidyoClientMessages.requestSetVolumeAudioIn({volume: 65535}));
        // new_config = {
        //     enableAudioAGC: true,
        //     enableEchoCancellation: true
        // };
        // clientConfigurationSet(new_config);
    };

    setVolumeOff = function(){
        // var new_config = {
        //     enableAudioAGC: false,
        //     enableEchoCancellation: false
        // };
        // clientConfigurationSet(new_config);
        self.client.sendRequest(vidyoClientMessages.requestSetVolumeAudioIn({volume: 0}));
    };
    /**
     * Mute local microphone
     * @param  {Boolean} mute true - mute, false - unmute
     * @return {Object} Application object
     */
    clientMicrophoneMute = function (mute) {
        logger.log('info', mute, 'clientMicrophoneMute('+mute+')');
        if (mute){
            setVolumeOff();
        }else{
            setVolumeOn();
        }
        self.callbacks.OutEventMutedAudioIn({isMuted: mute});
        return self;
    };

    /**
     * Mute local camera. Other participants will not see the user.
     * @param  {Boolean} mute true - mute, false - unmute
     * @return {Object} Application object
     */
    clientVideoMute = function (mute) {
        logger.log('info', mute, 'clientVideoMute('+mute+')');
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

    /**
     * Get recording and livestreaming state
     * @return {Object} Recording and livestreaming state
     */
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

    ///**
    // * Get current user information
    // * @return {Object} Current user information object
    // */
    //clientCurrentUserGet = function () {
    //    //logger.log('info', 'configuration', 'clientCurrentUserGet()');
    //    var request = vidyoClientMessages.requestGetCurrentUser({});
    //    var msg;
    //    if (self.client.sendRequest(request)) {
    //        msg = "VidyoWeb sent " + request.type + " request successfully";
    //    } else {
    //        msg = "VidyoWeb did not send " + request.type + " request successfully!";
    //    }
    //    //logger.log('info', 'configuration', "requestGetCurrentUser(): " + msg, request);
    //
    //    return request;
    //};

    /**
     * Select remote share to see
     * @param  {Int} currApp ID of share to see
     * @return {Object} Currently available shares
     */
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
    /**
     * Select remote share to see
     * @param  {Int} currApp ID of share to see
     * @return {Object} Currently available shares
     */
    chromeClientSharesGet = function (callback) {
        logger.log('info', 'call', 'chromeClientSharesGet()');
        var request = vidyoClientMessages.requestGetWindowShares({});
        var msg;
        if (self.client.sendRequest(request, callback)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'call', "clientSharesGet(): " + msg, request);

        return request;
    };

    /**
     * Select remote share to see
     * @param  {Int} currApp ID of share to make watch
     * @return {Object} Application object
     */
    clientSharesSetCurrent = function (currApp) {
        logger.log('info', 'call', 'clientSharesSetCurrent()');

        if(proxyWrapper.isChrome) {
            chromeClientSharesGet(function(request){
                request.newApp = currApp + 1;
                request.type = "RequestSetWindowShares";
                request.requestType = "ChangeSharingWindow";

                var msg;

                if (self.client.sendRequest(request)) {
                    msg = "VidyoWeb sent " + request.type + " request successfully";
                } else {
                    msg = "VidyoWeb did not send " + request.type + " request successfully!";
                }
                logger.log('info', 'call', "clientSharesGet() : " + msg, request);

                return request;
            });
        }else {
            var request = clientSharesGet();
            request.newApp = currApp + 1;
            request.type = "RequestSetWindowShares";
            request.requestType = "ChangeSharingWindow";

            var msg;

            if (self.client.sendRequest(request)) {
                msg = "VidyoWeb sent " + request.type + " request successfully";
            } else {
                msg = "VidyoWeb did not send " + request.type + " request successfully!";
            }
            logger.log('info', 'call', "clientSharesGet() : " + msg, request);

            return request;
        }

    };

    /**
     * Toggle between preview modes
     * @return {Object} Application object
     */
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

    /**
     * Sets preview mode
     * @param  {String} previewMode 'None' - no preview, 'PIP' - picture in picture, 'Dock' - docked view
     * @return {Object} Application object
     */
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

    /**
     * Toggle layout between equal and one big participant views
     * @return {Object} Application object
     */
    clientLayoutToggle = function () {
        logger.log('info', 'call', "clientLayoutToggle()");
        self.numPreferred = self.numPreferred ? 0 : 1;
        $('#PinOn').prop("checked", false);
        $('#PinOff').prop("checked", false);
        if (self.numPreferred == 0){
            $('#PinOn').prop("checked", true);
        }else{
            $('#PinOff').prop("checked", true);
        }
        return clientLayoutSet(self.numPreferred);
    };

    /**
     * Set number of preferred participants.
     * Preferred participants will be shown in the larger area.
     * @param  {Integer} numPreferred Number of preferred participants.
     * @return {Object} Application object
     */
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

    ///**
    // * Get information about local endpoint's media.
    // * @return {Object} Object with local endpoint's media information
    // */
    //clientLocalMediaInfo = function () {
    //    //logger.log('info', 'call', 'clientLocalMediaInfo()');
    //    var output = {};
    //    var requestGetEncodeResolution = vidyoClientMessages.requestGetEncodeResolution();
    //    var requestGetVideoFrameRateInfo = vidyoClientMessages.requestGetVideoFrameRateInfo();
    //    var requestGetMediaInfo = vidyoClientMessages.requestGetMediaInfo();
    //    var msg;
    //    if (self.client.sendRequest(requestGetEncodeResolution) &&
    //        self.client.sendRequest(requestGetVideoFrameRateInfo) &&
    //        self.client.sendRequest(requestGetMediaInfo)) {
    //        msg = "VidyoWeb sent all requests successfully";
    //        output = $.extend(output, requestGetVideoFrameRateInfo, requestGetMediaInfo, requestGetEncodeResolution);
    //    } else {
    //        msg = "VidyoWeb did not send requests successfully!";
    //    }
    //    //logger.log('info', 'call', "clientLocalMediaInfo(): " + msg, output);
    //    return output;
    //};

    /**
     * Get information about participants in a conference.
     * @return {Object} Object with participants' array
     */
    //clientParticipantsGet = function () {
    //    //logger.log('info', 'call', 'clientParticipantsGet()');
    //    var requestNum = vidyoClientMessages.requestGetNumParticipants({});
    //    var me = clientCurrentUserGet();
    //    var participants = [];
    //    var msg;
    //
    //    if (self.client.sendRequest(requestNum)) {
    //        var i;
    //        var participantRequest;
    //        for (i = 0; i < requestNum.numParticipants; i++) {
    //            participantRequest = vidyoClientMessages.requestGetParticipantStatisticsAt({
    //                index: i
    //            });
    //            if (self.client.sendRequest(participantRequest)) {
    //                if (participantRequest.result === true) {
    //                    // TODO: Use URI for self detection
    //                    if (me && me.currentUserDisplay && (me.currentUserDisplay === participantRequest.name)) {
    //                        participantRequest.isMe = true;
    //                        participantRequest.encoderInfo = clientLocalMediaInfo();
    //                    }
    //                    participants.push(participantRequest);
    //                } else {
    //                    logger.log('warning', 'call', "clientParticipantsGet() - Result is not succesful for participant #", i);
    //                }
    //
    //            } else {
    //                logger.log('warning', 'call', "clientParticipantsGet() - Failed to get participant #", i);
    //            }
    //        }
    //        msg = "VidyoWeb sent " + requestNum.type + " request successfully";
    //    } else {
    //        msg = "VidyoWeb did not send " + requestNum.type + " request successfully!";
    //    }
    //    //logger.log('info', 'call', "clientParticipantsGet(): " + msg, participants);
    //
    //    updateChatUri(participants);
    //    return participants;
    //};

    updateChatUri = function(participants){
        if (self.isChatEnabled){
            $(".member-list-chat-button").hide();
            for (i = 0; i < participants.length; i++) {
                $(".member-list-chat-button[data-name='" + participants[i].name +"']").data('uri', participants[i].uri);
                $(".member-list-chat-button[data-name='" + participants[i].name +"']").show();
            }
        }
    };
    /**
     * Retrieves Vidyo runtime configuration
     * @return {Object} Runtime configuration
     */
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

    /**
     * Retrieves Vidyo runtime configuration
     * @return {Object} Runtime configuration
     */
    chromeClientConfigurationGet = function (response) {
        logger.log('info', 'configuration', 'chromeClientConfigurationGet()');
        var request = vidyoClientMessages.requestGetConfiguration({});
        self.client.sendRequest(request, response)
        return request;
    };

    /**
     * Retrieves Vidyo runtime configuration
     * @return {Object} Runtime configuration
     */
    chromeClientConfigurationUpdate = function (force_update) {
        logger.log('info', 'configuration', 'chromeClientConfigurationUpdate()');
        var response = function(updatedConf){
            window.startedConf = updatedConf;
            if(force_update){updatedConf = clientConfigurationBootstrap(updatedConf);}
            self.events.configurationUpdateEvent.trigger("done", updatedConf);
        };

        chromeClientConfigurationGet(response)
    };

    /**
     * Sets Vidyo runtime configuration
     * @return {Object} Applied configuration
     */
    clientConfigurationSet = function (vidyoConfig) {
        logger.log('info', 'configuration', 'clientConfigurationSet(', vidyoConfig, ')');
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

    /**
     * Gets desktops and windows available in the system
     * @return {Object} Desktops and windows object
     */
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

    /**
     * Gets desktops and windows available in the system
     * @return {Object} Desktops and windows object
     */
    chromeClientLocalSharesGet = function (callback) {
        logger.log('info', 'call', 'clientDesktopsAndWindowsGet()');
        var request = vidyoClientMessages.requestGetWindowsAndDesktops({});
        var msg;
        if (self.client.sendRequest(request, callback)) {
            msg = "VidyoWeb sent " + request.type + " request successfully";
        } else {
            msg = "VidyoWeb did not send " + request.type + " request successfully!";
        }
        logger.log('info', 'call', "clientDesktopsAndWindowsGet(): " + msg, request);

        return request;
    };

    /**
     * Send a group chat message
     * @param  {String} message Message to send.
     * @return {Object} Application object
     */
    clientGroupChatSend = function (message) {
        logger.log('info', 'call', "clientGroupChatSend('", message, "')");

        var params = {}, inEvent, msg;

        params.message = message;

        inEvent = vidyoClientMessages.inEventGroupChat(params);

        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientGroupChatSend(): " + msg);

        return self;
    };

    /**
     * Send a private chat message
     * @param  {String} message Message to send.
     * @return {Object} Application object
     */
    clientPrivateChatSend = function (uri, message) {
        logger.log('info', 'call', "clientPrivateChatSend('", uri, message, "')");

        var params = {}, inEvent, msg;

        params.message = message;
        params.uri = uri;

        inEvent = vidyoClientMessages.inEventPrivateChat(params);

        if (self.client.sendEvent(inEvent)) {
            msg = "VidyoWeb sent " + inEvent.type + " event successfully";
        } else {
            msg = "VidyoWeb did not send " + inEvent.type + " event successfully!";
        }
        logger.log('info', 'call', "clientPrivateChatSend(): " + msg);

        return self;
    };
    /**
     * Start sharing
     * @param  {String} shareId Share window or desktop id. Undefined to stop share.
     * @return {Object} Application object
     */
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

    /**
     * Stop sharing
     * @return {Object} Application object
     */
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

    /**
     * Configure vidyoPlugin runtime on startup
     * @param  {Object} conf Runtime configuration
     * @return {Object}      Applied runtime configuration
     */
    clientConfigurationBootstrap = function (conf) {
        logger.log('info', 'call', "clientConfigurationBootstrap()");
        if(conf.currentCamera == -1 && conf.cameras.length > 0){conf.currentCamera = 0;}
        conf.enableAutoStart = 0;
        conf.enableShowConfParticipantName = true;
        conf.userID = "";
        conf.password = "";
        conf.serverAddress = "";
        conf.serverPort = "";
        conf.portalAddress = "";

        return clientConfigurationSet(conf);
    };
    window.view_chrome_plugin_install = function(step){
        // self.cache.$preCallImage.hide();
        // $('.chrome_plugin_install').removeClass('hidden');
        // $('.chrome_plugin_install > div').removeClass('active');
        $('.step1, .step2, .step3, .step4, .step5, .step6, .step7').addClass('active');
        if(step == 0){
            $('.chrome_plugin_install').addClass('hidden');
        }else{
            $('.step' + step).addClass('active');
        }
    };

    window.view_other_plugin_install = function(step){
        // self.cache.$preCallImage.hide();
        // $('.extention_init').removeClass('hidden');
        // $('.extention_init > div').removeClass('active');
        $('.step1, .step2, .step3, .step4, .step5, .step6, .step7').removeClass('active');

        if(step == 0){
            $('.extention_init').addClass('hidden');
        }else{
            $('.step' + step).addClass('active');
        }
    };

    detectCameraStatusAndContinue = function() {
        self.client.sendRequest({type: 'RequestGetCameraStatus'}, function(cameraReady) {
                if (cameraReady.status) {
                    startChromeVideo();
                } else {
                    //loop until camera detected
                    setTimeout(detectCameraStatusAndContinue, 2000);
                }
            }
        );
    }
    var chromePluginInstallPrompted = false;
    var isNotDownloaded = true;
    detectVidyoClientForWebAndContinue = function() {
        var checkVersion = proxyWrapper.supportedVersions[0];
        proxyWrapper.sendEvent({
            type: 'RequestConnectVersion',
            version: checkVersion
        }, function (connectRes) {
            logger.log("proxyWrapper.sendEvent(RequestConnectVersion): " +  connectRes);
            if (connectRes.result) {
                proxyWrapper.isSupportedVersion(function (supported, version) {
                    logger.log("proxyWrapper.isSupportedVersion: supported:" + supported + ", version:" + version);
                    if (supported) {
                        if (chromePluginInstallPrompted){
                            location.reload();
                        }
                        view_chrome_plugin_install(4);
                        proxyWrapper.start(function (startRes) {
                            logger.log("proxyWrapper.start: " + startRes);
                            detectCameraStatusAndContinue();
                        });
                    } else {
                        chromePluginInstallPrompted = true;
                        logger.log('version not supported, need to install VidyoClientforWeb');
                        view_chrome_plugin_install(3);
                        if (isNotDownloaded){
                            window.location = $('.download_me').attr('href');
                            isNotDownloaded=false;
                        };
                        setTimeout(detectVidyoClientForWebAndContinue, 4000);
                    }
                });
            } else {
                logger.log('no version sent');
                setTimeout(detectVidyoClientForWebAndContinue, 2000)
            }
        });
    };

    var onOutEvent = function (event) {
        fuu = self.callbacks[event.type];
        try {
            fuu(event)
            console.log('onOutEvent', event.type);
        }
        catch(err) {
            console.log('---------------------------------------------')
            console.log('onOutEvent unknown event', event);
        }
    };

    var didCheckExtension = false;
    detectExtensionAndContinue = function() {
        proxyWrapper.detectExtension('jbagnbabffebnloeajochhpipcjhpamb', function (result) {
            logger.log("proxyWrapper.detectExtension result:" + result);
            extensionInstalled = result;
            if (extensionInstalled && !didCheckExtension) {
                proxyWrapper.connect();
                proxyWrapper.setOutEventDispatchMethod(onOutEvent);
                detectVidyoClientForWebAndContinue();
            } else if (extensionInstalled && didCheckExtension) {
                logger.log('Page should reload in order to utilize the extension');
                location.reload();
            } else {
                logger.log("No Extension detected, need to install Extension");
                //prompt user to install Extension
                view_chrome_plugin_install(window.clicked_by_install ? 2:1)
                logger.log("Will check extension again after short delay");
                setTimeout(detectExtensionAndContinue, 2000);
            }
            didCheckExtension = true;
        });
    };

    startChromeVideo = function() {
        var retval = false;
        var holder = document.getElementById('pluginWrap');
        //holder.innerHTML = '<video autoplay width="100%" height="100%"></video>';

        var video = holder.childNodes[0];
        proxyWrapper.useVideoElem(video, function(message, permissionDeniedError) {
            if (!permissionDeniedError && !message) {
                retval = true;
            } else if (permissionDeniedError) {
                $.showFlashMessage('VidyoWeb needs access to your camera in order to join a conference.' + 'If you change your mind, click the camera icon in your url bar and allow the browser to use your devices', {type: 'alert', timeout: 3000})
            } else {
                $.showFlashMessage('VidyoWeb could not start your camera. Please reload the page and try again.', {type: 'alert', timeout: 3000})
            }
        });
        return retval;
    };

    startChromePlugin = function() {

        self.client.setProxy(proxyWrapper);
        if (!proxyWrapper.started) {
            detectExtensionAndContinue();
        }else{
            startChromeVideo();
        }
        return true;
    };

    /**
     * Initializes and connects vidyo.client JavaScript library and plugin object.
     * @return {Object} Application object
     */
    vidyoPluginInitAndStart = function () {
        logger.log('info', 'plugin', 'vidyoPluginInitAndStart()');

        /* Sets configuration to defaults */
        vidyoPluginConfigurationPrepare(self.cache.$plugin.get()[0]);

        /* Attaches plugin object to the JS vidyo.client library */
        vidyoPluginLoad();

        /* Check if started correctly */

        if (proxyWrapper.isChrome){
            startChromePlugin();
            return true;
        }

        if (vidyoPluginIsLoaded()) {
            if (vidyoPluginIsStarted()) { // started already
                self.events.pluginLoadedEvent.trigger('fail', "Another instance is running?");
            } else { // not started yet
                if (vidyoPluginStart()) {
                    //self.events.pluginLoadedEvent.trigger('done');
                } else { //failed to start
                    self.events.pluginLoadedEvent.trigger('fail', "Failed to start Vidyo Library");
                }
            }
        } else {
            /* Failed to load plugin */
            logger.log('warning', 'plugin', "Failed to load plugin.");

            if (vidyoPluginIsInstalled()) {
                /* Plugin is installed but not loaded. Probably blocked by the browser. */
                logger.log('warning', 'plugin', "Plugin is installed but not loaded. Probably blocked by the browser.");
                //var details = self.templates.pluginEnableInstructionsTemplate({
                //});
                //self.events.pluginLoadedEvent.trigger('info', {message: "Plugin is installed but not loaded. Probably blocked by the browser.", details: details});
                view_other_plugin_install(3);
                uiStartPluginDetection(true);
            } else {
                /* Notify deferred object to show plugin download */
                logger.log('warning', 'plugin', "Plugin is not installed. Starting plugin auto detection.");
                if (Immerss.platform != 'windows' && Immerss.platform != 'mac'){
                    var details = self.templates.pluginInstallInstructionsTemplate({
                        mac: (Immerss.platform == 'mac'),
                        win: (Immerss.platform == 'windows'),
                        unkOs: (Immerss.platform != 'windows' && Immerss.platform != 'mac')
                    });
                    self.events.pluginLoadedEvent.trigger('info', {message: "", details: details});
                }
                view_other_plugin_install(window.clicked_by_install ? 2:1);
                /* Start plugin polling */
                uiStartPluginDetection(true);
            }
        }
        return self;
    };

    /**
     * Get status of plugin in the DOM
     * @return {Boolean} true for plugin is loaded into DOM and false for opposite
     */
    vidyoPluginIsLoaded = function () {
        logger.log('info', 'plugin', 'vidyoPluginIsLoaded()');
        return self.client.isLoaded();
    };

    /**
     * Prepares configuration object for JavaScript Library
     * @param  {Object} plugin Plugin DOM object
     * @param  {Object} config Configuration
     * @return {Object} Application object with applied configuration
     */
    vidyoPluginConfigurationPrepare = function (plugin, config) {
        logger.log('info', 'plugin', 'vidyoPluginConfigurationPrepare()');


        var localConfig = {
            plugin: plugin,
            defaultOutEventCallbackMethod: function (event) {
                logger.log('info', 'plugin', 'default callback for client lib: ', event);
            },
            useCallbackWithPlugin: true,
            outEventCallbackObject: self,
            logCallback: function (message) {
                if (self.logConfig.enableVidyoPluginLogs) {
                    logger.log("jsclient::", message);
                }
            },
            callbacks: self.callbacks
        };

        self.config.vidyoConfig = $.extend({}, self.config.vidyoConfig, config, localConfig);

        return self;
    };

    /**
     * Loads plugin into vidyo.client library with configuration
     * @param  {Object} config Optional configuration object
     * @return {Object} Application object
     */
    vidyoPluginLoad = function (config) {
        logger.log('info', 'plugin', 'vidyoPluginLoad() begin');

        self.config.vidyoConfig = $.extend({}, self.config.vidyoConfig, config);
        //logger.log(conf);
        self.client = vidyoClient(self.config.vidyoConfig);
        if (!self.client) {
            return undefined;
        }
        return self;
    };


    /**
     * Detects if plugin is installed or not
     *
     * @return {Boolean} Application object
     */
    vidyoPluginIsInstalled = function () {
        var isFound = false;
        logger.log('info', 'plugin', 'vidyoPluginIsInstalled()');
        navigator.plugins.refresh(false);

        /* Try NPAPI approach */
        /*jslint unparam: true*/
        $.each(navigator.mimeTypes, function (i, val) {
            if (val.type === self.config.pluginMimeType) {
                /* Reload page when plugin is detected */
                logger.log('info', 'plugin', 'vidyoPluginIsInstalled() -- NPAPI plugin found');
                isFound = true;
                return true;
            }
        });
        /*jslint unparam: false*/

        /* Try IE approach */
        try {
            var control = new ActiveXObject(self.config.activexType);
            if (control) {
                logger.log('info', 'plugin', 'vidyoPluginIsInstalled() -- ActiveX plugin found');
                isFound = true;
            }
        } catch (ignore) {

        }

        if (isFound) {
            return true;
        } else {
            return false;
        }
    };
    var isVidyoPluginWasInstalled = vidyoPluginIsInstalled();

    /**
     * Check start status of Vidyo Client library
     * @return {Boolean} true for started and false for not started
     */
    vidyoPluginIsStarted = function () {
        logger.log('info', 'plugin', 'vidyoPluginIsStarted');
        return self.client.isStarted();
    };

    /**
     * Starts Vidyo library runtime
     * @return {Boolena} True for success and false for error
     */
    vidyoPluginStart = function () {
        logger.log('info', 'plugin', 'vidyoPluginStart');
        var msg;

        if (!self.client) {
            if (!vidyoPluginLoad()) {
                return false;
            }
        }

        /* Set all callbacks */
        try {
            $.each(self.config.vidyoConfig.callbacks, function (key, val) {
                self.client.setOutEventCallbackMethod(key, val);
            });
        } catch (e) {
            logger.log('warning', 'plugin', "vidyoPluginStartFailed -  to set callbacks");
        }

        if (self.client.start()) {
            msg = "VidyoWeb started successfully";
        } else {
            msg = "VidyoWeb did not start successfully!";
            return false;
        }

        logger.log('info', 'plugin', "vidyoPluginStart(): " + msg);

        return true;
    };

    /**
     * Stops Vidyo library runtime
     * @return {Object} Application object
     */
    vidyoPluginStop = function () {
        $("#pluginWrap").remove();
        logger.log('info', 'plugin', 'vidyoPluginStop()');
        var msg;

        if (self.client.stop(true, true)) {
            msg = "VidyoWeb stopped successfully";
        } else {
            msg = "VidyoWeb did not stop successfully!";
        }
        logger.log('info', 'plugin', "vidyoPluginStop(): " + msg);

        self.client.setPlugin(void(0));
        return self;
    };

    loginParticipantAndWait = function () {
        initWebsocketAndWait(self);
        if (Immerss.presenter) {
            loginPesenter();
        }
    };

    loginPesenter = function () {
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
    };


    /**
     * Starts timer that refreshes participant information
     * @return {Object} Application object
     */
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

    /**
     * Stops participant refresh timer
     * @return {Object} Application object
     */
    helperConferenceUpdateTimerStop = function () {
        logger.log('info', 'application', "helperConferenceUpdateTimerStop()");
        window.clearInterval(self.participantRefreshTimer);
        self.participantRefreshTimer = 0;
        return self;
    };



    /**
     * Main application entry point
     * @return {Object}   Application object
     */

    var main = function () {
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

    if (!vidyoConfig.envProduction){
        window.app = app; // use this as a hook for debugging
    }
});
