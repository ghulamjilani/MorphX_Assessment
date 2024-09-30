(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.UserLogoView = (function(superClass) {
    extend(UserLogoView, superClass);

    function UserLogoView() {
      return UserLogoView.__super__.constructor.apply(this, arguments);
    }

    UserLogoView.prototype.el = '#userLogoModal';

    UserLogoView.prototype.cropper_params = {
      aspectRatio: 1 / 1
    };

    UserLogoView.prototype.render = function() {
      this.listenTo(this.model, 'change:logo', this.updateLogo);
      return this.$el.on('hidden.bs.modal', function() {
        return $('#userAccountModal').modal('show');
      });
    };

    UserLogoView.prototype.autosave = function() {
      return this.model.saveToUser();
    };

    UserLogoView.prototype.updateLogo = function() {
      return $(".User-listImage.you, #profile-pic").css('background-image', "url('" + (this.model.get('logo')) + "')");
    };

    return UserLogoView;

  })(Forms.ImageUploaderModal);

}).call(this);
