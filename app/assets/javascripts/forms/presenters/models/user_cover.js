(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Presenters.Models.UserCover = (function(superClass) {
    extend(UserCover, superClass);

    function UserCover() {
      return UserCover.__super__.constructor.apply(this, arguments);
    }

    UserCover.prototype.validate = function(attrs) {
      UserCover.__super__.validate.apply(this, arguments);
      if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
        return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
      if (attrs.img && (attrs.img.width < 600 || attrs.img.height < 300)) {
        return "Cover should be at least 600x300px (recommended 1400x600px)";
      }
    };

    UserCover.prototype.toFormData = function() {
      var data;
      if (this.get("saved") || !this.get("image")) {
        return [];
      }
      data = [];
      if (this.get("image")) {
        data.push(["user_account[original_bg_image]", this.get("image")]);
      }
      if (this.get("x")) {
        data.push(["user_account[crop_x]", this.get("x")]);
      }
      if (this.get("y")) {
        data.push(["user_account[crop_y]", this.get("y")]);
      }
      if (this.get("width")) {
        data.push(["user_account[crop_w]", this.get("width")]);
      }
      if (this.get("height")) {
        data.push(["user_account[crop_h]", this.get("height")]);
      }
      if (this.get("rotate")) {
        data.push(["user_account[rotate]", this.get("rotate")]);
      }
      return data;
    };

    UserCover.prototype.saveToUser = function() {
      return $.ajax({
        url: Routes.save_cover_profile_path(),
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
            _this.set(data, {
              silent: true
            });
            return _this.markAsSaved();
          };
        })(this),
        error: (function(_this) {
          return function(data, error) {
            _this.set(_this.previousAttributes());
            _this.markAsChanged();
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

    return UserCover;

  })(Forms.UploadedImage);

}).call(this);
