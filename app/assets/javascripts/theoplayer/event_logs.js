function getCookies() {
  var c = document.cookie, v = 0, cookies = {};
  if (document.cookie.match(/^\s*\$Version=(?:"1"|1);\s*(.*)/)) {
      c = RegExp.$1;
      v = 1;
  }
  if (v === 0) {
      c.split(/[,;]/).map(function(cookie) {
          var parts = cookie.split(/=/, 2),
              name = decodeURIComponent(parts[0].trimLeft()),
              value = parts.length > 1 ? decodeURIComponent(parts[1].trimRight()) : null;
          cookies[name] = value;
      });
  } else {
      c.match(/(?:^|\s+)([!#$%&'*+\-.0-9A-Z^`a-z|~]+)=([!#$%&'*+\-.0-9A-Z^`a-z|~]*|"(?:[\x20-\x7E\x80\xFF]|\\[\x00-\x7F])*")(?=\s*[,;]|$)/g).map(function($0, $1) {
          var name = $0,
              value = $1.charAt(0) === '"'
                        ? $1.substr(1, -1).replace(/\\(.)/g, "$1")
                        : $1;
          cookies[name] = value;
      });
  }
  return cookies;
}

window.LogDisabled = function() {
  try {return window.ConfigFrontend.log_events.disable}catch(e){return false}
};

var isTokenUpdating = false // when updating jwt token by XMLHttpRequest

window.adEventLog = function(eventName, data) {
  return true // disable old logs
    if (LogDisabled()){
      return true
    }
    if(isTokenUpdating) return
    var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance
    if(window.Routes) {
      xmlhttp.open("POST", Routes.api_v1_system_logs_path({format: 'json'}));
    } else {
      xmlhttp.open("POST", ConfigGlobal.usage.user_messages_url);
    }
    xmlhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    var token = getCookies('_unite_session_jwt');
    var refresh = getCookies('_unite_session_jwt_refresh');
    if (token){
      xmlhttp.setRequestHeader("Authorization", token);
    }
    else if(refresh) {
      isTokenUpdating = true
      var Rxmlhttp = new XMLHttpRequest();
      Rxmlhttp.open("GET", "/api/v1/auth/user_tokens");
      Rxmlhttp.setRequestHeader("Authorization", "Bearer " + refresh);
      Rxmlhttp.send()
      Rxmlhttp.onload = function() {
        var res = JSON.parse(Rxmlhttp.response).response
        setCookie("_unite_session_jwt", res.jwt_token, +(jwtParse(res.jwt_token).exp + '000'))
        setCookie("_cable_jwt", res.jwt_token, +(jwtParse(res.jwt_token).exp + '000'), location.hostname)
        setCookie("_unite_session_jwt_refresh", res.jwt_token_refresh, +(jwtParse(res.jwt_token_refresh).exp + '000'))
        localStorage.setItem("_unite_session_jwt_refresh", res.jwt_token_refresh);
        isTokenUpdating = false
      };
      Rxmlhttp.onerror = function() {
        isTokenUpdating = false
      };
    }
    xmlhttp.send(JSON.stringify({ service: 'Theoplayer', page: window.location.href, event: eventName, data: data }));
  };

window.THEOplayer_UI_Events = function(player) {
    try {
      player.addEventListener('playing', function(e) {
        adEventLog('playing', 'current time: ' +  e.currentTime);
      });

      player.addEventListener('pause', function(e) {
        adEventLog('pause', 'current time: ' +  e.currentTime);
      });

      player.ads.addEventListener('adbegin', function(e) {
        adEventLog('adbegin', 'duration: ' + e.ad.duration);
      });

      // detect tracks being added to the player
      player.textTracks.addEventListener('addtrack', function(e0) {
        // detect cues being added to the track
        e0.track.addEventListener('addcue', function(e1){
          // detect a cue being shown from a track
          e1.cue.addEventListener('enter', function(e2) {
            adEventLog('enter', 'text: ' + (e2.cue.text ? e2.cue.text.substr(0,30) : ""));
          });
        });
      });

      // detect video tracks being added to the player
      player.videoTracks.addEventListener('addtrack', function(e0) {
        // detect quality changes of a track
        e0.track.addEventListener('activequalitychanged', function(e1) {
          adEventLog('activequalitychanged', 'quality: ' + e1.quality.height);
        });
      });

    }
    catch (e) {
      //FIXME change to Airbrake after deploy in production
      console.log(e)
    }
};
