(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.UserImage = (function(superClass) {
    extend(UserImage, superClass);

    function UserImage() {
      return UserImage.__super__.constructor.apply(this, arguments);
    }

    UserImage.prototype.validate = function(attrs) {
      UserImage.__super__.validate.apply(this, arguments);
      if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
        return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
      if (attrs.img && (attrs.img.width < 280 || attrs.img.height < 280)) {
        return "Avatar should be at least 280x280 px";
      }
    };

    UserImage.prototype.saveToUser = function() {
      return $.ajax({
        url: Routes.save_logo_profile_path(),
        data: this.getFormData(),
        type: 'POST',
        processData: false,
        contentType: false,
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            return _this.autosaveStart();
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            _this.set(data);
            return _this.markAsSaved();
          };
        })(this),
        error: (function(_this) {
          return function(data, error) {
            _this.set(_this.previous('logo'));
            _this.markAsChanged();
            _this.trigger('logo:failed');
            return $.showFlashMessage(data.responseText || data.statusText, {
              type: "error"
            });
          };
        })(this),
        complete: (function(_this) {
          return function() {
            return _this.autosaveStop();
          };
        })(this)
      });
    };

    UserImage.prototype.toFormData = function() {
      var data;
      if (this.get("saved") || !this.get("image")) {
        return [];
      }
      data = [];
      if (this.get("image")) {
        data.push(["user_account[logo][original_image]", this.get("image")]);
      }
      if (this.get("x")) {
        data.push(["user_account[logo][crop_x]", this.get("x")]);
      }
      if (this.get("y")) {
        data.push(["user_account[logo][crop_y]", this.get("y")]);
      }
      if (this.get("width")) {
        data.push(["user_account[logo][crop_w]", this.get("width")]);
      }
      if (this.get("height")) {
        data.push(["user_account[logo][crop_h]", this.get("height")]);
      }
      if (this.get("rotate")) {
        data.push(["user_account[logo][rotate]", this.get("rotate")]);
      }
      return data;
    };

    return UserImage;

  })(Forms.UploadedImage);

}).call(this);
