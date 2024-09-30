//= require_self
+function () {
    "use strict";
    window.StudiosCalc = Backbone.View.extend({
        el: 'body.studios_calc',

        events: {
            'click .monthlyBreakdownBtn a': 'toggleBreakdown',
            'ajax:success form#lets_talk': 'clearLetsTalkForm',
            'ajax:error form#lets_talk': 'errorOnLetsTalkForm',
            'shown.bs.tab a[role=tab]': 'render',
            'change input[type=checkbox]': 'render',
            'change .ROICalc_b input[type=number]': 'render',
            'keyup .ROICalc_b input[type=number]': 'render',
            'click #schedule_demo': 'openScheduleDemo',
            'click .SeeDetailsScroll': 'SeeDetailsScroll',
            'click .LetsTalkScroll': 'LetsTalkScroll',
            'click .RevenueCalculatorScroll': 'RevenueCalculatorScroll'
        },

        initialize: function (options) {
            this.render();
            return this;
        },

        render: function () {
            this.setPlan();
            this.calcPaidMonthlyPlan();
            this.calcPaidAnnuallyPlan();
            this.updateTotalCost();
            this.updateMonthlyCost();
            this.calcAnnualizedROI();
            this.updateLetsTalkForm();
            var telInput = $("form#lets_talk input[name=phone]");
            telInput.intlTelInput({
                initialCountry: "auto",
                separateDialCode: true,
                geoIpLookup: function (callback) {
                    var cb;
                    cb = function () {
                        return null;
                    };
                    return $.get('https://ipinfo.io?token=42576d359578ce', cb, "jsonp").always(function (resp) {
                        var countryCode;
                        countryCode = resp && resp.country ? resp.country : "";
                        return callback(countryCode);
                    });
                },
                utilsScript: "/Phone-select/utils.js"
            });
            this.$('form#lets_talk').validate({
                rules: {
                    name: {
                        required: true,
                        minlength: 2,
                        maxlength: 250
                    },
                    email: {
                        emailImmerss: true,
                        required: true
                    },
                    phone: {
                        intlTelInput: true
                    }
                },
                errorElement: "span",
                focusCleanup: true,
                ignore: '',
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
            return this;
        },

        toggleBreakdown: function (e) {
            e.preventDefault();
            var hide;
            hide = this.$('.monthlyBreakdownBtn a span.show_breakdown').hasClass('hide');
            this.$('.NGS_White_section.monthlyBreakdown_table').toggleClass('hide', hide);
            this.$('.monthlyBreakdownBtn a span.hide_breakdown').toggleClass('hide', hide);
            this.$('.monthlyBreakdownBtn a span.show_breakdown').toggleClass('hide', !hide);
        },

        setPlan: function () {
            this.studio_plan = this.$('.StudioPlan .tab-pane.active').attr('plan');
        },

        getTotalCost: function () {
            if (this.studio_plan === 'monthly') {
                return this.total_paid_monthly * 12;
            } else {
                return this.total_paid_annually;
            }
        },

        getMonthlyCost: function () {
            if (this.studio_plan === 'monthly') {
                return this.total_paid_monthly;
            } else {
                return this.total_paid_annually / 12;
            }
        },

        calcPaidMonthlyPlan: function () {
            this.total_paid_monthly = 0.0;
            _.each(this.$('#PaidMonthly input[type=checkbox]:checked'), (function (_this) {
                return function (input) {
                    return _this.total_paid_monthly += parseFloat($(input).val());
                };
            })(this));
            this.$('#PaidMonthly .TotalCharge em.cost').html(this.formatCurrency(this.total_paid_monthly));
        },

        calcPaidAnnuallyPlan: function () {
            this.total_paid_annually = 0.0;
            _.each(this.$('#PaidAnnually input[type=checkbox]:checked'), (function (_this) {
                return function (input) {
                    return _this.total_paid_annually += parseFloat($(input).val());
                };
            })(this));
            this.$('#PaidAnnually .TotalCharge em.cost').html(this.formatCurrency(this.total_paid_annually));
        },

        calcAnnualizedROI: function () {
            this.single_classes_count = parseInt(this.$('.ROICalc_b input[name=single_classes_count]').val() || 0);
            this.single_classes_cost = parseFloat(this.$('.ROICalc_b input[name=single_classes_cost]').val() || 0);
            this.individual_sessions_revenue = this.single_classes_count * this.single_classes_cost * 0.7;
            this.new_subscriptions_count = parseInt(this.$('.ROICalc_b input[name=new_subscriptions_count]').val() || 0);
            this.new_subscriptions_cost = parseFloat(this.$('.ROICalc_b input[name=new_subscriptions_cost]').val() || 0);
            this.subscribers_revenue = this.new_subscriptions_count * this.new_subscriptions_cost * 0.7;
            this.updateMonthlyEarnings();
        },

        updateTotalCost: function () {
            this.$('.your_total_cost').html(this.formatCurrency(this.getTotalCost()));
        },

        updateMonthlyCost: function () {
            this.$('.your_monthly_cost').html(this.formatCurrency(this.getMonthlyCost()));
        },

        updateTotalEarnings: function () {
            this.$('.your_total_earnings').html(this.formatCurrency(this.total_earnings));
            this.$('.sessions_monthly_revenue').html(this.formatCurrency(this.individual_sessions_revenue));
            this.$('.subscriptions_monthly_revenue').html(this.formatCurrency(this.subscribers_revenue));
        },

        updateMonthlyEarnings: function () {
            this.total_earnings = 0.0;
            _.each(this.$('.your_monthly_earnings'), (function (_this) {
                return function (td) {
                    var value;
                    value = parseInt($(td).data('month')) * _this.subscribers_revenue + _this.individual_sessions_revenue;
                    _this.total_earnings += value;
                    return $(td).html(_this.formatCurrency(value));
                };
            })(this));
            this.updateTotalEarnings();
        },

        updateLetsTalkForm: function () {
            this.$('form#lets_talk input[name=plan]').val(this.studio_plan);
            this.$('form#lets_talk input[name=configured_autonomous_camera]').val(this.$(".tab-pane[plan=" + this.studio_plan + "] input[name=configured_autonomous_camera]").prop('checked'));
            this.$('form#lets_talk input[name=multi_instructor_capability]').val(this.$(".tab-pane[plan=" + this.studio_plan + "] input[name=multi_instructor_capability]").prop('checked'));
            this.$('form#lets_talk input[name=single_classes_count]').val(this.$(".ROICalc_b input[name=single_classes_count]").val());
            this.$('form#lets_talk input[name=single_classes_cost]').val(this.$(".ROICalc_b input[name=single_classes_cost]").val());
            this.$('form#lets_talk input[name=new_subscriptions_count]').val(this.$(".ROICalc_b input[name=new_subscriptions_count]").val());
            this.$('form#lets_talk input[name=new_subscriptions_cost]').val(this.$(".ROICalc_b input[name=new_subscriptions_cost]").val());
        },

        formatCurrency: function (value) {
            return "$" + (value.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,").toString());
        },

        clearLetsTalkForm: function (e) {
            $.showFlashMessage(I18n.t('assets.javascripts.studio.clear_lets_talk_form_success'), {type: 'success', timeout: 5000});
            this.$('form#lets_talk')[0].reset();
            this.$('form#lets_talk .input-block').addClass('state-clear');
        },

        errorOnLetsTalkForm: function (e) {
            $.showFlashMessage('Error on form submitting.', {type: 'alert'});
        },

        openScheduleDemo: function (e) {
            var schedule_url;
            e.preventDefault();
            schedule_url = this.$('#schedule_demo').attr('href');
            window.open(schedule_url, 'Schedule a demo', "width=" + (parseInt(screen.width - screen.width * 0.5)) + ", height=" + (parseInt(screen.height - screen.height * 0.5)) + ", resizable=yes, top=" + (parseInt(screen.height * 0.1 / 2)) + ", left=" + (parseInt(screen.width * 0.1 / 2)) + ", scrollbars=yes, status=no, menubar=no, toolbar=no, location=no, directories=no");
        },

        SeeDetailsScroll: function (e) {
            e.preventDefault();
            this.scrollingTo(this.$('.SeeDetailsScroll_target')[0]);
        },

        LetsTalkScroll: function (e) {
            e.preventDefault();
            this.scrollingTo(this.$('.LetsTalkScroll_target')[0]);
        },

        RevenueCalculatorScroll: function (e) {
            e.preventDefault();
            this.scrollingTo(this.$('.RevenueCalculatorScroll_target')[0]);
        },

        scrollingTo: function (element) {
            $([document.documentElement, document.body]).animate({
                scrollTop: this.$(element).offset().top - 170
            }, 2000);
        },
    });
}();
