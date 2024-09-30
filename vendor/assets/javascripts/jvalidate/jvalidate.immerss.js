$.extend($.validator.prototype, {
    // Check form without highlighting
    // There's checkForm() method for this but for some reason it sometimes highlight elements
    isValid: function () {
        if (this.pendingRequest > 0) {
            return false;
        }
        is_valid = true;
        for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++) {
            var item = this.check(elements[i]);
            if (item !== undefined) {
                is_valid = is_valid && item;
            }
        }
        return is_valid;
    },

    // Override default start/stop request methods to trigger custom event on form
    // Used for remote validation to disable/enable submit button
    startRequest: function (element) {
        if (!this.pending[element.name]) {
            $(this.currentForm).trigger('validation:remote:start');
            this.pendingRequest++;
            $(element).addClass(this.settings.pendingClass);
            this.pending[element.name] = true;
        }
    },
    stopRequest: function (element, valid) {
        $(this.currentForm).trigger('validation:remote:stop');
        this.pendingRequest--;

        // Sometimes synchronization fails, make sure pendingRequest is never < 0
        if (this.pendingRequest < 0) {
            this.pendingRequest = 0;
        }
        delete this.pending[element.name];
        $(element).removeClass(this.settings.pendingClass);
        if (valid && this.pendingRequest === 0 && this.formSubmitted && this.form()) {
            $(this.currentForm).submit();
            this.formSubmitted = false;
        } else if (!valid && this.pendingRequest === 0 && this.formSubmitted) {
            $(this.currentForm).triggerHandler("invalid-form", [this]);
            this.formSubmitted = false;
        }
    }
});

$.validator.addMethod("emailImmerss", function (value, element) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        var result = /^[A-Za-z0-9][^@\s]+@([^@\s]+\.)+[^@\s]+$/g.test(value);
        if (result) {
            var rightSide, rightSideOtherNames, firstLvlDomain, isFirstLvlDomainCorrect, isAnotherNamesCorrect;

            rightSide = value.split('@')[1].split('.');
            firstLvlDomain = rightSide[rightSide.length - 1];
            rightSideOtherNames = rightSide.slice(0, rightSide.length - 1);

            //Do not allow digits in first lvl domain
            isFirstLvlDomainCorrect = !(/\d+/.test(firstLvlDomain));

            //Another lvls of domain names (2nd and higher) should not contain only digits
            isAnotherNamesCorrect = _.all(rightSideOtherNames, function (name) {
                return name.replace(/\d/g, "") != "";
            });

            return isFirstLvlDomainCorrect && isAnotherNamesCorrect;
        } else {
            return false;
        }
    }

}, "Please enter a valid email address.");

$.validator.addMethod('tagsLength', function (value, element, params) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        if (!params) {
            params = {};
        }
        _(params).defaults({
            minlength: 0,
            maxlength: 0,
            separator: ','
        });
        var minlength = $.validator.methods.minlength;
        var maxlength = $.validator.methods.maxlength;
        params.errorsOn = undefined;

        value = value.split(params.separator);
        value = value.filter(function (e) {
            return e
        });
        if (!minlength.call(this, value, element, params.minlength))
            params.errorsOn = 'minlength';
        if (!maxlength.call(this, value, element, params.maxlength, 'maxlength'))
            params.errorsOn = 'maxlength';
        return typeof params.errorsOn === 'undefined';

    }
}, function (params, element) {
    var errType = params.errorsOn;
    var abbr = $(element).data('abbr') || 'tags';
    var messages = {
        minlength: $.validator.format("Please enter at least {0} " + abbr + "."),
        maxlength: $.validator.format("Please enter at most  {0} " + abbr + ".")
    };

    return messages[errType](params[errType]);
});

$.validator.addMethod('tagsUniqueness', function (value, element) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        array = value.split(',');
        array = array.filter(function (e) {
            return e
        });
        return array.length === $.unique(array).length;
    }
}, "Tags should be unique");

