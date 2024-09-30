(function(window){
    'use strict';
    // RegEx ISO 8601 Formatted Date, e.g. 2013-08-24T08:00:00-00:00
    var regexMatchForIso8601Date = /[0-9]T[0-9]/;
    var invalidDateMessage = 'Invalid Date';

    var L2date = function (value, format) {
        if($.trim(format) === "")
            format = 'MMM D LT';
        this.format = format;
        this.value = value || new Date();
        this.timezone = Immerss.timezoneOffset || moment().utcOffset();
    };

    L2date.prototype.convertUtcToLocalDisplay = function () {
        // Check that the date is not in ISO 8601 format, if not
        //   then add postfix so can be converted to UTC
        var value = this.value;
        if (!regexMatchForIso8601Date.test(this.value)) value = value + ' UTC';
        if (!moment(value).isValid()) return invalidDateMessage;
        return moment(value).utcOffset(this.timezone).format(this.format);
    };

    L2date.prototype.dateTimeWithZone = function() {
        var format;
        if(Immerss.timeFormat === "24hour"){
            format = 'MMMM D YYYY HH:mm Z';
        }else{
            format = 'lll Z';
        }
        return moment(this.value).utcOffset(this.timezone).format(format);
    };

    L2date.prototype.toCustomFormat = function(format) {
        return moment(this.value).utcOffset(this.timezone).format(format);
    };

    window.L2date = L2date;
})(window);
