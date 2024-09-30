+function (window) {
    'use strict';
    var ServiceSubscriptionsPaymentModalView = Backbone.View.extend({
        events: {
            'shown.bs.tab a[data-target="#Payment_PayPal"]': 'preparePaypal',
            'shown.bs.tab a[data-target="#Payment_AddCreditCard"]': 'prepareStripeForm',
            'shown.bs.tab a[data-target="#Payment_SystemCredit"]': 'prepareSysCreditForm',
            'change #stripe_card': 'checkTaxByCardZipCode',
            'click a#add_card': 'showAddCardForm',
            'submit form#payment-form': 'submitStripeForm',
            'change #card_country': 'setupStripeZipCode',
            'change #zip_code': 'checkStripeTaxByZipCode',
            'keyup #zip_code': 'checkStripeTaxByZipCode',
            'change #paypal_country': 'setupPayPalZipCode',
            'change #paypal_zip_code': 'checkPaypalTaxByZipCode',
            'keyup #paypal_zip_code': 'checkPaypalTaxByZipCode',
            'click .apply_coupon': 'applyCoupon',
            'focus input.coupon': 'clearCouponError',
            'click .serchEmailWrapp button': 'checkEmail',
            'change .serchEmailWrapp #EmailForGift': 'checkEmailPresence',
            'keyup #EmailForGift': 'clearRecipientError'
        },
        initialize: function (options) {
            this.stripe_key = options.stripe_key;
            this.subscription_id = options.subscription_id;
            this.amount = parseFloat(options.amount / 100.0);
            this.tax = 0.0;
            this.discount = 0.0;
            this.coupon = {};
            this.country = '';
            this.zip_code = 0;
            this.total = this.amount - this.discount + this.tax;
            var that = this;
            $('#joybee_subscription_modal').on('hide.bs.modal', function () {
                return that.undelegateEvents();
            });
            this.render();
            return this;
        },
        render: function () {
            this.stripe_form = this.$('#payment-form');
            this.cards_form = this.$('#payment-form-existing-card');
            this.paypal_form = this.$('#paypal_payment_form');
            this.prepareStripeForm();
        },
        showAddCardForm: function (e) {
            this.cards_form.addClass('hidden');
            this.setupStripeValidator();
            this.setupStripeZipCode();
            this.stripe_form.removeClass('hidden').css('visibility', 'visible');
            this.setupStripe();
            this.country = this.stripe_form.find('#card_country').val();
            this.zip_code = this.stripe_form.find('#zip_code').val();
            this.calcTax();
            this.updateTotal();
        },
        setupStripeZipCode: function () {
            if (this.stripe_form.find('#card_country').val() === 'US') {
                this.stripe_form.find('#zip_code_block').show();
                this.stripe_form.find('#card_country').parents('.country_col').removeClass('col-md-12').addClass('col-md-6');
            } else {
                this.stripe_form.find('#zip_code_block').hide();
                this.stripe_form.find('#card_country').parents('.country_col').removeClass('col-md-6').addClass('col-md-12');
            }
        },
        setupPayPalZipCode: function () {
            if (this.paypal_form.find('#paypal_country').val() === 'US') {
                this.paypal_form.find('#paypal_zip_code_block').show();
                this.paypal_form.find('#paypal_country').parents('.country_col').removeClass('col-md-12').addClass('col-md-6');
            } else {
                this.paypal_form.find('#paypal_zip_code_block').hide();
                this.paypal_form.find('#paypal_country').parents('.country_col').removeClass('col-md-6').addClass('col-md-12');
            }
        },
        checkStripeTaxByZipCode: function () {
            this.stripe_form.find('.submitBox button').addClass('disabled').attr('disabled', true);
            this.country = this.stripe_form.find('#card_country').val();
            this.zip_code = parseInt(this.stripe_form.find('#zip_code').val());
            this.calcTax();
            this.updateTotal();
            this.stripe_form.find('.submitBox button').removeClass('disabled').removeAttr('disabled');
        },
        checkPaypalTaxByZipCode: function () {
            this.paypal_form.find('.submitBox button').addClass('disabled').attr('disabled', true);
            this.country = $('#paypal_country').val();
            this.zip_code = parseInt(this.paypal_form.find('#paypal_zip_code').val());
            this.calcTax();
            this.updateTotal();
            this.paypal_form.find('.submitBox button').removeClass('disabled').removeAttr('disabled');
        },
        calcTax: function () {
            // TODO: уточнить по налогам актуального штата
            // if (this.country === 'US' && 75000 <= this.zip_code && this.zip_code <= 79999) {
            if (false) {
                this.tax = this.amountWithDiscount() / 100 * 8.25;
            } else {
                this.tax = 0.0;
            }
            this.total = this.amountWithDiscount() + this.tax;
        },
        checkTaxByCardZipCode: function () {
            var data;
            this.cards_form.find('.submitBox button').addClass('disabled').attr('disabled', true);
            data = this.cards_form.find('select[name=stripe_card] option:selected').data();
            this.country = data.country;
            this.zip_code = data.zip;
            this.calcTax();
            this.updateTotal();
            this.cards_form.find('.submitBox button').removeClass('disabled').removeAttr('disabled');
        },
        updateTotal: function () {
            this.$('.content .tax .pull-right').text('$' + this.tax.toFixed(2));
            this.$('.content .discount .pull-right').text('$' + this.discount.toFixed(2));
            if (this.coupon.name) {
                this.$('.content .discount .text').text("Discount (" + this.coupon.name + ")");
            }
            this.$('.content .TotalAmount .pull-right').text('$' + this.calcTotal().toFixed(2));
            this.$('.content .total_amount').text('$' + this.calcTotal().toFixed(2));
        },
        calcDiscount: function () {
            if (this.coupon === {}) {return;}
            return this.discount = this.coupon.amount_off ? this.coupon.amount_off / 100.0 : this.coupon.percent_off_precise ? this.amount / 100.0 * this.coupon.percent_off_precise : 0.0;
        },
        calcTotal: function () {
            return this.amountWithDiscount() + this.tax;
        },
        amountWithDiscount: function () {
            return this.amount - this.discount;
        },
        prepareStripeForm: function () {
            if (this.stripe_form.hasClass('hidden')) {
                this.checkTaxByCardZipCode();
            } else {
                this.setupStripeValidator();
                this.setupStripeZipCode();
                this.stripe_form.css('visibility', 'visible');
                this.setupStripe();
            }
        },
        prepareSysCreditForm: function () {
            this.tax = 0.0;
            this.discount = 0.0;
            this.total = this.amount;
            this.coupon = {};
            this.updateTotal();
        },
        preparePaypal: function () {
            this.setupPaypalValidator();
            this.setupPayPalZipCode();
            this.country = this.paypal_form.find('#paypal_country').val();
            this.zip_code = parseInt(this.paypal_form.find('#paypal_zip_code').val());
            this.calcTax();
            this.updateTotal();
        },
        setupStripeValidator: function () {
            var form;
            form = this.stripe_form;
            this.stripe_validator || (this.stripe_validator = this.stripe_form.validate({
                rules: {
                    'name_on_card': {
                        required: true,
                        minlength: 2,
                        maxlength: 250
                    },
                    'country': {
                        required: true
                    },
                    'zip_code': {
                        regex: '^[0-9]{5}',
                        required: {
                            depends: function (element) {
                                return form.find('#card_country').val() === 'US';
                            }
                        }
                    }
                },
                errorElement: 'span',
                ignore: '',
                errorPlacement: function (error, element) {
                    error.appendTo(element.parents('.input-block, .select-block').find('.errorContainerWrapp')).addClass('errorContainer');
                },
                highlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-block');
                    wrapper.addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-block');
                    wrapper.removeClass('error').addClass('valid');
                }
            }));
        },
        setupPaypalValidator: function () {
            var form;
            form = this.paypal_form;
            return this.paypal_validator || (this.paypal_validator = this.paypal_form.validate({
                rules: {
                    'country': {
                        required: true
                    },
                    'zip_code': {
                        regex: '^[0-9]{5}',
                        required: {
                            depends: function (element) {
                                return form.find('#paypal_country').val() === 'US';
                            }
                        }
                    }
                },
                errorElement: 'span',
                ignore: '',
                errorPlacement: function (error, element) {
                    error.appendTo(element.parents('.input-block, .select-block').find('.errorContainerWrapp')).addClass('errorContainer');
                },
                highlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-block');
                    wrapper.addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-block');
                    wrapper.removeClass('error').addClass('valid');
                }
            }));
        },
        setupStripe: function () {
            var elements, previousBrand, style;
            this.stripe = Stripe(this.stripe_key);
            elements = this.stripe.elements();
            style = {
                base: {
                    color: window.getComputedStyle(document.body, null).getPropertyValue('color'),
                    lineHeight: '18px',
                    fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
                    fontSmoothing: 'antialiased',
                    fontSize: '16px',
                    '::placeholder': {
                        color: '#aab7c4'
                    }
                },
                invalid: {
                    color: '#FF530D',
                    iconColor: '#FF530D'
                }
            };
            this.card = elements.create('card', {
                hidePostalCode: true,
                iconStyle: 'solid',
                style: style
            });
            this.card.mount("#" + this.el.id + " #card-element");
            this.$('.LoadingCover').hide();
            previousBrand = 'unknown';
            return this.card.addEventListener('change', function (event) {
                var displayError;
                if (event.brand !== previousBrand) {
                    previousBrand = event.brand;
                    console.log(event.brand);
                }
                displayError = document.getElementById('card-errors');
                if (event.error) {
                    displayError.textContent = event.error.message;
                } else {
                    displayError.textContent = '';
                }
            });
        },
        submitStripeForm: function (event) {
            var that = this;
            if (this.stripe_form.find('[name=stripe_token]').val() === null || this.stripe_form.find('[name=stripe_token]').val() === '') {
                event.preventDefault();
                event.stopPropagation();
                this.stripe.createToken(this.card, this.getTokenData()).then(function (result) {
                    var errorElement;
                    if (result.error) {
                        errorElement = that.$('#card-errors');
                        errorElement.text(result.error.message);
                        $.showFlashMessage(result.error.message, {type: 'error'})
                    } else {
                        that.stripe_form.find('[name=stripe_token]').val(result.token.id);
                        that.stripe_form.submit();
                    }
                });
            }
        },
        getTokenData: function () {
            var token_data = {
                name: this.stripe_form.find('#name_on_card').val(),
                address_country: this.stripe_form.find('#card_country').val(),
                currency: 'usd'
            };
            if (this.stripe_form.find('#zip_code').is(':visible')) {
                token_data.address_zip = this.stripe_form.find('#zip_code').val();
            }
            return token_data;
        },
        applyCoupon: function (e) {
            e.preventDefault();

            var data, form, id, input, obtain_type, url, that;
            that = this;
            form = $(e.target).parents('form');
            input = form.find('input.coupon');
            if (!input.val()) {
                return false;
            }
            obtain_type = form.find('[name=obtain_type]').val();
            if (obtain_type === 'Recording') {
                id = form.find('[name=recording_id]').val();
                return false;
            } else if (obtain_type === 'Channel Subscription') {
                id = null;
                return false;
            } else if (obtain_type === 'Immersive' || obtain_type === 'Livestream' || obtain_type === 'Replay') {
                id = form.find('[name=session_id]').val();
                data = {coupon: input.val(), session_id: id, obtain_type: obtain_type};
                url = Routes.apply_coupon_sessions_path();
            } else {
                id = form.find('input[name=plan_id]').val();
                data = {coupon: input.val(), plan_id: id};
                url = Routes.apply_coupon_service_subscriptions_path();
            }
            $.ajax({
                url: url,
                type: 'POST',
                dataType: 'json',
                data: data,
                success: function (res, textStatus, jqXHR) {
                    input.val('');
                    that.coupon = res.coupon;
                    that.$('input[name=discount]').val(that.coupon.name);
                    that.calcDiscount();
                    that.calcTax();
                    that.updateTotal();
                },
                error: function (res, error) {
                    input.val('');
                    $(e.target).parents('.coupon_col').find('.errorContainerWrapp').html('<span id="coupon-error" class="error errorContainer">Code is not valid.</span>');
                    $(e.target).parents('.coupon_col').find('.input-block').addClass('error');
                }
            });
            return false;
        },
        clearCouponError: function (e) {
            $(e.target).parents('.coupon_col').find('.input-block').removeClass('error');
            $(e.target).parents('.coupon_col').find('.errorContainerWrapp').html('');
        },
        clearRecipientError: function () {
            this.$('.serchEmailWrapp').removeClass('error');
            this.$('.serchEmailWrapp .errorContainer').text('');
        },
        checkEmailPresence: function(){
            var email = this.$('#EmailForGift').val();
            if (!email || !email.length){
                this.$('input[name=gift]').val(0);
                this.$('input[name=recipient]').val('');
                this.$('#gift_subscription_info').addClass('hidden');
                return false;
            }
        },
        checkEmail: function (e) {
            var email, that;
            email = this.$('#EmailForGift').val();
            that = this;
            this.checkEmailPresence();
            $.ajax({
                url: Routes.check_recipient_email_stripe_subscription_path(this.subscription_id),
                type: 'POST',
                dataType: 'json',
                data: {
                    email: email
                },
                beforeSend: function () {
                    that.clearRecipientError();
                    that.$('.serchEmailWrapp button').addClass('disabled');
                    that.$('.serchEmailWrapp button').attr('disabled', true);
                },
                success: function (res, textStatus, jqXHR) {
                    that.$('.serchEmailWrapp button').removeClass('disabled');
                    that.$('.serchEmailWrapp button').removeAttr('disabled');
                    if (res.is_valid) {
                        that.$('input[name=recipient]').val(res.email);
                        that.$('input[name=gift]').val(1);
                        that.$('#gift_subscription_info .recipient').html(res.name + " (" + res.email + ")");
                        that.$('#gift_subscription_info').removeClass('hidden');
                    } else {
                        that.$('.serchEmailWrapp .errorContainer').text(res.message);
                        that.$('.serchEmailWrapp').addClass('error');
                        that.$('input[name=gift]').val(0);
                        that.$('input[name=recipient]').val('');
                        that.$('#gift_subscription_info').addClass('hidden');
                    }
                    return false;
                },
                error: function (res, error) {
                    that.$('.serchEmailWrapp button').removeClass('disabled');
                    that.$('.serchEmailWrapp button').removeAttr('disabled');
                    that.$('.serchEmailWrapp').addClass('error');
                    that.$('.serchEmailWrapp .errorContainer').text(res.message);
                    return false;
                }
            });
            return false;
        }
    });
    window.ServiceSubscriptionsPaymentModalView = ServiceSubscriptionsPaymentModalView;
}(window);
