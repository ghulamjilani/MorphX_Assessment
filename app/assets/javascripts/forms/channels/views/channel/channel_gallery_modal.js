(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.ChannelGalleryModal = (function(superClass) {
    extend(ChannelGalleryModal, superClass);

    function ChannelGalleryModal() {
      return ChannelGalleryModal.__super__.constructor.apply(this, arguments);
    }

    ChannelGalleryModal.prototype.el = "#channelGalleryModal";

    ChannelGalleryModal.prototype.events = {
      "change input.inputfile": 'setImage',
      "drop .upload-info": 'setImage',
      "dragover .upload-info": function(e) {
        return e.preventDefault();
      },
      "click .clear": "сancelCropping",
      "click .save": "cropImage",
      "click #addImageByUrlTab button.mainButton": "addFromUrl",
      "keypress input#AddImageByUrl": "addFromUrl",
      "click button.gallery-save": "hide"
    };

    ChannelGalleryModal.prototype.initialize = function() {
      this.$container = this.$('.crop-container');
      this.channel = Forms.Channels.Cache.channel;
      this.model = {};
      this.tilesByCid = {};
      this.listenTo(this.collection, 'invalid', this.showUploader);
      this.listenTo(this.collection, 'image:loaded', this.showCropper);
      this.listenTo(this.collection, 'crop:done', this.hideCropper);
      this.listenTo(this.collection, 'fetch:success', this.renderPreviewTile);
      this.listenTo(this.collection, 'fetch:start', this.disableAddButton);
      this.listenTo(this.collection, 'fetch:success', this.enableAddButton);
      this.listenTo(this.collection, 'fetch:error', this.enableAddButton);
      this.listenTo(this.collection, 'link:saved', this.renderPreviewTile);
      this.listenTo(this.collection, 'crop:done', this.renderPreviewTile);
      this.listenTo(this.collection, 'remove', this.removePreviewTile);
      return this.render();
    };

    ChannelGalleryModal.prototype.render = function() {
      this.$el.find('input[type=text]').on('focusout', function() {
        return Forms.Helpers.formatInput(this);
      });
      return this.$el.on('hidden.bs.modal', (function(_this) {
        return function() {
          return _this.$el.find('.Gallery-list').html('');
        };
      })(this));
    };

    ChannelGalleryModal.prototype.setImage = function(e) {
      var files;
      e.preventDefault();
      this.showLoader();
      files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
      if (files && files[0]) {
        this.model = new Forms.Channels.Models.ChannelImage({
          file: files[0],
          type: 'image',
          collection: this.collection
        });
        if (this.model.isValid()) {
          this.collection.add(this.model);
          this.model.trigger('file:uploaded');
        } else {
          console.log("invalid image");
          this.showUploader();
        }
      } else {
        this.showUploader();
      }
      return this.clearFileInput();
    };

    ChannelGalleryModal.prototype.сancelCropping = function(e) {
      e.preventDefault();
      this.collection.remove(this.model);
      this.showUploader();
      return this.$container.html('');
    };

    ChannelGalleryModal.prototype.addFromUrl = function(e) {
      var url;
      if (e.type === 'keypress' && e.keyCode !== 13) {
        return;
      }
      e.preventDefault();
      url = this.$el.find("input#AddImageByUrl").val();
      this.collection.add({
        type: "link",
        url: url
      }, {
        validate: true
      });
      this.$el.find("input#AddImageByUrl").val('');
      return this.$el.find("#addImageByUrlTab .input-block").removeClass('event-focus');
    };

    ChannelGalleryModal.prototype.disableAddButton = function() {
      return this.$el.find("#addImageByUrlTab button.mainButton").text('Wait').attr('disabled', 'disabled');
    };

    ChannelGalleryModal.prototype.enableAddButton = function() {
      return this.$el.find("#addImageByUrlTab button.mainButton").text('Add').removeAttr('disabled');
    };

    ChannelGalleryModal.prototype.renderPreviewTile = function(item) {
      if (!this.tilesByCid[item.cid]) {
        this.tilesByCid[item.cid] = new Forms.Channels.Views.GalleryItemTileView({
          model: item,
          region: this.$el.find('.Gallery-list:visible')
        });
        return this.tilesByCid[item.cid].render();
      }
    };

    ChannelGalleryModal.prototype.removePreviewTile = function(item) {
      var view;
      view = this.tilesByCid[item.cid];
      if (view) {
        view.dispose();
        return delete this.tilesByCid[item.cid];
      }
    };

    return ChannelGalleryModal;

  })(Forms.ImageUploaderModal);

}).call(this);
