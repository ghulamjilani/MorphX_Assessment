(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.EditUserAccountModal = (function(superClass) {
    extend(EditUserAccountModal, superClass);

    function EditUserAccountModal() {
      this.initForm = bind(this.initForm, this);
      return EditUserAccountModal.__super__.constructor.apply(this, arguments);
    }

    EditUserAccountModal.prototype.el = "#userAccountModal";

    EditUserAccountModal.prototype.url = Routes.save_user_account_become_presenter_steps_path();

    EditUserAccountModal.prototype.events = {
      'change form [name*=user_account]': 'formChanged',
      'click .user_cover': 'showUserCoverModal',
      'click .user_logo': 'showUserLogoModal',
      'click .submitButton': 'saveUserAccountInfo',
      'change form [name*=talent_list]': 'checkTags',
      'focusout form .tagit input': 'checkTags'
    };

    EditUserAccountModal.prototype.initialize = function(opts) {
      this.$form = this.$el.find('form#user_account');
      this.$submitBtn = this.$form.find('button.submitButton');
      this.form_initialized = false;
      this.model = Forms.Channels.Cache.current_user;
      this.logo = new Forms.Channels.Models.UserImage();
      this.cover = new Forms.Channels.Models.UserCover();
      this.listenTo(this.cover, 'crop:done', this.showCover);
      this.listenTo(this.logo, 'crop:done', this.showLogo);
      return this.$el.on('shown.bs.modal', (function(_this) {
        return function() {
          if (!_this.form_initialized) {
            return _this.initForm();
          }
        };
      })(this));
    };

    EditUserAccountModal.prototype.render = function() {
      return this.$el.modal('show');
    };

    EditUserAccountModal.prototype.initForm = function() {
      var settings;
      settings = {
        rules: {
          'user_account[tagline]': {
            minlength: 8,
            maxlength: 160
          },
          'user_account[bio]': {
            required: true,
            minlength: 16,
            maxlength: 2000
          },
          'user_account[talent_list]': {
            maxlength: 160,
            tagsUniqueness: true,
            tagsLength: {
              minlength: 1,
              maxlength: 20
            },
            tagLength: {
              minlength: 2,
              maxlength: 100
            }
          }
        }
      };
      this.validateForm(settings);
      this.prepareInputs();
      this.setupTags();
      this.setupTagline();
      this.checkForm();
      return this.form_initialized = true;
    };

    EditUserAccountModal.prototype.saveUserAccountInfo = function(e) {
      e.preventDefault();
      if (!this.form_changed) {
        this.$el.modal('hide');
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
            _this.$submitBtn.attr('disabled', 'disabled');
            return _this.$submitBtn.find('span.spinnerSlider').show();
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            _this.model.set(data);
            return _this.$el.modal('hide');
          };
        })(this),
        error: function(data, error) {
          return $.showFlashMessage(data.responseText || data.statusText, {
            type: "error"
          });
        },
        complete: (function(_this) {
          return function() {
            _this.$submitBtn.find('span.spinnerSlider').hide();
            _this.checkForm();
            if (_this.isFormValid()) {
              return Immerss.userInfoReady = true;
            }
          };
        })(this)
      });
    };

    EditUserAccountModal.prototype.checkTags = function(e) {
      if (this.$el.find('.tagit input').is(':focus')) {
        return;
      }
      return this.$el.find('[name*=talent_list]').valid();
    };

    EditUserAccountModal.prototype.getFormData = function() {
      var formData;
      formData = new FormData;
      this.$form.find("[name^=user_account]").each(function() {
        return formData.append($(this).attr("name"), $(this).val());
      });
      if (this.logo.image) {
        _(this.logo.toFormData()).each(function(data) {
          return formData.append.apply(formData, data);
        });
      }
      if (this.cover.image) {
        _(this.cover.toFormData()).each(function(data) {
          return formData.append.apply(formData, data);
        });
      }
      return formData;
    };

    EditUserAccountModal.prototype.showUserCoverModal = function() {
      this.cover_modal || (this.cover_modal = new Forms.Channels.Views.UserCoverView({
        model: this.cover
      }));
      this.cover_modal.show();
      return this.hide();
    };

    EditUserAccountModal.prototype.showUserLogoModal = function() {
      this.logo_modal || (this.logo_modal = new Forms.Channels.Views.UserLogoView({
        model: this.logo
      }));
      this.logo_modal.show();
      return this.hide();
    };

    EditUserAccountModal.prototype.showLogo = function() {
      this.$el.find('.user_logo').css('background-image', "url('" + (this.logo.get('img_src')) + "')");
      return this.$el.find('.user_logo').attr('data-hover-text', 'Change Avatar');
    };

    EditUserAccountModal.prototype.showCover = function() {
      this.$el.find('.user_cover').css('background-image', "url('" + (this.cover.get('img_src')) + "')");
      return this.$el.find('.user_cover').attr('data-hover-text', 'Change Cover');
    };

    EditUserAccountModal.prototype.formChanged = function(e) {
      this.checkForm();
      this.form_changed = true;
      return this.autosave(e.target);
    };

    EditUserAccountModal.prototype.autosave = function(element) {
      if (!this.isElementValid(element)) {
        return;
      }
      return $.ajax({
        url: this.url + '?autosave=true',
        data: $(element).serialize(),
        type: 'POST',
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            _this.$submitBtn.attr('disabled', 'disabled');
            return _this.$submitBtn.find('span.spinnerSlider').show();
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            _this.model.set(data, {
              silent: true
            });
            if (_this.isFormValid()) {
              return Immerss.userInfoReady = true;
            }
          };
        })(this),
        error: function(data, error) {
          $.showFlashMessage(data.responseText || data.statusText, {
            type: "error"
          });
          if (this.isFormValid()) {
            return Immerss.userInfoReady = true;
          }
        },
        complete: (function(_this) {
          return function() {
            _this.$submitBtn.find('span.spinnerSlider').hide();
            return _this.checkForm();
          };
        })(this)
      });
    };

    EditUserAccountModal.prototype.hide = function() {
      return this.$el.modal('hide');
    };

    return EditUserAccountModal;

  })(Forms.FormView);

}).call(this);
