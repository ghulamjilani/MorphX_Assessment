//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.MultiTypeInviteIconView = (function(superClass) {
    extend(MultiTypeInviteIconView, superClass);

    function MultiTypeInviteIconView(options) {
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.buttonClicked = bind(this.buttonClicked, this);
      this.inviteAllContactsClicked = bind(this.inviteAllContactsClicked, this);
      MultiTypeInviteIconView.__super__.constructor.apply(this, arguments);
      this.allStates = ["immersive-and-livestream", "immersive", "livestream", "co-presenter"];
      switch (options.invitation_type) {
        case 'individual':
          this.plusSignClassName = 'modal_add_contact';
          break;
        case 'group':
          this.plusSignClassName = 'invite-all-contacts';
          break;
        default:
          this.plusSignClassName = null;
      }
      if (typeof options.unclickable !== 'undefined') {
        this.unclickable = options.unclickable;
      } else {
        this.unclickable = false;
      }
      if (typeof options.immersive_is_allowed !== 'undefined') {
        this.immersive_is_allowed = options.immersive_is_allowed;
      } else {
        this.immersive_is_allowed = sessionInviteUserModalView.immersive_is_allowed();
      }
      if (typeof options.livestream_is_allowed !== 'undefined') {
        this.livestream_is_allowed = options.livestream_is_allowed;
      } else {
        this.livestream_is_allowed = sessionInviteUserModalView.livestream_is_allowed();
      }
      if (typeof options.state !== 'undefined') {
        this.state = options.state;
      } else {
        if (this.immersive_is_allowed() && this.livestream_is_allowed()) {
          this.state = "immersive-and-livestream";
        } else if (this.immersive_is_allowed()) {
          this.state = "immersive";
        } else if (this.livestream_is_allowed()) {
          this.state = "livestream";
        } else {
          this.state = "co-presenter";
        }
      }
      if (typeof options.sessionInvitedUserView !== 'undefined') {
        this.sessionInvitedUserView = options.sessionInvitedUserView;
      }
      this.template = "<a class='current-state-status' style=\"cursor: pointer\" data-state=\"{{state}}\">\n  <span style=\"display:none\" class=\"state-double-icon immersive-and-livestream\" title=\"Interactive and Livestream\">\n    <i class=\"VideoClientIcon-LiveStream_2\"></i>\n    <i class=\"VideoClientIcon-human\"></i>\n  </span>\n  <span style=\"display:none\" class=\"state-double-icon immersive\"  title=\"Interactive\">\n    <i class=\"VideoClientIcon-LiveStream_2\"></i>\n    <i class=\"VideoClientIcon-human\"></i>\n  </span>\n  <span style=\"display:none\" class=\"state-double-icon  livestream\" title=\"Livestream\">\n    <i class=\"VideoClientIcon-LiveStream_2\"></i>\n    <i class=\"VideoClientIcon-human\"></i>\n  </span>\n  <span style=\"display:none\" class=\"co-presenter\" title=\"Co-Presenter\">CoP</span>\n</a>\n<a class=\"plus " + this.plusSignClassName + "\" style=\"cursor: pointer\">\n  <i class=\"VideoClientIcon-iPlus\"></i>\n</a>";
      this.template = Handlebars.compile(this.template);
    }

    MultiTypeInviteIconView.prototype.tagName = 'div';

    MultiTypeInviteIconView.prototype.events = {
      'click .current-state-status': 'buttonClicked',
      'click .invite-all-contacts': 'inviteAllContactsClicked'
    };

    MultiTypeInviteIconView.prototype.inviteAllContactsClicked = function() {
      var baseView, emails, existing_contact_emails, existing_invited_emails;

      baseView = sessionInviteUserModalView;
      existing_contact_emails = _.map(baseView.contacts, function(e) {
        return e.email;
      });
      existing_invited_emails = _.map(baseView.users.models, function(model) {
        return model.get('email');
      });
      emails = _.difference(existing_contact_emails, existing_invited_emails);
      _.map(emails, function(email) {
        return baseView.inviteByEmail(email);
      });
      if (emails.length > 0) {
        return baseView.render();
      }
    };

    MultiTypeInviteIconView.prototype.buttonClicked = function(e) {
      var changeState, except, nextState, stack;
      if ($(e.target).parents('.current-state-status').data('disabled')) {
        return;
      }
      except = [];
      if (!this.immersive_is_allowed() || !this.livestream_is_allowed()) {
        except.push("immersive-and-livestream");
      }
      if (!this.immersive_is_allowed()) {
        except.push("immersive");
      }
      if (!this.livestream_is_allowed()) {
        except.push("livestream");
      }
      stack = new InfiniteStack(_.difference(this.allStates, except));
      nextState = stack.nextAfter(this.state);
      if (typeof this.sessionInvitedUserView !== 'undefined') {
        if (this.state !== nextState) {
          this.sessionInvitedUserView.model.set('state', nextState);
          this.sessionInvitedUserView.updateModelInCollection();
        }
      }
      this.state = nextState;
      switch (this.plusSignClassName) {
        case 'modal_add_contact':
          if (window.console && window.console.log) {
            console.log('skipping');
          }
          break;
        case 'invite-all-contacts':
          changeState = (function(_this) {
            return function(k, view) {
              view.state = _this.state;
              return view.render();
            };
          })(this);
          $.each(sessionInviteUserModalView.contactMultiTypeInviteIconViews, changeState);
          break;
        case null:
          if ($('body').hasClass('videoclient')) {
            $('form.live-participant-form').find("input[name*=state]").remove();
            $('<input>').attr({
              type: 'hidden',
              value: this.state,
              name: 'state'
            }).appendTo('form.live-participant-form');
          }
      }
      return this.render();
    };

    MultiTypeInviteIconView.prototype.render = function() {
      var $span, data, html;
      data = {};
      data.state = this.state;
      data.immersive_is_allowed = this.immersive_is_allowed();
      data.livestream_is_allowed = this.livestream_is_allowed();
      html = this.template(data);
      this.$el.html(html);
      if (this.unclickable) {
        this.$el.find('.current-state-status').css('cursor', 'default').data('disabled', true);
      }
      if (typeof this.plusSignClassName === 'undefined' || this.plusSignClassName === null) {
        this.$el.find('.plus').hide();
        this.$el.css('display', 'inline-block');
      }
      $span = this.$el.find('span.' + this.state);
      if ($span.length !== 1) {
        throw new Error('can not find .' + this.state);
      }
      $($span).css('display', 'block').addClass('active');
      return this;
    };

    return MultiTypeInviteIconView;

  })(Backbone.View);

}).call(this);
