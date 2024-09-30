(function() {
  window.PhoneVerificationView = Backbone.View.extend({
    initialize: function(options) {
      if (options == null) {
        options = {};
      }
      this.templateSource = "<div class=\"placeholder-container\">\n  <input class=\"phoneSelect w435\" type=\"tel\" value=\"[%= value %]\" onkeyup=\"this.value = this.value.replace(/[^\\d]/g,'');\" >\n  <input type=\"hidden\" name='profile[user_account_attributes][phone]' value=\"[%= value %]\">\n  <span class=\"valid-msg hide\">✓ Valid</span>\n  <span class=\"error-msg hide\">Invalid number</span>\n</div>\n<a class=\"btn btn-s SendCodeToPhoneBTN ensure-link-style\" style='display: none'>\n  Send Code\n</a>";
      this.options = options;
      this.$el.html(this.template({
        value: this.options.value
      }));
      this.initializeTelInputListeners();
      this.confirmed_numbers = this.options.confirmed_numbers;
      return this.makeSendCodeVisibleIfNecessary((this.options.value || '').replace(/\s/g, ''));
    },
    makeSendCodeVisibleIfNecessary: function(fullNumberWithoutSpace) {
      if (fullNumberWithoutSpace === '') {
        return;
      }
      if (this.options.value == null) {
        return;
      }
      if (fullNumberWithoutSpace.length > 5) {
        if (_.contains(this.confirmed_numbers, fullNumberWithoutSpace)) {
          return $('.SendCodeToPhoneBTN').hide();
        } else {
          return $('.SendCodeToPhoneBTN').show();
        }
      } else {
        return $('.SendCodeToPhoneBTN').hide();
      }
    },
    template: function() {
      var template;
      template = _.template(this.templateSource);
      return template.apply(this, arguments);
    },
    setHiddenPhoneInputFromPlugin: function() {
      return $('input[name*=phone]').val(this.getFullPhoneFromPlugin());
    },
    getFullPhoneFromPlugin: function() {
      return $('input.phoneSelect:last').intlTelInput('getNumber');
    },
    initializeTelInputListeners: function() {
      var errorMsg, phoneWasOnceSet, reset, self, telInput, validMsg;
      telInput = this.$el.find(".phoneSelect");
      errorMsg = this.$el.find(".error-msg");
      validMsg = this.$el.find(".valid-msg");
      phoneWasOnceSet = $(this.el).find('input').val() !== '';
      if (phoneWasOnceSet) {
        telInput.intlTelInput({
          separateDialCode: true,
          utilsScript: "/Phone-select/utils.js"
        });
      } else {
        telInput.intlTelInput({
          initialCountry: "auto",
          separateDialCode: true,
          geoIpLookup: function(callback) {
            var cb;
            cb = function() {
              return null;
            };
            return $.get('https://ipinfo.io?token=42576d359578ce', cb, "jsonp").always(function(resp) {
              var countryCode;
              countryCode = resp && resp.country ? resp.country : "";
              return callback(countryCode);
            });
          },
          utilsScript: "/Phone-select/utils.js"
        });
      }
      reset = function() {};
      self = this;
      telInput.blur(function() {
        reset();
        self.setHiddenPhoneInputFromPlugin();
        return self.makeSendCodeVisibleIfNecessary(self.getFullPhoneFromPlugin());
      });
      return telInput.on("keyup change", reset);
    },
    events: {
      "click .SendCodeToPhoneBTN": "sendCodeClicked"
    },
    sendCodeClicked: function() {
      var _value;
      _value = $('input.phoneSelect:last').intlTelInput('getNumber');
      $.ajax({
        url: "/profiles/preview_phone_number_verification_modal",
        type: 'GET',
        data: {
          phone: _value
        },
        dataType: 'script'
      });
      return false;
    }
  });

}).call(this);
