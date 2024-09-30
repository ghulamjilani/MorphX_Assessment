(function (ns) {
    var CallStateEnum = {
        IDLE: "IDLE",
        CALLING: "CALLING",
        CONNECTING: "CONNECTING",
        CONNECTED: "CONNECTED",
        VIDEO_CONNECTED: "VIDEO_CONNECTED",
        VIDEO_STARTED: "VIDEO_STARTED"
    };
    var SDPStateEnum = {IDLE: "IDLE", COLLECTING: "COLLECTING", COLLECTED: "COLLECTED"};
    var pluginIceServer = {iceServers: []};
    var resolutionMap = {
        "180p": {w: 320, h: 180, br: "256"},
        "240p": {w: 426, h: 240, br: "384"},
        "270p": {w: 480, h: 270, br: "448"},
        "360p": {w: 640, h: 360, br: "512"},
        "480p": {w: 854, h: 480, br: "768"},
        "540p": {w: 960, h: 540, br: "1024"},
        "720p": {w: 1280, h: 720, br: "1536"},
        "1080p": {w: 1920, h: 1080, br: "2048"},
    };

    function log(level, ts, str) {
        console[level]('' + ts + ' [Plugin] ' + str);
    }

    function logInfo(str) {
        var ts = new Date().toLocaleTimeString();
        log('info', ts, str);
    }

    function logError(str) {
        var ts = new Date().toLocaleTimeString();
        log('error', ts, str);
    }

    function logDebug(str) {
        var ts = new Date().toLocaleTimeString();
        log('debug', ts, str);
    }

    function isBundleSupported() {
        return (webrtcDetectedBrowser === "chrome");
    }

    function empty() {
    }

    function plugin(messages, webrtcserver) {
        this.webrtcServerArg_ = webrtcserver;
        this.webrtcServer_ = this.webrtcServerArg_ === undefined ? '' : window.location.protocol + "//" + this.webrtcServerArg_;
        this.useCallbackForOutEvents = null;
        this.outEventCallbackObject = null;
        this.outEventCallbackMethod = null;
        this.messages_ = messages;
        this.configurationRequest_ = messages.requestGetConfiguration();
        this.configurationRequest_.videoPreferences = "";
        this.sendShareResolution_ = "";
        this.started_ = false;
        this.callState_ = CallStateEnum.IDLE;
        this.sdpState_ = SDPStateEnum.IDLE;
        this.session_ = null;
        this.guestName_ = "";
        this.maxSubscriptions_ = 0;
        this.currentSubscriptions_ = 0;
        this.callId_ = -1;
        this.peerConn_ = null;
        this.offer_ = null;
        this.additionalPeerConn_ = [];
        this.additionalPeerConnOffers_ = [];
        this.localStream_ = null;
        this.remoteStream_ = [];
        this.audioSources_ = null;
        this.videoSources_ = null;
        this.conferenceName_ = "";
        this.participants_ = [];
        this.participantUris_ = [];
        this.activeTalkers_ = [];
        this.volume_ = 0;
        this.audioInMuted_ = false;
        this.audioOutMuted_ = false;
        this.videoMuted_ = false;
        this.shareList_ = messages.requestWindowShares();
        this.shareApp_ = 0;
        this.remoteSharePeerConn_ = null;
        this.remoteSharePeerOffer_ = null;
        this.remoteShareStream_ = null;
        this.remoteShareStreamIndex_ = -1;
        this.pendingAttaches_ = [];
        this.numDesktops_ = 0;
        this.currentDesktopId_ = 1;
        this.localSharePeerConn_ = null;
        this.localShareStream_ = null;
        this.localShareOffer_ = null;
        this.serverMutedAudio = false;
        this.serverMutedVideo = false;
        this.recording = false;
        this.webcast = false;
        this.watchInterval_ = null;
        this.windowSizes_ = [];
        this.numPreferred_ = 0;
        this.activeVideoStreams_ = 0;
        this.pendingRequestId_ = -1;
        this.localStats_ = {};
        this.showStats_ = false;
        this.lectureModeListener_ = false;
        this.lectureModeStarted_ = false;
        this.lectureModePresenterUri_ = "";
        window.vidyoplugin = this;
        logDebug("Plugin construction called with server " + webrtcserver + " requests to " + this.webrtcServer_);
    }

    plugin.prototype.ready = function (cb) {
        cb();
    };
    plugin.prototype.isStarted = function () {
        return this.started_;
    };
    plugin.prototype.periodicExtensionCheck = function () {
        var self = this;
        setTimeout(function () {
            if (document.getElementById('vidyowebrtcscreenshare_is_installed')) {
                self.numDesktops_ = 1;
            } else {
                self.periodicExtensionCheck();
            }
        }, 3000);
    };
    plugin.prototype.getNumberOfLocalShares = function () {
        if (window.location.protocol !== "https:") {
            return 0;
        }
        if (webrtcDetectedBrowser === "chrome") {
            if (document.getElementById('vidyowebrtcscreenshare_is_installed')) {
                logInfo("vidyowebrtcscreenshare_is_installed");
                return 1;
            }
            this.periodicExtensionCheck();
            logInfo("vidyowebrtcscreenshare_is_installed NOT INSTALLED");
            return 0;
        }
        return 1;
    };
    plugin.prototype.start = function () {
        if (this.started_) {
            logInfo("Plugin already started!");
            return true;
        }
        this.started_ = true;
        var self = this;
        window.addEventListener('message', function (event) {
            if (event.origin !== window.location.origin) {
                return;
            }
            if (event.data.type === 'VidyoRequestId') {
                logInfo("VidyoRequestId - " + event.data.requestId);
                self.pendingRequestId_ = event.data.requestId;
            }
            if (event.data.type === 'VidyoOutEventSourceId') {
                self.pendingRequestId_ = -1;
                if (event.data.sourceId === "") {
                    self.currentDesktopId_ += 1;
                    return;
                }
                var width = 1280;
                var height = 720;
                if (resolutionMap.hasOwnProperty(self.sendShareResolution_)) {
                    width = resolutionMap[self.sendShareResolution_].w;
                    height = resolutionMap[self.sendShareResolution_].h;
                }
                var constraints = {
                    video: {
                        mandatory: {
                            chromeMediaSource: 'desktop',
                            chromeMediaSourceId: event.data.sourceId,
                            maxWidth: width,
                            maxHeight: height,
                            maxFrameRate: 5
                        }
                    }
                };
                self.startLocalShare(constraints);
            }
        });
        logDebug("Plugin.start, collecting sources");
        webrtcGetSources(function (audioSources, videoSources) {
            self.audioSources_ = audioSources;
            self.videoSources_ = videoSources;
            self.configurationRequest_.cameras = [];
            self.configurationRequest_.microphones = [];
            self.configurationRequest_.speakers = [];
            for (var i = 0; i < self.videoSources_.length; i++) {
                self.configurationRequest_.cameras[i] = self.videoSources_[i].label;
                logInfo("Source Camera: " + self.videoSources_[i].label);
            }
            self.configurationRequest_.numberCameras = self.videoSources_.length;

            $(window.videoSelect.options).each(function() {
                if($.cookie('webrtcLastVideo') == this.text){
                    window.videoSelect.selectedIndex = this.value
                }
            });
            self.configurationRequest_.currentCamera = window.videoSelect.value;
            for (var j = 0; j < self.audioSources_.length; j++) {
                self.configurationRequest_.microphones[j] = self.audioSources_[j].label;
                logInfo("Source Mic: " + self.audioSources_[j].label);
            }

            $(window.audioInputSelect.options).each(function() {
                if($.cookie('webrtcLastInput') == this.text){
                    window.audioInputSelect.selectedIndex = this.value
                }
            });
            self.configurationRequest_.numberMicrophones = self.audioSources_.length;
            self.configurationRequest_.currentMicrophone = window.audioInputSelect.value;
            self.configurationRequest_.speakers[0] = "Default";
            self.configurationRequest_.numberSpeakers = 1;
            self.configurationRequest_.currentSpeaker = 0;
            var devicesEvt = self.messages_.event('OutEventDevicesChanged');
            self.outEventCallbackObject.dispatchOutEvent(devicesEvt);
            logInfo("OutEventPluginConnectionSuccess --> UI ");
            var evt = self.messages_.event('OutEventPluginConnectionSuccess');
            self.outEventCallbackObject.dispatchOutEvent(evt);
        });
        return true;
    };
    plugin.prototype.stop = function () {
        logDebug("Plugin Stop called");
        this.started_ = false;
        return true;
    };
    plugin.prototype.changeCallState = function (newState) {
        logInfo("Changing CallState from " + this.callState_ + " to " + newState);
        this.callState_ = newState;
    };
    plugin.prototype.handleGetConfiguration = function (request) {
        for (var item in this.configurationRequest_) {
            request[item] = this.configurationRequest_[item];
        }
    };
    plugin.prototype.handleSetConfiguration = function (request) {
        for (var item in request) {
            this.configurationRequest_[item] = request[item];
        }
    };
    plugin.prototype.sendRequest = function (request) {
        var self = this;
        switch (request.type) {
            case"RequestGetConfiguration":
                self.handleGetConfiguration(request);
                break;
            case"RequestSetConfiguration":
                self.handleSetConfiguration(request);
                break;
            case"RequestGetCallState":
                if (self.callState_ === CallStateEnum.VIDEO_CONNECTED || self.callState_ === CallStateEnum.VIDEO_STARTED) {
                    request.callState = "InConference";
                } else {
                    request.callState = "Idle";
                }
                break;
            case"RequestGetWindowsAndDesktops":
                request.appWindowAppName = [];
                request.appWindowId = [];
                request.appWindowName = [];
                if (self.numDesktops_ > 0) {
                    request.numSystemDesktops = 1;
                    request.sysDesktopName[0] = 'Display';
                    request.sysDesktopId = [self.currentDesktopId_.toString()];
                } else {
                    request.numSystemDesktops = 0;
                    request.sysDesktopName = [];
                    request.sysDesktopId = [];
                }
                break;
            case"RequestGetCurrentSessionDisplayInfo":
                logInfo("RequestGetCurrentSessionDisplayInfo - " + self.conferenceName_);
                request.sessionDisplayText = self.conferenceName_;
                break;
            case"RequestGetCurrentUser":
                request.currentUserDisplay = self.guestName_;
                break;
            case"RequestGetEncodeResolution":
                self.getLocalEncodeResolution(request.rect);
                break;
            case"RequestGetVideoFrameRateInfo":
                self.getLocalFrameRates(request);
                break;
            case"RequestGetMediaInfo":
                self.getLocalMediaInfo(request);
                break;
            case"RequestGetNumParticipants":
                request.numParticipants = self.participants_.length;
                logInfo("RequestGetNumParticipants - " + request.numParticipants);
                break;
            case"RequestGetParticipantStatisticsAt":
                request.result = true;
                request.uri = self.participantUris_[request.index];
                request.name = self.participants_[request.index];
                self.getStatsForParticipant(request);
                break;
            case"RequestGetParticipants":
                request.name = self.participants_;
                request.URI = self.participantUris_;
                request.numberParticipants = self.participants_.length;
                break;
            case"RequestGetVolumeAudioOut":
                logDebug("RequestGetVolumeAudioOut - " + self.volume_);
                request.volume = self.volume_;
                break;
            case"RequestSetVolumeAudioOut":
                logDebug("RequestSetVolumeAudioOut - " + request.volume);
                self.handleSetAudioVolume(request.volume);
                break;
            case"RequestGetMutedAudioOut":
                logDebug("RequestGetMutedAudioOut - false");
                request.isMuted = self.audioOutMuted_;
                break;
            case"RequestGetMutedAudioIn":
                logDebug("RequestGetMutedAudioIn - false");
                request.isMuted = self.audioInMuted_;
                break;
            case"RequestGetMutedVideo":
                logDebug("RequestGetMutedVideo - false");
                request.isMuted = self.videoMuted_;
                break;
            case"RequestGetMutedServerAudioIn":
                logDebug("RequestGetMutedServerAudioIn - " + self.serverMutedAudio);
                request.isMuted = self.serverMutedAudio;
                break;
            case"RequestGetMutedServerVideo":
                logDebug("RequestGetMutedServerVideo - " + self.serverMutedVideo);
                request.isMuted = self.serverMutedVideo;
                break;
            case"RequestGetWindowShares":
                request.requestType = "ListSharingWindows";
                request.remoteAppUri = self.shareList_.remoteAppUri;
                request.remoteAppName = self.shareList_.remoteAppName;
                request.numApp = self.shareList_.numApp;
                request.currApp = self.shareList_.currApp;
                request.eventUri = self.shareList_.eventUri;
                request.newApp = self.shareList_.newApp;
                logDebug("RequestGetWindowShares - " + JSON.stringify(request));
                break;
            case"RequestSetWindowShares":
                logInfo("RequestSetWindowShares - " + JSON.stringify(request));
                self.shareList_.newApp = request.newApp;
                self.sendChangeShare(request.newApp);
                break;
            case"RequestGetPreviewMode":
                logInfo("RequestGetPreviewMode - Attaching video streams");
                if (self.callState_ === CallStateEnum.VIDEO_CONNECTED) {
                    self.changeCallState(CallStateEnum.VIDEO_STARTED);
                    self.doPendingAttaches();
                }
                if (self.activeVideoStreams_ > 0) {
                    setTimeout(function () {
                        self.updateActiveVideoStreams(self.activeVideoStreams_);
                    }, 500);
                }
                break;
            case"RequestGetConferenceInfo":
                request.recording = self.recording;
                request.webcasting = self.webcast;
                logDebug("RequestGetConferenceInfo - " + request.recording + ", " + request.webcasting);
                break;
            case"RequestGetLectureModeStatus":
                request.inLectureMode = self.lectureModeStarted_;
                request.inPresenterMode = (self.lectureModeStarted_ && !self.lectureModeListener_);
                request.isTherePresenter = (self.lectureModePresenterUri_ !== "");
                break;
            default:
                logError("sendRequest unhandled - " + JSON.stringify(request));
                return "ErrorInvalidRequest";
        }
        return "ErrorOk";
    };
    plugin.prototype.sendInConference = function () {
        var self = this;
        if (self.callState_ !== CallStateEnum.VIDEO_CONNECTED && self.callState_ !== CallStateEnum.VIDEO_STARTED) {
            logInfo("InConference Event --> UI");
            self.changeCallState(CallStateEnum.VIDEO_CONNECTED);
            var evt = self.messages_.event('OutEventCallState');
            evt.callState = 'InConference';
            evt.error = 0;
            evt.activeEid = -1;
            self.outEventCallbackObject.dispatchOutEvent(evt);
            var confActiveEvent = self.messages_.event('OutEventConferenceActive');
            self.outEventCallbackObject.dispatchOutEvent(confActiveEvent);
            if (self.callState_ === CallStateEnum.VIDEO_CONNECTED) {
                self.changeCallState(CallStateEnum.VIDEO_STARTED);
                self.doPendingAttaches();
            }
        }
    };
    plugin.prototype.handleConnectResponse = function (res) {
        var self = this;
        if (self.callState_ !== CallStateEnum.CONNECTING) {
            logError("Invalid state for InitConnection response - " + self.callState_);
        }
        if (res.error !== 0) {
            var x = self.messages_.event('callState');
            x.activeEid = -1;
            self.session_ = null;
            self.callId_ = -1;
            self.changeCallState(CallStateEnum.IDLE);
            self.webrtcServer_ = self.webrtcServerArg_ === undefined ? "" : window.location.protocol + "//" + self.webrtcServerArg_;
            x.error = 500;
            if (res.error === 4) {
                logInfo("ConnectResponse - CONFERENCE LOCKED !!");
                x.fault = 'ConferenceLocked';
                if (self.localStream_) {
                    stopMediaStream(self.localStream_);
                }
                self.sdpState_ = SDPStateEnum.IDLE;
            } else if (res.error === 6) {
                logInfo("ConnectResponse - WRONG PIN!!");
                x.fault = 'WrongPin';
                if (self.localStream_) {
                    stopMediaStream(self.localStream_);
                }
                self.sdpState_ = SDPStateEnum.IDLE;
            } else if (res.error === 35) {
                x.error = 6;
                x.type = 'OutEventLinked';
                if (self.localStream_) {
                    stopMediaStream(self.localStream_);
                }
                self.sdpState_ = SDPStateEnum.IDLE;
            } else if (res.error === 1017) {
                x.error = 500;
                x.type = 'OutEventLinked';
                if (self.localStream_) {
                    stopMediaStream(self.localStream_);
                }
                self.sdpState_ = SDPStateEnum.IDLE;
            } else {
                x.fault = res.error.toString();
                if (self.localStream_) {
                    stopMediaStream(self.localStream_);
                }
                self.sdpState_ = SDPStateEnum.IDLE;
            }
            self.outEventCallbackObject.dispatchOutEvent(x);
            return;
        }
        self.session_ = res.session;
        self.callId_ = res.callId;
        self.changeCallState(CallStateEnum.CONNECTED);
        self.collectIceAndSendSdp();
        if (self.sdpState_ === SDPStateEnum.COLLECTED) {
            self.sendSdp();
        }
        if (res.secure) {
            var signInEvent = self.messages_.event('OutEventSignIn');
            signInEvent.signinSecured = true;
            self.outEventCallbackObject.dispatchOutEvent(signInEvent);
        }
    };
    plugin.prototype.postMessageToServer = function (path, params, doLog, cb) {
        var oReq = new XMLHttpRequest();
        var url = this.webrtcServer_ + path;
        oReq.open("post", url, true);
        oReq.onload = function () {
            if (doLog) {
                logDebug("" + url + " response received with status " + oReq.status + " : " + oReq.statusText);
            }
            cb(true, oReq.status);
        };
        oReq.onerror = function (e) {
            logError("" + url + " error response");
            console.dir(e);
            cb(false, e);
        };
        var paramStr = JSON.stringify(params);
        if (doLog) {
            logInfo("" + url + " - " + paramStr);
        }
        oReq.send(paramStr);
    };
    plugin.prototype.postLogToServer = function (logStr) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.log = logStr;
        this.postMessageToServer("/log", params, false, empty);
    };
    plugin.prototype.sendConnect = function (e) {
        var self = this;
        var oReq = new XMLHttpRequest();
        oReq.open("post", this.webrtcServer_ + "/connect", true);
        var params = {};
        params.portalUri = e.portalUri;
        params.roomKey = e.roomKey;
        params.pin = e.pin;
        params.sessionId = e.requestId;
        params.guestName = e.guestName;
        params.videoPreferences = self.configurationRequest_.videoPreferences;
        params.callType = "webrtc";
        self.guestName_ = e.guestName;
        if (self.callState_ === CallStateEnum.IDLE) {
            self.changeCallState(CallStateEnum.CALLING);
        } else {
            logError("Invalid state for ConnectRequest - " + self.callState_);
        }
        oReq.onload = function () {
            if (oReq.status === 404 || oReq.status === 503) {
                logError("/connect received " + oReq.status + " disconnecting call");
                self.handleConnectResponse({error: "Server unreachable - " + oReq.status});
                return;
            }
            var res = JSON.parse(oReq.responseText);
            logInfo("Response for connect - " + JSON.stringify(res));
            self.session_ = res.session;
            self.callId_ = res.callId;
            self.configurationRequest_.videoPreferences = res.maxResolution;
            self.maxSubscriptions_ = res.maxSubscriptions;
            self.sendShareResolution_ = "1080p";
            self.remoteShareStreamIndex_ = res.maxSubscriptions + 1;
            var addr = window.location.hostname;
            if (res.host.length > 0) {
                self.webrtcServer_ = window.location.protocol + "//" + res.host;
                addr = res.host;
            }
            pluginIceServer.iceServers.length = 0;
            pluginIceServer.iceServers.push({urls: "stun:" + res.stunServer});
            if (res.turnCreds) {
                var urls = res.turnCreds.urls;
                for (var k = 0; k < urls.length; k++) {
                    if (urls[k].indexOf("self_address") !== -1) {
                        urls[k] = urls[k].replace("self_address", addr);
                    }
                }
                pluginIceServer.iceServers.push(res.turnCreds);
            }
            var server = self.webrtcServer_ === '' ? window.location.origin : self.webrtcServer_;
            var statsUrl = server + "/web/stats.html?session=" + self.session_ + "&callid=" + self.callId_;
            logInfo("Stats URL - " + statsUrl);
            if (self.callState_ === CallStateEnum.CALLING) {
                self.changeCallState(CallStateEnum.CONNECTING);
                self.getEvents();
            } else {
                logError("Invalid state for ConnectResponse - " + self.callState_);
            }
        };
        oReq.onerror = function (e) {
            logError("Connect Error");
            self.handleConnectResponse({error: "Server unreachable"});
        };
        var paramStr = JSON.stringify(params);
        params.pin = '****';
        logInfo("/connect - " + JSON.stringify(params));
        oReq.send(paramStr);
    };
    plugin.prototype.sendDisconnect = function (localDisconnect) {
        var self = this;
        logInfo("Leaving the conference call state - " + self.callState_ + " LocalDisconnect: " + localDisconnect);
        if (self.callState_ === CallStateEnum.IDLE) {
            return;
        }
        if (self.pendingRequestId_ !== -1) {
            window.postMessage({type: 'VidyoCancelRequest', requestId: self.pendingRequestId_}, '*');
            self.pendingRequestId_ = -1;
        }
        var localVideo = document.getElementById("localVideo");
        detachMediaStream(localVideo, self.localStream_, true, true);
        var remoteView, elemId, participantElem;
        for (var i = 0; i < self.maxSubscriptions_; i++) {
            elemId = "remoteVideo" + i;
            remoteView = document.getElementById(elemId);
            detachMediaStream(remoteView, self.remoteStream_[i], false, true);
            participantElem = document.getElementById("participant" + i);
            if (participantElem) {
                participantElem.innerHTML = "";
            }
            if (self.additionalPeerConn_[i]) {
                self.additionalPeerConn_[i].close();
                self.additionalPeerConn_[i] = null;
            }
            self.additionalPeerConn_.length = 0;
            self.additionalPeerConnOffers_.length = 0;
        }
        var shareView = document.getElementById("shareVideo0");
        detachMediaStream(shareView, self.remoteShareStream_, false, true);
        if (self.remoteSharePeerConn_ !== null) {
            self.remoteSharePeerConn_.close();
            self.remoteSharePeerConn_ = null;
            self.remoteSharePeerOffer_ = null;
            self.remoteShareStream_ = null;
        }
        participantElem = document.getElementById("shareName");
        if (participantElem) {
            participantElem.innerHTML = "";
        }
        if (self.showStats_) {
            self.clearStats();
        }
        self.showStats_ = false;
        self.localStats_ = {};
        self.stopLocalShare();
        if (self.peerConn_ !== null) {
            self.peerConn_.close();
            self.peerConn_ = null;
        }
        self.offer_ = null;
        self.remoteStream_.length = 0;
        self.activeTalkers_.length = 0;
        self.participants_.length = 0;
        self.participantUris_.length = 0;
        self.currentSubscriptions_ = 0;
        self.shareApp_ = 0;
        self.shareList_ = self.messages_.requestWindowShares();
        self.activeVideoStreams_ = 0;
        self.lectureModeListener_ = false;
        self.lectureModeStarted_ = false;
        self.lectureModePresenterUri_ = "";
        clearInterval(self.watchInterval_);
        self.windowSizes_.length = 0;
        self.numPreferred_ = 0;
        self.changeCallState(CallStateEnum.IDLE);
        self.sdpState_ = SDPStateEnum.IDLE;
        self.audioInMuted_ = false;
        self.audioOutMuted_ = false;
        self.videoMuted_ = false;
        self.serverMutedAudio = false;
        self.serverMutedVideo = false;
        self.recording = false;
        self.webcast = false;
        if (localDisconnect) {
            var params = {};
            params.session = self.session_;
            params.callId = self.callId_;
            params.callType = "webrtc";
            self.postMessageToServer("/disconnect", params, true, empty);
        }
        self.handleDisconnectedEvent(localDisconnect);
        self.webrtcServer_ = self.webrtcServerArg_ === undefined ? "" : window.location.protocol + "//" + self.webrtcServerArg_;
    };
    plugin.prototype.sendChangeShareRequest = function (eventUri, sdp, cb) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.eventUri = eventUri;
        params.sdp = sdp;
        logInfo("sendChangeShareRequest sdp - " + sdp.sdp);
        this.postMessageToServer("/changeshare", params, true, cb);
    };
    plugin.prototype.sendCandidate = function (streamId, candidate) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.streamId = streamId;
        params.candidate = candidate.candidate;
        params.sdpMid = candidate.sdpMid;
        params.sdpMlineIndex = candidate.sdpMLineIndex;
        this.postMessageToServer("/candidate", params, true, empty);
    };
    plugin.prototype.sendChangeShare = function (newApp) {
        var self = this;
        if (newApp === 0 && self.shareApp_ === 0) {
            return;
        }
        var eventUri = '';
        var remoteAppName = '';
        if (newApp > 0) {
            eventUri = self.shareList_.remoteAppUri[newApp - 1];
            remoteAppName = self.shareList_.remoteAppName[newApp - 1];
        }
        logInfo("Changing the share from " + self.shareApp_ + " to " + newApp + ": Name - " + remoteAppName + " EventURI: " + eventUri);
        if (isBundleSupported()) {
            self.sendChangeShareRequest(eventUri, {sdp: ''}, empty);
        }
        else if (self.remoteSharePeerConn_ !== null) {
            self.sendChangeShareRequest(eventUri, {sdp: ""}, empty);
        }
        else if (self.remoteSharePeerConn_ === null) {
            self.remoteSharePeerConn_ = new RTCPeerConnection(pluginIceServer);
            self.remoteSharePeerConn_.onicecandidate = function (evt) {
                if (evt.candidate === null) {
                    logInfo("RemoteSharePeerConn: Candidate collection complete");
                } else {
                    self.sendCandidate(10, evt.candidate);
                }
            };
            self.remoteSharePeerConn_.oniceconnectionstatechange = function (state) {
                logInfo("remote share: oniceconnectionstatechange called " + state.target.iceConnectionState);
                self.postLogToServer("remote share: oniceconnectionstatechange called " + state.target.iceConnectionState);
            };
            self.remoteSharePeerConn_.onsignalingstatechange = function (state) {
                logInfo("remote share: onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
                self.postLogToServer("remote share: onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
            };
            var offerConstraints = {offerToReceiveAudio: false, offerToReceiveVideo: true};
            self.remoteSharePeerConn_.createOffer(function (offer) {
                logDebug("remote share: createOffer success " + offer.sdp);
                self.remoteSharePeerOffer_ = offer;
                self.sendChangeShareRequest(eventUri, offer, function (s, e) {
                    if (s) {
                        if (self.remoteSharePeerOffer_ !== null) {
                            self.remoteSharePeerOffer_ = null;
                            self.remoteSharePeerConn_.setLocalDescription(offer, function () {
                                logDebug("remote share: setlocaldescription success ");
                            }, function (err) {
                                logError("remote share: SetLocalDescription error");
                            });
                        } else {
                            logDebug("remote share: answer came first");
                        }
                    } else {
                        logError("remote share: SetLocalDescription send error");
                    }
                });
            }, function (err) {
                logError("remote share: CreateOffer error");
            }, offerConstraints);
        }
        if (newApp === 0) {
            var shareView = document.getElementById("shareVideo0");
            detachMediaStream(shareView, self.remoteShareStream_, false, false);
            self.shareApp_ = newApp;
            var shareName = document.getElementById("shareName");
            shareName.innerHTML = "";
            self.remoteSharePeerConn_.close();
            self.remoteSharePeerConn_ = null;
            self.remoteShareStream_ = null;
            self.remoteSharePeerOffer_ = null;
        }
    };
    plugin.prototype.handleDisconnectedEvent = function (localDisconnect) {
        var self = this;
        var x = self.messages_.event('OutEventCallState');
        x.callState = 'Idle';
        x.error = 0;
        x.activeEid = -1;
        logInfo("CallState Idle --> UI");
        self.outEventCallbackObject.dispatchOutEvent(x);
        setTimeout(function () {
            var x = self.messages_.event('OutEventConferenceEnded');
            self.outEventCallbackObject.dispatchOutEvent(x);
            logInfo("OutEventConferenceEnded --> UI");
            if (!localDisconnect) {
                var y = self.messages_.event('OutEventUserMessage');
                y.messageType = 'DisconnectedFromConference';
                self.outEventCallbackObject.dispatchOutEvent(y);
            }
        }, 500);
    };
    plugin.prototype.muteLocalAudio = function (muted) {
        this.audioInMuted_ = muted;
        if (!this.localStream_) {
            return;
        }
        var enabled = this.localStream_.getAudioTracks()[0].enabled;
        logDebug("MuteAudioIn - changing from " + enabled + " to " + !muted);
        this.localStream_.getAudioTracks()[0].enabled = !muted;
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.muted = muted;
        this.postMessageToServer("/muteaudio", params, true, empty);
    };
    plugin.prototype.handleMuteAudioIn = function (e) {
        this.muteLocalAudio(e.willMute);
    };
    plugin.prototype.handleMuteAudioOut = function (e) {
        for (var i = 0; i < this.maxSubscriptions_; i++) {
            if (this.remoteStream_[i]) {
                var audioTrack = this.remoteStream_[i].getAudioTracks()[0];
                if (audioTrack) {
                    var enabled = this.remoteStream_[i].getAudioTracks()[0].enabled;
                    logDebug("AudioTrack" + i + " : MuteAudioOut - changing from " + enabled + " to " + !e.willMute);
                    this.remoteStream_[i].getAudioTracks()[0].enabled = !e.willMute;
                }
            }
        }
        this.audioOutMuted_ = e.willMute;
        var y = this.messages_.event('OutEventMutedAudioOut');
        y.isMuted = e.willMute;
        this.outEventCallbackObject.dispatchOutEvent(y);
    };
    plugin.prototype.handleSetAudioVolume = function (volume) {
        this.volume_ = volume;
        for (var i = 0; i < this.maxSubscriptions_; i++) {
            var remoteView = document.getElementById("remoteVideo" + i);
            if (remoteView) {
                remoteView.volume = volume / 65000;
            }
        }
    };
    plugin.prototype.muteLocalVideo = function (muted) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.muted = muted;
        this.videoMuted_ = muted;
        this.postMessageToServer("/mutevideo", params, true, empty);
    };
    plugin.prototype.handleMuteVideo = function (e) {
        this.muteLocalVideo(e.willMute);
    };
    plugin.prototype.handleFreezeImage = function (e) {
        var par = {};
        par.callId = this.callId_;
        par.session = this.session_;
        par.enable = e.freeze;
        this.postMessageToServer("/freezeimage", par, true, empty);
        var elem = document.getElementById("localVideo");
        if (elem) {
            if (e.freeze) {
                elem.pause();
            } else {
                elem.play();
            }
        }
    };
    plugin.prototype.updateSelfView = function (val) {
        logDebug("UpdateSelfView - " + val);
    };
    plugin.prototype.getSourceId = function (val) {
        var self = this;
        if (webrtcDetectedBrowser === "chrome") {
            if (self.pendingRequestId_ === -1) {
                window.postMessage({type: 'VidyoRequestGetWindowsAndDesktops'}, '*');
            }
            return;
        }
        var constraints = {video: {mediaSource: "window", mozMediaSource: "window"}};
        self.startLocalShare(constraints);
    };
    plugin.prototype.startLocalShare = function (constraints) {
        var self = this;
        logInfo("Starting Local Screen Share with source **" + JSON.stringify(constraints) + "** ...");
        self.localSharePeerConn_ = new RTCPeerConnection(pluginIceServer);
        self.localSharePeerConn_.onicecandidate = function (evt) {
            if (evt.candidate === null) {
                logInfo("LocalSharePeerConn: Candidate collection complete");
            } else {
                self.sendCandidate(0, evt.candidate);
            }
        };
        self.localSharePeerConn_.oniceconnectionstatechange = function (state) {
            logInfo("share: oniceconnectionstatechange called " + state.target.iceConnectionState);
            self.postLogToServer("share: oniceconnectionstatechange called " + state.target.iceConnectionState);
        };
        self.localSharePeerConn_.onsignalingstatechange = function (state) {
            logInfo("share: onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
            self.postLogToServer("share: onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
        };
        var triggerOffer = function () {
            logDebug("share: onnegotiationneeded called");
            var offerConstraints = {offerToReceiveAudio: false, offerToReceiveVideo: false};
            self.localSharePeerConn_.createOffer(function (offer) {
                logInfo("Share: createoffer success " + offer.sdp);
                var params = {};
                params.session = self.session_;
                params.callId = self.callId_;
                params.sdp = offer;
                self.localShareOffer_ = offer;
                self.postMessageToServer("/startlocalshare", params, true, function (s, e) {
                    if (s) {
                        if (self.localShareOffer_ !== null) {
                            self.localShareOffer_ = null;
                            self.localSharePeerConn_.setLocalDescription(offer, function () {
                                logInfo("Share: setLocalDescription success");
                            }, function (err) {
                                logError("Share: SetLocalDescription error");
                            });
                        } else {
                            logInfo("startLocalShare - answer came first");
                        }
                    } else {
                        logError("Share: SetLocalDescription send error");
                    }
                });
            }, function (err) {
                logError("Share: CreateOffer error");
            }, offerConstraints);
        };
        self.localSharePeerConn_.onnegotiationneeded = triggerOffer;
        self.localSharePeerConn_.onaddstream = function (evt) {
            logInfo("share: onaddstream called - Should not happen");
        };
        self.localSharePeerConn_.onremovestream = function (evt) {
            logInfo("share: onremovestream called - Should not happen");
        };
        getUserMedia(constraints, function (shareStream) {
            logInfo("Got user media for screen share");
            self.localShareStream_ = shareStream;
            shareStream.onended = function () {
                logInfo("share stream ended called, stopping sharing");
                self.currentDesktopId_ += 1;
                self.stopLocalShare();
            };
            self.localSharePeerConn_.addStream(shareStream);
        }, function (err) {
            logError("Error in Screen Share GUM " + typeof(err));
            console.dir(err);
            self.currentDesktopId_ += 1;
        });
    };
    plugin.prototype.stopLocalShare = function () {
        var self = this;
        logDebug("stopLocalShare called...");
        if (self.pendingRequestId_ !== -1) {
            window.postMessage({type: 'VidyoCancelRequest', requestId: self.pendingRequestId_}, '*');
            self.pendingRequestId_ = -1;
        }
        if (self.localShareStream_ !== null) {
            stopMediaStream(self.localShareStream_);
            self.localShareStream_ = null;
        }
        if (self.localSharePeerConn_ !== null) {
            self.localSharePeerConn_.close();
            self.localSharePeerConn_ = null;
            self.localShareOffer_ = null;
            var params = {};
            params.session = self.session_;
            params.callId = self.callId_;
            self.postMessageToServer("/stoplocalshare", params, true, empty);
        }
    };
    plugin.prototype.getWindowSizes = function () {
        var windowSizes = [];
        for (var i = 0; i < this.activeVideoStreams_; i++) {
            var remoteView = document.getElementById("remoteVideo" + i);
            if (remoteView) {
                var windowsize = {};
                windowsize.width = remoteView.clientWidth;
                windowsize.height = remoteView.clientHeight;
                if (windowsize.width === 0 || windowsize.height === 0) {
                    break;
                }
                var maxWidth = 640;
                var maxHeigth = 360;
                if (resolutionMap.hasOwnProperty(this.configurationRequest_.videoPreferences)) {
                    maxWidth = resolutionMap[this.configurationRequest_.videoPreferences].w;
                    maxHeigth = resolutionMap[this.configurationRequest_.videoPreferences].h;
                }
                if (windowsize.width > maxWidth) {
                    windowsize.width = maxWidth;
                }
                if (windowsize.height > maxHeigth) {
                    windowsize.height = maxHeigth;
                }
                windowSizes.push(windowsize);
            }
        }
        return windowSizes;
    };
    plugin.prototype.windowSizeChanged = function (windowSizes) {
        if (windowSizes.length <= 0) {
            return;
        }
        var reqObj = {};
        reqObj.windowSizes = windowSizes;
        reqObj.numPreferred = 0;
        if ((this.shareList_.newApp === 0 && this.activeVideoStreams_ > 2) || (this.numPreferred_ === 1 && this.activeVideoStreams_ > 2)) {
            reqObj.numPreferred = 1;
        }
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.windows = reqObj;
        this.postMessageToServer("/windowsizes", params, true, empty);
    };
    plugin.prototype.sendEvent = function (e) {
        var self = this;
        switch (e.type) {
            case"PrivateInEventVcsoapGuestLink":
                self.sendConnect(e);
                self.numDesktops_ = self.getNumberOfLocalShares();
                break;
            case"InEventLeave":
                logInfo("InEventLeave - hangup call");
                self.sendDisconnect(true);
                break;
            case"EventPreview":
                self.updateSelfView(e.previewMode);
                break;
            case"InEventLoginCancel":
                logInfo("InEventLoginCancel - Cancel call");
                self.sendDisconnect(true);
                break;
            case"InEventMuteAudioIn":
                self.handleMuteAudioIn(e);
                break;
            case"InEventMuteAudioOut":
                self.handleMuteAudioOut(e);
                break;
            case"InEventMuteVideo":
                self.handleMuteVideo(e);
                break;
            case"InEventShare":
                self.getSourceId(e.window);
                break;
            case"InEventUnshare":
                self.stopLocalShare();
                break;
            case"InEventLayout":
                logDebug("InEventLayout preferred - " + e.numPreferred);
                self.numPreferred_ = e.numPreferred;
                self.windowSizes_ = this.getWindowSizes();
                self.windowSizeChanged(self.windowSizes_);
                break;
            case"InEventGroupChat":
                var params = {};
                params.callId = self.callId_;
                params.session = self.session_;
                params.message = e.message;
                self.postMessageToServer("/groupchatmessage", params, true, empty);
                break;
            case"InEventPrivateChat":
                var param = {};
                param.callId = self.callId_;
                param.session = self.session_;
                param.uri = e.uri;
                param.message = e.message;
                self.postMessageToServer("/privatechatmessage", param, true, empty);
                break;
            case"InEventSetFreezeImage":
                self.handleFreezeImage(e);
                break;
            case"InEventToggleStats":
                self.showStats_ = e.show;
                if (self.showStats_ === false) {
                    self.clearStats();
                } else {
                    self.showStats();
                }
                break;
            case"InEventLectureClearRaiseHand":
                var lectureHandMsg = {};
                lectureHandMsg.callId = self.callId_;
                lectureHandMsg.session = self.session_;
                lectureHandMsg.raise = e.raise;
                self.postMessageToServer("/lecturehand", lectureHandMsg, true, empty);
                break;
            default:
                logError("sendEvent unhandled - " + JSON.stringify(e));
                return false;
        }
        return true;
    };
    plugin.prototype.handleRemoteSdp = function (sdp) {
        var self = this;
        var setRemoteSdp = function () {
            var br = resolutionMap.hasOwnProperty(self.configurationRequest_.videoPreferences) ? resolutionMap[self.configurationRequest_.videoPreferences].br : "768";
            sdp.sdp = sdp.sdp.replace(/a=mid:video\r\n/g, 'a=mid:video\r\nb=AS:' + br + '\r\n');
            sdp.sdp = sdp.sdp.replace(/a=mid:sdparta_1\r\n/g, 'a=mid:sdparta_1\r\nb=AS:' + br + '\r\n');
            self.peerConn_.setRemoteDescription(new RTCSessionDescription(sdp), function () {
                logInfo("Remote SDP set successfully with type " + sdp.type + " sdp - " + sdp.sdp);
            }, function (e) {
                logError("Remote SDP set error");
                console.dir(e);
            });
        };
        if (self.offer_ !== null) {
            logInfo("Answer came first set local description");
            var o = self.offer_;
            self.offer_ = null;
            self.peerConn_.setLocalDescription(o, function () {
                self.sdpState_ = SDPStateEnum.COLLECTED;
                if (self.callState_ === CallStateEnum.IDLE) {
                    stopMediaStream(self.localStream_);
                    self.sdpState_ = SDPStateEnum.IDLE;
                } else {
                    setRemoteSdp();
                }
            }, function (err) {
                logError("SetLocalDescription error");
                console.dir(err);
            });
        } else {
            setRemoteSdp();
        }
    };
    plugin.prototype.updateActiveVideoStreams = function (active) {
        logInfo("OutEventVideoStreamsChanged --> UI streamCount=" + active + " prev=" + this.activeVideoStreams_);
        this.activeVideoStreams_ = active;
        var streamsChangedEvent = this.messages_.event('OutEventVideoStreamsChanged');
        streamsChangedEvent.streamCount = active;
        this.outEventCallbackObject.dispatchOutEvent(streamsChangedEvent);
        this.windowSizes_ = this.getWindowSizes();
        this.windowSizeChanged(this.windowSizes_);
    };
    plugin.prototype.handleParticipantsChanged = function (res) {
        this.participants_.length = 0;
        this.participantUris_.length = 0;
        for (var i = 0; i < res.count; i++) {
            this.participants_.push(res.names[i]);
            this.participantUris_.push(res.uris[i]);
        }
        var k = this.messages_.event('OutEventParticipantsChanged');
        this.outEventCallbackObject.dispatchOutEvent(k);
        logInfo("OutEventParticipantsChanged --> UI count=" + res.names.length);
        if (this.currentSubscriptions_ === 0) {
            this.sendInConference();
        }
        if (this.participants_.length == 1 || this.participants_.length == 0){
            $('.selfViewDiv-wrapper').addClass('selfViewDiv2-wrapper').removeClass('selfViewDiv-wrapper')
        }else{
            $('.selfViewDiv2-wrapper').addClass('selfViewDiv-wrapper').removeClass('selfViewDiv2-wrapper')
        }

        this.updateSubscriptions();
    };
    plugin.prototype.updateSubscriptions = function () {
        var count = this.participants_.length;
        if (count <= 0) {
            return;
        }
        if (this.lectureModeListener_) {
            count = 1;
        }
        if (count > 1) {
            count -= 1;
        }
        if (count > this.maxSubscriptions_) {
            count = this.maxSubscriptions_;
        }
        if (this.currentSubscriptions_ !== count) {
            if (this.currentSubscriptions_ < count) {
                while (this.currentSubscriptions_ < count) {
                    logInfo("Count increased to " + count + " adding subscription to " + this.currentSubscriptions_ + " Max is " + this.maxSubscriptions_);
                    if (this.currentSubscriptions_ < this.maxSubscriptions_) {
                        this.addSubscription();
                    }
                }
            } else {
                while (this.currentSubscriptions_ > count) {
                    logInfo("Count decreased to " + count + " removing subscription  from " + this.currentSubscriptions_);
                    this.removeSubscription();
                    if (this.activeVideoStreams_ > this.currentSubscriptions_) {
                        this.updateActiveVideoStreams(this.currentSubscriptions_);
                    }
                }
            }
        }
    };
    plugin.prototype.sendAddStream = function (streamId, sdp, cb) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.streamId = streamId;
        params.sdp = sdp;
        logInfo("sendAddStream sdp - " + sdp.sdp);
        this.postMessageToServer("/addstream", params, true, cb);
    };
    plugin.prototype.sendRemoveStream = function (streamId) {
        var params = {};
        params.session = this.session_;
        params.callId = this.callId_;
        params.streamId = streamId;
        this.postMessageToServer("/removestream", params, true, empty);
    };
    plugin.prototype.addSubscription = function () {
        var self = this;
        this.currentSubscriptions_ += 1;
        if (isBundleSupported() || this.currentSubscriptions_ === 1) {
            this.sendAddStream(this.currentSubscriptions_, {sdp: ''}, empty);
            return;
        }
        var index = this.currentSubscriptions_ - 1;
        this.additionalPeerConn_[index] = new RTCPeerConnection(pluginIceServer);
        this.additionalPeerConn_[index].onicecandidate = function (evt) {
            if (evt.candidate === null) {
                logInfo("PeerConn" + index + ": Candidate collection complete");
            } else {
                self.sendCandidate(index + 1, evt.candidate);
            }
        };
        this.additionalPeerConn_[index].oniceconnectionstatechange = function (state) {
            logInfo("PeerConn" + index + ": oniceconnectionstatechange called " + state.target.iceConnectionState);
            self.postLogToServer("PeerConn" + index + ": oniceconnectionstatechange called " + state.target.iceConnectionState);
        };
        this.additionalPeerConn_[index].onsignalingstatechange = function (state) {
            logInfo("PeerConn" + index + ": onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
            self.postLogToServer("PeerConn" + index + ": onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
        };
        this.additionalPeerConn_[index].onaddstream = function (evt) {
            logInfo("PeerConn" + index + ": onaddstream called");
            self.remoteStream_[index] = evt.stream;
            self.attachRemoteStream('', index + 1);
            if (self.remoteStream_[index].getAudioTracks()[0]) {
                self.remoteStream_[index].getAudioTracks()[0].enabled = !self.audioOutMuted_;
            }
        };
        this.additionalPeerConn_[index].onremovestream = function (evt) {
            logInfo("PeerConn" + index + ": onremovestream called");
        };
        var offerConstraints = {offerToReceiveAudio: false, offerToReceiveVideo: true};
        this.additionalPeerConn_[index].createOffer(function (offer) {
            logInfo("PeerConn" + index + ": createOffer success " + offer.sdp);
            self.additionalPeerConnOffers_[index] = offer;
            self.sendAddStream(index + 1, offer, function (s, e) {
                if (s) {
                    if (self.additionalPeerConnOffers_[index] !== null) {
                        self.additionalPeerConnOffers_[index] = null;
                        self.additionalPeerConn_[index].setLocalDescription(offer, function () {
                            logDebug("PeerConn" + index + ": setlocaldescription success ");
                        }, function (err) {
                            logError("PeerConn" + index + ": SetLocalDescription error");
                        });
                    } else {
                        logDebug("PeerConn" + index + ": answer came first");
                    }
                } else {
                    logError("PeerConn" + index + ": SetLocalDescription send error");
                }
            });
        }, function (err) {
            logError("PeerConn" + index + ": CreateOffer error");
        }, offerConstraints);
    };
    plugin.prototype.removeSubscription = function () {
        this.currentSubscriptions_ -= 1;
        var index = this.currentSubscriptions_;
        if (!isBundleSupported()) {
            if (this.additionalPeerConn_[index]) {
                this.additionalPeerConn_[index].close();
                this.additionalPeerConn_[index] = null;
                this.additionalPeerConnOffers_[index] = null;
            }
        }
        this.sendRemoveStream(index + 1);
        this.removeRemoteStream(index);
    };
    plugin.prototype.handleActiveTalkers = function (names) {
        this.activeTalkers_.length = 0;
        for (var j = 0; j < names.length; j++) {
            this.activeTalkers_.push(names[j]);
        }
        if (this.callState_ !== CallStateEnum.VIDEO_STARTED) {
            return;
        }
        var count = names.length;
        var active = 0;
        for (var i = 0; i < this.currentSubscriptions_ && i < count; i++) {
            var elemId = "participant" + i;
            var docElement = document.getElementById(elemId);
            var videoElem = document.getElementById("remoteVideo" + i);
            if (names[i].active) {
                active += 1;
            }
            if (docElement && videoElem) {
                var participantName = docElement.innerHTML;
                var newName = names[i].name;
                if (names[i].active) {
                    if (participantName !== newName) {
                        document.getElementById(elemId).innerHTML = newName;
                        videoElem.style.visibility = "visible";
                    }
                } else {
                    docElement.innerHTML = "";
                    videoElem.style.visibility = "hidden";
                }
            }
        }
        if (active !== this.activeVideoStreams_) {
            this.updateActiveVideoStreams(active);
        }
    };
    plugin.prototype.getStreamIndex = function (uri) {
        for (var i = 0; i < this.activeVideoStreams_; ++i) {
            if (this.activeTalkers_[i].url === uri) {
                return i;
            }
        }
        return -1;
    };
    plugin.prototype.getStatsForParticipant = function (statsRequest) {
        var index = this.getStreamIndex(statsRequest.uri);
        if (index === -1) {
            return;
        }
        if (this.localStats_[index]) {
            for (var s in this.localStats_[index]) {
                statsRequest[s] = this.localStats_[index][s];
            }
        }
    };
    plugin.prototype.getStatsForStreamIndex = function (index, statsRequest) {
        var pc = this.peerConn_;
        if (!isBundleSupported() && index > 0) {
            pc = this.additionalPeerConn_[index];
        }
        if (!this.localStats_[index]) {
            this.localStats_[index] = {
                videoResolution: {height: 0, width: 0},
                videoFrameRate: 0,
                videoDecodedFrameRate: 0,
                videoDisplayedFrameRate: 0,
                videoKBitsPerSecRecv: 0,
                firs: 0,
                nacks: 0,
                packetsLost: 0,
                lastBytesReceivedTS: Date.now(),
                noStats: true
            };
        }
        for (var s in this.localStats_[index]) {
            statsRequest[s] = this.localStats_[index][s];
        }
        var self = this;
        var track = this.remoteStream_[index].getVideoTracks()[0];
        webrtcGetStats(pc, track, function (streamStats) {
            if (!streamStats.hasOwnProperty("bytesReceived")) {
                return;
            }
            if (self.localStats_[index].bytesReceived) {
                var timeDiff = (Date.now() - self.localStats_[index].lastBytesReceivedTS) / 1000;
                var bitDiff = (streamStats.bytesReceived - self.localStats_[index].bytesReceived) * 8 / 1000;
                streamStats.videoKBitsPerSecRecv = Math.floor(bitDiff / timeDiff);
            } else {
                streamStats.videoKBitsPerSecRecv = 0;
                streamStats.noStats = true;
            }
            self.localStats_[index] = streamStats;
            self.localStats_[index].lastBytesReceivedTS = Date.now();
        });
    };
    plugin.prototype.updateRemoteShareStats = function () {
        var self = this;
        if (self.shareApp_ > 0) {
            if (!self.localStats_.remoteShare) {
                self.localStats_.remoteShare = {
                    videoResolution: {height: 0, width: 0},
                    videoFrameRate: 0,
                    videoDecodedFrameRate: 0,
                    videoDisplayedFrameRate: 0,
                    videoKBitsPerSecRecv: 0,
                    firs: 0,
                    nacks: 0,
                    packetsLost: 0,
                    lastBytesReceivedTS: Date.now(),
                    noStats: true
                };
            }
            var track = self.remoteStream_[self.remoteShareStreamIndex_ - 1].getVideoTracks()[0];
            var pc = self.peerConn_;
            if (!isBundleSupported()) {
                pc = self.remoteSharePeerConn_;
            }
            webrtcGetStats(pc, track, function (streamStats) {
                if (!streamStats.hasOwnProperty("bytesReceived")) {
                    return;
                }
                if (self.localStats_.remoteShare.bytesReceived) {
                    var timeDiff = (Date.now() - self.localStats_.remoteShare.lastBytesReceivedTS) / 1000;
                    var bitDiff = (streamStats.bytesReceived - self.localStats_.remoteShare.bytesReceived) * 8 / 1000;
                    streamStats.videoKBitsPerSecRecv = Math.floor(bitDiff / timeDiff);
                } else {
                    streamStats.videoKBitsPerSecRecv = 0;
                    streamStats.noStats = true;
                }
                self.localStats_.remoteShare = streamStats;
                self.localStats_.remoteShare.lastBytesReceivedTS = Date.now();
            });
        }
    };
    plugin.prototype.updateEncodeStats = function () {
        if (!this.localStats_.local) {
            this.localStats_.local = {
                videoResolution: {height: 0, width: 0},
                captureFrameRate: 0,
                encodeFrameRate: 0,
                videoKBitsPerSecSend: 0,
                numFirs: 0,
                numNacks: 0,
                lastBytesSentTS: Date.now(),
                noStats: true
            };
        }
        var self = this;
        var track = this.localStream_.getVideoTracks()[0];
        webrtcGetStats(self.peerConn_, track, function (stats) {
            if (!stats.hasOwnProperty("bytesSent")) {
                return;
            }
            if (self.localStats_.local.bytesSent) {
                var timeDiff = (Date.now() - self.localStats_.local.lastBytesSentTS) / 1000;
                var bitDiff = (stats.bytesSent - self.localStats_.local.bytesSent) * 8 / 1000;
                stats.videoKBitsPerSecSend = Math.floor(bitDiff / timeDiff);
            } else {
                stats.videoKBitsPerSecSend = 0;
                stats.noStats = true;
            }
            self.localStats_.local = stats;
            self.localStats_.local.lastBytesSentTS = Date.now();
        });
        if (self.localShareStream_ !== null) {
            if (!this.localStats_.localShare) {
                this.localStats_.localShare = {
                    videoResolution: {height: 0, width: 0},
                    captureFrameRate: 0,
                    encodeFrameRate: 0,
                    videoKBitsPerSecSend: 0,
                    numFirs: 0,
                    numNacks: 0,
                    lastBytesSentTS: Date.now(),
                    noStats: true
                };
            }
            track = self.localShareStream_.getVideoTracks()[0];
            webrtcGetStats(self.localSharePeerConn_, track, function (stats) {
                if (!stats.hasOwnProperty("bytesSent")) {
                    return;
                }
                if (self.localStats_.localShare.bytesSent) {
                    var timeDiff = (Date.now() - self.localStats_.localShare.lastBytesSentTS) / 1000;
                    var bitDiff = (stats.bytesSent - self.localStats_.localShare.bytesSent) * 8 / 1000;
                    stats.videoKBitsPerSecSend = Math.floor(bitDiff / timeDiff);
                } else {
                    stats.videoKBitsPerSecSend = 0;
                    stats.noStats = true;
                }
                self.localStats_.localShare = stats;
                self.localStats_.localShare.lastBytesSentTS = Date.now();
            });
        }
    };
    plugin.prototype.getLocalEncodeResolution = function (req) {
        req.width = this.localStats_.local.videoResolution.width;
        req.height = this.localStats_.local.videoResolution.height;
    };
    plugin.prototype.getLocalFrameRates = function (req) {
        req.captureFrameRate = this.localStats_.local.captureFrameRate;
        req.encodeFrameRate = this.localStats_.local.encodeFrameRate;
        req.sendFrameRate = this.localStats_.local.encodeFrameRate;
    };
    plugin.prototype.getLocalMediaInfo = function (req) {
        req.numIFrames = 0;
        req.numFirs = this.localStats_.local.numFirs;
        req.numNacks = this.localStats_.local.numNacks;
        req.mediaRTT = this.localStats_.local.mediaRTT;
    };
    plugin.prototype.addRemoteStream = function (label, id, sdp) {
        var self = this;
        if (isBundleSupported() || id === 1) {
            self.attachRemoteStream(label, id);
            return;
        }
        id -= 1;
        if (self.additionalPeerConn_[id] === null) {
            logInfo("PeerConn" + id + ": PeerConnection null, not adding");
            return;
        }
        var setAdditionalPeerConnRemoteDescription = function () {
            self.additionalPeerConn_[id].setRemoteDescription(new RTCSessionDescription(sdp), function () {
                logInfo("PeerConn" + id + ": Remote SDP set successfully with type " + sdp.type + " sdp - " + sdp.sdp);
            }, function (e) {
                logError("PeerConn" + id + ": Remote SDP set failed");
                console.dir(e);
            });
        };
        if (self.additionalPeerConnOffers_[id] !== null) {
            var o = self.additionalPeerConnOffers_[id];
            self.additionalPeerConnOffers_[id] = null;
            logInfo("PeerConn" + id + ": setting offer first");
            self.additionalPeerConn_[id].setLocalDescription(o, function () {
                logDebug("PeerConn" + id + ": setlocaldescription success ");
                setAdditionalPeerConnRemoteDescription();
            }, function (err) {
                logError("PeerConn" + id + ": SetLocalDescription error");
            });
        } else {
            setAdditionalPeerConnRemoteDescription();
        }
    };
    plugin.prototype.removeRemoteStream = function (id) {
        var remoteStream = this.remoteStream_[id];
        if (remoteStream) {
            logInfo("Detaching stream from " + id);
            var remoteView = document.getElementById("remoteVideo" + id);
            this.remoteStream_[id] = null;
            detachMediaStream(remoteView, remoteStream, false, false);
            var docElement = document.getElementById("participant" + id);
            if (docElement) {
                docElement.innerHTML = "";
            }
            return;
        }
    };
    plugin.prototype.handleShareAdded = function (res) {
        this.shareList_.remoteAppUri = res.shares.remoteAppUri.slice(1);
        this.shareList_.remoteAppName = res.shares.remoteAppName.slice(1);
        this.shareList_.numApp = res.shares.numApp;
        this.shareList_.currApp = res.shares.currApp;
        if (res.shares.eventUri === "") {
            res.shares.eventUri = res.shares.remoteAppUri[res.shares.numApp];
        }
        this.shareList_.eventUri = res.shares.eventUri;
        this.shareList_.newApp = res.shares.newApp;
        logInfo("Share added, shares are " + JSON.stringify(this.shareList_));
        var k = this.messages_.event('OutEventAddShare');
        k.URI = res.shares.eventUri;
        this.outEventCallbackObject.dispatchOutEvent(k);
        logInfo("OutEventAddShare --> UI - " + res.shares.eventUri);
    };
    plugin.prototype.handleShareRemoved = function (res) {
        this.shareList_.remoteAppUri = res.shares.remoteAppUri.slice(1);
        this.shareList_.remoteAppName = res.shares.remoteAppName.slice(1);
        this.shareList_.numApp = res.shares.numApp;
        this.shareList_.currApp = res.shares.currApp;
        this.shareList_.eventUri = res.shares.eventUri;
        this.shareList_.newApp = res.shares.newApp;
        logInfo("Share removed, shares are - " + JSON.stringify(this.shareList_));
        var k = this.messages_.event('OutEventRemoveShare');
        k.URI = res.shares.eventUri;
        this.outEventCallbackObject.dispatchOutEvent(k);
        logInfo("OutEventRemoveShare --> UI - " + res.shares.eventUri);
    };
    plugin.prototype.handleShareStreamChange = function (label, sdp) {
        var self = this;
        var shareName = document.getElementById("shareName");
        var dispName = this.shareList_.remoteAppName[this.shareList_.newApp - 1];
        if (this.shareApp_ !== 0) {
            logInfo("Sharing going on, toggling, name - " + dispName);
            this.shareApp_ = this.shareList_.newApp;
            shareName.innerHTML = dispName;
            return;
        }
        if (this.shareList_.newApp === 0) {
            logInfo("remote share: share stopped, returning");
            return;
        }
        if (!isBundleSupported()) {
            if (this.remoteSharePeerConn_ === null) {
                logInfo("remote share: share stopped, returning");
                return;
            }
            this.remoteSharePeerConn_.onaddstream = function (evt) {
                logInfo("remote share: onaddstream called ");
                self.remoteShareStream_ = evt.stream;
                self.remoteStream_[self.remoteShareStreamIndex_ - 1] = evt.stream;
                self.shareApp_ = self.shareList_.newApp;
                self.attachRemoteStream(label, self.remoteShareStreamIndex_, "shareVideo0");
            };
            var setRemoteShareRemoteDescription = function () {
                if (sdp.sdp && sdp.sdp.length > 0) {
                    self.remoteSharePeerConn_.setRemoteDescription(new RTCSessionDescription(sdp), function () {
                        logInfo("remote share: Remote SDP set successfully with type " + sdp.type + " sdp - " + sdp.sdp);
                    }, function (e) {
                        logError("remote share: Remote SDP set error");
                        console.dir(e);
                    });
                }
            };
            if (this.remoteSharePeerOffer_ !== null) {
                logInfo("remote share: setLocalDescription first");
                var o = this.remoteSharePeerOffer_;
                this.remoteSharePeerOffer_ = null;
                self.remoteSharePeerConn_.setLocalDescription(o, function () {
                    logDebug("remote share: setlocaldescription success answer firstcase ");
                    setRemoteShareRemoteDescription();
                }, function (err) {
                    logError("remote share: SetLocalDescription error");
                });
            } else {
                setRemoteShareRemoteDescription();
            }
        } else {
            this.shareApp_ = this.shareList_.newApp;
            this.attachRemoteStream(label, self.remoteShareStreamIndex_, "shareVideo0");
        }
        if (shareName) {
            shareName.innerHTML = dispName;
            logInfo("Sharing setting name - " + dispName);
        }
    };
    plugin.prototype.handleStartLocalShareResponse = function (sdp) {
        var self = this;
        var setShareRemoteDescription = function () {
            self.localSharePeerConn_.setRemoteDescription(new RTCSessionDescription(sdp), function () {
                logInfo("Share: Remote SDP set successfully with type " + sdp.type + " sdp - " + sdp.sdp);
            }, function (e) {
                logError("Share: Remote SDP set error");
                console.dir(e);
            });
        };
        if (self.localShareOffer_ !== null) {
            var o = self.localShareOffer_;
            self.localShareOffer_ = null;
            logInfo("handleStartLocalShareResponse - setting offer first");
            self.localSharePeerConn_.setLocalDescription(o, function () {
                setShareRemoteDescription();
            }, function (err) {
                logError("Share: SetLocalDescription error");
            });
        } else {
            setShareRemoteDescription();
        }
    };
    plugin.prototype.handleServerMutedAudio = function (muted, unmuteable) {
        if (unmuteable) {
            var k = this.messages_.event('OutEventMutedAudioIn');
            k.isMuted = muted;
            this.outEventCallbackObject.dispatchOutEvent(k);
        } else {
            this.serverMutedAudio = muted;
            this.muteLocalAudio(muted);
            var y = this.messages_.event('OutEventMutedServerAudioIn');
            y.isMuted = muted;
            this.outEventCallbackObject.dispatchOutEvent(y);
        }
    };
    plugin.prototype.handleServerMutedVideo = function (muted, unmuteable) {
        if (unmuteable) {
            var j = this.messages_.event('OutEventMutedVideo');
            j.isMuted = muted;
            this.outEventCallbackObject.dispatchOutEvent(j);
        } else {
            this.serverMutedVideo = muted;
            this.muteLocalVideo(muted);
            var y = this.messages_.event('OutEventMutedServerVideo');
            y.isMuted = muted;
            this.outEventCallbackObject.dispatchOutEvent(y);
        }
    };
    plugin.prototype.sendConferenceInfoEvent = function () {
        var y = this.messages_.event('OutEventConferenceInfoUpdate');
        this.outEventCallbackObject.dispatchOutEvent(y);
    };
    plugin.prototype.handleRecordingStatus = function (status) {
        if (status !== this.recording) {
            logInfo("Recording changed from " + this.recording + " to " + status);
            this.recording = status;
        }
        this.sendConferenceInfoEvent();
    };
    plugin.prototype.handleWebcastStatus = function (status) {
        if (status !== this.webcast) {
            logInfo("Webcast changed from " + this.webcast + " to " + status);
            this.webcast = status;
        }
        this.sendConferenceInfoEvent();
    };
    plugin.prototype.handleGroupChatMessage = function (res) {
        var groupChatEvent = this.messages_.event('OutEventGroupChat');
        groupChatEvent.uri = res.uri;
        groupChatEvent.displayName = res.displayName;
        groupChatEvent.message = res.message;
        this.outEventCallbackObject.dispatchOutEvent(groupChatEvent);
    };
    plugin.prototype.handlePrivateChatMessage = function (res) {
        var privateChatEvent = this.messages_.event('OutEventPrivateChat');
        privateChatEvent.uri = res.uri;
        privateChatEvent.displayName = res.displayName;
        privateChatEvent.message = res.message;
        this.outEventCallbackObject.dispatchOutEvent(privateChatEvent);
    };
    plugin.prototype.handleLectureModeStage = function (stage) {
        var strStage = "";
        switch (stage) {
            case 0:
                strStage = "LectureModeListen";
                this.lectureModeListener_ = true;
                this.updateSubscriptions();
                break;
            case 1:
                strStage = "LectureModePresenter";
                this.lectureModeListener_ = false;
                this.updateSubscriptions();
                break;
            case 2:
                strStage = "LectureModeAllowedToSpeak";
                break;
            case 3:
                strStage = "LectureModeStarted";
                logInfo("Lecture Mode Started");
                this.lectureModeStarted_ = true;
                break;
            case 10:
                strStage = "LectureModeStopped";
                logInfo("Lecture Mode Stopped");
                this.lectureModeListener_ = false;
                this.lectureModeStarted_ = false;
                this.updateSubscriptions();
                break;
            default:
                logError("Unknown LectureModeStage - " + stage);
                break;
        }
        var lectureModeStageEvt = this.messages_.event('OutEventLectureModeStage');
        lectureModeStageEvt.stage = strStage;
        this.outEventCallbackObject.dispatchOutEvent(lectureModeStageEvt);
    };
    plugin.prototype.handleLectureHand = function () {
        var lectureHandClearedEvt = this.messages_.event('OutEventLectureModeHandCleared');
        this.outEventCallbackObject.dispatchOutEvent(lectureHandClearedEvt);
    };
    plugin.prototype.handleLectureModePresenterChanged = function (uriOfPresenter) {
        this.lectureModePresenterUri_ = uriOfPresenter;
        var lectureModePresenterChanged = this.messages_.event('OutEventLectureModePresenterChanged');
        lectureModePresenterChanged.uriOfPresenter = uriOfPresenter;
        this.outEventCallbackObject.dispatchOutEvent(lectureModePresenterChanged);
    };
    plugin.prototype.handleCandidate = function (cand) {
        var o = {candidate: cand.candidate, sdpMid: cand.sdpMid, sdpMLineIndex: cand.sdpMlineIndex};
        var c = new RTCIceCandidate(o);
        switch (cand.streamId) {
            case 0:
                this.localSharePeerConn_.addIceCandidate(c);
                break;
            case 1:
                this.peerConn_.addIceCandidate(c);
                break;
            case 10:
                this.remoteSharePeerConn_.addIceCandidate(c);
                break;
            default:
                if (this.additionalPeerConn_[cand.streamId - 1]) {
                    this.additionalPeerConn_[cand.streamId - 1].addIceCandidate(c);
                }
                break;
        }
    };
    plugin.prototype.getEvents = function () {
        var self = this;
        if (self.callState_ !== CallStateEnum.IDLE) {
            var oReq = new XMLHttpRequest();
            oReq.open("post", self.webrtcServer_ + "/events", true);
            var params = {};
            params['session'] = self.session_;
            params['callId'] = self.callId_;
            oReq.onload = function () {
                if (oReq.status === 404 || oReq.status === 503) {
                    logError("getEvents received " + oReq.status + " disconnecting call");
                    self.sendDisconnect(false);
                    return;
                }
                logDebug("Received Events  - " + oReq.responseText);
                var evts = JSON.parse(oReq.responseText);
                for (var r = 0; r < evts.length; r++) {
                    var res = evts[r];
                    if (res.type === 'connectResponse') {
                        self.handleConnectResponse(res);
                    } else if (res.type === 'callDisconnected') {
                        self.sendDisconnect(false);
                    } else if (res.type === 'sdp') {
                        self.conferenceName_ = res.conf;
                        self.handleRemoteSdp(res.sdp);
                    } else if (res.type === 'participantsChanged') {
                        self.handleParticipantsChanged(res);
                    } else if (res.type === 'activeTalkersChanged') {
                        self.handleActiveTalkers(res.names);
                    } else if (res.type === 'streamAdded') {
                        self.addRemoteStream(res.label, res.id, res.sdp);
                    } else if (res.type === 'shareAdded') {
                        self.handleShareAdded(res);
                    } else if (res.type === 'shareRemoved') {
                        self.handleShareRemoved(res);
                    } else if (res.type === 'shareStreamChanged') {
                        self.handleShareStreamChange(res.label, res.sdp);
                    } else if (res.type === 'startLocalShareResponse') {
                        self.handleStartLocalShareResponse(res.sdp);
                    } else if (res.type === 'serverMutedAudio') {
                        self.handleServerMutedAudio(res.muted, res.unmuteable);
                    } else if (res.type === 'serverMutedVideo') {
                        self.handleServerMutedVideo(res.muted, res.unmuteable);
                    } else if (res.type === 'recordingStatus') {
                        self.handleRecordingStatus(res.status);
                    } else if (res.type === 'webcastStatus') {
                        self.handleWebcastStatus(res.status);
                    } else if (res.type === 'groupChatMessage') {
                        self.handleGroupChatMessage(res);
                    } else if (res.type === 'privateChatMessage') {
                        self.handlePrivateChatMessage(res);
                    } else if (res.type === 'lectureModeStage') {
                        self.handleLectureModeStage(res.stage);
                    } else if (res.type === 'lectureHand') {
                        self.handleLectureHand();
                    } else if (res.type === 'lectureModePresenterChanged') {
                        self.handleLectureModePresenterChanged(res.uriOfPresenter);
                    } else if (res.type === 'candidateEvent') {
                        self.handleCandidate(res);
                    } else {
                        logError("Unhandled event from server - " + res.type);
                    }
                }
                self.getEvents();
            };
            oReq.onerror = function (e) {
                logError("getEvents error");
                console.dir(e);
                self.sendDisconnect(false);
            };
            oReq.send(JSON.stringify(params));
        }
    };
    plugin.prototype.addPendingAttach = function (elemId, stream) {
        var obj = {};
        obj.elemId = elemId;
        obj.stream = stream;
        this.pendingAttaches_.push(obj);
    };
    plugin.prototype.doPendingAttaches = function () {
        logDebug("Doing pending attaches count=" + this.pendingAttaches_.length);
        for (var i = 0; i < this.pendingAttaches_.length; i++) {
            var obj = this.pendingAttaches_[i];
            var elemId = obj.elemId;
            var stream = obj.stream;
            var elem = document.getElementById(elemId);
            attachMediaStream(elem, stream);
        }
        if (this.shareApp_ !== 0) {
            var shareName = document.getElementById("shareName");
            shareName.innerHTML = this.shareList_.remoteAppName[this.shareList_.newApp - 1];
        }
        this.pendingAttaches_.length = 0;
        this.handleActiveTalkers(this.activeTalkers_.slice());
        this.watchForViewChange();
        var disableFunc = function (e) {
            e.preventDefault();
            return false;
        };
        var videoElements = document.getElementsByTagName('video');
        for (var k = 0; k < videoElements.length; k++) {
            videoElements[k].addEventListener('contextmenu', disableFunc);
        }
    };
    plugin.prototype.getReceiveStatsForDisplay = function (statRequest) {
        var name = statRequest.videoResolution.width + "x" + statRequest.videoResolution.height + " ";
        name += statRequest.videoKBitsPerSecRecv + "kbps ";
        name += statRequest.videoDisplayedFrameRate + "fps ";
        name += statRequest.firs + "/" + statRequest.nacks + "/" + statRequest.packetsLost;
        if (statRequest.noStats) {
            name = "...";
        }
        return name;
    };
    plugin.prototype.clearStats = function () {
        var elem;
        for (var i = 0; i < this.maxSubscriptions_; i++) {
            elem = document.getElementById("participantStats" + i);
            elem.style.display = "none";
            elem.innerHTML = "";
        }
        document.getElementById("selfViewName").innerHTML = "Self View";
        elem = document.getElementById("shareStats");
        elem.innerHTML = "";
        elem.style.display = "none";
    };
    plugin.prototype.showStats = function () {
        var self = this;
        var elem = document.getElementById("participantStats0");
        if (!elem) {
            return;
        }
        if (self.showStats_ === false) {
            return;
        }
        var name = '';
        var statRequest = {};
        for (var i = 0; i < self.activeVideoStreams_; i++) {
            statRequest.uri = self.activeTalkers_[i].url;
            self.getStatsForParticipant(statRequest);
            elem = document.getElementById("participantStats" + i);
            elem.innerHTML = self.getReceiveStatsForDisplay(statRequest);
            elem.style.display = "inline-block";
        }
        if (self.shareApp_ > 0) {
            statRequest = self.localStats_.remoteShare;
            elem = document.getElementById("shareStats");
            elem.innerHTML = self.getReceiveStatsForDisplay(statRequest);
            elem.style.display = "inline-block";
        }
        var localStats = self.localStats_.local;
        name = "Self View <br> " + localStats.videoResolution.width + "x" + localStats.videoResolution.height + " ";
        name += localStats.videoKBitsPerSecSend + "kbps ";
        name += localStats.encodeFrameRate + "fps ";
        name += localStats.numFirs + "/" + localStats.numNacks;
        if (localStats.noStats) {
            name = "Self View <br> ...";
        }
        document.getElementById("selfViewName").innerHTML = name;
    };
    plugin.prototype.watchForViewChange = function () {
        var self = this;
        self.watchInterval_ = setInterval(function () {
            var windowSizes = self.getWindowSizes();
            if (windowSizes.length !== self.windowSizes_.length) {
                self.windowSizes_ = windowSizes;
                self.windowSizeChanged(windowSizes);
            } else {
                for (var i = 0; i < windowSizes.length; i++) {
                    if (windowSizes[i].height !== self.windowSizes_[i].height || windowSizes[i].width !== self.windowSizes_[i].width) {
                        self.windowSizes_ = windowSizes;
                        self.windowSizeChanged(windowSizes);
                        break;
                    }
                }
            }
            self.updateEncodeStats();
            for (var k = 0; k < self.activeVideoStreams_; k++) {
                var stats = {};
                self.getStatsForStreamIndex(k, stats);
            }
            if (self.shareApp_ > 0) {
                self.updateRemoteShareStats();
            }
            self.showStats();
        }, 5000);
    };
    plugin.prototype.attachOrQueueUp = function (elem, remoteStream) {
        var remoteView = document.getElementById(elem);
        if (this.callState_ === CallStateEnum.VIDEO_STARTED) {
            logInfo("Attaching Stream to " + elem);
            attachMediaStream(remoteView, remoteStream);
            this.handleActiveTalkers(this.activeTalkers_.slice());
        } else {
            logInfo("Pending attach stream to " + elem);
            this.addPendingAttach(elem, remoteStream);
        }
    };
    plugin.prototype.attachRemoteStream = function (label, id, elemId) {
        if (isBundleSupported()) {
            var remoteStreams = this.peerConn_.getRemoteStreams();
            for (var i = 0; i < remoteStreams.length; i++) {
                var remoteStream = remoteStreams[i];
                if (remoteStream && remoteStream.id === label) {
                    var elem = elemId || "remoteVideo" + i;
                    this.remoteStream_[i] = remoteStream;
                    if (this.remoteStream_[i].getAudioTracks()[0]) {
                        this.remoteStream_[i].getAudioTracks()[0].enabled = !this.audioOutMuted_;
                    }
                    this.attachOrQueueUp(elem, this.remoteStream_[i]);
                    return;
                }
            }
            logError("Attach Remote Stream label not found - " + label);
            return;
        }
        id -= 1;
        logInfo("Attach Remote Stream using id - " + id);
        var elem1 = elemId || "remoteVideo" + id;
        this.attachOrQueueUp(elem1, this.remoteStream_[id]);
    };
    plugin.prototype.collectIceAndSendSdp = function () {
        var self = this;
        if (self.sdpState_ !== SDPStateEnum.IDLE) {
            logDebug("Ignore collect SDP request since in state - " + self.sdpState_);
            return;
        }
        logDebug("Changing SDP State to COLLECTING");
        self.sdpState_ = SDPStateEnum.COLLECTING;
        self.peerConn_ = new RTCPeerConnection(pluginIceServer);
        self.peerConn_.onicecandidate = function (evt) {
            if (evt.candidate === null) {
                logDebug("Main: Candidate collection complete");
            } else {
                self.sendCandidate(1, evt.candidate);
            }
        };
        self.peerConn_.oniceconnectionstatechange = function (state) {
            if (state.target && state.target.iceConnectionState === "failed") {
                logInfo("oniceconnectionstatechange called - " + state.target.iceConnectionState);
                self.sendDisconnect(false);
            } else {
                logInfo("oniceconnectionstatechange called - " + state.target.iceConnectionState);
                self.postLogToServer("main: oniceconnectionstatechange called - " + state.target.iceConnectionState);
            }
        };
        self.peerConn_.onsignalingstatechange = function (state) {
            logInfo("onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
            self.postLogToServer("main: onsignalingstatechange called - " + (state.target ? state.target.signalingState : state));
        };
        var triggerLocalOffer = function () {
            var offerConstraints = {offerToReceiveAudio: true, offerToReceiveVideo: true};
            logDebug("onnegotiationneeded called");
            self.peerConn_.createOffer(function (offer) {
                self.localDescCreated(offer);
            }, function (err) {
                logError("CreateOffer error");
                console.dir(err);
            }, offerConstraints);
        };
        self.peerConn_.onnegotiationneeded = triggerLocalOffer;
        self.peerConn_.onaddstream = function (evt) {
            logInfo("onaddstream called - " + evt.stream.id);
            if (!isBundleSupported()) {
                self.remoteStream_[0] = evt.stream;
            }
        };
        self.peerConn_.onremovestream = function (evt) {
            logError("onremovestream called - " + evt.stream.id);
        };
        var videoId = "";
        var videoLabel = "";
        if (self.configurationRequest_.numberCameras > 0) {
            try{
                videoId = self.videoSources_[self.configurationRequest_.currentCamera].id;
                videoLabel = self.videoSources_[self.configurationRequest_.currentCamera].label;
            }catch (e){
                videoId = self.videoSources_[0].id;
                videoLabel = self.videoSources_[0].label;
            }
        }
        var audioId = '0'
        if(self.configurationRequest_.numberMicrophones>0){
            audioId = self.audioSources_[self.configurationRequest_.currentMicrophone].id;
            logInfo("Current camera " + self.configurationRequest_.currentCamera + " Id: " + videoId + " Label: " + videoLabel);
            logInfo("Current Mic " + self.configurationRequest_.currentMicrophone + " Id: " + audioId + " Label: " + self.audioSources_[self.configurationRequest_.currentMicrophone].label);
            logInfo("Video Preference: " + self.configurationRequest_.videoPreferences);
        }
        var optionalConstraintObj = [];
        var mandatoryConstraintObj = {};
        var mediaOptions = {audio: {optional: [{sourceId: audioId}]}};
        if (videoId !== "") {
            var w = resolutionMap[self.configurationRequest_.videoPreferences].w;
            var h = resolutionMap[self.configurationRequest_.videoPreferences].h;
            switch (self.configurationRequest_.videoPreferences) {
                case"1080p":
                case"720p":
                case"540p":
                case"480p":
                case"360p":
                case"270p":
                case"240p":
                case"180p":
                    optionalConstraintObj.push({minHeight: h});
                    optionalConstraintObj.push({minWidth: w});
                    mandatoryConstraintObj.maxHeight = h;
                    mandatoryConstraintObj.maxWidth = w;
                    break;
                default:
                    logInfo("UNKNOWN VIDEO PREFERENCE - " + self.configurationRequest_.videoPreferences);
                    break;
            }
            optionalConstraintObj.push({sourceId: videoId});
            mediaOptions.video = {mandatory: mandatoryConstraintObj, optional: optionalConstraintObj};
        }
        if (audioId === '0') {
            mediaOptions.audio = true;
        }
        if (videoId === '0') {
            delete mediaOptions.video.optional.sourceId;
        }
        getUserMedia(mediaOptions, function (stream) {
            self.localStream_ = stream;
            if (self.audioInMuted_) {
                var enabled = self.localStream_.getAudioTracks()[0].enabled;
                logDebug("MuteAudioIn - changing from " + enabled + " to " + !self.audioInMuted_);
                self.localStream_.getAudioTracks()[0].enabled = !self.audioInMuted_;
            }
            self.addPendingAttach("localVideo", self.localStream_);
            self.peerConn_.addStream(stream);
        }, function (err) {
            logError("GetUserMedia error");
            self.postLogToServer("GetUserMedia error: " + JSON.stringify(err));
            console.dir(err);
            self.handleConnectResponse({error: "Camera/Microphone access failed"});
        });
    };
    plugin.prototype.localDescCreated = function (desc) {
        var self = this;
        self.offer_ = desc;
        self.sendSdp(desc, function (s, e) {
            if (s) {
                if (self.offer_ !== null) {
                    self.offer_ = null;
                    self.peerConn_.setLocalDescription(desc, function () {
                        logDebug("LocalDescCreated: Changing SDP State to COLLECTED from " + self.sdpState_);
                        self.sdpState_ = SDPStateEnum.COLLECTED;
                        if (self.callState_ === CallStateEnum.IDLE) {
                            stopMediaStream(self.localStream_);
                            self.sdpState_ = SDPStateEnum.IDLE;
                        } else {
                        }
                    }, function (err) {
                        logError("SetLocalDescription error");
                        console.dir(err);
                    });
                }
            } else {
                stopMediaStream(self.localStream_);
                self.sdpState_ = SDPStateEnum.IDLE;
                logError("SetLocalDescription send error");
            }
        });
    };
    plugin.prototype.sendSdp = function (sdp, cb) {
        var self = this;
        if (self.callState_ === CallStateEnum.CONNECTED) {
            var params = {};
            params.session = self.session_;
            params.callId = self.callId_;
            params.sdp = sdp;
            logInfo("main video sdp - " + sdp.sdp);
            self.postMessageToServer("/setsdp", params, true, cb);
        }
    };
    ns.plugin = plugin;
})(window);