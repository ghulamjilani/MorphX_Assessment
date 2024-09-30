//= require_self

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.PreviewPurchaseMissingConfirmedEmailView = (function(superClass) {
    extend(PreviewPurchaseMissingConfirmedEmailView, superClass);

    function PreviewPurchaseMissingConfirmedEmailView(options) {
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.submitClicked = bind(this.submitClicked, this);
      this.setVariablesForNotNewEmail = bind(this.setVariablesForNotNewEmail, this);
      this.setVariablesForBlankOrNewEmail = bind(this.setVariablesForBlankOrNewEmail, this);
      this.inputBlurred = bind(this.inputBlurred, this);
      this.emailHasBeenConfirmed = bind(this.emailHasBeenConfirmed, this);
      PreviewPurchaseMissingConfirmedEmailView.__super__.constructor.apply(this, arguments);
      this.template = HandlebarsTemplates['application/preview_purchase_missing_confirmed_email'];
      this.email = options.email;
      this.original_email = this.email;
      if (this.email === '') {
        this.setVariablesForBlankOrNewEmail();
      } else {
        this.setVariablesForNotNewEmail();
      }
    }

    PreviewPurchaseMissingConfirmedEmailView.prototype.tagName = 'div';

    PreviewPurchaseMissingConfirmedEmailView.prototype.events = {
      'click .submit': 'submitClicked',
      'blur input': 'inputBlurred'
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.emailHasBeenConfirmed = function() {
      var cb;
      cb = function() {
        return $('.submit-payment').removeClass('disabled');
      };
      return this.$el.fadeOut(cb);
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.inputBlurred = function() {
      this.email = this.$el.find('input').val();
      if (this.email === '') {
        this.setVariablesForBlankOrNewEmail();
      } else {
        if (this.email === this.original_email) {
          this.setVariablesForNotNewEmail();
        } else {
          this.setVariablesForBlankOrNewEmail();
        }
      }
      return this.render();
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.setVariablesForBlankOrNewEmail = function() {
      this.message_text = 'Please add and confirm your email before proceeding with the payment!';
      return this.button_title = 'Send Email Confirmation';
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.setVariablesForNotNewEmail = function() {
      this.message_text = 'Please confirm your email before proceeding with the payment!';
      return this.button_title = 'Resend Email Confirmation';
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.submitClicked = function() {
      this.email = this.$el.find('input').val();
      this.setVariablesForNotNewEmail();
      this.render();
      return $.ajax({
        type: "POST",
        url: '/send-email-confirmation-from-preview-purchase',
        data: {
          email: this.email
        },
        dataType: 'script'
      });
    };

    PreviewPurchaseMissingConfirmedEmailView.prototype.render = function() {
      var data;
      data = {};
      data.message_text = this.message_text;
      data.button_title = this.button_title;
      data.email = this.email;
      this.$el.html(this.template(data));
      return $('.modal:visible .submit-payment').addClass('disabled');
    };

    return PreviewPurchaseMissingConfirmedEmailView;

  })(Backbone.View);

}).call(this);
