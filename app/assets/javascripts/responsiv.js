jQuery(document).ready(function($){

	if (jQuery('body').hasClass('mobile_device')){

		checkOrientation();

		window.addEventListener("orientationchange", function() {
			setTimeout(function() {
				checkOrientation();
			}, 500);
		}, false);
	}

    // Detect ios 11_0_x affected
    // NEED TO BE UPDATED if new versions are affected
    var ua = navigator.userAgent,
        iOS = /iPad|iPhone|iPod/.test(ua),
        iOS11 = /OS 11_0_1|OS 11_0_2|OS 11_0_3|OS 11_1/.test(ua);

    // ios 11 bug caret position
    if ( iOS && iOS11 ) {

        // Add CSS class to body
        $("body").addClass("iosBugFixCaret");

    }

});
$(document).ready(function(){
  if ($('.fixedNotification').length) {
    $('body').addClass('fixed');
    $('.fixedNotification').css('bottom', 20 + 'px');
    } else {
    $('.drift-conductor-item').removeClass('fixed');
    }
})

function checkOrientation(){
	if (window.matchMedia("(orientation: portrait)").matches) {
		jQuery('html').removeClass('orientation-landscape').addClass('orientation-portrait');
		console.log('portrait');
	}

	if (window.matchMedia("(orientation: landscape)").matches) {
		jQuery('html').removeClass('orientation-portrait').addClass('orientation-landscape');
		console.log('landscape');

		var $mainWrapper = $('#WholeLivestreamDiv'),
				wrapperHeight = $('.MainVideoFrame-wrapper').height();
				$mainWrapper.height(wrapperHeight);
	}

}

$(function() {
    var pushy = $('.pushy'), //menu css class
        body = $('body'),
        container = $('#container'), //container css class
        push = $('.push'), //css class to add pushy capability
        siteOverlay = $('.site-overlay'), //site overlay
        closeMobileNav = $('.site-overlay, .closeMobileNavBTN, .closeMobileNav'), //close nav
        pushyClass = "pushy-open", //menu position & menu open class
        pushyActiveClass = "pushy-active", //css class to toggle site overlay
        containerClass = "container-push", //container open class
        pushClass = "push-push", //css class to add pushy capability
        menuBtn = $('.menu-btn, .pushy a, .pushy button'), //css classes to toggle the menu
        menuBtnLeftPush = $('.LeftPush'), //css classes to toggle the menu
        menuSpeed = 200, //jQuery fallback menu speed
        menuWidth = pushy.width() + "px"; //jQuery fallback menu width

    function togglePushy(){
        body.toggleClass(pushyActiveClass); //toggle site overlay
        pushy.toggleClass(pushyClass);
        container.toggleClass(containerClass);
        push.toggleClass(pushClass); //css class to add pushy capability
        return false
    }

    function openPushyFallback(){
        body.addClass(pushyActiveClass); //toggle site overlay
        pushy.addClass(pushyClass);
        container.addClass(containerClass);
        push.addClass(pushClass); //css class to add pushy capability
        $('.select2-drop-active').css( "display", "none" );
        $('.drift-frame-controller').css('right', 300 + 'px');
    }

    function closePushyFallback(){
        body.removeClass(pushyActiveClass); //toggle site overlay
        pushy.removeClass(pushyClass);
        container.removeClass(containerClass);
        push.removeClass(pushClass); //css class to add pushy capability
        $('.select2-drop-active').css( "display", "block" );
        $('.drift-frame-controller').css('right', 0 + 'px');
    }
    let startPoz = null;
    let swipe = document.querySelector('.header');
    swipe.addEventListener("touchstart",function(e){
      if(e.touches.length === 1) {
        startPoz = e.touches.item(0).clientX;
      }
    });
    swipe.addEventListener("touchend",function(e){
      let swipeWidthInPx = 100;
      if(startPoz){
        let endPoz = e.changedTouches.item(0).clientX;
        //right swipe
        if(endPoz > startPoz + swipeWidthInPx){
          closePushyFallback();
        }
      }
    });

        //toggle menu
        $('.menu-btn').on('click', function() {
            openPushyFallback();
        });
        //close menu when clicking site overlay
        closeMobileNav.click(function(){
            closePushyFallback();
        });

        // create a session and download uploads icons
        $('.session-dropdown-list').click(function(e) {
          e.preventDefault();
          $('.session-dropdown-list').toggleClass('active');
          $('.session-dropdown-list i').attr('style', function(index, attr){
            return attr == undefined ? 'color: var(--tp__active)!important' : null;
          });
          $('.session-dropdown').toggleClass('hide');
        });
});

