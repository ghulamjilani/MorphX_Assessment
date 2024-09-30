
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
     * Holds cached events
     * @type {Object}
     */
    self.events = {};

    /**
     * Map of handlebars templates
     * @type {Object}
     */
    self.templates = {};

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
        self.cache.$pluginContainer = $(self.config.pluginContainer);
        self.cache.$plugin = $(self.config.pluginContainer).children(":first"); //Firefox quirk
        return self;
    };

    /**
     * Build handlebars templates
     * @return {Object} Application object
     */
    applicationBuildTemplates = function () {
        self.templates.pluginTemplate = handlebars['default'].compile(self.config.pluginTemplate);
        return self;
    };

    /**
     * Add plugin object to DOM
     * @return {Object} application object
     */
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
             * Vidyo library is successfully started.
             */
            OutEventLogicStarted: function () {
                logger.log('info', 'callback', "OutEventLogicStarted()");

                var conf = clientConfigurationGet();

                /* Update configuration with defaults */
                var updatedConf = clientConfigurationBootstrap(conf);
                self.events.configurationUpdateEvent.trigger("done", updatedConf);
            },
            OutEventDevicesChanged: function (e) {
                logger.log('info', 'callback', "OutEventDevicesChanged()", e);
                var conf = clientConfigurationGet();
                /* Update configuration with new values */
                self.events.configurationUpdateEvent.trigger("done", conf);
            }

        };


        return self;
    };

    /**
     * Binds application events.
     * UI is updated here.
     * @return {Object} Application object
     */
    applicationBindSubscribeEvents = function () {
        /* Subscription events */
        logger.log('info', 'application', 'applicationBindSubscribeEvents()');

        /* Occurred when plugin is really ready  */
        self.events.pluginLoadedEvent
            .on('done', function () {
                logger.log('info', 'plugin', 'pluginLoadedEvent::done');
                $('#videoPluginDownload').hide();
                $('#pluginSuccessWrapp').addClass('SuccessEv');
                $('#pluginSuccess').html(Immerss.pluginVersion);
                $('#pluginJoinSuccess').show();
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
                    camera: newConfig.cameras[0],
                    speaker: newConfig.speakers[0],
                    microphone: newConfig.microphones[0]
                };

                $.each(newConfig.cameras, function (i, name) {
                    if (i === newConfig.currentCamera){
                        data.camera = name
                    }
                });


                $.each(newConfig.speakers, function (i, name) {
                    if (i === newConfig.currentSpeaker){
                        data.speaker = name
                    }
                });

                $.each(newConfig.microphones, function (i, name) {
                    if (i === newConfig.currentMicrophone){
                        data.microphone = name
                    }
                });

                if (data.camera){
                    $('#CamSuccessWrapp').addClass('SuccessEv');
                    $('#CamSuccess').html(data.camera);
                }else{
                    $('#CamSuccessWrapp').addClass('FallEv');
                    $('#CamSuccess').html('Please plug in web cam');
                    $('#pluginJoinSuccess').remove();
                    $('#pluginJoinCheckMic').remove();
                    $('#pluginJoinCheckCam').show();
                };

                if (data.microphone){
                    $('#MicSuccessWrapp').addClass('SuccessEv');
                    $('#MicSuccess').html(data.microphone);
                }else{
                    $('#MicSuccessWrapp').addClass('FallEv');
                    $('#MicSuccess').html('Please plug in microphone');
                    $('#pluginJoinSuccess').remove();
                    $('#pluginJoinCheckCam').remove();
                    $('#pluginJoinCheckMic').show();
                };

                if (data.speaker){
                    $('#SpeakerSuccessWrapp').addClass('SuccessEv');
                    $('#SpeakerSuccess').html(data.speaker);
                }else{
                    $('#SpeakerSuccessWrapp').addClass('FallEv');
                    $('#SpeakerSuccess').html('Please plug in speaker');
                };
                vidyoPluginStop();
            });

        return self;
    };

    /**
     * Binds UI events like button press, etc
     * @return {Object} Application object
     */
    applicationBindUIEvents = function () {

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


    uiStart = function () {
        logger.log('info', 'ui', 'uiStart()');
        uiShowInCallContainerMinimizedAndWithPlugin();
        return self;
    };

    vidyoPluginStop = function () {
        $("#pluginContainer").remove();
        $("#pluginJoinContainer").remove();
        fixIEpluginCheck();
        try{
            logger.log('info', 'plugin', 'vidyoPluginStop()');
            var msg;

            if (self.client.stop(true, true)) {
                msg = "VidyoWeb stopped successfully";
            } else {
                msg = "VidyoWeb did not stop successfully!";
            }
            logger.log('info', 'plugin', "vidyoPluginStop(): " + msg);
            self.client.setPlugin(void(0));
        }catch(e){}
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
                        $('.unobtrusive-flash-container > div').alert('close');
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
        /* in case of no plugin detected, try again */
        window.setTimeout(function () {
                uiStartPluginDetection(runWhenDetected);
            },
            1000);
        return;
    };

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

        $.showFlashMessage(title + details, {type: 'instructions', timeout: 3000});
        return self;
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
     * Sets Vidyo runtime configuration
     * @return {Object} Applied configuration
     */
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

    /**
     * Configure vidyoPlugin runtime on startup
     * @param  {Object} conf Runtime configuration
     * @return {Object}      Applied runtime configuration
     */
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
        if (vidyoPluginIsLoaded()) {
            if (vidyoPluginIsStarted()) { // started already
                self.events.pluginLoadedEvent.trigger('done');
                fixIEpluginCheck();
            } else { // not started yet
                if (vidyoPluginStart()) {
                    self.events.pluginLoadedEvent.trigger('done');
                } else { //failed to start
                    self.events.pluginLoadedEvent.trigger('fail', "Failed to start Vidyo Library");
                    vidyoPluginStop();
                }
            }
        } else {
            /* Failed to load plugin */
            logger.log('warning', 'plugin', "Failed to load plugin.");

            if (vidyoPluginIsInstalled()) {
                /* Plugin is installed but not loaded. Probably blocked by the browser. */
                self.events.pluginLoadedEvent.trigger('info', "Plugin is installed but not loaded. Probably blocked by the browser.");
                $('#videoPluginCheck').show();
                $('#videoPluginDownload').hide();
                $('#pluginJoinSuccess').remove();
                $('#pluginJoinBlocked').show();

                uiStartPluginDetection(true);
            } else {
                /* Notify deferred object to show plugin download */
                logger.log('warning', 'plugin', "Plugin is not installed. Starting plugin auto detection.");
                $('#videoPluginCheck').hide();
                $('#videoPluginDownload').show();
                $('#pluginJoinUninstalled').show();
                /* Start plugin polling */
                uiStartPluginDetection(true);
            }
            vidyoPluginStop();
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
            logCallback: function (message) {},
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
     * Main application entry point
     * @return {Object}   Application object
     */

    var main = function () {
        applicationBuildTemplates();
        applicationAddPlugin();
        applicationBuildCache();
        applicationBuildSubscribeEvents();
        uiStart();
        applicationBindEvents();
        return self;
    };

    self.main = main;
    self.application = application;
    window.app = self.application;
    return self;

};


$(function () {
    if($('#videoPluginCheck, #pluginJoinRow').length){
        logger.enable(vidyoConfig.enableAppLogs); // Don't show logs if configuration prohibits
        logger.enableStackTrace(vidyoConfig.enableStackTrace);
        logger.setLevelsCategories(vidyoConfig.applicationLevelsCategories);

        logger.log('info', 'application', 'domReady::DOM is loaded');

        app = application(vidyoConfig);
        app.main();

        if (!vidyoConfig.envProduction){
            window.app = app; // use this as a hook for debugging
        };
    };
});


window.vidyoConfig = {
    pluginMimeType: ("application/x-vidyoweb-" + Immerss.pluginVersion), // will add version later on
    activexType: ("VidyoInc.VidyoWeb_" + Immerss.pluginVersion), // will add version later on
    pluginDetectionTimeout: 1000, //in ms, polling frequency
    /* Logging */
    enableAppLogs: (Immerss.environment == 'production'), // main application
    envProduction: (Immerss.environment == 'production'), //
    enableVidyoPluginLogs: false, // jsclient
    enableVidyoClientLogs: false, // client
    applicationLevelsCategories: {
        // all: true,
        // none: false,
        call: "debug",
        portal: "warning",
        configuration: "debug",
        login: "debug",
        application: "info",
        soap: "warning",
        ui: "info",
        callback: "info",
        cache: "none"
        },
    defaultLogLevelsAndCategories: "fatal error warning info@App info@AppEvents info@AppEmcpClient info@LmiApp info@LmiH264SvcPace",
    enableStackTrace: false,

    pluginContainer: "#videoPluginCheck #pluginContainer, #pluginJoinContainer",
    pluginTemplate: "<object id='{{id}}' type='{{mimeType}}' style='height: 1px;width: 1px;'>",
};
window.fixIEpluginCheck = function(){
    $('.pluginStatusWrapper script').remove();
    var status_html = $('.pluginStatusWrapper').html();
    $('.pluginStatusWrapper', window.parent.document).html(status_html);
    $('#iframePluginStatusWrapper', window.parent.document).attr('src', '');
    $('#iframePluginStatusWrapper', window.parent.document).remove();
};
