(function () {
    var extend = function (child, parent) {
            for (var key in parent) {
                if (hasProp.call(parent, key)) child[key] = parent[key];
            }

            function ctor() {
                this.constructor = child;
            }

            ctor.prototype = parent.prototype;
            child.prototype = new ctor();
            child.__super__ = parent.prototype;
            return child;
        },
        hasProp = {}.hasOwnProperty;

    (function () {
        'use strict';
        var AlmostDoneModalView;
        AlmostDoneModalView = (function (superClass) {
            extend(AlmostDoneModalView, superClass);

            function AlmostDoneModalView() {
                return AlmostDoneModalView.__super__.constructor.apply(this, arguments);
            }

            AlmostDoneModalView.prototype.el = '#almostDoneModal';

            AlmostDoneModalView.prototype.events = {
                'ajax:beforeSend form': 'beforeRequest',
                'ajax:success form': 'successRequest',
                'ajax:error form': 'errorRequest',
                'focus input, select': 'toggleFocusField',
                'focusout input, select': 'toggleFocusField',
                'change input, select': 'validateForm',
                'blur input:not(.birthday_date), select': 'validateForm',
                'click .birthday_date_icon': 'birthday_date_icon_click',
                'focus #user_password': 'focusPassword',
                'blur #user_password': 'blurPassword',
                'input input.strength-password': 'validatePassword',
                'keydown input': 'validateForm',
                'keyup input': 'validateForm'
            };

            AlmostDoneModalView.prototype.initialize = function () {
                this.prepareForm();
                this.initDatepicker();
                this.validateForm();
                return this.render();
            };

            AlmostDoneModalView.prototype.prepareForm = function () {
                this.$('option[value=""]').each(function () {
                    return $(this).attr('disabled', true);
                });
                this.$('.birthday > .form-control').removeClass('form-control');
                this.validator = this.$('form#almost_done_user').validate({
                    rules: {
                        'user[email]': {
                            emailImmerss: true,
                            required: true,
                            remote: '/remote_validations/user_email'
                        },
                        'user[password]': {
                            strengthPassword: true
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
                        'birthdate': {
                            birthdate: true,
                            required: true
                        }
                    },
                    messages: {
                        'user[email]': {
                            remote: 'This email is already in use.'
                        }
                    },
                    ignore: '.ignore',
                    focusCleanup: true,
                    onclick: false,
                    onkeyup: false,
                    errorPlacement: function (error, element) {
                        return false;
                    },
                    showErrors: function (errorMap, errorList) {
                        $.each(errorList, function (index, value) {
                            if($(value.element).hasClass('strength-password')){ return }
                            return $(value.element).parents('.borderedInput').attr('data-content', value.message);
                        });
                        return this.defaultShowErrors();
                    },
                    highlight: function (element) {
                        if($(element).hasClass('strength-password')){ return }
                        if ($(element).hasClass('birthday_date') && $('.ui-datepicker-calendar').is(':visible')) {
                            return;
                        }
                        return $(element).parents('.borderedInput').addClass('error').removeClass('valid').popover('show');
                    },
                    unhighlight: function (element) {
                        return $(element).parents('.borderedInput').removeClass('error').addClass('valid').popover('hide');
                    }
                });
                if (this.$('form#almost_done_user').is(':visible')) {
                    this.validateForm();
                }
            };

            AlmostDoneModalView.prototype.showHiddenInputs = function (e) {
                var $wrap;
                $wrap = $(e.target).parents('.borderedInput');
                if ($wrap.find('a.borderedInput-title').is(':hidden')) {
                    return;
                }
                $wrap.find('a.borderedInput-title').hide().nextAll('.borderedInput-hidenBox').eq(0).show();
            };

            AlmostDoneModalView.prototype.beforeRequest = function () {
                window.disableUnobtrusiveFlash = true;
                this.$('.submitBtn').attr('disabled', true);
            };

            AlmostDoneModalView.prototype.successRequest = function (event, xhr, status) {
                window.location.reload();
            };

            AlmostDoneModalView.prototype.errorRequest = function (event, xhr, status) {
                var errors;
                if (xhr.responseJSON && xhr.responseJSON.response) {
                    errors = xhr.responseJSON.response.errors;
                }
                if (errors) {
                    return $.each(errors, (function (_this) {
                        return function (key, value) {
                            var $el;
                            if (key === 'birthdate') {
                                key = 'birthdate(3i)';
                            }
                            $el = _this.validator.findByName("user[" + key + "]").parents('.borderedInput');
                            $el.attr('data-content', value);
                            return $el.addClass('error').removeClass('valid').popover('show');
                        };
                    })(this));
                }
            };

            AlmostDoneModalView.prototype.validateForm = function () {
                if (this.$('form#almost_done_user').is(':visible') && this.validator && this.validator.checkForm()) {
                    this.$('.submitBtn').removeAttr('disabled').text('Submit');
                } else {
                    this.$('.submitBtn').attr('disabled', true).text('Fill the form to proceed');
                }
            };

            AlmostDoneModalView.prototype.toggleFocusField = function (e) {
                $(e.currentTarget).parents('.borderedInput').toggleClass('focus-event', e.type === 'focusin');
            };

            AlmostDoneModalView.prototype.focusPassword = function (e) {
                if (!this.isPasswordValid) {
                    this.$('.password-Strength-2-tooltip').show()
                }
            };
            
            AlmostDoneModalView.prototype.blurPassword = function (e) {
                this.$('.password-Strength-2-tooltip').hide()
            };

            AlmostDoneModalView.prototype.validatePassword = function (e) {
                calculatePasswordStrength(this.el);
            };

            AlmostDoneModalView.prototype.birthday_date_icon_click = function () {
                this.$('#birthday_date').datepicker("show");
            };

            AlmostDoneModalView.prototype.initDatepicker = function () {
                this.$('#birthday_date').datepicker({
                    showOn: 'focus',
                    dateFormat: 'dd MM yy',
                    minDate: '-90Y',
                    maxDate: '-13Y',
                    yearRange: '-90:-13',
                    changeYear: true,
                    changeMonth: true,
                    onSelect: (function (_this) {
                        return function () {
                            var date;
                            date = _this.$('#birthday_date').datepicker('getDate');
                            _this.$('[name="user[birthdate(1i)]"]').val(date.getFullYear());
                            _this.$('[name="user[birthdate(2i)]"]').val(date.getMonth() + 1);
                            _this.$('[name="user[birthdate(3i)]"]').val(date.getDate());
                            _this.validateForm();
                            return _this.$('#birthday_date').valid();
                        };
                    })(this)
                });
                return this.$('button.ui-datepicker-trigger').hide();
            };

            return AlmostDoneModalView;

        })(Backbone.View);
        return $(function () {
            if ($('#almostDoneModal').length > 0) {
                return new AlmostDoneModalView();
            }
        });
    })();

}).call(this);
