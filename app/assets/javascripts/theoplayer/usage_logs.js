// playing
var sendEachPlayingTime = 10
var lastSendedTime = -1
var lastUsageBytes = 0 // TODO: find a better way to catch used bytes
// seeking
var currentTime = -1
var startSeek = -1
// pause
var lastPauseTime = 0

window.usagePlayerEventsStarted = false

window.addUsagePlayerListeners = function() {
  window.usagePlayerEventsStarted = true

  window.player.addEventListener('timeupdate', function(e) {
    if(startSeek == -1 && window.player.currentTime - lastSendedTime >= sendEachPlayingTime) {
      theoUsage("timeupdate", {currentTime: window.player.currentTime});
      lastSendedTime = window.player.currentTime;
    }
    if(startSeek == -1) currentTime = window.player.currentTime;
  });

  window.player.addEventListener('pause', function(e) {
    theoUsage("pause", { pauseTime: window.player.currentTime - lastPauseTime });
    lastPauseTime = window.player.currentTime
    if(startSeek == -1) {
      theoUsage("timeupdate", {currentTime: window.player.currentTime});
      lastSendedTime = window.player.currentTime;
    }
  });

  window.player.addEventListener('seeked', function(e) {
    theoUsage("seeked", {seeked: e.currentTime, last: startSeek });
    startSeek = -1;
    currentTime = window.player.currentTime;
    lastPauseTime = window.player.currentTime
    lastSendedTime = window.player.currentTime;
  });

  window.player.addEventListener('seeking', function(e) {
    if(startSeek == -1) {
      theoUsage("timeupdate", {currentTime});
      lastSendedTime = currentTime;
      startSeek = currentTime;
    }
  });
}

var getQuality = function() {
  if(player.videoTracks && player.videoTracks[0] && player.videoTracks[0].activeQuality) {
    return player.videoTracks[0].activeQuality.height;
  } else {
    return 0;
  }
}
var getBandwidth = function() {
  if(player.videoTracks && player.videoTracks[0] && player.videoTracks[0].activeQuality) {
    return player.videoTracks[0].activeQuality.bandwidth / 8 / 1024 // bit to kB
  } else {
    return 0;
  }
}

var theoUsage = function(eventName, data = null) {
  if(!window.sendPlayerUsage) return

  var isLivestream = !!window.Immerss.session && !window.Immerss.replay

  if(eventName == "pause") {
    window.sendPlayerUsage({
      event_type: "PAUSE_TIME",
      event_value: window.player.currentTime, //data.pauseTime,
      current_time: window.player.currentTime,
      video_resolution: getQuality()
    })
  }
  if(eventName == "timeupdate" && !isLivestream) {
    window.sendPlayerUsage({
      event_type: "PLAYBACK_TIME",
      event_value: data.currentTime - lastSendedTime,
      current_time: data.currentTime,
      video_resolution: getQuality()
    })
  }
  if(eventName == "seeked") {
    window.sendPlayerUsage({
      event_type: "REWIND_TIME",
      event_value: [data.last, data.seeked],
      video_resolution: getQuality()
    })
  }
  if(["pause", "timeupdate"].includes(eventName) && !isLivestream) {
    window.sendPlayerUsage({
      event_type: "PLAYBACK_BANDWIDTH", // it's not bandwidth - we're sending volume https://principlesoft.slack.com/archives/G011AN79WSK/p1664891402471409?thread_ts=1664889332.137829&cid=G011AN79WSK
      event_value: (window.player.metrics.totalBytesLoaded - lastUsageBytes) / 1024, //getBandwidth(),
      current_time: window.player.currentTime,
      video_resolution: getQuality()
    })
    lastUsageBytes = window.player.metrics.totalBytesLoaded
  }

  if(eventName == "timeupdate" && isLivestream) {
    window.sendPlayerUsage({
      event_type: "LIVESTREAM_TIME",
      event_value: data.currentTime - lastSendedTime,
      current_time: data.currentTime,
      video_resolution: getQuality()
    })
  }
  if(["pause", "timeupdate"].includes(eventName) && isLivestream) {
    window.sendPlayerUsage({
      event_type: "LIVESTREAM_BANDWIDTH", // it's not bandwidth - we're sending volume https://principlesoft.slack.com/archives/G011AN79WSK/p1664891402471409?thread_ts=1664889332.137829&cid=G011AN79WSK
      event_value: (window.player.metrics.totalBytesLoaded - lastUsageBytes) / 1024, //getBandwidth(),
      current_time: window.player.currentTime,
      video_resolution: getQuality()
    })
    lastUsageBytes = window.player.metrics.totalBytesLoaded
  }
}