$.validator.addMethod('tagLength', function (value, element, params) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        if (!params) {
            params = {};
        }
        _(params).defaults({
            minlength: 0,
            maxlength: 0,
            separator: ','
        });
        var minlength = $.validator.methods.minlength;
        var maxlength = $.validator.methods.maxlength;
        params.errorsOn = undefined;

        values = value.split(params.separator);
        values = values.filter(function (e) {
            return e
        });
        $this = this;

        $.each(values, function (index, v) {
            v = $.trim(v);
            if (!minlength.call($this, v, element, params.minlength))
                params.errorsOn = 'minlength';
            if (!maxlength.call($this, v, element, params.maxlength, 'maxlength'))
                params.errorsOn = 'maxlength';
        });
        return typeof params.errorsOn === 'undefined';

    }
}, function (params, element) {
    var errType = params.errorsOn;
    var abbr = $(element).data('abbr') || 'symbols';
    var messages = {
        minlength: $.validator.format("Minimum tag length should be {0} " + abbr + "."),
        maxlength: $.validator.format("Maximum tag length should be {0} " + abbr + ".")
    };
    return messages[errType](params[errType]);
});

$.validator.addMethod('minlengthWithOutHtml', function (value, element, param) {
    value = $("<span>" + value + "</span>").text();
    return $.validator.methods.minlength.call(this, value, element, param);
}, $.validator.messages.minlength);

$.validator.addMethod('maxlengthWithOutHtml', function (value, element, param) {
    value = $("<span>" + value + "</span>").text();
    return $.validator.methods.maxlength.call(this, value, element, param);
}, $.validator.messages.maxlength);

$.validator.addMethod('regex', function (value, element, regexp) {
    var re = new RegExp(regexp);
    mr = value.match(re);
    return this.optional(element) || !!mr && mr[0] == value;
}, "Invalid format");

$.validator.addMethod('intlTelInput', function (value, element, params) {
    //if(value === ''){ return true }
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        code = $(element).intlTelInput('getValidationError');

        if (code === 0 || code === -99) {
            return true;
        } else {
            return false;
        }
    }
}, 'Invalid phone number.');

$.validator.addMethod('dateSelect', function (value, element) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        dd = $('select#user_birthdate_3i').val();
        mm = $('select#user_birthdate_2i').val();
        yy = $('select#user_birthdate_1i').val();
        if (dd === null || mm === null || yy === null) {
            return false;
        }
        string = dd + '/' + mm + '/' + yy;
        return moment(string, 'DD/M/YYYY').isValid();
    }
}, 'Invalid date.');

$.validator.addMethod('birthdate', function (value, element) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        dd = $('[name*="birthdate(1i)"]').val();
        mm = $('[name*="birthdate(2i)"]').val();
        yy = $('[name*="birthdate(3i)"]').val();
        if (dd === null || mm === null || yy === null) {
            return false;
        }
        string = dd + '/' + mm + '/' + yy;
        return moment(string, 'DD/M/YYYY').isValid();
    }
}, 'Invalid date.');

$.validator.addMethod('birthday', function (value, element, format) {
    if (this.optional(element)) {
        return this.optional(element);
    } else {
        if (!!format) {
            format = 'DD MMMM YYYY';
        }
        date = $(element).val();
        if (date === null) {
            return false;
        }
        return moment(date, format).format(format) === date;
    }
}, 'Invalid date format.');

$.validator.addMethod("urlImmerss", function (value, element) {
    return this.optional(element) || /^(?:https?:\/\/)?(?:www\.)?((?:[\w\-]+)(?:\.[\w\-]+)*(?:\.[a-z]+))(?:\/?.+)?$/i.test(value);
}, $.validator.messages.url);

$.validator.addMethod("channelListedRequred", function (value, element) {
    return $(element).find("option[value='" + value + "']").data("is-listed")
}, 'This channel is unlisted, please make it listed first.');

$.validator.addMethod("subscriptionRequred", function (value, element) {
    return !$(element).find("option[value='" + value + "']").data("is-subscription-present")
}, 'This channel already has a subscription.');
