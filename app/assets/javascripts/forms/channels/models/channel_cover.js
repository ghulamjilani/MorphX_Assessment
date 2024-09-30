(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.ChannelCover = (function(superClass) {
    extend(ChannelCover, superClass);

    function ChannelCover() {
      return ChannelCover.__super__.constructor.apply(this, arguments);
    }

    ChannelCover.prototype.validate = function(attrs) {
      ChannelCover.__super__.validate.apply(this, arguments);
      if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
        return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
      if (attrs.img && (attrs.img.width < 415 || attrs.img.height < 115)) {
        return "Cover should be at least 415x115 px";
      }
    };

    ChannelCover.prototype.readyToSave = function() {
      return this.id || this.get('image');
    };

    ChannelCover.prototype.toFormData = function() {
      var data;
      if (!this.get("image")) {
        return [];
      }
      data = [];
      data.push(["channel[cover_attributes][image]", this.get("image")]);
      data.push(["channel[cover_attributes][crop_x]", this.get("x")]);
      data.push(["channel[cover_attributes][crop_y]", this.get("y")]);
      data.push(["channel[cover_attributes][crop_w]", this.get("width")]);
      data.push(["channel[cover_attributes][crop_h]", this.get("height")]);
      data.push(["channel[cover_attributes][rotate]", this.get("rotate")]);
      data.push(["channel[cover_attributes][is_main]", true]);
      return data;
    };

    return ChannelCover;

  })(Forms.UploadedImage);

}).call(this);
