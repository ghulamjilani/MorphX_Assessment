(function () {
    if ($('body').hasClass('profiles-edit_public')) {
        window.profile_form_validator = $('#edit_profile').validate({
            rules: {
                'profile[custom_slug_value]': {
                    regex: '^[A-Za-z0-9][A-Za-z0-9-]+'
                },
                'profile[user_account_attributes][bio]': {
                    minlength: 16,
                    maxlength: 2000
                }
            },
            errorElement: 'span',
            ignore: '.ignore',
            onclick: false,
            focusout: true,
            focusCleanup: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block, .select-tag-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block, .select-tag-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block, .select-tag-block');
                return wrapper.removeClass('error').addClass('valid');
            },
            showErrors: function (errorMap, errorList) {
                return this.defaultShowErrors();
            }
        });

        $(document).on('focusout', '#edit_profile input[type=text], #edit_profile textarea', function () {
            Forms.Helpers.formatInput(this);
            Forms.Helpers.setCount(this);
            if (!profile_form_validator.isValid())
                profile_form_validator.showErrors();
        });
    }
    $(".combined_notification").change(function (e) {
        var $toggleBlock;
        $toggleBlock = $("#notification_controls");
        if ($(this).is(":checked")) {
            $toggleBlock.show();
        } else {
            $toggleBlock.hide();
        }
    });
    
    $("input[type=radio][name*=everytime]").change(function (e) {
      if (this.value == "false") {
          $(".sentNotifTimesInput").removeClass("disabled");
          $("input[type=radio][name*=frequency][value=day]").prop("checked", true);
      }
      else {
          $(".sentNotifTimesInput").addClass("disabled");
          $("input[type=radio][name*=frequency]").prop("checked", false);
      }
    });

    if ($('body.profiles-edit_application, body.profiles-update_application').length > 0) {
        var container = $('.profiles-edit_application #edit_profile, .profiles-update_application #edit_profile');
        var isPasswordValid = false;
        passwordEl = container.find('.strength-password');

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
        
        window.profile_form_validator = $('#edit_profile').validate({
            rules: {
                'profile[current_password]': {
                    required: function () {
                        return $('input[name="profile[password]"]').val().length > 0
                    }
                },
                'profile[password]': {
                    strengthPassword: function () {
                        return $('input[name="profile[password]"]').val().length > 0
                    }
                },
                'profile[password_confirmation]': {
                    equalTo: '#profile_password'
                }
            },
            errorElement: 'span',
            ignore: '.ignore',
            onclick: false,
            focusout: true,
            focusCleanup: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.borderedInput, .select-tag-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.borderedInput, .select-tag-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.borderedInput, .select-tag-block');
                return wrapper.removeClass('error').addClass('valid');
            },
            showErrors: function (errorMap, errorList) {
                return this.defaultShowErrors();
            }
        });
        $(document).on('focusout', '#edit_profile input[type=password]', function () {
            if (!profile_form_validator.isValid()){
                profile_form_validator.showErrors();
            }
        });
    }
    if ($('body').hasClass('profiles-edit_general')) {
        $(document).ready(function () {
            $('#birthday_date_general').datepicker({
                showOn: 'focus',
                dateFormat: 'dd MM yy',
                minDate: '-90Y',
                maxDate: '-13Y',
                yearRange: '-90:-13',
                changeYear: true,
                changeMonth: true,
                onSelect: function () {
                    var date;
                    date = $('#birthday_date_general').datepicker('getDate');
                    $('[name="profile[birthdate(1i)]"]').val(date.getFullYear());
                    $('[name="profile[birthdate(2i)]"]').val(date.getMonth() + 1);
                    $('[name="profile[birthdate(3i)]"]').val(date.getDate());
                    return $('#birthday_date_general').valid();
                }
            });
        });
        $('#edit_profile input[name*="name"], #birthday_date_general, #phone-country').after('<div class="errorContainerWrapp" style="position:absolute"></div>')
        window.profile_form_validator = $('#edit_profile').validate({
            rules: {
                'profile[first_name]': {
                    required: true,
                        minlength: 2,
                        maxlength: 50,
                        regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞßïÏ][A-Za-zА-Яа-яÄäÖöÜüẞßïÏ0-9\\s.\']+'
                },
                'profile[last_name]': {
                    required: true,
                    minlength: 2,
                    maxlength: 50,
                    regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞßïÏ][A-Za-zА-Яа-яÄäÖöÜüẞßïÏ0-9\\s.\']+'
                },
                'profile[display_name]': {
                    required: true,
                    minlength: 2,
                    maxlength: 50,
                    regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞßïÏ][A-Za-zА-Яа-яÄäÖöÜüẞßïÏ0-9\\s.\']+'
                },
                'country': {
                    required: true
                }
            },

            errorElement: 'span',
            ignore: '.ignore',
            onclick: false,
            focusout: true,
            focusCleanup: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.custom-input').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.custom-input');
                if(element.tagName == 'INPUT' && element.hasAttribute('name') && element.getAttribute('name').includes('name','birthdate', 'country')){
                  element.setAttribute("style", "color:#F23535; border-bottom: 1px solid #F23535;");
                };
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.custom-input');
                if(element.tagName == 'INPUT' && element.hasAttribute('name') && element.getAttribute('name').includes('name','birthdate', 'country')){
                  element.setAttribute("style", "color: var(--tp__secondary); border-bottom: 1px solid var(--border__separator);");
                };
                return wrapper.removeClass('error').addClass('valid');
            },
            showErrors: function (errorMap, errorList) {
                return this.defaultShowErrors();
            }
          });
        $(document).on('focusout', '#edit_profile input[type=text], select', function () {
            if (!profile_form_validator.isValid())
                profile_form_validator.showErrors();
        });
    }
    if ($('form').hasClass('edit_contacts')) {
        window.profile_form_validator = $('#new_user').validate({
            rules: {
                'user[email]': {
                    emailImmerss: true,
                    required: true,
                }
            },
            errorElement: 'span',
            ignore: '.ignore',
            focusCleanup: false,
            focusInvalid: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.removeClass('error').addClass('valid');
            }
        });
    }
}).call(this);
