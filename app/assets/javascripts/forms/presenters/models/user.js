(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Presenters.Models.User = (function(superClass) {
    extend(User, superClass);

    function User() {
      return User.__super__.constructor.apply(this, arguments);
    }

    User.prototype.defaults = {
      logo: Immerss.defaultUserLogo
    };

    User.prototype.initialize = function(params) {
      if (params.type !== 'email' || params.type !== 'search') {
        this.logo = new Forms.Presenters.Models.UserImage();
        return this.cover = new Forms.Presenters.Models.UserCover();
      }
    };

    User.prototype.toParams = function() {
      return $.param(this.toJSON());
    };

    return User;

  })(Forms.Model);

}).call(this);
