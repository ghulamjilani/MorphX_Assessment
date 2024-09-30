(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Collections.ChannelGallery = (function(superClass) {
    extend(ChannelGallery, superClass);

    function ChannelGallery() {
      return ChannelGallery.__super__.constructor.apply(this, arguments);
    }

    ChannelGallery.prototype.model = function(attrs, options) {
      if (attrs.type === 'link') {
        return new Forms.Channels.Models.ChannelLink(attrs, options);
      } else {
        return new Forms.Channels.Models.ChannelImage(attrs, options);
      }
    };

    ChannelGallery.prototype.changed = function() {
      return this.filter(function(model) {
        return model.isNew() || model.hasChanged();
      });
    };

    ChannelGallery.prototype.toFormData = function() {
      var data;
      if (this.models.length === 0) {
        return [];
      }
      data = [];
      _(this.changed()).each(function(item, i) {
        if (item.isNew()) {
          if ((item.get('type') === 'image' && !item.get("image")) || (item.get('type') === 'link' && !item.get("url"))) {
            return;
          }
          if (item.get('type') === 'image') {
            if (item.get("image")) {
              data.push(["channel[images_attributes][" + i + "][image]", item.get("image")]);
            }
            if (item.get("x")) {
              data.push(["channel[images_attributes][" + i + "][crop_x]", item.get("x")]);
            }
            if (item.get("y")) {
              data.push(["channel[images_attributes][" + i + "][crop_y]", item.get("y")]);
            }
            if (item.get("width")) {
              data.push(["channel[images_attributes][" + i + "][crop_w]", item.get("width")]);
            }
            if (item.get("height")) {
              data.push(["channel[images_attributes][" + i + "][crop_h]", item.get("height")]);
            }
            if (item.get("rotate")) {
              return data.push(["channel[images_attributes][" + i + "][rotate]", item.get("rotate")]);
            }
          } else {
            if (item.get("url")) {
              data.push(["channel[channel_links_attributes][" + i + "][url]", item.get("url")]);
            }
            return data.push(["channel[channel_links_attributes][" + i + "][description]", item.get("description") || ""]);
          }
        } else {
          if (item.get('type') === 'image') {
            data.push(["channel[images_attributes][" + i + "][id]", item.id]);
            if (item.hasChanged('description')) {
              data.push(["channel[images_attributes][" + i + "][description]", item.get("description")]);
            }
            if (item.get("_destroy")) {
              return data.push(["channel[images_attributes][" + i + "][_destroy]", item.get("_destroy")]);
            }
          } else {
            data.push(["channel[channel_links_attributes][" + i + "][id]", item.id]);
            if (item.hasChanged('description')) {
              data.push(["channel[channel_links_attributes][" + i + "][description]", item.get("description")]);
            }
            if (item.get("_destroy")) {
              return data.push(["channel[channel_links_attributes][" + i + "][_destroy]", item.get("_destroy")]);
            }
          }
        }
      });
      return data;
    };

    return ChannelGallery;

  })(Forms.Collection);

}).call(this);
