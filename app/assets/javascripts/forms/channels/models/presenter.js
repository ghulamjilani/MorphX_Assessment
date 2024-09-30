(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Models.Presenter = (function(superClass) {
    extend(Presenter, superClass);

    function Presenter() {
      return Presenter.__super__.constructor.apply(this, arguments);
    }

    Presenter.prototype.defaults = {
      logo: Immerss.defaultUserLogo
    };

    Presenter.prototype.toParams = function() {
      return $.param(this.toJSON());
    };

    return Presenter;

  })(Forms.Model);

}).call(this);
