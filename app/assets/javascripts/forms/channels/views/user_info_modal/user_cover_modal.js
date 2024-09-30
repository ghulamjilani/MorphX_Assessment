(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.UserCoverView = (function(superClass) {
    extend(UserCoverView, superClass);

    function UserCoverView() {
      return UserCoverView.__super__.constructor.apply(this, arguments);
    }

    UserCoverView.prototype.el = '#userCoverModal';

    UserCoverView.prototype.cropper_params = {
      aspectRatio: 7 / 3
    };

    UserCoverView.prototype.render = function() {
      return this.$el.on('hidden.bs.modal', function() {
        return $('#userAccountModal').modal('show');
      });
    };

    UserCoverView.prototype.autosave = function() {
      return this.model.saveToUser();
    };

    return UserCoverView;

  })(Forms.ImageUploaderModal);

}).call(this);
