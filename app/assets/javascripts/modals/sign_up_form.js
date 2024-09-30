(function () {
    'use strict';
    var SignUpModalView;
    SignUpModalView = Backbone.View.extend({
        el: '#signupPopup',
        events: {
            'click a.borderedInput-title': 'showHiddenInputs',
            'click .showSignUpFormAgain': 'showSignUpFormAgain',
            'click .showSocialMediaAgain': 'showMediaAgain',
            'ajax:beforeSend form': 'beforeRequest',
            'ajax:success form': 'successRequest',
            'ajax:error form': 'errorRequest',
            'focus input, select': 'toggleFocusField',
            'focusout input, select': function (e) {
                this.toggleFocusField(e);
                this.validateForm(e);
            },
            'change input, select': 'validateForm',
            'blur input:not(.birthday_date), select': 'validateForm',
            'click .birthday_date_icon': 'birthday_date_icon_click',
            'keydown input': 'validateForm',
            'keyup input': 'validateForm',
            'click .socialBtn.social_inputs': 'setAuthOriginCookie',
            'focus #user_password': 'focusPassword',
            'blur #user_password': 'blurPassword',
            'blur [name*=email]': 'trimEmail'
        },

        initialize: function () {
            this.isPasswordValid = false;
            this.submit_text = $('#signupPopup .signupBtn').text();
            this.prepareForm();
            this.initDatepicker();
            var that = this;
            $('#resetPasswordPopup').on('show.bs.modal', function () {
                that.$el.modal('hide')
            })
            this.render();
            if(location.pathname === "/users/invitation/accept") {
                this.showSignUpFormAgain()
            }
            return this
        },

        trimEmail: function (e) {
            var value = $(e.target).val().replace(/ +?/g, '')
            $(e.target).val('');
            $(e.target).val(value);
            $(e.target).valid();
        },

        showSignUpFormAgain: function () {
            $('#signupPopup').removeClass('signUpWithMedia');
            $('#signupPopup').addClass('signUpWithEmail');
            this.validateForm();
        },

        showMediaAgain: function () {
            $('#signupPopup').removeClass('signUpWithEmail');
            $('#signupPopup').addClass('signUpWithMedia');
            return false;
        },

        prepareForm: function () {
            this.$('option[value=""]').each(function () {
                return $(this).attr('disabled', true);
            });
            this.$('.birthday > .form-control').removeClass('form-control');
            this.validator = this.$('form#new_user').validate({
                rules: {
                    'user[first_name]': {
                        required: true,
                        minlength: 2,
                        maxlength: 50,
                        regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\\s.\'\"\`\-]+$'
                    },
                    'user[last_name]': {
                        required: true,
                        minlength: 2,
                        maxlength: 50,
                        regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\\s.\'\"\`\-]+$'
                    },
                    'user[birthdate(1i)]': {
                        required: true
                    },
                    'user[birthdate(2i)]': {
                        required: true
                    },
                    'user[birthdate(3i)]': {
                        required: true
                    },
                    'user[birthdate]': {
                        birthdate: true,
                        required: true
                    },
                    'user[gender]': {
                        required: true
                    },
                    'user[email]': {
                        emailImmerss: true,
                        required: true,
                        remote: '/remote_validations/user_email'
                    }
                },
                messages: {
                    'user[email]': {
                        remote: 'This email is already in use.'
                    }
                },
                ignore: '.ignore',
                focusCleanup: false,
                focusInvalid: true,
                errorElement: "span",
                errorPlacement: function (error, element) {
                    return error.appendTo(element.parents('.borderedInput').find('.errorContainerWrapp')).addClass('errorContainer signUpError');
                },
                highlight: function (element) {
                    return $(element).parents('.borderedInput').addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    return $(element).parents('.borderedInput').removeClass('error').addClass('valid');
                }
            });
            if (this.$('form#new_user').is(':visible')) {
                return this.validateForm();
            }
        },

        showHiddenInputs: function (e) {
            var $wrap;
            $wrap = $(e.target).parents('.borderedInput');
            if ($wrap.find('a.borderedInput-title').is(':hidden')) {
                return;
            }
            return $wrap.find('a.borderedInput-title').hide().nextAll('.borderedInput-hidenBox').eq(0).show();
        },

        focusPassword: function (e) {
            if (!this.isPasswordValid) {
                this.$('.password-Strength-2-tooltip').show()
            }
        },

        blurPassword: function (e) {
            this.$('.password-Strength-2-tooltip').hide()
        },

        validatePassword() {
            this.isPasswordValid = calculatePasswordStrength(this.el)
        },

        beforeRequest: function () {
            window.disableUnobtrusiveFlash = true;
            this.$('.signupBtn').attr('disabled', true);
        },

        successRequest: function (event, xhr, status) {
            var redirect_url;
            redirect_url = xhr.location || xhr.redirect_path || xhr.response.redirect_path;
            if (redirect_url.length === 0 || window.location.href === redirect_url) {
                return window.location.reload();
            }
            window.location.href = redirect_url;
        },

        errorRequest: function (event, xhr, status) {
            var errors;
            if (xhr.responseJSON && xhr.responseJSON.response) {
                errors = xhr.responseJSON.response.errors;
            } else if (xhr.responseText) {
                errors = xhr.responseText
            }

            if (typeof errors == 'string') {
                $.showFlashMessage(errors, {
                    type: 'error',
                    timeout: 5000
                });
            } else if (typeof errors == 'object') {
                var that = this;
                $.each(errors, (function (key, value) {
                    var $el;
                    if (key === 'birthdate') {
                        key = 'birthdate(3i)';
                    }
                    $el = that.validator.findByName("user[" + key + "]").parents('.borderedInput');
                    $el.attr('data-content', value);
                    $el.addClass('error').removeClass('valid').popover('show');
                }));
            }
        },

        validateForm: function (e) {
            this.validatePassword()
            if (this.$('form#new_user').is(':visible') && this.validator && this.validator.checkForm() &&
                this.isPasswordValid) {
                this.$('.signupBtn').removeAttr('disabled').text(this.submit_text);
            } else {
                this.$('.signupBtn').attr('disabled', true).text(this.submit_text);
            }
        },

        toggleFocusField: function (e) {
            $(e.currentTarget).parents('.borderedInput').toggleClass('focus-event', e.type === 'focusin');
            return false;
        },

        birthday_date_icon_click: function (e) {
            this.$('#birthday_date').datepicker("show");
            return false;
        },

        initDatepicker: function () {
            var that = this;
            this.$('#birthday_date').datepicker({
                showOn: 'focus',
                dateFormat: 'dd MM yy',
                minDate: '-90Y',
                maxDate: '-13Y',
                yearRange: '-90:-13',
                changeYear: true,
                changeMonth: true,
                onSelect: function () {
                    var date;
                    date = that.$('#birthday_date').datepicker('getDate');
                    that.$('[name="user[birthdate(1i)]"]').val(date.getFullYear());
                    that.$('[name="user[birthdate(2i)]"]').val(date.getMonth() + 1);
                    that.$('[name="user[birthdate(3i)]"]').val(date.getDate());
                    that.$('#birthday_date').valid();
                },
                beforeShow: function(input, inst) {
                    $(document).off('focusin.bs.modal');
                },
                onClose: () => {
                    $(document).on('focusin.bs.modal');
                    this.validateForm();    
                },
            });
            this.$('button.ui-datepicker-trigger').hide();
        },
        setAuthOriginCookie: function () {
            var date = new Date();
            date.setTime(date.getTime() + (5 * 60 * 1000));
            $.cookie('social_auth_origin', 'signup', {expires: date, path: '/'});
        }
    });
    $(function () {
        if ($('#signupPopup').length > 0)
            new SignUpModalView();
        var timestamp;
        timestamp = moment().tz(Intl.DateTimeFormat().resolvedOptions().timeZone).format('Z');
        if (timestamp) {
            $.cookie('tzinfo', timestamp);
            return $('[name="user[tzinfo]"]').val(timestamp);
        }
    });
}).call(this);
