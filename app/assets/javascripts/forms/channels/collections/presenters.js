(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Collections.Presenters = (function(superClass) {
    extend(Presenters, superClass);

    function Presenters() {
      return Presenters.__super__.constructor.apply(this, arguments);
    }

    Presenters.prototype.model = function(attrs) {
      return new Forms.Channels.Models.Presenter(attrs);
    };

    Presenters.prototype.changed = function() {
      return this.filter(function(model) {
        return model.isNew() || model.hasChanged();
      });
    };

    Presenters.prototype.withoutOwner = function() {
      return this.filter(function(model) {
        return model.id !== Forms.Channels.Cache.current_user.id && !model.get('_destroy');
      });
    };

    Presenters.prototype.toFormDataSet = function() {
      var data;
      data = [];
      _(this.changed()).each(function(item, i) {
        if (item.id) {
          data.push(["presenters[" + i + "][id]", item.id]);
        }
        if (item.get('user_id')) {
          data.push(["presenters[" + i + "][user_id]", item.get('user_id')]);
        }
        if (item.get('type')) {
          data.push(["presenters[" + i + "][type]", item.get('type')]);
        }
        if (item.get('email')) {
          data.push(["presenters[" + i + "][email]", item.get('email')]);
        }
        if (item.get('_destroy')) {
          return data.push(["presenters[" + i + "][_destroy]", item.get('_destroy')]);
        }
      });
      return data;
    };

    return Presenters;

  })(Forms.Collection);

}).call(this);
