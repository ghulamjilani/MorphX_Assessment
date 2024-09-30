function InitBilling() {
    console.log('InitBilling');
    window.stripeObj = Stripe(Immerss.stripeKey);
    var $add_card_form = $('#add_card_form');
    var $card;
    $add_card_form.on('submit', function (event) {
        if ($add_card_form.find('[name=stripe_token]').val() === null || $add_card_form.find('[name=stripe_token]').val() === '') {
            event.preventDefault();
            event.stopPropagation();
            stripeObj.createToken($card, getTokenData()).then(function (result) {
                var errorElement;
                if (result.error) {
                    errorElement = $add_card_form.find('#card-errors');
                    errorElement.textContent = result.error.message;
                    $.showFlashMessage(result.error.message, {type: 'error'})
                } else {
                    $add_card_form.find('[name=stripe_token]').val(result.token.id);
                    $add_card_form.submit();
                }
            });
        }
    });

    function getTokenData() {
        var token_data = {
            name: $add_card_form.find('#name_on_card').val(),
            address_country: $add_card_form.find('#card_country').val(),
            currency: 'usd'
        };
        if ($add_card_form.find('#zip_code').is(':visible')) {
            token_data.address_zip = $add_card_form.find('#zip_code').val();
        }
        return token_data;
    }

    function setupStripe() {
        var elements, previousBrand, style;
        elements = stripeObj.elements();
        style = {
            base: {
                color: window.getComputedStyle(document.body, null).getPropertyValue('color'),
                lineHeight: '18px',
                fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
                fontSmoothing: 'antialiased',
                fontSize: '14px',
                '::placeholder': {
                    color: '#6f7073'
                }
            },
            invalid: {
                color: '#FF530D',
                iconColor: '#FF530D'
            }
        };
        $card = elements.create('card', {
            hidePostalCode: true,
            iconStyle: 'solid',
            style: style
        });
        $card.mount("#card-element");
        previousBrand = 'unknown';
        $card.addEventListener('change', function (event) {
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
        $('#add_card_form').validate({
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
                    regex: '[0-9]*',
                    required: function() {
                        return $('#card_country').val() === 'US';
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
        });
        return false;
    }

    function checkZipCode() {
        var $zip_code = $('#zip_code_block');
        var $country = $('#card_country');

        var zipForUS = function (value) {
            if (value === 'US') {
                $zip_code.removeClass('hide');
            } else {
                $zip_code.addClass('hide');
            }
        }

        zipForUS($country.val());

        $country.on('change', function () {
            var $this = $(this);
            zipForUS($this.val())
        });
    }

    function togglePaymentMethodsList(e) {
        e.preventDefault();
        $('.PaymentMethods, .AddNewCard').toggleClass('hide');
    }

    $('.AddPaymentMethod, .BackToBackPaymentList').click(function (e) {
        togglePaymentMethodsList(e)
    });
    setupStripe();
    checkZipCode();
}