//= require_self
//= require_tree ./collections
//= require_tree ./models
//= require_tree ./views/

(function() {
  this.Forms.Channels = {
    Cache: {},
    Models: {},
    Collections: {},
    Views: {},
    "new": function() {
      this.Cache.channel = new this.Models.Channel();
      this.Cache.current_user = new this.Models.Presenter(Immerss.currentUser);
      this.Cache.presenters = new this.Collections.Presenters;
      this.Cache.presenters.add(this.Cache.current_user);
      return new this.Views.ChannelForm({
        model: this.Cache.channel,
        presenters: this.Cache.presenters,
        url: Immerss.createPath,
        action: 'new'
      });
    },
    edit: function() {
      this.Cache.channel = new this.Models.Channel(Immerss.channel);
      this.Cache.current_user = new this.Models.Presenter(Immerss.currentUser);
      this.Cache.presenters = new this.Collections.Presenters;
      this.Cache.presenters.add(this.Cache.current_user);
      this.Cache.presenters.add(Immerss.presenters);
      return new this.Views.ChannelForm({
        model: this.Cache.channel,
        presenters: this.Cache.presenters,
        url: Immerss.updatePath,
        action: 'edit'
      });
    }
  };

  _.extend(Forms.Channels, Backbone.Events);

}).call(this);
