(function(ns) {

var RTCPeerConnection = null;
var getUserMedia = null;
var attachMediaStream = null;
var reattachMediaStream = null;
var webrtcDetectedBrowser = null;
var webrtcDetectedVersion = null;
var webrtcGetSources = null;
var webrtcGetStats = null;

var detachMediaStream = function(element, stream, isLocal, stop) {
        console.log("Detaching media stream ", element, " stream ", stream);
        if (element) {
            element.pause();
            element.src = '';
            // element.parentNode.removeChild(element);
        }

        // stopping stream (camera, ...)

        if (stream) {
            if (webrtcDetectedBrowser === "firefox") { // no stop method on remote streams in firefox
                if (isLocal && stop) {
                    // stream.stop();
                    stopMediaStream(stream);
                }
            } else {
                if (stop) {
                    // stream.stop();
                    stopMediaStream(stream);
                }
            }
        }
};

var stopMediaStream = function(s) {
    var t = s.getTracks();
    for (var i = 0; i < t.length; i++) {
        t[i].stop();
    }
};

function EmptyAudioVideoSources(cb) {
  var audioSources = [{'id': '0', 'label': 'Default'}];
  var videoSources = [{'id': '0', 'label': 'Default'}];
  setTimeout(function() {
    cb(audioSources, videoSources);
  }, 100);
}


function maybeFixConfiguration(pcConfig) {
  if (pcConfig === null) {
    return;
  }
  for (var i = 0; i < pcConfig.iceServers.length; i++) {
    if (pcConfig.iceServers[i].hasOwnProperty('urls')){
      pcConfig.iceServers[i]['url'] = pcConfig.iceServers[i]['urls'];
      delete pcConfig.iceServers[i]['urls'];
    }
  }
}

if (navigator.mozGetUserMedia) {
  console.log("This appears to be Firefox");

  webrtcDetectedBrowser = "firefox";

  webrtcDetectedVersion =
           parseInt(navigator.userAgent.match(/Firefox\/([0-9]+)\./)[1], 10);

  // The RTCPeerConnection object.
  RTCPeerConnection = function(pcConfig, pcConstraints) {
    // .urls is not supported in FF yet.
    // maybeFixConfiguration(pcConfig);
    return new mozRTCPeerConnection(pcConfig, pcConstraints);
  };

  // The RTCSessionDescription object.
  RTCSessionDescription = mozRTCSessionDescription;

  // The RTCIceCandidate object.
  RTCIceCandidate = mozRTCIceCandidate;

  // Get UserMedia (only difference is the prefix).
  // Code from Adam Barth.
  getUserMedia = navigator.mozGetUserMedia.bind(navigator);
  navigator.getUserMedia = getUserMedia;

  // Creates iceServer from the url for FF.
  createIceServer = function(url, username, password) {
    var iceServer = null;
    var urlParts = url.split(':');
    if (urlParts[0].indexOf('stun') === 0) {
      // Create iceServer with stun url.
      iceServer = { 'url': url };
    } else if (urlParts[0].indexOf('turn') === 0) {
      if (webrtcDetectedVersion < 27) {
        // Create iceServer with turn url.
        // Ignore the transport parameter from TURN url for FF version <=27.
        var turnUrlParts = url.split("?");
        // Return null for createIceServer if transport=tcp.
        if (turnUrlParts.length === 1 ||
            turnUrlParts[1].indexOf('transport=udp') === 0) {
          iceServer = {'url': turnUrlParts[0],
                       'credential': password,
                       'username': username};
        }
      } else {
        // FF 27 and above supports transport parameters in TURN url,
        // So passing in the full url to create iceServer.
        iceServer = {'url': url,
                     'credential': password,
                     'username': username};
      }
    }
    return iceServer;
  };

  createIceServers = function(urls, username, password) {
    var iceServers = [];
    // Use .url for FireFox.
    for (i = 0; i < urls.length; i++) {
      var iceServer = createIceServer(urls[i],
                                      username,
                                      password);
      if (iceServer !== null) {
        iceServers.push(iceServer);
      }
    }
    return iceServers;
  };

  // Attach a media stream to an element.
  attachMediaStream = function(element, stream) {
    console.log('Attaching Media Stream ', element, '  ', stream);
    if (!element) { return; }
    element.mozSrcObject = stream;
    element.play();
  };

  reattachMediaStream = function(to, from) {
    console.log("Reattaching media stream");
    to.mozSrcObject = from.mozSrcObject;
    to.play();
  };

  // Fake get{Video,Audio}Tracks
  if (!MediaStream.prototype.getVideoTracks) {
    MediaStream.prototype.getVideoTracks = function() {
      return [];
    };
  }

  if (!MediaStream.prototype.getAudioTracks) {
    MediaStream.prototype.getAudioTracks = function() {
      return [];
    };
  }
  webrtcGetSources = EmptyAudioVideoSources;

  webrtcGetStats = function(pc, track, callback) {
    pc.getStats(track, 
      function(resp) {
        var stats = {};
        stats.videoResolution = {};
        stats.videoResolution.height = 0;
        stats.videoResolution.width = 0;

        for (var stat in resp) {
          if (stat.indexOf("rtp") !== -1) {
            if (stat.indexOf("inbound") !== -1) {
              stats.firs = 0;
              stats.nacks = 0;
              stats.videoFrameRate = Math.floor(resp[stat]["framerateMean"]);
              stats.videoDecodedFrameRate = stats.videoFrameRate;
              stats.videoDisplayedFrameRate = stats.videoFrameRate;
              stats.bytesReceived = resp[stat]["bytesReceived"];
              stats.packetsReceived = resp[stat]["packetsReceived"];
              stats.packetsLost = resp[stat]["packetsLost"];
              callback(stats);
              return;
            } else if (stat.indexOf("outbound") !== -1) {
              stats.captureFrameRate = Math.floor(resp[stat]["framerateMean"]);
              stats.encodeFrameRate = stats.captureFrameRate
              stats.numFirs = 0;
              stats.numNacks = 0;
              stats.mediaRTT = 0;
              stats.bytesSent = resp[stat]["bytesSent"];
              callback(stats);
              return;
            }
          }
        }
      },
      function (err) {
        callback({error: err});
      });

  };

} else if (navigator.webkitGetUserMedia) {
  console.log("This appears to be Chrome");

  webrtcDetectedBrowser = "chrome";
  webrtcDetectedVersion =
         parseInt(navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./)[2], 10);

  // Creates iceServer from the url for Chrome M33 and earlier.
  createIceServer = function(url, username, password) {
    var iceServer = null;
    var urlParts = url.split(':');
    if (urlParts[0].indexOf('stun') === 0) {
      // Create iceServer with stun url.
      iceServer = { 'url': url };
    } else if (urlParts[0].indexOf('turn') === 0) {
      // Chrome M28 & above uses below TURN format.
      iceServer = {'url': url,
                   'credential': password,
                   'username': username};
    }
    return iceServer;
  };

  // Creates iceServers from the urls for Chrome M34 and above.
  createIceServers = function(urls, username, password) {
    var iceServers = [];
    if (webrtcDetectedVersion >= 34) {
      // .urls is supported since Chrome M34.
      iceServers = {'urls': urls,
                    'credential': password,
                    'username': username };
    } else {
      for (i = 0; i < urls.length; i++) {
        var iceServer = createIceServer(urls[i],
                                        username,
                                        password);
        if (iceServer !== null) {
          iceServers.push(iceServer);
        }
      }
    }
    return iceServers;
  };

  // The RTCPeerConnection object.
  RTCPeerConnection = function(pcConfig, pcConstraints) {
    // .urls is supported since Chrome M34.
    if (webrtcDetectedVersion < 34) {
      maybeFixConfiguration(pcConfig);
    }
    return new webkitRTCPeerConnection(pcConfig, pcConstraints);
  };

  // Get UserMedia (only difference is the prefix).
  // Code from Adam Barth.
  getUserMedia = navigator.webkitGetUserMedia.bind(navigator);
  navigator.getUserMedia = getUserMedia;

  // Attach a media stream to an element.
  attachMediaStream = function(element, stream) {
    console.log('Attaching Media Stream ', element, '  ', stream);
    if (!element)  { return; }
    if (typeof element.srcObject !== 'undefined') {
      element.srcObject = stream;
    } else if (typeof element.mozSrcObject !== 'undefined') {
      element.mozSrcObject = stream;
    } else if (typeof element.src !== 'undefined') {
      element.src = URL.createObjectURL(stream);
    } else {
      console.log('Error attaching stream to element.');
    }
  };

  reattachMediaStream = function(to, from) {
    to.src = from.src;
  };

  function webkitGetSources(cb, secondTime) {
    if (location.protocol !== 'https:') {
      EmptyAudioVideoSources(cb);
      return;
    }

    // On chrome mobile, https does not store the permissions, hence it goes into an infinite loop of asking for permission
    if (secondTime === undefined) {
      secondTime = false;
    }

    // MediaStreamTrack.getSources(function(sourceInfos) {
    navigator.mediaDevices.enumerateDevices().then(function(sourceInfos) {
      var audioSources = [];
      var videoSources = [];
      for (var i = 0; i < sourceInfos.length; ++i) {
        var sourceInfo = sourceInfos[i];
        if (!sourceInfo.label) {
          if (secondTime) {
            EmptyAudioVideoSources(cb);
            return;
          }
          var mediaOptions = {
            video: true,
            audio: true
          };
          /** Chrome has this 'security' feature where labels are given only if the user has granted permission to access microphone/camera */
          getUserMedia(mediaOptions, function (stream) {
            // stream.stop();
            stopMediaStream(stream);
            webkitGetSources(cb, true);
            return;
          }, function(err){
            console.error("Denied getUserMedia - using Default sources");
            EmptyAudioVideoSources(cb);
          });
          return;
        }
        console.dir(sourceInfo);
        if (sourceInfo.kind === 'audioinput') {
          var audioSource = {'id': sourceInfo.deviceId, 'label': sourceInfo.label.replace(/\([a-zA-Z0-9]+:[a-zA-Z0-9]+\)/, '')} ;
          audioSources.push(audioSource);

        } else if (sourceInfo.kind === 'videoinput') {
          var videoSource = {'id': sourceInfo.deviceId, 'label': sourceInfo.label.replace(/\([a-zA-Z0-9]+:[a-zA-Z0-9]+\)/, '')} ;
          if (videoSource.label !== 'VidyoCamera') {
            videoSources.push(videoSource);
          } else {
            console.log('Dropping VidyoCamera');
          }
        } else {
          console.log('Some other kind of source: ', sourceInfo);
        }
      }
      cb(audioSources, videoSources);
    });
  }

  webrtcGetSources = webkitGetSources;


  webrtcGetStats = function(pc, track, callback) {
    pc.getStats(
      function (resp) {
        var results = resp.result();
        var stats = {};
        stats.videoResolution = {};
        for (var res in results) {
          if (results[res].id.indexOf("ssrc") !== -1) {
            if (results[res].id.indexOf("_recv") !== -1) {
              stats.videoResolution.height = results[res].stat('googFrameHeightReceived');
              stats.videoResolution.width = results[res].stat('googFrameWidthReceived');
              stats.firs = results[res].stat('googFirsSent');
              stats.nacks = results[res].stat('googNacksSent');
              stats.videoFrameRate = results[res].stat('googFrameRateReceived');
              stats.videoDecodedFrameRate = results[res].stat('googFrameRateDecoded');
              stats.videoDisplayedFrameRate = results[res].stat('googFrameRateOutput');
              stats.bytesReceived = results[res].stat('bytesReceived');
              stats.packetsReceived = results[res].stat('packetsReceived');
              stats.packetsLost = results[res].stat('packetsLost');
              callback(stats);
              return;
            } else if (results[res].id.indexOf("_send") !== -1) {
              stats.videoResolution.width = results[res].stat('googFrameWidthInput');
              stats.videoResolution.height = results[res].stat('googFrameHeightInput');
              stats.captureFrameRate = results[res].stat('googFrameRateInput');
              stats.encodeFrameRate = results[res].stat('googFrameRateSent');
              stats.numFirs = results[res].stat('googFirsReceived');
              stats.numNacks = results[res].stat('googNacksReceived');
              stats.mediaRTT = results[res].stat('googRtt');
              stats.bytesSent = results[res].stat('bytesSent');
              callback(stats);
              return;
            }
          }
        }
      }, 
      track, 
      function() {
      });
    };
} else {
  console.log("Browser does not appear to be WebRTC-capable");
}

ns.RTCPeerConnection     = RTCPeerConnection;
ns.getUserMedia          = getUserMedia;
ns.attachMediaStream     = attachMediaStream;
ns.detachMediaStream     = detachMediaStream;
ns.stopMediaStream       = stopMediaStream;
ns.webrtcDetectedBrowser = webrtcDetectedBrowser;
ns.webrtcDetectedVersion = webrtcDetectedVersion;
ns.webrtcGetSources      = webrtcGetSources;
ns.webrtcGetStats        = webrtcGetStats;

})(window);
