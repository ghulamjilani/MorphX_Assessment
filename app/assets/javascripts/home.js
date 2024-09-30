//= require widget/views/live-guide-view

function dateAsFormattedString(date) {
  date = $.datepicker.formatDate('M dd, yy', date);
  return date
}

// yes we test in production(at least we can be sure that it is not ignored)
var timestamp = Date.parse("January 21, 2014");
var date = new Date(timestamp);

if (dateAsFormattedString(date) != 'Jan 21, 2014') {
  alert("dateAsFormattedString UnexpectedResponse exception");
}

function rgb2hex(rgb) {
  rgb = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
  function hex(x) {
    return ("0" + parseInt(x).toString(16)).slice(-2);
  }
  return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
}

function invertColor(hexTripletColor) {
  if (hexTripletColor.indexOf('rgb') != -1) {
    hexTripletColor = rgb2hex(hexTripletColor);
  }

  var color = hexTripletColor;
  color = color.substring(1); // remove #
  color = parseInt(color, 16); // convert to integer
  color = 0xFFFFFF ^ color; // invert three bytes
  color = color.toString(16); // convert to hex
  color = ("000000" + color).slice(-6); // pad with leading zeros
  color = "#" + color; // prepend #
  return color;
}

function military_hours_to_am_pm_hours(hours) {
  return(hours == 0 ? "12" : hours > 12 ? hours - 12 : hours);
}

function am_pm_label(hours) {
  return(hours < 12 ? "AM" : "PM");
}
//jQuery(window).ready(function(){
//  if(jQuery('body').hasClass('home-index')){
//    jQuery('.slider-inner-wrapp').removeClass('shadowtile').attr('style', '');
//    jQuery('.slider-wrapp').show();
//    //    main slider baner
//    var WindowHeight = jQuery(window).height();
//
//    jQuery('.slider').owlCarousel({
//        animateOut: 'fadeOut',
//        animateIn: 'animateOut',
//        nav:true,
//        navText:'',
//        loop:true,
//        autoplayHoverPause:false,
//        items:1,
//        lazyLoad: true,
//        margin:0,
//        stagePadding:0,
//        smartSpeed:450,
//        responsive:{
//            0:{
//                nav:false,
//                autoplay:false
//            },
//            992:{
//                autoplay:true,
//                nav:true
//            }
//        }
//    });
//
//    jQuery('#HowItWorks').click(function(e){
//      jQuery('.HowItWorks').fadeToggle();
//      return false;
//    });
//    jQuery('.HowItWorks .closeB').click(function(e){
//      jQuery('.HowItWorks').fadeToggle();
//      return false;
//    });
//    $(document).scroll(function() {
//      var y = $(this).scrollTop();
//      var h = jQuery('.slider-inner').height();
//      if (y > h) {
//        jQuery('.HowItWorks').hide();
//      }
//    });
//  };
//});
