//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.SessionInviteUserModalView = (function(superClass) {
    extend(SessionInviteUserModalView, superClass);

    function SessionInviteUserModalView(options) {
      var intervalID;
      if (options == null) {
        options = {};
      }
      this.inviteContactClicked = bind(this.inviteContactClicked, this);
      this.inviteByEmailClicked = bind(this.inviteByEmailClicked, this);
      this.inviteByEmail = bind(this.inviteByEmail, this);
      this.render = bind(this.render, this);
      this.afterRender = bind(this.afterRender, this);
      this.checkRenderQueue = bind(this.checkRenderQueue, this);
      this.inviteSubmitButtonClicked = bind(this.inviteSubmitButtonClicked, this);
      this.postponedRender = bind(this.postponedRender, this);
      SessionInviteUserModalView.__super__.constructor.apply(this, arguments);
      this.immersive_is_allowed = options.immersive_is_allowed;
      this.livestream_is_allowed = options.livestream_is_allowed;
      this.url = options.url;
      this.contacts = options.contacts;
      this.users = options.users;
      this.renderQueue = $({});
      this.template = HandlebarsTemplates['application/session_invite_user_modal'];
      intervalID = setInterval(this.checkRenderQueue, 20);
      $('#invite-user-modal').on('close hidden hidden.bs.modal', function() {
        $('form.formtastic.session').find("input[name*=invited_users_attributes]").remove();
        $('<input>').attr({
          type: 'hidden',
          value: JSON.stringify(sessionInviteUserModalView.users),
          name: 'session[invited_users_attributes]'
        }).appendTo('form.formtastic.session');
        displayUsersInForm();
        return $('.contacts-search').val('');
      });
      this.users.bind('change', this.render);
      this.render = _.wrap(this.render, (function(_this) {
        return function(render) {
          render();
          return _this;
        };
      })(this));
    }

    SessionInviteUserModalView.prototype.tagName = 'div';

    SessionInviteUserModalView.prototype.el = '#session-invite-user-modal-placeholder';

    SessionInviteUserModalView.prototype.postponedRender = function() {
      this.renderQueue.queue('update', function(next) {});
      return this.renderQueue.queue('update').length;
    };

    SessionInviteUserModalView.prototype.events = {
      'click .invite_btn': 'inviteByEmailClicked',
      'click .invite-submit-button': 'inviteSubmitButtonClicked'
    };

    SessionInviteUserModalView.prototype.inviteSubmitButtonClicked = function(e) {
      $.ajax({
        type: "POST",
        url: this.url,
        data: "invited_users_attributes=" + encodeURIComponent(JSON.stringify(sessionInviteUserModalView.users))
      });
      return false;
    };

    SessionInviteUserModalView.prototype.checkRenderQueue = function() {
      if (this.renderQueue.queue('update').length > 0) {
        this.renderQueue.clearQueue('update');
        return this.render();
      }
    };

    SessionInviteUserModalView.prototype.afterRender = function() {
      return displayUsersInForm();
    };

    SessionInviteUserModalView.prototype.render = function() {
      var addMultiTypes, addOne, already_invited_emails, data, placeholder, view;
      data = {};
      already_invited_emails = _.map(this.users.models, function(model) {
        return model.get('email');
      });
      data.contacts = _.reject(this.contacts, function(obj) {
        return _.contains(already_invited_emails, obj.email);
      });
      data.done_button_instead_of_submit = $('#invite-modal-portal').length === 0;
      this.$el.html(this.template(data));
      view = new MultiTypeInviteIconView({
        immersive_is_allowed: this.immersive_is_allowed,
        livestream_is_allowed: this.livestream_is_allowed,
        invitation_type: 'group'
      });
      this.$el.find('.group-state-buttons').append(view.render().el);
      this.contactMultiTypeInviteIconViews = [];
      addMultiTypes = (function(_this) {
        return function(k, buttonsEl) {
          view = new MultiTypeInviteIconView({
            immersive_is_allowed: _this.immersive_is_allowed,
            livestream_is_allowed: _this.livestream_is_allowed,
            invitation_type: 'individual'
          });
          _this.contactMultiTypeInviteIconViews.push(view);
          return $(buttonsEl).append(view.render().el);
        };
      })(this);
      $.each($('.contactsList .buttons'), addMultiTypes);
      if (data.done_button_instead_of_submit) {
        placeholder = $('#invite-user-modal .RightBlock.users_list .invited');
      } else {
        placeholder = $('#invite-modal-portal .RightBlock.users_list .invited');
      }
      if (placeholder.length === 0) {
        throw new Error('can not find placeholder');
      }
      placeholder.html('');
      addOne = function(invitedUser) {
        view = new SessionInvitedUserView({
          model: invitedUser,
          collection: this.users,
          immersive_is_allowed: this.immersive_is_allowed,
          livestream_is_allowed: this.livestream_is_allowed
        });
        return placeholder.append(view.render().el);
      };
      this.users.each(addOne, this);
      return this.afterRender();
    };

    SessionInviteUserModalView.prototype.inviteByEmail = function(email, state) {
      var existing_emails, input, model, opts;
      input = document.createElement('input');
      input.type = 'email';
      input.value = email;
      existing_emails = _.map(this.users.models, function(model) {
        return model.get('email');
      });
      if (_.contains(existing_emails, email)) {
        $.showFlashMessage(email + " has been already invited", {
          type: 'error',
          timeout: 5000
        });
        return false;
      }
      if (!input.checkValidity() || email === '') {
        return false;
      } else {
        opts = extractAttributesFromContactsByEmail(sessionInviteUserModalView.contacts, email);
        model = new InvitedUser({
          email: email,
          avatar_url: opts.avatar_url,
          state: state,
          add_as_contact: opts.add_as_contact
        });
        this.users.add(model);
        return true;
      }
    };

    SessionInviteUserModalView.prototype.inviteByEmailClicked = function(e) {
      var email, state;
      e.preventDefault();
      e.stopPropagation();
      email = $('.modal:visible .email input[type=email]').val();
      if (sessionInviteUserModalView.immersive_is_allowed() && sessionInviteUserModalView.livestream_is_allowed()) {
        state = 'immersive-and-livestream';
      } else if (sessionInviteUserModalView.immersive_is_allowed()) {
        state = 'immersive';
      } else if (sessionInviteUserModalView.livestream_is_allowed()) {
        state = 'livestream';
      } else {
        state = 'co-presenter';
      }
      if (this.inviteByEmail(email, state)) {
        this.render();
      }
      return false;
    };

    SessionInviteUserModalView.prototype.inviteContactClicked = function(email, state) {
      if (this.inviteByEmail(email, state)) {
        return this.render();
      }
    };

    return SessionInviteUserModalView;

  })(Backbone.View);

}).call(this);
