(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.Channel = (function(superClass) {
    extend(Channel, superClass);

    function Channel() {
      return Channel.__super__.constructor.apply(this, arguments);
    }

    Channel.prototype.initialize = function(options) {
      this.cover = new Forms.Channels.Models.ChannelCover(this.get('cover'));
      this.logo = new Forms.Channels.Models.ChannelLogo(this.get('logo'));
      return this.gallery = new Forms.Channels.Collections.ChannelGallery(this.get('gallery'));
    };

    Channel.prototype.validate = function(attrs) {
      if (!this.cover.readyToSave()) {
        return "Channel should have cover image.";
      }
    };

    Channel.prototype.showErrors = function() {
      return $.showFlashMessage(this.validationError, {
        type: "error"
      });
    };

    return Channel;

  })(Forms.Model);

}).call(this);
