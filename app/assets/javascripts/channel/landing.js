(function() {
  (function(window) {
    var duration, slideCount;
    if (!$('body').hasClass('channel_landing')) {
      return;
    }
    if ($('#slideshow-2').length) {
      slideCount = $('#slideshow-2').data('itemcount');
      duration = 300;
      $('#slideshow-1 .slideshow').on('initialized.owl.carousel', (function(_this) {
        return function(e) {
          return $('#slideshow-1 .owl-prev').addClass('disabled');
        };
      })(this)).owlCarousel({
        items: 1,
        margin: 0,
        nav: false,
        video: true,
        navText: '',
        dots: false,
        navContainer: '#slideshow-1 .direction-nav'
      }).on('changed.owl.carousel', (function(_this) {
        return function(e) {
          var itemCount, itemCurent, next, prev;
          itemCount = e.item.count;
          itemCurent = e.item.index;
          prev = $('#slideshow-1 .owl-prev');
          next = $('#slideshow-1 .owl-next');
          if (itemCurent === 0) {
            prev.addClass('disabled');
          } else {
            prev.removeClass('disabled').css('opacity', '1');
          }
          if (itemCurent === itemCount - 1) {
            next.addClass('disabled');
          } else {
            next.removeClass('disabled').css('opacity', '1');
          }
          $('.owl-item').removeClass('center');
          $('.slide[data-slide-number='+e.item.index+']').parent().addClass('center');
          $('#slideshow-2 .slideshow').trigger('to.owl.carousel', [e.item.index, duration, true]);
        };
      })(this));
      $('#slideshow-2 .slideshow').owlCarousel({
        margin: 0,
        autoWidth: true,
        items: slideCount,
        center: true
      }).on('click', '.owl-item', function() {
        $('.owl-item').removeClass('center');
        $('.slide[data-slide-number='+$(this).index()+']').parent().addClass('center');
        $('#slideshow-1 .slideshow').trigger('to.owl.carousel', [$(this).index(), duration, true]);
      });
      $(document.documentElement).keyup((function(_this) {
        return function(event) {
          if (event.keyCode === 37) {
            $('#slideshow-1 .slideshow').trigger('prev.owl');
          } else if (event.keyCode === 39) {
            $('#slideshow-1 .slideshow').trigger('next.owl');
          }
        };
      })(this));
    }
    $('.ch-p_aboutTxt').each(function() {
      var $ts;
      $ts = $(this).parents('.ch-p_aboutTxt_wrapp');
      if (this.offsetHeight < this.scrollHeight) {
        $ts.addClass('crowded');
        return $ts.find('a').click(function() {
          var txt;
          $ts.toggleClass('open');
          txt = $ts.hasClass('open') ? 'Read Less' : 'Read More';
          $(this).text(txt);
          $ts.find('.ch-p_aboutTxt').scrollTo(0);
          return false;
        });
      }
    });
    $('a[data-remote]').on('ajax:before', function(e) {
      return $(e.currentTarget).attr('disabled', true).addClass('disabled');
    }).on('ajax:complete', function(e) {
      return $(e.currentTarget).removeAttr('disabled').removeClass('disabled');
    });
    $('.ch-p_presenter_mobile_showMore').click(function(e) {
      var textEl;
      e.preventDefault();
      textEl = $(this).find('span');
      if ($(textEl).text() === 'more') {
        $(textEl).text('less');
      } else {
        $(textEl).text('more');
      }
      $(this).toggleClass('active');
      return $('.ch-p_presenter_mobile_content').toggleClass('active');
    });
    $('.birthdate_Datepicker').datepicker({
      dateFormat: 'dd MM yy',
      minDate: '1D',
      maxDate: '3M',
      showOn: 'both',
      buttonText: '<i class="birthdate_Datepicker-show VideoClientIcon-calendar-icon text-color-Blue margin-right-5"></i>',
      changeMonth: true,
      beforeShow: function(input, inst) {
        return _.defer(function() {
          return inst.dpDiv.css({
            "z-index": 999
          });
        });
      }
    });
    $('#requestSessionModal form').on('ajax:success', function() {
      return $('#requestSessionModal').modal('hide');
    });
    $('#requestSessionModal form').validate({
      rules: {
        'date': {
          required: true
        },
        'requested_at': {
          required: true
        },
        'delivery_method': {
          required: true
        },
        'comment': {
          required: true,
          minlength: 3,
          maxlength: 250
        }
      },
      ignore: '.ignore',
      errorElement: "span",
      errorPlacement: function(error, element) {
        return error.appendTo(element.parents('.input-block, .select-block, .select-tag-block').find('.errorContainerWrapp')).addClass('errorContainer');
      },
      highlight: function(element) {
        return $(element).parents('.input-block, .select-block, .select-tag-block').addClass('error').removeClass('valid');
      },
      unhighlight: function(element) {
        return $(element).parents('.input-block, .select-block, .select-tag-block').removeClass('error').addClass('valid');
      }
    });
    $.each($('section.tile-cake'), function() {
      var imgOBJ, imgOBJItem, itemattr;
      imgOBJ = $(this).find('.owl-lazy');
      imgOBJItem = $(imgOBJ).get(0);
      itemattr = $(imgOBJItem).attr('data-src');
      return $(imgOBJItem).css({
        'background-image': "url('" + itemattr + "')",
        'opacity': 1
      });
    });
    return $('.chanelLIst-item').on('click', function(e) {
      $(e.currentTarget).parents('.chanelLIst').find('.chanelLIst-item.active').removeClass('active');
      return $(e.currentTarget).addClass('active');
    });
  })(window);

}).call(this);
