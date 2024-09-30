//= require_self

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.UserAccount = (function(superClass) {
    extend(UserAccount, superClass);

    function UserAccount() {
      return UserAccount.__super__.constructor.apply(this, arguments);
    }

    UserAccount.prototype.initialize = function() {};

    return UserAccount;

  })(Backbone.Model);

  window.VanityUrlSwitchView = (function(superClass) {
    extend(VanityUrlSwitchView, superClass);

    function VanityUrlSwitchView(options) {
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.afterRender = bind(this.afterRender, this);
      VanityUrlSwitchView.__super__.constructor.apply(this, arguments);
      this.slug = options.slug;
      this.render = _.wrap(this.render, (function(_this) {
        return function(render) {
          render();
          return _this;
        };
      })(this));
    }

    VanityUrlSwitchView.prototype.tagName = 'div';

    VanityUrlSwitchView.prototype.el = '#vanity-url-switch-placeholder';

    VanityUrlSwitchView.prototype.events = {
      'click #select-another-option': 'selectAnotherOptionClicked',
      'click #change-url': 'changeUrlClicked',
      'click .cancel': 'closeModalselectAnotherOptionClicked'
    };

    VanityUrlSwitchView.prototype.afterRender = function() {};

    VanityUrlSwitchView.prototype.changeUrlClicked = function(event) {
      var newVal;
      newVal = $('#get-custom-url-modal input').val();
      $.ajax({
        type: "POST",
        url: '/remote_validations/user_slug',
        data: "slug=" + encodeURIComponent(newVal),
        dataType: 'script'
      });
      return false;
    };

    VanityUrlSwitchView.prototype.closeModalselectAnotherOptionClicked = function(event) {
      $('#get-custom-url-modal').modal('hide');
      return false;
    };

    VanityUrlSwitchView.prototype.selectAnotherOptionClicked = function(event) {
      $('#choose-or-keep-buttons-container').hide();
      $('#vanity-url-input-container').show();
      return $('.result').hide();
    };

    VanityUrlSwitchView.prototype.render = function() {
      var data, template;
      data = {
        slug: this.slug,
        host: window.envHOST
      };
      template = HandlebarsTemplates['application/vanity_url_switch'];
      this.$el.html(template(data));
      return this.afterRender();
    };

    return VanityUrlSwitchView;

  })(Backbone.View);

}).call(this);
