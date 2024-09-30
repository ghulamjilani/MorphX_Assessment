(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Profiles.Views.Cover = (function(superClass) {
    extend(Cover, superClass);

    function Cover() {
      return Cover.__super__.constructor.apply(this, arguments);
    }

    Cover.prototype.el = '#publicCoverModal';

    Cover.prototype.cropper_params = {
      aspectRatio: 4 / 1
    };

    Cover.prototype.initialize = function() {
      this.model = new Forms.Profiles.Models.Cover;
      return Cover.__super__.initialize.apply(this, arguments);
    };

    Cover.prototype.render = function() {
      return this.listenTo(this.model, 'crop:done', this.updatePreview);
    };

    Cover.prototype.autosave = function() {
      return this.model.saveToUser();
    };

    Cover.prototype.updatePreview = function() {
      return $(".CoverImage-demo").css('background-image', "url('" + (this.model.get('img_src')) + "')");
    };

    return Cover;

  })(Forms.ImageUploaderModal);

}).call(this);
