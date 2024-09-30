(function() {
  $(function() {
    var forgotPassBtn, forgotPassForm, forgotPassFormValidate;
    forgotPassForm = $("#resetPasswordForm");
    if (forgotPassForm.length > 0) {
      forgotPassBtn = $("#resetPasswordForm .resetPasswordBtn");

      forgotPassFormValidate = forgotPassForm.validate({
        rules: {
          "user[email]": {
            required: true,
            emailImmerss: true
          }
        },
        errorElement: 'span',
        errorPlacement: function(error, element) {
          forgotPassBtn.attr('disabled', true);
          return error.appendTo(element.parents('.borderedInput').find('.errorContainerWrapp')).addClass('errorContainer');
        },
        highlight: function(element) {
          return $(element).parents('.borderedInput').addClass('error').removeClass('valid');
        },
        unhighlight: function(element) {
          return $(element).parents('.borderedInput').removeClass('error').addClass('valid');
        },
      });
      forgotPassForm.on("ajax:beforeSend", function() {
        return forgotPassBtn.attr('disabled', true);
      });
      forgotPassForm.on("ajax:success", function() {
        $("#resetPasswordForm #user_email").val('');
        return $.showFlashMessage("You will receive an email with instructions on how to reset your password in a few minutes.", {
          type: "success"
        });
      });
      forgotPassForm.on("ajax:error", function(event, xhr, status) {
        var errors;
        $('#resetPasswordForm input[name="user[email]"]').parents('.borderedInput').addClass('error').removeClass('valid');
        if (xhr.status === 422) {
          errors = _(xhr.responseJSON.errors).inject(function(res, value, key) {
            key = key[0].toUpperCase() + key.substring(1);
            res.push(key + " " + value[0]);
            return res;
          }, []);
          $("#resetPasswordForm #user_email").attr('data-content', errors.join("<br/>"));
        } else {
          $("#resetPasswordForm #user_email").attr('data-content', "Internal server error");
        }
        return forgotPassBtn.attr('disabled', true).text(errors);
      });

      $('#resetPasswordForm input').bind('keyup', function() {
        if (forgotPassFormValidate.isValid()) {
          return forgotPassBtn.removeAttr('disabled').text('Send reset link');
        } else {
          return forgotPassBtn.attr('disabled', true).text('Send reset link');
        }
      });
    }

    var resetPasswordForm = $("#reset_password_form");
    var resetPasswordBtn;
    if (resetPasswordForm.length > 0) {
      resetPasswordBtn = $("#reset_password_form").find('#user_submit_action');

      var container = $('.users-passwords-edit #reset_password_form');
      var isPasswordValid = false;
      var passwordEl = container.find('.strength-password');

      passwordEl.on('input', function() {
        isPasswordValid = calculatePasswordStrength(container);
      })

      passwordEl.on('focus', function() {
          if(!isPasswordValid){
              container.find('.password-Strength-2-tooltip').show();   
          }
      })

      passwordEl.on('blur', function() {
          container.find('.password-Strength-2-tooltip').hide();
      })

      resetPasswordFormValidate = $("#reset_password_form").validate({
        rules: {
          'user[password]': {
            required: true
          },
          'user[password_confirmation]': {
            equalTo: '#user_password'
          }
        },
        errorElement: 'span',
        errorPlacement: function(error, element) {
          return error.appendTo(element.parents('.borderedInput').find('.errorContainerWrapp')).addClass('errorContainer');
        },
        highlight: function(element) {
          return $(element).parents('.borderedInput').addClass('error').removeClass('valid');
        },
        unhighlight: function(element) {
          return $(element).parents('.borderedInput').removeClass('error').addClass('valid');
        },
        showErrors: function (errorMap, errorList) {
          return this.defaultShowErrors();
        }
      });

      $(document).on('change input focusout', '#reset_password_form input', function () {
        if (resetPasswordFormValidate.isValid() && isPasswordValid) {
          resetPasswordBtn.removeAttr('disabled');
        } else {
          resetPasswordBtn.attr('disabled', true);
          resetPasswordFormValidate.showErrors();
        }
      });
    }
  });

}).call(this);
