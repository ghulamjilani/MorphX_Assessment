(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.GalleryItemTileView = (function(superClass) {
    extend(GalleryItemTileView, superClass);

    function GalleryItemTileView() {
      return GalleryItemTileView.__super__.constructor.apply(this, arguments);
    }

    GalleryItemTileView.prototype.className = 'tile';

    GalleryItemTileView.prototype.template = HandlebarsTemplates['forms/shared/gallery_item'];

    GalleryItemTileView.prototype.events = {
      "change .description": "updateDescription",
      "click .remove_gallery_item": "removeItem"
    };

    GalleryItemTileView.prototype.initialize = function(options) {
      this.disposed = false;
      this.$region = $(options.region);
      return this.listenTo(this.model, 'change:description', this.updateDescriptionInput);
    };

    GalleryItemTileView.prototype.render = function() {
      this.$el.html(this.template(this.model.toJSON()));
      if (this.$region.find('.add_block').length) {
        this.$el.insertBefore(this.$region.find('.add_block'));
      } else {
        this.$region.append(this.$el);
      }
      this.$el.show('fast');
      if (!this.model.get('img_src')) {
        return this.showLoader();
      }
    };

    GalleryItemTileView.prototype.updateDescriptionInput = function() {
      return this.$el.find('.description').val(this.model.get('description'));
    };

    GalleryItemTileView.prototype.updateDescription = function(event) {
      return this.model.set({
        description: $(event.target).val(),
        saved: false
      });
    };

    GalleryItemTileView.prototype.removeItem = function(e) {
      e.preventDefault();
      this.$el.hide('fast');
      return this.model.set({
        '_destroy': 1
      });
    };

    GalleryItemTileView.prototype.dispose = function() {
      var i, len, prop, properties;
      if (this.disposed) {
        return;
      }
      this.$el.hide('fast').remove();
      properties = ['el', '$el', 'model', 'template'];
      for (i = 0, len = properties.length; i < len; i++) {
        prop = properties[i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return GalleryItemTileView;

  })(Forms.View);

}).call(this);
