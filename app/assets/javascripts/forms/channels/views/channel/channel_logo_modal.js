(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.ChannelLogoModal = (function(superClass) {
    extend(ChannelLogoModal, superClass);

    function ChannelLogoModal() {
      return ChannelLogoModal.__super__.constructor.apply(this, arguments);
    }

    ChannelLogoModal.prototype.el = "#channel_avatar_modal";

    ChannelLogoModal.prototype.cropper_params = {
      aspectRatio: 1 / 1
    };

    ChannelLogoModal.prototype.initialize = function() {
      this.channel = Forms.Channels.Cache.channel;
      this.$container = this.$('.crop-container');
      this.listenTo(this.model, 'invalid', this.showUploader);
      this.listenTo(this.model, 'image:loaded', this.showCropper);
      this.listenTo(this.model, 'crop:done', this.dispose);
      return this.render();
    };

    return ChannelLogoModal;

  })(Forms.ImageUploaderModal);

}).call(this);
