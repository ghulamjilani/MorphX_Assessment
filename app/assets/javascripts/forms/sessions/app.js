//= require_self

//= require_tree ./views

(function() {
  this.Forms.Sessions = {
    Cache: {},
    Models: {},
    Collections: {},
    Views: {},
    new_form: function() {}
  };

  _.extend(Forms.Sessions, Backbone.Events);

}).call(this);
