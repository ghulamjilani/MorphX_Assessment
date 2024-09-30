(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.ImageUploaderModal = (function(superClass) {
    extend(ImageUploaderModal, superClass);

    function ImageUploaderModal() {
      return ImageUploaderModal.__super__.constructor.apply(this, arguments);
    }

    ImageUploaderModal.prototype.template = HandlebarsTemplates['forms/shared/image_cropper'];

    ImageUploaderModal.prototype.cropper_params = {};

    ImageUploaderModal.prototype.events = {
      "change input.inputfile": 'setImage',
      "drop .upload-info": 'setImage',
      "dragover .upload-info": function(e) {
        return e.preventDefault();
      },
      "click .clear": 'сancelCropping',
      "click .save": 'cropImage'
    };

    ImageUploaderModal.prototype.initialize = function() {
      this.$container = this.$('.crop-container');
      this.listenTo(this.model, 'invalid', this.showUploader);
      this.listenTo(this.model, 'image:loaded', this.showCropper);
      this.listenTo(this.model, 'crop:done', this.dispose);
      this.listenTo(this.model, 'crop:done', this.autosave);
      return this.render();
    };

    ImageUploaderModal.prototype.show = function() {
      return this.$el.modal('show');
    };

    ImageUploaderModal.prototype.hide = function() {
      return this.$el.modal('hide');
    };

    ImageUploaderModal.prototype.setImage = function(e) {
      var files;
      e.preventDefault();
      this.showLoader();
      files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
      if (files && files[0]) {
        this.model.set({
          file: files[0]
        });
        if (this.model.isValid()) {
          this.model.trigger('file:uploaded', this.model);
        }
      } else {
        this.showUploader();
      }
      return this.clearFileInput();
    };

    ImageUploaderModal.prototype.showCropper = function() {
      this.$container.html(this.template(this.getTemplateData()));
      this.$container.show('fast');
      this.hideUploader();
      return initCrop(this.cropper_params);
    };

    ImageUploaderModal.prototype.hideCropper = function() {
      this.$container.html('');
      return this.showUploader();
    };

    ImageUploaderModal.prototype.getTemplateData = function() {
      return {
        cid: this.model.cid,
        base64_img: this.model.get('base64_img')
      };
    };

    ImageUploaderModal.prototype.showLoader = function() {
      this.$(".upload-info span").hide('fast');
      this.$(".upload-area .row").show('fast');
      return this.$('.LoadingCover').removeClass('hidden');
    };

    ImageUploaderModal.prototype.hideUploader = function() {
      return this.$(".upload-area .row").hide('fast');
    };

    ImageUploaderModal.prototype.showUploader = function() {
      this.$(".upload-area .row, .upload-info span").show('fast');
      this.$(".upload-info span").show('fast');
      return this.$('.LoadingCover').addClass('hidden');
    };

    ImageUploaderModal.prototype.cropImage = function(e) {
      var cropData, croppedCanvas;
      e.preventDefault();
      this.showLoader();
      cropData = this.$container.find('#crop-img').cropper('getData');
      croppedCanvas = this.$container.find('#crop-img').cropper('getCroppedCanvas');
      this.$container.html('');
      return this.model.crop(cropData, croppedCanvas);
    };

    ImageUploaderModal.prototype.сancelCropping = function(e) {
      e.preventDefault();
      this.showUploader();
      this.$container.html('');
      return this.model.clearFile();
    };

    ImageUploaderModal.prototype.clearFileInput = function() {
      this.$('input.inputfile').wrap('<form>').closest('form').get(0).reset();
      return this.$('input.inputfile').unwrap();
    };

    ImageUploaderModal.prototype.dispose = function() {
      this.hide();
      this.showUploader();
      return this.$container.html('');
    };

    ImageUploaderModal.prototype.autosave = function() {
      return console.log('Not implemented!');
    };

    return ImageUploaderModal;

  })(Forms.View);

  _.extend(Forms.ImageUploaderModal, Forms.Mixins);

}).call(this);
