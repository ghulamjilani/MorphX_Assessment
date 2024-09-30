(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.UploadedImage = (function(superClass) {
    extend(UploadedImage, superClass);

    function UploadedImage() {
      return UploadedImage.__super__.constructor.apply(this, arguments);
    }

    UploadedImage.prototype.initialize = function() {
      _(this).extend($.Deferred());
      this.on('invalid', this.showErrors);
      this.on('invalid', this.clearFile);
      return this.on('file:uploaded', this.parseData);
    };

    UploadedImage.prototype.validate = function(attrs) {
      if (/\.(jpg|jpeg|png|bmp)+$/i.test(attrs.file.name)) {
        return "This format is not supported. Please use one of the following: jpg, jpeg, png, bmp";
      }
      if (attrs.file && attrs.file.size > 10485760) {
        return "File " + attrs.file.name + " is too large. Maximum allowed file size is 10 megabytes (10485760 bytes).";
      }
    };

    UploadedImage.prototype.parseData = function(file) {
      return _.defer((function(_this) {
        return function() {
          var reader;
          if (_this.isValid()) {
            file = _this.get("file");
            reader = new FileReader;
            reader.onload = function(e) {
              var img;
              img = new Image;
              img.onload = function() {
                _this.set({
                  "base64_img": img.src,
                  img: img
                });
                if (_this.isValid()) {
                  return _this.trigger('image:loaded', _this);
                }
              };
              return img.src = e.target.result;
            };
            return reader.readAsDataURL(file);
          }
        };
      })(this));
    };

    UploadedImage.prototype.showErrors = function() {
      return $.showFlashMessage(this.validationError, {
        type: "error"
      });
    };

    UploadedImage.prototype.crop = function(cropData, croppedCanvas) {
      this.set({
        x: cropData.x.toString(),
        y: cropData.y.toString(),
        width: cropData.width.toString(),
        height: cropData.height.toString(),
        rotate: cropData.rotate.toString(),
        img_src: croppedCanvas.toDataURL(),
        image: this.get('file'),
        saved: false
      });
      this.clearFile();
      return this.trigger('crop:done', this);
    };

    UploadedImage.prototype.clearFile = function() {
      this.unset('file', {
        silent: true
      });
      this.unset('img', {
        silent: true
      });
      return this.unset('base64_img', {
        silent: true
      });
    };

    UploadedImage.prototype.resetAttributes = function() {
      return this.set(this.previousAttributes());
    };

    UploadedImage.prototype.toJSON = function() {
      return {
        id: this.id,
        cid: this.cid,
        img_src: this.get('img_src'),
        description: this.get('description') || ""
      };
    };

    UploadedImage.prototype.autosaveStart = function() {
      this.set({
        on_save: true
      });
      return this.trigger('autosave:start', this);
    };

    UploadedImage.prototype.autosaveStop = function() {
      this.set({
        on_save: false
      });
      return this.trigger('autosave:end', this);
    };

    UploadedImage.prototype.markAsChanged = function() {
      return this.set({
        saved: false
      });
    };

    UploadedImage.prototype.markAsSaved = function() {
      return this.set({
        saved: true
      });
    };

    UploadedImage.prototype.getFormData = function() {
      var formData;
      formData = new FormData;
      _(this.toFormData()).each(function(data) {
        return formData.append.apply(formData, data);
      });
      return formData;
    };

    return UploadedImage;

  })(Forms.Model);

  _.extend(Forms.UploadedImage, Forms.Mixins);

}).call(this);
