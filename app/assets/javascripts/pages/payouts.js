function prepareTitles() {
    $("[title]").not("iframe[class^='drift']").tooltip({
        content: function() {
            return $(this).prop('title');
        },
        position: {
            my: 'center top+5',
            at: 'center bottom+5'
        },
        show: false,
        hide: false
    });
}

function checkIbanFormat(str) {
    return /^([A-Z]{2}[ \-]?[0-9]{2})(?=(?:[ \-]?[A-Z0-9]){9,30}$)((?:[ \-]?[A-Z0-9]{3,5}){2,7})([ \-]?[A-Z0-9]{1,3})?$/.test(str);
}

function validateIbanChecksum(iban) {
    const ibanStripped = iban.replace(/[^A-Z0-9]+/gi, '') //keep numbers and letters only
        .toUpperCase(); //calculation expects upper-case
    const m = ibanStripped.match(/^([A-Z]{2})([0-9]{2})([A-Z0-9]{9,30})$/);
    if (!m) return false;

    const numbericed = (m[3] + m[1] + m[2]).replace(/[A-Z]/g, function (ch) {
        //replace upper-case characters by numbers 10 to 35
        return (ch.charCodeAt(0) - 55);
    });
    //The resulting number would be to long for javascript to handle without loosing precision.
    //So the trick is to chop the string up in smaller parts.
    const mod97 = numbericed.match(/\d{1,7}/g)
        .reduce(function (total, curr) {
            return Number(total + curr) % 97
        }, '');

    return (mod97 === 1);
}

$.validator.addMethod("iban", function (value, element) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        // return (checkIbanFormat(value) && validateIbanChecksum(value));
        return checkIbanFormat(value);
    }

}, "Please enter a valid IBAN.");

function InitPayouts() {
    $('#addNewPayoutMethod').on('click', function (e) {
        $('#SelectPayoutType').removeClass('hide');
        $('.PayoutsList').addClass('hide');
    });
    $('#SelectPayoutType a.next').on('click', function (e) {
        const type = $('input[name=payout_method]').val();
        $(`.Add${type}PayoutMethod`).removeClass('hide');
        $('#SelectPayoutType').addClass('hide');
    });
    $('#SelectPayoutType a.back').on('click', function (e) {
        $('#SelectPayoutType').addClass('hide');
        $('.PayoutsList').removeClass('hide');
    });
    $('.AddBankPayoutMethod a.back').on('click', function (e) {
        $('.AddBankPayoutMethod').addClass('hide');
        $('#SelectPayoutType').removeClass('hide');
    });
    $('body').on("submit", "#account_info_payouts_form", function (event) {
        console.log('submit', event);
        event.preventDefault();
        $.ajax({
            url: $(this).attr("action"),
            type: $(this).attr("method"),
            dataType: "script",
            data: new FormData(this),
            processData: false,
            contentType: false,
            error: function (xhr, desc, err) {
                if (xhr.status != 200) {
                    $.showFlashMessage(xhr.responseText, {type: 'error', timeout: 6000})
                }
                $('#account_info_payouts_form button[type="submit"]').removeAttr('disabled').text('Next')
            }
        })
    })
    $('body').on("submit", "#bank_account_payouts_form", function(event) {
        event.preventDefault();
        $.ajax({
            url: $(this).attr("action"),
            type: $(this).attr("method"),
            dataType: "script",
            data: new FormData(this),
            processData: false,
            contentType: false,
            error: function (xhr, desc, err) {
                if (xhr.status != 200) {
                    $.showFlashMessage(xhr.responseText, {type: 'error', timeout: 6000})
                }
                $('#bank_account_payouts_form button[type="submit"]').removeAttr('disabled').text('Next')
            }
        })
    })
    $('body').on('ajax:error', '#account_info_payouts_form, #bank_account_payouts_form', function (data, error) {
        console.log(data, error);
        $.showFlashMessage(error.responseText, {type: 'error', timeout: 6000});
    })
    $('body').on('click', '#account_info_payouts_form a.back', function (e) {
        e.preventDefault();
        $('#add_account_info').html('').addClass('hide');
        $('#create_account').removeClass('hide');
    })
    $('body').on('click', '#bank_account_payouts_form a.back', function (e) {
        e.preventDefault();
        $('#add_bank_info').html('').addClass('hide');
        $('#add_account_info').removeClass('hide');
    })
}

function InitPersonalInfoValidation() {
    $('#account_info_payouts_form').validate({
        rules: {
            'account_info[first_name]': {
                required: true,
                minlength: 2,
                maxlength: 100
            },
            'account_info[last_name]': {
                required: true,
                minlength: 2,
                maxlength: 100
            },
            'account_info[date_of_birth]': {
                required: true
            },
            'account_info[phone]': {
                required: true
            },
            'account_info[business_website]': {
                required: true,
                url: true
            },
            'account_info[mcc]': {
                required: true
            },
            'account_info[address_line_1]': {
                required: true
            },
            'account_info[city]': {
                required: true
            },
            'account_info[email]': {
                required: true,
                emailImmerss: true,
            },
            'account_info[ssn_last_4]': {
                required: true
            },
            'account_info[state]': {
                required: true
            },
            'account_info[country]': {
                required: true
            },
            'account_info[zip]': {
                required: function() {
                    return $('#account_country').val() === 'US'
                }
            },
        },
        errorElement: "span",
        ignore: ':hidden',
        errorPlacement: function (error, element) {
            return error.appendTo(element.parents('.input-block, .select-block, label.radio').find('.errorContainerWrapp')).addClass('errorContainer');
        },
        highlight: function (element) {
            var wrapper;
            wrapper = $(element).parents('.input-block, .select-block, label.radio');
            return wrapper.addClass('error').removeClass('valid');
        },
        unhighlight: function (element) {
            var wrapper;
            wrapper = $(element).parents('.input-block, .select-block, label.radio');
            return wrapper.removeClass('error').addClass('valid');
        },
        messages: {
            'account_info[business_website]': {
                url: 'Please enter a valid URL (eg: https://example.com)'
            }
        },
    });
}

function InitBankInfoValidation() {
    $('#bank_account_payouts_form').validate({
        rules: {
            'bank_account[routing_number]': {
                required: function () {
                    // not required if IBAN provided
                    return !checkIbanFormat($('input[name="bank_account[account_number]"]').val())
                },
            },
            'bank_account[account_number]': {
                required: true,
            },
            'bank_account[account_holder_name]': {
                required: true
            },
            'bank_account[currency]': {
                required: true
            },
            'bank_account[country]': {
                required: true
            }
        },
        errorElement: "span",
        ignore: ':hidden',
        errorPlacement: function (error, element) {
            return error.appendTo(element.parents('.input-block, .select-block, label.radio').find('.errorContainerWrapp')).addClass('errorContainer');
        },
        highlight: function (element) {
            var wrapper;
            wrapper = $(element).parents('.input-block, .select-block, label.radio');
            return wrapper.addClass('error').removeClass('valid');
        },
        unhighlight: function (element) {
            var wrapper;
            wrapper = $(element).parents('.input-block, .select-block, label.radio');
            return wrapper.removeClass('error').addClass('valid');
        }
    });
}
