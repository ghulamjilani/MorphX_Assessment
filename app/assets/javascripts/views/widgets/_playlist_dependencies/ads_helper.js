+function () {
    "use strict";

    var adsTemplate = null;
    var getAdsTemplate = function(){
        if(!adsTemplate){
            adsTemplate = Handlebars.compile($('#adsTmpl').text());
        }
        return adsTemplate;
    };
    var formattedAdsDuration = function(durationSeconds){
        var seconds, hours, minutes,
            result = [];
        hours = parseInt(durationSeconds  / (60 * 60));
        minutes = parseInt((durationSeconds - hours * 60 * 60) / 60);
        seconds = parseInt(durationSeconds - hours * 60 * 60 - minutes * 60);
        if(hours < 10) {
            result.push('0' + hours)
        }else{
            result.push(hours)
        }
        if(minutes < 10) {
            result.push('0' + minutes)
        }else{
            result.push(minutes)
        }
        if(seconds < 10) {
            result.push('0' + seconds)
        }else{
            result.push(seconds)
        }

        return result.join(':');
    };
    window.getAdsUrl = function(attrs){
        var template = getAdsTemplate();
        var templateData = {};

        templateData.commercials_url = attrs.commercials_url;
        templateData.commercials_duration_formatted = formattedAdsDuration(attrs.commercials_duration);
        templateData.commercials_mime_type = attrs.commercials_mime_type;
        return URL.createObjectURL(new Blob([$.trim(template(templateData))], { type: "application/xml" }));
    };
}();
