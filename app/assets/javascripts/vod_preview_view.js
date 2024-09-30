(function() {
  var scrollToRecordingTile, scrollToVodTile;

  $(function() {
    var scrollToVideoIfRequestedViaParams;
    $('body').on('click', '#reload_vod', function(e) {
      var el, view;
      e.preventDefault();
      el = $('.PlayVideoOnDemand[data-id=' + $.getUrlVar('video_id') + ']');
      view = new VodPreviewView({
        data: $(el).data(),
        el: '#video-preview-container'
      });
      return view.render();
    });
    return (scrollToVideoIfRequestedViaParams = function() {
      var hashfragment_array, recording_id, uri_dec, video_id;
      console.log('Skip scrollToVideoIfRequestedViaParams');
      return;
      $.removeCookie('redirect_back_to_after_signup', {
        path: '/'
      });
      video_id = $.getUrlVar('video_id');
      recording_id = $.getUrlVar('recording_id');
      if (video_id) {
        return scrollToVodTile(video_id);
      } else if (recording_id) {
        return scrollToRecordingTile(recording_id);
      } else {
        uri_dec = decodeURIComponent(location.hash);
        hashfragment_array = uri_dec.split('#_');
        if (hashfragment_array[1] === 'Video') {
          history.pushState(null, null, "?video_id=" + hashfragment_array[2]);
          return scrollToVodTile(hashfragment_array[2]);
        } else if (hashfragment_array[1] === 'Recording') {
          history.pushState(null, null, "?recording_id=" + hashfragment_array[2]);
          return scrollToRecordingTile(hashfragment_array[2]);
        }
      }
    })();
  });

  $.extend({
    getUrlVars: function() {
      var hash, hashes, i, vars;
      vars = [];
      hash = void 0;
      hashes = location.search.slice(1).split('&');
      i = 0;
      while (i < hashes.length) {
        hash = hashes[i].split('=');
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
        i++;
      }
      return vars;
    },
    getUrlVar: function(name) {
      return $.getUrlVars()[name];
    }
  });

  scrollToVodTile = function(video_id) {
    var el, view;
    $('[href=#videos]').click();
    el = $('.PlayVideoOnDemand[data-id=' + video_id + ']');
    view = new VodPreviewView({
      data: $(el).data(),
      el: '#video-preview-container'
    });
    view.render();
    return setTimeout((function() {
      return $('html, body').animate({
        scrollTop: el.offset().top.toFixed() - 70
      }, 1000);
    }), 1200);
  };

  scrollToRecordingTile = function(recording_id) {
    var el, view;
    $('[href=#videos]').click();
    el = $('.PlayRecording[data-id=' + recording_id + ']');
    view = new RecordingPreviewView({
      data: $(el).data(),
      el: '#video-preview-container'
    });
    view.render();
    return setTimeout((function() {
      return $('html, body').animate({
        scrollTop: el.offset().top.toFixed() - 70
      }, 1000);
    }), 1200);
  };

  window.VodPreviewView = Backbone.View.extend({
    initialize: function(options) {
      if (options == null) {
        options = {};
      }
      this.data = options.data;
      return this.template = HandlebarsTemplates['application/vod_preview'];
    },
    attachProperBehaviourToSubmitButtion: function() {
      var userIsSignedIn;
      userIsSignedIn = !!Immerss.currentUserId;
      if (this.data['obtainableForAmount'] && this.data['obtainableForAmount'] !== '$0.00') {
        setTimeout((function() {
          $('.VodPurchasePopup').fadeIn();
        }), 60000);
        if (userIsSignedIn) {
          this.$('.rent-as-signed-in').single().show();
          this.$('.rent-video-for-amount-button').single().attr('data-remote', true).attr('href', this.data['obtainUrl']);
          this.$('.vod-purchase-btn').single().attr('data-remote', true).attr('href', this.data['obtainUrl']);
        } else {
          this.$('.login-and-rent').single().show();
        }
        this.$('.RentVideoBTN_wrapp, .rent-to-continue-watching').show();
        this.$('#right_Vod_bar').addClass('for-rent');
      }
      if (!userIsSignedIn) {
        this.$('.rent-video-for-amount-button').single().attr('data-target', '#loginPopup').attr('data-toggle', 'modal');
        return this.$('.vod-purchase-btn').single().attr('data-target', '#loginPopup').attr('data-toggle', 'modal');
      }
    },
    render: function() {
      var templateData;
      templateData = {
        id: this.data['id'],
        url: this.data['url'],
        level: this.data['level'],
        title: this.data['title'],
        duration: this.data['duration'],
        description: this.data['description'],
        posterUrl: this.data['posterUrl'],
        lists: this.data['lists']
      };
      if (this.data['obtainableForAmount']) {
        templateData['obtainableForAmount'] = this.data['obtainableForAmount'];
      }
      this.$el.html(this.template(templateData));
      initializeDateTimes();
      this.attachProperBehaviourToSubmitButtion();
      $('#session-Sessions .thumbnails.activeVideoTile').removeClass('activeVideoTile');
      return $('.VodSection').atLeastOnce().slideDown("slow");
    }
  });

  window.RecordingPreviewView = Backbone.View.extend({
    initialize: function(options) {
      if (options == null) {
        options = {};
      }
      this.data = options.data;
      return this.template = HandlebarsTemplates['application/recording_preview'];
    },
    events: {
      'click .triangle': 'play'
    },
    play: function(e) {
      e.preventDefault();
      return this.getVideoUrl();
    },
    getVideoUrl: function() {
      var $play;
      $play = this.$('a.play');
      $.ajax({
        url: Routes.get_video_recording_path(this.data['id']),
        type: 'POST',
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            _this.$('.triangle').attr('disabled', true).addClass('disabled');
            _this.$('.icon-googleplay').hide();
            _this.$('.spinnerSlider').show();
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            _this.$('iframe').load(function() {
              _this.$('iframe').css('visibility', 'visible');
              return _this.$('.spinnerSlider').hide();
            });
            _this.$('iframe').attr('src', data.video_url + '&start=1');
          };
        })(this),
        error: (function(_this) {
          return function(data) {
            _this.$('.triangle').removeAttr('disabled').removeClass('disabled');
            _this.$('.icon-googleplay').show();
            _this.$('.spinnerSlider').hide();
            $.showFlashMessage('You have no permissions to watch this video.', {
              type: 'error'
            });
          };
        })(this)
      });
    },
    attachProperBehaviourToSubmitButtion: function() {
      var userIsSignedIn;
      userIsSignedIn = !!Immerss.currentUserId;
      if (this.data['obtainableForAmount'] && this.data['obtainableForAmount'] !== '$0.00') {
        $('.VodPurchasePopup').fadeIn();
        if (userIsSignedIn) {
          this.$('.rent-as-signed-in').show();
          this.$('.rent-video-for-amount-button').attr('data-remote', true).attr('href', this.data['obtainUrl']);
          this.$('.vod-purchase-btn').attr('data-remote', true).attr('href', this.data['obtainUrl']);
        } else {
          this.$('.login-and-rent').show();
        }
        this.$('.RentVideoBTN_wrapp, .rent-to-continue-watching').show();
        this.$('#right_Vod_bar').addClass('for-rent');
        this.$('.triangle').hide();
      }
      if (!userIsSignedIn) {
        this.$('.rent-video-for-amount-button').attr('data-target', '#loginPopup').attr('data-toggle', 'modal');
        return this.$('.vod-purchase-btn').attr('data-target', '#loginPopup').attr('data-toggle', 'modal');
      }
    },
    render: function() {
      var templateData;
      templateData = {
        id: this.data['id'],
        url: this.data['url'],
        level: this.data['level'],
        title: this.data['title'],
        duration: this.data['duration'],
        description: this.data['description'],
        thumbnailUrl: this.data['thumbnailUrl'],
        lists: this.data['lists']
      };
      if (this.data['obtainableForAmount']) {
        templateData['obtainableForAmount'] = this.data['obtainableForAmount'];
      }
      this.$el.html(this.template(templateData));
      initializeDateTimes();
      this.attachProperBehaviourToSubmitButtion();
      $('#session-Sessions .thumbnails.activeVideoTile').removeClass('activeVideoTile');
      this.$('.VodSection').slideDown('slow');
      return this.$('a.triangle').click();
    }
  });

}).call(this);
