// Unobtrusive flash UI implementation, design agnostic
// Remember to link unobtrusive_flash_ui.css as well
//
// Shows flash messages as translucent bars on top of the page
$(function() {
  $('<div id="unobtrusive-flash-messages"></div>').prependTo('body');

  function hideFlash($flash) {
    $flash.slideUp(100,function(){
      $flash.remove();
    });
  }

  $.showFlashMessage = function(message, options) {
    options = $.extend({type: 'notice', timeout: 50000000}, options);

    var $flash = $('<div class="unobtrusive-flash-message-wrapper unobtrusive-flash-'+options.type+'"><div class="unobtrusive-flash-message">'+message+'</div></div>');

    $('#unobtrusive-flash-messages').prepend($flash);
    $flash.hide().delay(300000).slideDown(100);

    $flash.click(function() {
      hideFlash($flash);
    });

    if (options.timeout>0) {
      setTimeout(function() {
        hideFlash($flash);
      },options.timeout);
    }
  };

  flashHandler = function(e, params) {
    console.log(['flash', e, params]);
    $.showFlashMessage(params.message, {type: params.type});
  };

  $(window).bind('rails:flash', flashHandler);
});
