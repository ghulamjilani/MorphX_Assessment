$.showFlashMessage = function(message, options) {
    options = $.extend({type: 'notice', timeout: 5000000}, options);


    if (options.type=='notice') {
        options.type = 'info';
    } else if(options.type=='alert') {
        options.type = 'error';
    } else if(options.type=='error') {
        options.type = 'error';
    }
    var $flash = $('section.flashMessage > .'+options.type);
    $flash.html(message);
    $('section.flashMessage').addClass(options.type)

    $flash.click(function() {
        hideFlash();
    });

    if (options.timeout>0) {
        setTimeout(function() {
            hideFlash();
        },options.timeout);
    }
};
function hideFlash() {
    $('section.flashMessage').removeClass('info');
    $('section.flashMessage').removeClass('error');
}

