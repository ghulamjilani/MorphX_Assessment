(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.FormView = (function(superClass) {
    extend(FormView, superClass);

    function FormView() {
      return FormView.__super__.constructor.apply(this, arguments);
    }

    FormView.prototype.validateForm = function(settings, custom_form, custom_btn) {
      var $btn, $defaults, $form, $this;
      if (custom_form == null) {
        custom_form = false;
      }
      if (custom_btn == null) {
        custom_btn = false;
      }
      $this = this;
      $form = custom_form || this.$form;
      $btn = custom_btn || this.$submitBtn;
      $defaults = {
        rules: {},
        errorElement: "span",
        ignore: '',
        onkeyup: (function(_this) {
          return function() {
            return _this.checkForm();
          };
        })(this),
        onclick: false,
        focusCleanup: true,
        errorPlacement: function(error, element) {
          return error.appendTo(element.parents('.input-block, .select-block').find('.errorContainerWrapp')).addClass('errorContainer');
        },
        highlight: function(element) {
          var wrapper;
          wrapper = $(element).parents('.input-block, .select-block');
          return wrapper.addClass('error').removeClass('valid');
        },
        unhighlight: function(element) {
          var wrapper;
          wrapper = $(element).parents('.input-block, .select-block');
          return wrapper.removeClass('error').addClass('valid');
        },
        showErrors: function(errorMap, errorList) {
          this.defaultShowErrors();
          return $this.checkForm();
        }
      };
      $.extend($defaults, settings);
      $form.validate($defaults);
      if ($btn) {
        $form.on('validation:remote:start', (function(_this) {
          return function() {
            return $btn.attr('disabled', true).addClass('disabled');
          };
        })(this));
      }
      if (this.$form === $form) {
        this.validator = this.$form.data('validator');
      }
    };

    FormView.prototype.checkForm = function() {
      if (!this.validator) {
        return;
      }
      if (this.isFormValid()) {
        return this.$submitBtn.removeAttr('disabled').removeClass('disabled');
      } else {
        return this.$submitBtn.attr('disabled', true).addClass('disabled');
      }
    };

    FormView.prototype.isFormValid = function() {
      return this.validator.isValid();
    };

    FormView.prototype.isElementValid = function(el) {
      return this.validator.check(el);
    };

    FormView.prototype.checkAndCount = function(element) {
      if (this.validator && $(element).parents('.input-block').find('.counter_block').length > 0) {
        if (this.isElementValid(element)) {
          $(element).parents('.input-block').find('.counter_block').removeClass('error');
        } else {
          $(element).parents('.input-block').find('.counter_block').addClass('error');
        }
      }
      return Forms.Helpers.setCount(element);
    };

    FormView.prototype.prepareInputs = function() {
      this.$('.input-block').find('input[type=text], textarea').on('blur', function() {
        return Forms.Helpers.formatInput(this);
      });
      $.each(this.$('.input-block textarea[data-autoresize]'), (function(_this) {
        return function(i, element) {
          Forms.Helpers.resizeTextarea(element);
          Forms.Helpers.setCount(element);
          return $(element).removeAttr('data-autoresize');
        };
      })(this));
      $.each(this.$('.input-block input.with_counter'), (function(_this) {
        return function(i, element) {
          return Forms.Helpers.setCount(element);
        };
      })(this));
      this.$('.input-block textarea, .input-block input.with_counter').on('keydown keyup focus blur change', (function(_this) {
        return function(e) {
          return _this.checkAndCount(e.target);
        };
      })(this));
    };

    FormView.prototype.setupTags = function(placeholder) {
      var setTagsCount;
      placeholder || (placeholder = "Add tags");
      setTagsCount = function(el) {
        var count;
        count = $(el).tagit('assignedTags').length;
        return $(el).parents('.input-block').find('.counter_block').html(count + "/20");
      };
      $.each(this.$('.tag'), function() {
        $(this).tagit({
          placeholderText: placeholder,
          allowSpaces: true,
          tagLimit: 20,
          beforeTagAdded: function(e, ui) {
            if (ui.tagLabel.length < 2 || ui.tagLabel.length > 100) {
              $(e.target).parents('.tag_list_wrapp').find('input.ui-autocomplete-input').effect('highlight', {
                color: 'rgba(255,40,40,0.1)'
              });
              return false;
            }
          },
          afterTagAdded: function(e, ui) {
            if (ui.tagLabel.length < 2 || ui.tagLabel.length > 100) {
              $(e.target).effect('highlight');
              return $(ui.tag).effect('highlight').addClass('error');
            }
          }
        });
        return setTagsCount(this);
      });
      this.$('.tag').on('change', function() {
        return setTagsCount(this);
      });
      return this.$('input.ui-autocomplete-input').on('focusout', function() {
        return $(this).parents('.input-block').removeClass('event-focus');
      });
    };

    FormView.prototype.setupTagline = function() {
      $.each(this.$('.tagline'), (function(_this) {
        return function(i, element) {
          return Forms.Helpers.setCount(element);
        };
      })(this));
      return this.$('.tagline').on('keyup', (function(_this) {
        return function(e) {
          _this.checkAndCount(e.target);
          return Forms.Helpers.setCount(e.target);
        };
      })(this));
    };

    FormView.prototype.clearForm = function() {
      this.$form[0].reset();
      this.validator.resetForm();
      $.each(this.$form.find('.input-block'), function(i, element) {
        if ($(element).find('input:blank:not([placeholder])').length > 0) {
          return $(element).addClass('state-clear');
        }
      });
      this.$form.find('.input-block').removeClass('valid error');
      this.$form.find('.input-block').find('input, textarea').removeClass('valid');
      $.each(this.$form.find('.input-block').find('.with_counter, textarea'), (function(_this) {
        return function(i, element) {
          return _this.checkAndCount(element);
        };
      })(this));
      return autosize.update(this.$form.find('.input-block textarea'));
    };

    return FormView;

  })(Backbone.View);

  _.extend(Forms.FormView, Forms.Mixins);

}).call(this);
