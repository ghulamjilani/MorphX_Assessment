//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.DonationAmount = (function(superClass) {
    extend(DonationAmount, superClass);

    function DonationAmount() {
      this.url = bind(this.url, this);
      return DonationAmount.__super__.constructor.apply(this, arguments);
    }

    DonationAmount.prototype.initialize = function(options) {
      if (options == null) {
        options = {};
      }
      DonationAmount.__super__.initialize.apply(this, arguments);
      if (typeof options.abstract_session_id === 'undefined') {
        throw new Error('options.abstract_session_id has to be provided');
      }
      this.set('abstract_session_id', options.abstract_session_id);
      if (typeof options.abstract_session_type === 'undefined') {
        throw new Error('options.abstract_session_type has to be provided');
      }
      return this.set('abstract_session_type', options.abstract_session_type);
    };

    DonationAmount.prototype.url = function() {
      return '/paypal_donations/info?abstract_session_id=' + this.get('abstract_session_id') + '&abstract_session_type=' + this.get('abstract_session_type');
    };

    return DonationAmount;

  })(Backbone.Model);

  window.DonationAmountView = (function(superClass) {
    extend(DonationAmountView, superClass);

    function DonationAmountView(options) {
      var ref;
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.actionButtonClicked = bind(this.actionButtonClicked, this);
      this.reload = bind(this.reload, this);
      DonationAmountView.__super__.constructor.apply(this, arguments);
      if (typeof options.can_make_donations === 'undefined') {
        throw new Error('options.can_make_donations has to be provided');
      }
      this.can_make_donations = options.can_make_donations;
      if (typeof options.donate_title_as_singular === 'undefined') {
        throw new Error('options.donate_title_as_singular has to be provided');
      }
      this.donate_title_as_singular = options.donate_title_as_singular;
      if (typeof options.paypal_item_name === 'undefined') {
        throw new Error('options.paypal_item_name has to be provided');
      }
      this.paypal_item_name = options.paypal_item_name;
      if (typeof options.paypal_item_number === 'undefined') {
        throw new Error('options.paypal_item_number has to be provided');
      }
      this.paypal_item_number = options.paypal_item_number;
      if (typeof options.env === 'undefined') {
        throw new Error('options.env has to be provided');
      }
      this.env = options.env;
      if (typeof options.business === 'undefined') {
        throw new Error('options.business has to be provided');
      }
      this.business = options.business;
      if (typeof options.form_action_attribute_value === 'undefined') {
        throw new Error('options.form_action_attribute_value has to be provided');
      }
      this.form_action_attribute_value = options.form_action_attribute_value;
      if (typeof options.fixed_donation_options === 'undefined') {
        throw new Error('options.fixed_donation_optionsbusiness has to be provided');
      }
      ref = options.fixed_donation_options, this.first_fixed_donation_option = ref[0], this.second_fixed_donation_option = ref[1], this.third_fixed_donation_option = ref[2];
      this.model.fetch().done(this.render);
      this.model.bind('change', this.render);
      this.template = HandlebarsTemplates['donate_amount'];
    }

    DonationAmountView.prototype.events = {
      'click .action': 'actionButtonClicked',
      'click .paypal-button': 'paypalButtonClicked'
    };

    DonationAmountView.prototype.tagName = 'div';

    DonationAmountView.prototype.paypalButtonClicked = function() {
      this.readCustomAmount();
      return this.submitFormIfValid();
    };

    DonationAmountView.prototype.readCustomAmount = function() {
      var actual;
      if ($('input[type=radio][name=donation_type]:last').is(':checked')) {
        actual = $('input[name=custom]').val();
      } else {
        actual = $('input[type=radio][name=donation_type]:checked').val();
      }
      return $('input[name=amount]').val(actual);
    };

    DonationAmountView.prototype.submitFormIfValid = function() {
      var actual, valid;
      if ($('input[type=radio][name=donation_type]:last').is(':checked')) {
        actual = $('input[name=custom]').val();
        valid = /^\d{0,4}(\.\d{0,2})?$/.test(actual);
        if (actual !== '' && valid) {
          $('form[action*="paypal.com"]').submit();
          $('#section-with-options-and-form').slideUp();
        } else {

        }
        return true;
      } else {
        if ($('input[type=radio][name=donation_type]:checked').length === 1) {
          $('form[action*="paypal.com"]').submit();
          return $('#section-with-options-and-form').slideUp();
        }
      }
    };

    DonationAmountView.prototype.reload = function() {
      this.model = new DonationAmount({
        abstract_session_id: this.model.get('abstract_session_id'),
        abstract_session_type: this.model.get('abstract_session_type')
      });
      return this.model.fetch().done((function(_this) {
        return function() {
          return _this.render();
        };
      })(this));
    };

    DonationAmountView.prototype.actionButtonClicked = function(e) {
      var actual;
      actual = $(e.target).html();
      switch (actual) {
        case 'Hide counter':
          $.ajax({
            type: "POST",
            url: '/paypal_donations/toggle_visibility',
            data: 'session_id=' + this.model.get('session_id'),
            success: function() {
              $(e.target).attr('title', 'Make *Raised so far* amount visible for participants');
              return $(e.target).html('Display counter');
            }
          });
          break;
        case 'Display counter':
          $.ajax({
            type: "POST",
            url: '/paypal_donations/toggle_visibility',
            data: 'session_id=' + this.model.get('session_id'),
            success: function() {
              $(e.target).attr('title', 'Make *Raised so far* amount hidden for participants');
              return $(e.target).html('Hide counter');
            }
          });
          break;
        default:
          throw new Error('can not interpret - ' + actual);
      }
      return e.preventDefault();
    };

    DonationAmountView.prototype.render = function() {
      var cb, data, html;
      data = this.model.toJSON();
      cb = function() {
        return $('form[action*="paypal.com"]').attr('target', '_blank');
      };
      setTimeout(cb, 400);
      data.business = this.business;
      data.can_make_donations = this.can_make_donations;
      data.donate_title_as_singular = this.donate_title_as_singular;
      data.env = this.env;
      data.first_fixed_donation_option = this.first_fixed_donation_option;
      data.form_action_attribute_value = this.form_action_attribute_value;
      data.paypal_item_name = this.paypal_item_name;
      data.paypal_item_number = this.paypal_item_number;
      data.second_fixed_donation_option = this.second_fixed_donation_option;
      data.third_fixed_donation_option = this.third_fixed_donation_option;
      data.third_fixed_donation_option = this.third_fixed_donation_option;
      data.success_ipn_callback_url = Routes.success_ipn_callback_url();
      html = this.template(data);
      this.$el.html(html);
      if (Immerss.canManagePaypalDonationsVisibility) {
        this.$el.find('.tools').show();
      }
      if ($('.ContributorsList-b > div').length >= 3) {
        $('.ContributorsList-b').jScrollPane();
      }
      return this;
    };

    return DonationAmountView;

  })(Backbone.View);

}).call(this);
