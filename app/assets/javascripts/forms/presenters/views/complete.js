(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Presenters.Views.Complete = (function(superClass) {
    extend(Complete, superClass);

    function Complete() {
      this.initForm = bind(this.initForm, this);
      return Complete.__super__.constructor.apply(this, arguments);
    }

    Complete.prototype.region = "#presenter_info";

    Complete.prototype.url = Routes.save_complete_presenter_index_path();

    Complete.prototype.el = "#presenter_info";

    Complete.prototype.events = {
      'click .user_logo': 'showUserLogoModal',
      'click .submitButton': 'saveUserAccountInfo'
    };

    Complete.prototype.initialize = function(opts) {
      this.$form = this.$el.find('form#user_account');
      this.$submitBtn = this.$form.find('button.submitButton');
      this.$region = $(this.region);
      this.model = Forms.Presenters.current_user;
      this.logo = this.model.logo;
      this.listenTo(this.logo, 'crop:done', this.showLogo);
      return this.render();
    };

    Complete.prototype.render = function() {
      return this.initForm();
    };

    Complete.prototype.checkForm = function() {
      if (!this.validator) {
        return;
      }
      return this.validator.isValid();
    };

    Complete.prototype.initForm = function() {
      var settings;
      settings = {
        rules: {
          'user_account[bio]': {
            required: true,
            minlength: 24,
            maxlength: 2000
          }
        }
      };
      this.validateForm(settings);
      this.prepareInputs();
      return this.checkForm();
    };

    Complete.prototype.saveUserAccountInfo = function(e) {
      e.preventDefault();
      if (!this.validator.isValid()) {
        return false;
      }
      return $.ajax({
        url: this.url,
        data: this.getFormData(),
        processData: false,
        contentType: false,
        type: 'POST',
        beforeSend: (function(_this) {
          return function() {
            return _this.$submitBtn.attr('disabled', 'disabled');
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            return window.location = data.path;
          };
        })(this),
        error: function(data, error) {
          $.showFlashMessage(data.responseText || data.statusText, {
            type: "error"
          });
          this.$submitBtn.removeAttr('disabled');
          return this.checkForm();
        }
      });
    };

    Complete.prototype.getFormData = function() {
      var formData;
      formData = new FormData;
      formData.append('channel_id', Immerss.channelId);
      this.$form.find("[name^=user_account]").each(function() {
        return formData.append($(this).attr("name"), $(this).val());
      });
      if (this.logo.image) {
        _(this.logo.toFormData()).each(function(data) {
          return formData.append.apply(formData, data);
        });
      }
      return formData;
    };

    Complete.prototype.showUserLogoModal = function(e) {
      this.logo_modal || (this.logo_modal = new Forms.Presenters.Views.UserLogoView({
        model: this.logo
      }));
      return this.logo_modal.show();
    };

    Complete.prototype.showLogo = function() {
      this.$el.find('.avatar').attr('src', "" + (this.logo.get('img_src')));
      return this.$el.find('.user_logo').attr('data-hover-text', 'Change Avatar');
    };

    return Complete;

  })(Forms.FormView);

}).call(this);
