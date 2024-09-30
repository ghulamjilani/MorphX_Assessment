(function() {
  window.FollowersCollection = Backbone.Collection.extend({});

  window.UsersShowFollowersView = Backbone.View.extend({
    events: {
      "click .see-all": "seeAll"
    },
    templateSource: "<div>\n  <h3>\n    Followers\n    <span class=\"followersCount\"> [%= counter %] </span>\n    <a class=\"pull-right see-all ensure-link-style\">See all</a>\n  </h3>\n</div>\n[% if (followers.length > 0) { %]\n  <ul>\n    [% _.each(followers, function(user) { %]\n      <li>\n          <a href=\"[%= user.relative_path %]\"\n             alt=\"[%= user.public_display_name %]\" title=\"[%= user.public_display_name %]\"\n          >\n\n            <img src=\"[%= user.avatar_url %]\" width=28 height=28 alt=\"[%= user.public_display_name %]\" title=\"[%= user.public_display_name %]\" class= 'img-circle'>\n          </a>\n      </li>\n    [% }) %]\n[% } %]",
    initialize: function(options) {
      this.options = options;
      return this.container = this.options.container;
    },
    render: function() {
      this.template = _.template(this.templateSource);
      this.$el.html(this.template({
        followers: this.collection,
        counter: this.options.followers_count
      }));
      return this.container.html(this.$el);
    },
    seeAll: function(event) {
      event.preventDefault();
      $("a[href='#presenter-page-Followers']").click();
      return $.scrollTo($("a[href='#presenter-page-Followers']"));
    }
  });

  window.UsersShowFollowingsView = Backbone.View.extend({
    events: {
      "click .see-all": "seeAll"
    },
    templateSource: "<div>\n  <h3>\n    Followings\n    <span class=\"followersCount\"> [%= counter %] </span>\n    <a style=\"display: none\" class=\"pull-right see-all ensure-link-style\">See all</a>\n  </h3>\n</div>\n[% if (followings.length > 0) { %]\n  <ul>\n    [% _.each(followings, function(user) { %]\n      <li>\n          <a href=\"[%= user.relative_path %]\"\n             alt=\"[%= user.public_display_name %]\" title=\"[%= user.public_display_name %]\"\n          >\n\n            <img src=\"[%= user.avatar_url %]\" width=28 height=28 alt=\"[%= user.public_display_name %]\" title=\"[%= user.public_display_name %]\" class= 'img-circle'>\n          </a>\n      </li>\n    [% }) %]\n[% } %]",
    initialize: function(options) {
      this.options = options;
      return this.container = this.options.container;
    },
    render: function() {
      this.template = _.template(this.templateSource);
      this.$el.html(this.template({
        followings: this.collection,
        counter: this.options.followingss_count
      }));
      return this.container.html(this.$el);
    },
    seeAll: function(event) {
      event.preventDefault();
      $("a[href='#presenter-page-Followings']").click();
      return $.scrollTo($("a[href='#presenter-page-Followings']"));
    }
  });

}).call(this);
