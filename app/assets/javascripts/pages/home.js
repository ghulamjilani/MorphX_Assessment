//= require_self

(function () {
    (function (window) {
        'use strict';
        $(document).ready(function () {
            function changeCapthaSize() {
              var containerWidth = $('.formContainer').width();
              var reCaptchaWidth = 304;
              if (reCaptchaWidth > containerWidth){
                $('.g-recaptcha > div').css('width', `${containerWidth}` + 'px');
                $('.g-recaptcha div > iframe').css('width', `${containerWidth}` + 'px');
                $('.g-recaptcha div > iframe').css('border', 1 + 'px solid #d3d3d3');
                $('.g-recaptcha div > iframe').css('border-radius', 3 + 'px');
              }
            }
            $(window).ready(function(){
              changeCapthaSize();
            });
            $(window).resize(function(){
              changeCapthaSize();
            });
            var bindScrollEvent, owl, slides;
            bindScrollEvent = function () {
                clearTimeout($.data(this, 'scrollTimer'));
                $.data(this, 'scrollTimer', setTimeout((function () {
                    var scrolltop;
                    scrolltop = $(window).scrollTop();
                    // if ($('body').hasClass('transpered-header')) {
                        if ($(window).width() > 978 && scrolltop > 0) {
                            $('body').removeClass('header-top');
                        } else {
                            $('body').addClass('header-top');
                        }
                    // }
                }), 0));
            };
            $(window).scroll(bindScrollEvent);
            $(window).resize(bindScrollEvent);
            owl = $('.flexslider-ComingSoon .slides');
            slides = $('.flexslider-ComingSoon .slides .ComingSoon-slide').length;
            owl.on('initialized.owl.carousel', function (event) {
                return $('#announcements .spinnerSlider').fadeOut();
            });
            owl.owlCarousel({
                center: true,
                items: 1,
                loop: false,
                callbacks: true,
                autoWidth: false,
                nav: true,
                navText: '',
                autoplay: true,
                margin: 0,
                lazyLoad: true,
                responsive: {
                    0: {
                        loop: slides > 1,
                        items: 1
                    },
                    600: {
                        loop: slides >= 3,
                        items: 3
                    },
                    1200: {
                        loop: slides >= 7,
                        items: 7
                    }
                }
            });
        });

        $('body.home-index form#lets_talk').on('ajax:success', function(){
            if (Immerss.environment == 'production')
                gtag_report_conversion();
            $.showFlashMessage('Thank you!', {type: 'success', timeout: 5000});
            $('form#lets_talk')[0].reset();
            $('form#lets_talk .input-block:not(.phone-area)').addClass('state-clear');
        });
        $('body.home-landing.Morphx form#lets_talk').on('ajax:success', function(){
            $('form#lets_talk')[0].reset();
            $('form#lets_talk .input-block').addClass('state-clear');
            $('#contactUs.modal').modal('hide');
        });
        var telInput = $("body.home form#lets_talk input[name=phone]");
        telInput.intlTelInput({
            initialCountry: "auto",
            separateDialCode: true,
            geoIpLookup: function (callback) {
                var cb;
                cb = function () {
                    return null;
                };
                return $.get('https://ipinfo.io?token=42576d359578ce', cb, "jsonp").always(function (resp) {
                    var countryCode;
                    countryCode = resp && resp.country ? resp.country : "";
                    return callback(countryCode);
                });
            },
            utilsScript: "/Phone-select/utils.js"
        });
        $('body.home form#lets_talk').validate({
            rules: {
                name: {
                    required: true,
                    minlength: 2,
                    maxlength: 250
                },
                company: {
                    minlength: 2,
                    maxlength: 250
                },
                email: {
                    emailImmerss: true,
                    required: true
                },
                phone: {
                    intlTelInput: true
                },
                about: {
                    maxlength: 2000
                }
            },
            errorElement: "span",
            focusCleanup: true,
            ignore: '',
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.removeClass('error').addClass('valid');
            }
        });
        $('body').on('click', '.modal_email_show', function (e) {
            $('body').on('shown.bs.modal', '#email-modal-share', function () {
                window.email_share_form = $('.email_share_form').validate({
                    rules: {
                        'emails': {
                            required: true
                        },
                        'subject': {
                            required: true
                        },
                        'body': {
                            required: false
                        }
                    },
                    errorElement: 'span',
                    ignore: ''
                });
                window.initializeFormsVisibility();
            });
            $('body').on('ajax:error', '.email_share_form', function (xhr, data) {
                window.email_share_form.showErrors(data.responseJSON);
            });
            window.modal_email_share = $(modalBody).filter('#email-modal-share').modal('show');
            $('body').on('ajax:success', '.email_share_form', function (xhr, data) {
                window.modal_email_share.modal('hide');
            });
            e.preventDefault();
        });
    })(window);

}).call(this);
