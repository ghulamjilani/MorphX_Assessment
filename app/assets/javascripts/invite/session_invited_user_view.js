//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.SessionInvitedUserView = (function(superClass) {
    extend(SessionInvitedUserView, superClass);

    function SessionInvitedUserView(options) {
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.removeUserClicked = bind(this.removeUserClicked, this);
      this.updateModelInCollection = bind(this.updateModelInCollection, this);
      this.addAsContactCheckboxClicked = bind(this.addAsContactCheckboxClicked, this);
      SessionInvitedUserView.__super__.constructor.apply(this, arguments);
      this.model.bind('change', this.render);
      this.immersive_is_allowed = options.immersive_is_allowed;
      this.livestream_is_allowed = options.livestream_is_allowed;
      this.template = "<div class=\"list-group-item\" data-email=\"{{ email }}\" data-name=\"{{ display_name }}\">\n  <img class=\"some-class\" width=\"16\" height=\"16\" src=\"{{ avatar_url }}\">\n  <strong title=\"{{ email }}\">\n    {{ display_name }}\n  </strong>\n  <div class=\"buttons\">\n    <div class=\"removable multi-type-invite-icon-view\" style=\"padding-left: 30px; display: none\">\n    </div>\n\n    <a class=\"removable {{#if remove_is_allowed}} ensure-link-style remove_invited_user {{/if}}\">\n      <span alt=\"Remove\" class=\"VideoClientIcon-iPlus rotateIcon btn-lg\" style=\"top: 0; padding: 0; {{#unless remove_is_allowed}} visibility: hidden {{/unless}}\" title=\"Remove\"></span>\n    </a>\n  </div>\n\n  <div>\n    <span class=\"label label-primary\">{{ this.status }}</span>\n  </div>\n  {{#if add_as_contact_is_allowed}}\n    <div class=\"removable friend_input_content\" style=\"margin-top: 4px\">\n      <label class=\"checkbox choice\">\n        <input class=\"add-as-contact-checkbox\" name=\"InputName\" type=\"checkbox\" value=\"1\" {{#if add_as_contact}} checked {{/if}}>\n\n        <span>\n          Add this user as contact\n        </span>\n      </label>\n    </div>\n  {{/if}}\n\n</div>";
      this.template = Handlebars.compile(this.template);
    }

    SessionInvitedUserView.prototype.events = {
      'click .add-as-contact-checkbox': 'addAsContactCheckboxClicked',
      'click .remove_invited_user': 'removeUserClicked'
    };

    SessionInvitedUserView.prototype.tagName = 'div';

    SessionInvitedUserView.prototype.addAsContactCheckboxClicked = function(e) {
      if (!$(e.target).hasClass('disabled')) {
        if ($(e.target).is(':checked')) {
          this.model.set('add_as_contact', true);
        } else {
          this.model.set('add_as_contact', false);
        }
        this.updateModelInCollection();
      }
      return e.preventDefault();
    };

    SessionInvitedUserView.prototype.updateModelInCollection = function() {
      var index;
      index = sessionInviteUserModalView.users.indexOf(this.model);
      sessionInviteUserModalView.users.remove(this.model);
      sessionInviteUserModalView.users.add(this.model, {
        at: index
      });
      return sessionInviteUserModalView.render();
    };

    SessionInvitedUserView.prototype.removeUserClicked = function(e) {
      sessionInviteUserModalView.users.remove(this.model);
      sessionInviteUserModalView.render();
      return e.preventDefault();
    };

    SessionInvitedUserView.prototype.render = function() {
      var data, existing_contact_emails, html, unclickable, view;
      data = this.model.toJSON();
      data.remove_is_allowed = this.model.get('status') !== 'accepted';
      existing_contact_emails = _.map(sessionInviteUserModalView.contacts, function(e) {
        return e.email;
      });
      data.add_as_contact_is_allowed = !_.contains(existing_contact_emails, this.model.get('email'));
      html = this.template(data);
      this.$el.html(html);
      unclickable = this.model.get('status') !== 'pending';
      view = new MultiTypeInviteIconView({
        immersive_is_allowed: this.immersive_is_allowed,
        livestream_is_allowed: this.livestream_is_allowed,
        state: this.model.get('state'),
        unclickable: unclickable,
        sessionInvitedUserView: this
      });
      this.$el.find('.multi-type-invite-icon-view').css('display', 'inline-block').html(view.render().el).show();
      return this;
    };

    return SessionInvitedUserView;

  })(Backbone.View);

}).call(this);
