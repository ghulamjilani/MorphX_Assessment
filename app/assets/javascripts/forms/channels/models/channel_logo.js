(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.ChannelLogo = (function(superClass) {
    extend(ChannelLogo, superClass);

    function ChannelLogo() {
      return ChannelLogo.__super__.constructor.apply(this, arguments);
    }

    ChannelLogo.prototype.validate = function(attrs) {
      ChannelLogo.__super__.validate.apply(this, arguments);
      if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
        return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
      if (attrs.img && (attrs.img.width < 100 || attrs.img.height < 100)) {
        return "Logo should be at least 100x100px";
      }
    };

    ChannelLogo.prototype.readyToSave = function() {
      return this.id || this.get('image');
    };

    ChannelLogo.prototype.toFormData = function() {
      var data;
      if (!this.get("image")) {
        return [];
      }
      data = [];
      data.push(["channel[logo_attributes][original]", this.get("image")]);
      data.push(["channel[logo_attributes][crop_x]", this.get("x")]);
      data.push(["channel[logo_attributes][crop_y]", this.get("y")]);
      data.push(["channel[logo_attributes][crop_w]", this.get("width")]);
      data.push(["channel[logo_attributes][crop_h]", this.get("height")]);
      data.push(["channel[logo_attributes][rotate]", this.get("rotate")]);
      return data;
    };

    return ChannelLogo;

  })(Forms.UploadedImage);

}).call(this);
