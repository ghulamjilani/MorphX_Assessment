// Unobtrusive flash UI implementation with Bootstrap 3
// For sites that use Bootstrap http://getbootstrap.com/
//
// Declare a .unobtrusive-flash-container wherever you want the messages to appear
// Defaults to .container, .container-fluid (core Bootstrap classes), or just the body tag, whichever is present
$(function() {

  $.showFlashMessage = function(message, options) {
    options = $.extend({type: 'notice', timeout: 6000}, options);
    // Workaround for common Rails flash type to match common Bootstrap alert type
    if (options.type=='notice') {
      options.type = 'info';
    } else if(options.type=='alert') {
      options.type = 'warning';
    } else if(options.type=='error') {
      options.type = 'danger';
    } else if(options.type=='success1') {
      options.type = 'success';
    } else if(options.type=='success2') {
      options.type = 'success';
    } else if(options.type=='success3') {
      options.type = 'success';
    } else if(options.type=='success4') {
      options.type = 'success';
    } else if(options.type=='success5') {
      options.type = 'success';
    } else if(options.type=='error1') {
      options.type = 'danger';
    } else if(options.type=='error2') {
      options.type = 'danger';
    } else if(options.type=='error3') {
      options.type = 'danger';
    } else if(options.type=='error4') {
      options.type = 'danger';
    } else if(options.type=='error5') {
      options.type = 'danger';
    }

    var $flash = $('<div class="alert alert-'+options.type+'"><button type="button" class="close VideoClientIcon-iPlus rotateIcon" data-dismiss="alert"></button><div class="bodyFlashMessage">'+message+'</div></div>');

    if ($('.modal:visible').length == 1) {
      var $flashContainer = $( $('.modal:visible').find('.unobtrusive-flash-container')[0] );
    }else if($('.v-modal:visible').length == 1){
      var $flashContainer = $( $('.v-modal:visible').find('.unobtrusive-flash-container')[0] );
    }else if($('.shareModalMK2').is(':visible')){
      var $flashContainer = $( $('.shareModalMK2').find('.unobtrusive-flash-container')[0] );
    }else if ($('.RF__wrapper').is(':visible')) {
      var $flashContainer = $( $('.RF__wrapper:visible').find('.unobtrusive-flash-container')[0] );
    }else if ($('.header__container').is(':visible')) {
      var $flashContainer = $( $('.header__container:visible').find('.unobtrusive-flash-container')[0] );
    }else if($('.header.pushy.pushy-right.pushy-open').is(':visible')){
      var $flashContainer = $( $('.header .unobtrusive-flash-container.open-pushy-flash') );
    }else if ($('.unobtrusiveMobile-flash-container').is(':visible')) {
      var $flashContainer = $('.unobtrusiveMobile-flash-container')
    }else if ($('.sidebarFlash').is(':visible')) {
      var $flashContainer = $( $('.sidebarFlash:visible').find('.unobtrusive-flash-container')[0] );
    }else if (typeof $flashContainer === "undefined") {
      var $flashContainer = $($('.unobtrusive-flash-container:visible')[0] || $('.container')[0] || $('.container-fluid')[0] || $('body')[0]);
    }else {
      throw new Error('can not find flash container');
    }
    $flashContainer.prepend($flash);

    $flash.hide().delay(300).slideDown(100);

    $flash.alert();

    if (options.timeout>0) {
      setTimeout(function() {
        $flash.alert('close');
      },options.timeout);
    }
  };

  flashHandler = function(e, params) {
    setTimeout(function() {
      $.showFlashMessage(params.message, {type: params.type});
    }, 250);
  };

  $(window).bind('rails:flash', flashHandler);
});
