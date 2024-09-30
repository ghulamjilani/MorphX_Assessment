(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.ChannelCoverModal = (function(superClass) {
    extend(ChannelCoverModal, superClass);

    function ChannelCoverModal() {
      return ChannelCoverModal.__super__.constructor.apply(this, arguments);
    }

    ChannelCoverModal.prototype.el = "#chanelCoverModal";

    ChannelCoverModal.prototype.cropper_params = {
      aspectRatio: 7 / 3
    };

    ChannelCoverModal.prototype.initialize = function() {
      this.channel = Forms.Channels.Cache.channel;
      this.$container = this.$('.crop-container');
      this.listenTo(this.model, 'invalid', this.showUploader);
      this.listenTo(this.model, 'image:loaded', this.showCropper);
      this.listenTo(this.model, 'crop:done', this.dispose);
      return this.render();
    };

    return ChannelCoverModal;

  })(Forms.ImageUploaderModal);

}).call(this);
