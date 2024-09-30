(function () {
    'use strict';
    var LogInModalView;
    LogInModalView = Backbone.View.extend({
        el: '#loginPopup',
        social: '.soclogBlock',

        events: {
            'ajax:beforeSend form': 'beforeRequest',
            'ajax:error form': 'errorRequest',
            'click .showSocialMedia': 'hideForm',
            'click .showLoginForm': 'showForm',
            'click .showFormAgain': 'showFormAgain',
            'focus input': 'toggleFocusField',
            'focusout input': 'toggleFocusField',
            'change input': 'validateForm',
            'blur input': 'validateForm',
            'keydown input': 'validateForm',
            'keyup input': 'validateForm',
            'change #userEmail': 'processAvatar',
            'load #userEmail': 'processAvatar',
            'click .socialBtn.social_inputs': 'setAuthOriginCookie',
            'blur #userEmail': 'trimEmail',
        },

        initialize: function () {
            this.prepareForm();
            var that = this;
            that.$el.on('shown.bs.modal', function () {
                var value = that.$('#userEmail').val();
                if (value) {
                    that.fetchAvatar(value);
                }
                that.validateForm();
            });

            $('#resetPasswordPopup').on('show.bs.modal', function () {
                return that.$el.modal('hide');
            });
            return this.render();
        },


        prepareForm: function () {
            this.$('option[value=""]').each(function () {
                return $(this).attr('disabled', true);
            });
            this.validator = this.$('form').validate({
                rules: {
                    'user[email]': {
                        required: true,
                        emailImmerss: true
                    },
                    'user[password]': {
                        required: true,
                        minlength: 6,
                        maxlength: 128
                    }
                },
                ignore: '.ignore',
                focusCleanup: true,
                onclick: false,
                onkeyup: false,
                errorElement: "span",
                errorPlacement: function (error, element) {
                    return error.appendTo(element.parents('.borderedInput').find('.errorContainerWrapp')).addClass('errorContainer signInError');
                },
                highlight: function (element) {
                    return $(element).parents('.borderedInput').addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    return $(element).parents('.borderedInput').removeClass('error').addClass('valid');
                },
            });
            this.validateForm();
        },

        trimEmail: function (e) {
            var value = $(e.target).val().replace(/ +?/g, '')
            $(e.target).val('');
            $(e.target).val(value);
            $(e.target).valid();
        },

        beforeRequest: function () {
            window.disableUnobtrusiveFlash = true;
            this.$('.loginBtn').attr('disabled', true);
        },

        successRequest: function (event, xhr, status) {
            var redirect_url;
            redirect_url = xhr.location || xhr.response && xhr.response.redirect_path;
            if (redirect_url.length === 0 || window.location.href === redirect_url) {
                return window.location.reload();
            }
            return window.location.href = redirect_url;
        },

        errorRequest: function (event, xhr, status) {
            this.$('input[name="user[password]"]').val('').parents('.borderedInput').addClass('error').removeClass('valid');
            this.$('.loginBtn').attr('disabled', true).text(xhr.responseText);
        },

        validateForm: function (e) {
            if (this.validator && this.validator.checkForm()) {
                this.$('.loginBtn').removeAttr('disabled').text('Log In');
            } else {
                this.$('.loginBtn').attr('disabled', true).text('Log In');
            }
        },

        toggleFocusField: function (e) {
            $(e.currentTarget).parents('.borderedInput').toggleClass('focus-event', e.type === 'focusin');
        },

        processAvatar: function (e) {
            var char_or_backspace, value;
            if (this.$el.is(':hidden') || !this.$('form').find('#userEmail').val().length || !this.validator.check(this.$('form').find('#userEmail'))) {
                return;
            }
            char_or_backspace = e.which === 8 || e.which === 46 || e.which !== 0;
            value = this.$('#userEmail').val();
            if (value.length === 0) {
                this.showDefaultAvatar();
            } else if (char_or_backspace && value.length >= 4) {
                this.fetchAvatar(value);
            }
        },

        hideForm: function () {
            $('#loginPopup').addClass('logInWithMedia');
            return false;
        },

        showForm: function () {
            $('#loginPopup').addClass('logInWithForm');
            return false;
        },

        showFormAgain: function () {
            $('#loginPopup').removeClass('logInWithMedia');
        },

        fetchAvatar: function (email) {
            if (!email || email.length === 0)
                return;
            var that = this;
            $.ajax({
                type: 'GET',
                url: '/api/v1/public/users/fetch_avatar',
                data: {
                    'email': email
                },
                dataType: 'json',
                success: function (data, status, xhr) {
                    if (data.response.url.length) {
                        that.$('img#login_default_avatar').hide();
                        that.$('img#login_user_avatar').attr('src', data.response.url).show();
                    } else {
                        that.showDefaultAvatar();
                    }
                }
            });
        },

        showDefaultAvatar: function () {
            this.$('img#login_user_avatar').attr('src', '').hide();
            this.$('img#login_default_avatar').show();
        },
        setAuthOriginCookie: function () {
            var date = new Date();
            date.setTime(date.getTime() + (5 * 60 * 1000));
            $.cookie('social_auth_origin', 'signin', {expires: date, path: '/'});
        }
    });

    if ($('#loginPopup').length > 0)
        new LogInModalView();
}).call(this);

window.addEventListener("message", function (e) {
    var message = typeof (e.data) == 'object' ? e.data.type : e.data;
    switch (message) {
        case ('openLoginPopup'):
            window.eventHub.$emit("open-modal:auth", "login")
            // $('#loginPopup').modal('show');
            return;
    }
}, false);