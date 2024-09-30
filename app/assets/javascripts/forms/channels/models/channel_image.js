(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.ChannelImage = (function(superClass) {
    extend(ChannelImage, superClass);

    function ChannelImage() {
      return ChannelImage.__super__.constructor.apply(this, arguments);
    }

    ChannelImage.prototype.url = Routes.save_channel_gallery_image_become_presenter_steps_path();

    ChannelImage.prototype.defaults = {
      type: 'image'
    };

    ChannelImage.prototype.initialize = function(options) {
      this.collection = options.collection;
      return Forms.Channels.Models.ChannelImage.__super__.initialize.call(this);
    };

    ChannelImage.prototype.validate = function(attrs) {
      ChannelImage.__super__.validate.apply(this, arguments);
      if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
        return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
      if (attrs.img && (attrs.img.width < 300 || attrs.img.height < 150)) {
        return "Gallery image should be at least 300x150px (recommended 1400x600px)";
      }
      if (this.collection.where({type: "image"}).length > Immerss.maxImagesSize) {
        return "Image " + attrs.file.name + " will not be added - maximum " + Immerss.maxImagesSize + " images are allowed";
      }
    };

    ChannelImage.prototype.destroy = function() {
      if (this.isNew()) {
        return this.collection.remove(this);
      } else {
        return this.set({
          '_destroy': true
        });
      }
    };

    return ChannelImage;

  })(Forms.UploadedImage);

}).call(this);
