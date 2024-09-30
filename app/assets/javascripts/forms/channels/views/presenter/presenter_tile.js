(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.PresenterTileView = (function(superClass) {
    extend(PresenterTileView, superClass);

    function PresenterTileView() {
      return PresenterTileView.__super__.constructor.apply(this, arguments);
    }

    PresenterTileView.prototype.region = '#networkPresenters';

    PresenterTileView.prototype.className = 'tile';

    PresenterTileView.prototype.template = HandlebarsTemplates['forms/channels/presenter_item'];

    PresenterTileView.prototype.events = {
      "click .remove_user_item": "removePresenter"
    };

    PresenterTileView.prototype.initialize = function() {
      this.$region = $(this.region);
      return this.render();
    };

    PresenterTileView.prototype.render = function() {
      this.$el.html(this.template(this.model.toJSON()));
      return this.$el.insertBefore(this.$region.find('.tile.add'));
    };

    PresenterTileView.prototype.removePresenter = function(e) {
      e.preventDefault();
      this.$el.remove();
      return this.model.set({
        '_destroy': true
      });
    };

    return PresenterTileView;

  })(Forms.View);

}).call(this);
