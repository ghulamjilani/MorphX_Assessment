//= require ../views/widgets/_playlist_dependencies/ads_helper

(function() {
  function disableScroll() {
    // Get the current page scroll position
    scrollTop =
      window.pageYOffset || document.documentElement.scrollTop;
    scrollLeft =
      window.pageXOffset || document.documentElement.scrollLeft,

        // if any scroll is attempted,
        // set this to the previous value
        window.onscroll = function() {
            window.scrollTo(scrollLeft, scrollTop);
        };
  }
  window.initTheOplayer = function(url, append, data) {
    var Button, MyButton, PIPbtn, PicInPicButton, attrs, element, exit_PIP, isAdsAvailable, player, req_PIP, source, vidObject;
    if (append == null) {
      append = '#jwplayer_data_contaioner';
    }
    element = document.createElement('div');
    element.className = 'video-js theoplayer-skin theo-seekbar-above-controls';
    document.querySelector(append).append(element);
    if (data.video) {
      attrs = data.video;
    } else {
      attrs = data.session;
    }
    isAdsAvailable = function() {
      if (!attrs) {
        return false;
      }
      return _.isString(attrs.commercials_url) && _.isString(attrs.commercials_mime_type) && _.isNumber(attrs.commercials_duration);
    };
    player = new THEOplayer.Player(element, {
      license: window.ConfigFrontend.services.theo_player.license,
      libraryLocation: location.origin + "/javascripts/theo/",
      autoplay: true,
      mutedAutoplay: 'all',
      ui: {
        width: '100%',
        height: '100%',
        language: 'en',
        languages: {
          "en": {
            "The content will play in": "Starts in"
          }
        },
        fullscreen: {
          fullscreenOptions: {
            navigationUI: "auto"
          }
        }
      }
    });
    THEOplayer_UI_Hotkeys(player)
    THEOplayer_UI_Events(player)
    source = { crossOrigin: "anonymous" }
    player.addEventListener('canplay', function(e) {
      var v_height, v_width;
      v_width = player.videoWidth;
      v_height = player.videoHeight;
      var vjs = document.querySelector('.video-js')
      if(vjs) {
        vjs.setAttribute('data-originalVideoWidth', v_width);
        vjs.setAttribute('data-originalVideoHeight', v_height);
      }
    });
    // if (document.querySelector('body').classList.value.includes('mobile_device')) {
    //   player.addEventListener('play', function() {
    //     var container = document.querySelector('.main-video-container')
    //     if (window.matchMedia("(orientation: landscape)").matches) {
    //       window.onscroll = disableScroll
    //       container.style.cssText = 'height: 100vh !important; width: 100vw; position: fixed !important; left: 0; top: 0;'
    //     }
    //   })
    // }
    if (url.split('.').pop() === 'm3u8') {
      source.sources = [
        {
          src: url,
          type: 'application/x-mpegurl'
        }
      ];
    } else {
      source.sources = [
        {
          src: url
        }
      ];
    }
    if (isAdsAvailable()) {
      source.ads = [
        {
          sources: window.getAdsUrl(attrs),
          timeOffset: 'start'
        }
      ];
      player.currentTime = attrs.commercials_duration;
    }
    player.source = source;
    player.muted = true;
    player.autoplay = true;
    consoleEvents(player);
    window.lastPlayer = player;
    Button = THEOplayer.videojs.getComponent('Button');
    MyButton = THEOplayer.videojs.extend(Button, {
      constructor: function() {
        Button.apply(this, arguments);

        /* initialize your button */
      },
      handleClick: function() {
        document.querySelector('body').classList.toggle('curtainActive');
        document.dispatchEvent(new CustomEvent("curtainActiveEvent"));
      },
      buildCSSClass: function() {
        return 'curtainTogl';
      }
    });
    THEOplayer.videojs.registerComponent('MyButton', MyButton);
    player.ui.getChild('controlBar').addChild('myButton', {});

    vidObject = document.querySelectorAll('.main-video-container video') ? document.querySelectorAll('.main-video-container video')[1] : null;
    if (document.pictureInPictureEnabled && vidObject) {
      PIPbtn = document.querySelector('.PicInPicOn');
      exit_PIP = function() {
        document.exitPictureInPicture();
        console.log('leavepictureinpicture ');
        PIPbtn.removeClass('active');
        document.querySelector('body').removeClass('PIP_active');
      };
      req_PIP = function() {
        var video = document.querySelector('.main-video-container video')
        video.requestPictureInPicture();
        PIPbtn.addClass('active');
        document.querySelector('body').addClass('PIP_active');
        console.log('showPictureinpicture');
      };
      vidObject.addEventListener('leavepictureinpicture', function(event) {
        PIPbtn.removeClass('active');
        document.querySelector('body').removeClass('PIP_active');
      });
      document.querySelector('.main-video-container').classList.add('PIP_suported');
      PicInPicButton = THEOplayer.videojs.extend(Button, {
        constructor: function() {
          Button.apply(this, arguments);

          this.el().disabled = true;
        },
        handleClick: function() {
          PIPbtn = document.querySelector('.PicInPicOn');
          if (!document.pictureInPictureElement) {
            req_PIP();
          } else {
            exit_PIP();
          }
        },
        buildCSSClass: function() {
          return 'PicInPicOn';
        }
      });
      THEOplayer.videojs.registerComponent('PicInPicButton', PicInPicButton);
      player.ui.getChild('controlBar').addChild('PicInPicButton', {});

      document.querySelector('.main-video-container video').onloadedmetadata = function(e) {
        document.querySelector('.PicInPicOn').removeAttribute('disabled');
      };
    }

    // chaanges for context menu
    function customizeContextMenu(container) {
      var contextMenuLink = container.querySelector('.theo-context-menu-a');
      // change context menu href
      contextMenuLink.href = ConfigGlobal.host
      contextMenuLink.innerHTML = I18n.t('assets.javascripts.powered');
    }
    var element = document.querySelector('.main-video-container');
    if (element)
        customizeContextMenu(element);


    return player;
  };


  // if (document.querySelector('body').classList.value.includes('mobile_device')) {
  //   function setFullScreen() {
  //     var video = document.querySelector('.main-video-container video');
  //     var container = document.querySelector('.main-video-container')
  //     const isVideoPlaying = video && video.currentTime > 0 && !video.paused && !video.ended && video.readyState > 2;
  //     if (container && isVideoPlaying && !window.matchMedia("(orientation: landscape)").matches) {
  //       container.style.cssText = 'height: 100vh !important; width: 100vw; position: fixed !important; left: 0; top: 0;'
  //       window.onscroll = disableScroll
  //     } else {
  //       window.onscroll = function() {}
  //       container.removeAttribute('style');
  //     }
  //   }
  //   window.addEventListener("orientationchange", setFullScreen);
  // }

  var checkWaiting = false
  var seekingCount = 0
  setInterval(() => {
    seekingCount = 0
  }, 5000)
  window.consoleEvents = function(player) {
    window.player = player
    if(!window.usagePlayerEventsStarted && window.addUsagePlayerListeners) {
      window.addUsagePlayerListeners()
    }

    if(!window.usagePlayerEventsStarted && !window.addUsagePlayerListeners) {
      var usagePlayerTryCount = 5
      var usagePlayerStartingInterval = setInterval(() => {
        if(window.usagePlayerEventsStarted) clearInterval(usagePlayerStartingInterval)
        if(usagePlayerTryCount <= 0) clearInterval(usagePlayerStartingInterval)

        if(!window.usagePlayerEventsStarted && window.addUsagePlayerListeners) {
          window.addUsagePlayerListeners()
        }

        usagePlayerTryCount--

      }, 1000)
    }

    var arr = ['canplay', 'canplaythrough', 'contentprotectionerror', 'contentprotectionsuccess', 'encrypted', 'ended', 'error', 'loadeddata', 'loadedmetadata', 'pause', 'play', 'playing', 'presentationmodechange', 'progress', 'ratechange', 'readystatechange', 'representationchange', 'seeked', 'seeking', 'segmentnotfound', 'volumechange', 'waiting'];
    return arr.map(function(i, type){
      return player.addEventListener(type, function(e) {
        var el = document.querySelector('.theo-live-control');
        if(el){
          var style = window.getComputedStyle(el, null);
          var display = style.getPropertyValue('display');
          var show = display == 'none' ? false : true;
        } else {
          var show = false;
        }
        if(!checkWaiting && type == 'waiting' && document.querySelector('.theoplayer-skin.vjs-waiting') && show){
          checkWaiting = true
          setTimeout(function() {
            checkWaiting = false
          }, 2000)
        }
        return console.log(e);
      });
    })
  };

  window.initPreviewTheOplayer = function(url, append) {
    var player;
    if (append == null) {
      append = '#jwplayer_data_contaioner';
    }
    player = initTheOplayer(url, append);
    player.addEventListener('waiting', function(e) {
      document.querySelector(append).style.display = 'none';
      return document.querySelector('#start_stream_first').style.display = 'block';
    });
    return player.addEventListener('progress', function(e) {
      document.querySelector('#start_stream_first').style.display = 'none';
      return document.querySelector(append).style.display = 'block';
    });
  };

}).call(this);

//url mp4 only
//seconds 0: first, -1: last or can set 0%..100%
// width 0: auto
// height 0: auto
// callback = function(imageDataUrl){console.log(imageDataUrl)}

window.videoImageDataUrl = function (url, seconds, width, height, callback) {
    let video = document.createElement('video')
    if (seconds < 1 || seconds == null)
      seconds = 1
    video.src = url
    video.crossOrigin = 'anonymous'
    video.currentTime = seconds
    video.load()
    video.addEventListener('canplaythrough', function() {
      let resultWidth = video.videoWidth
      let resultHeight = video.videoHeight
      let proportion = resultWidth/resultHeight
      if (width > 0 && height == 0){
          resultWidth = width
          resultHeight = width/proportion
      }
      if (width == 0 && height > 0){
          resultWidth = height*proportion
          resultHeight = height
      }
      if (width > 0 && height > 0){
          resultWidth = width
          resultHeight = height
      }
      let canvas = document.createElement('canvas')
      canvas.height = resultHeight
      canvas.width = resultWidth
      let ctx = canvas.getContext('2d')
      ctx.drawImage(video, 0, 0, resultWidth, resultHeight)
      callback(canvas.toDataURL('image/png'))
    })
}
