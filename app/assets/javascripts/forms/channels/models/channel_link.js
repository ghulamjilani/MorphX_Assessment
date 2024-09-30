(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.ChannelLink = (function(superClass) {
    extend(ChannelLink, superClass);

    function ChannelLink() {
      return ChannelLink.__super__.constructor.apply(this, arguments);
    }

    ChannelLink.prototype.defaults = {
      type: 'link'
    };

    ChannelLink.prototype.initialize = function() {
      this.disposed = false;
      this.channel = Forms.Channels.Cache.channel;
      if (this.isNew() && (this.validationError == null)) {
        this.fetchLink();
      }
      this.on('invalid', this.showErrors);
      return this.on('invalid', this.destroy);
    };

    ChannelLink.prototype.validate = function(attrs) {
      if ($.trim(attrs.url) === "") {
        return "Url of supporting material must be present.";
      }
      if (!/^(https?|s?ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(attrs.url)) {
        return "You must provide a valid url.";
      }
      if (this.collection.where({
        type: "link"
      }).length > Immerss.maxLinksSize) {
        return "Link " + attrs.url + " will not be added - maximum " + Immerss.maxLinksSize + " links are allowed";
      }
      if (this.collection.where({
        type: "link",
        url: attrs.url
      }).length > 0) {
        return "Link with " + attrs.url + " is already in the list";
      }
    };

    ChannelLink.prototype.fetchLink = function() {
      return $.ajax({
        url: Routes.channel_links_path(),
        data: "channel_link[url]=" + (this.get('url')),
        type: 'POST',
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            return _this.collection.trigger('fetch:start', _this);
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            _this.set(data, {
              silent: true
            });
            return _this.collection.trigger('fetch:success', _this);
          };
        })(this),
        error: (function(_this) {
          return function(data, error) {
            _this.collection.trigger('fetch:error', _this);
            _this.collection.remove(_this);
            return $.showFlashMessage(data.responseJSON.error || data.responseText, {
              type: "error"
            });
          };
        })(this)
      });
    };

    ChannelLink.prototype.destroy = function() {
      if (this.isNew()) {
        return this.collection.remove(this);
      } else {
        return this.set({
          '_destroy': true
        });
      }
    };

    ChannelLink.prototype.showErrors = function() {
      return $.showFlashMessage(this.validationError, {
        type: "error"
      });
    };

    return ChannelLink;

  })(Forms.Model);

}).call(this);
