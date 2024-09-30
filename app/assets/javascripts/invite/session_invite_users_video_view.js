//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.SessionInviteUsersVideoView = (function(superClass) {
    extend(SessionInviteUsersVideoView, superClass);

    function SessionInviteUsersVideoView(options) {
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      SessionInviteUsersVideoView.__super__.constructor.apply(this, arguments);
      if (typeof options.immersive_is_allowed !== 'undefined') {
        this.immersive_is_allowed = options.immersive_is_allowed;
      } else {
        throw new Error('immersive_is_allowed has to be provided');
      }
      if (typeof options.livestream_is_allowed !== 'undefined') {
        this.livestream_is_allowed = options.livestream_is_allowed;
      } else {
        throw new Error('livestream_is_allowed has to be provided');
      }
      if (typeof options.session_id !== 'undefined') {
        this.session_id = options.session_id;
      } else {
        throw new Error('session_id has to be provided');
      }
      if (typeof options.users !== 'undefined') {
        this.users = options.users;
      } else {
        throw new Error('users has to be provided');
      }
      this.template = "{{#each users}}\n  <div class=\"list-group-item\" data-email=\"{{ this.email }}\">\n    <img src=\"{{ this.avatar_url }}\">\n    <strong>\n      {{ this.display_name }}\n    </strong>\n\n    <span class=\"label label-primary\">{{ this.status }}</span>\n  </div>\n{{/each}}";
    }

    SessionInviteUsersVideoView.prototype.tagName = 'div';

    SessionInviteUsersVideoView.prototype.getTemplateFunction = function() {
      return Handlebars.compile(this.template);
    };

    SessionInviteUsersVideoView.prototype.render = function() {
      var addMultiTypes, data, html, templateFunc;
      data = {};
      data.users = this.users.toJSON();
      templateFunc = this.getTemplateFunction();
      html = templateFunc(data);
      this.$el.html(html);
      addMultiTypes = (function(_this) {
        return function(key, model) {
          var container, content, email, view;
          view = new MultiTypeInviteIconView({
            unclickable: true,
            state: model.get('state'),
            immersive_is_allowed: _this.immersive_is_allowed,
            livestream_is_allowed: _this.livestream_is_allowed
          });
          email = model.get('email');
          container = $(".list-group-item[data-email='" + email + "']");
          content = view.render().el;
          if (model.get('status') === 'pending') {
            $(container).append("<a class='removeItem instant-remove-invited-user-from-video ensure-link-style' data-email='" + email + "' data-session-id='" + _this.session_id + "'> <i class='VideoClientIcon-iPlus'> </a>");
          }
          return $(container).append(content);
        };
      })(this);
      return $.each(this.users.models, addMultiTypes);
    };

    return SessionInviteUsersVideoView;

  })(Backbone.View);

}).call(this);
