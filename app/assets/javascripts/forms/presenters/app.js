//= require_self

//= require_tree ./models
//= require_tree ./views
(function() {
  this.Forms.Presenters = {
    Cache: {
      progress: 0
    },
    Models: {},
    Collections: {},
    Views: {},
    start: function() {
      this.current_user = new this.Models.User(Immerss.user);
      return this.presenter_info = new this.Views.Complete();
    }
  };

  _.extend(Forms.Presenters, Backbone.Events);

}).call(this);
