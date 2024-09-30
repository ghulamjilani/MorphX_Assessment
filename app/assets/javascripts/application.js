//= require jquery2
//= require underscore
//= require backbone
//= require handlebars
//= require bootstrap3/bootstrap.min

//= require jquery_ujs
//= require jquery-ui
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/widgets/tooltip
//= require jquery-ui/widgets/spinner
//= require jquery-ui/widgets/selectmenu
//= require fix_jQuryUI_for_mobile
//= require jquery.cookie
//= require jquery.timeago
//= require jquery.tap.min
//= require jquery.jscrollpane.min
//= require jquery.mousewheel
//= require jquery.fitvid

//= require hover-dropdown.min
//= require plugins/owl.carousel
//= require cropper.min
//= require js-routes
//= require i18n/translations
//= require jquery.jplayer
//= require jquery.scrollTo
//= require select2

//= require cable

//= require ServerDate
//= require crop
//= require intlTelInput
//= require textAreaScroll

//= require jquery.raty
//= require ratyrate

//= require jvalidate/jquery.validate
//= require jvalidate/additional-methods
//= require jvalidate/jvalidate.immerss

//= require unobtrusive_flash
//= require unobtrusive_flash_bootstrap

//= require header

//= require general_websocket_events

//= require pages/home
//= require dashboard

//= require pages/widgets

//= require pages/PAralaxPages/Init

//= require moment
//= require moment-timezone
//= require l2date
//= require fullcalendar

//= require tag-it.min
//= require bootstrap-maxlength

//= require_tree ./templates/application
//= require templates/donate_amount

//= require remaining

//= require profile_forms
//= require devise_forms

//= require_self
//= require blocking_popup
//= require phone_verification

//= require link_to_has_many
//= require presenters
//= require sessions
//= require abstract_session_invite_modals

//= require presenter_video_client
//= require bootstrap-formhelpers-phone
//= require liveStream_onSessionPage
//= require responsiv
//= require clear_search_helper

//= require preview_purchase_missing_confirmed_email
//= require widget/views/users-show-followers

//= require pages/player/player
//= require pages/tiles
//= require_tree ./templates/sessions
//= require_tree ./templates/recordings
//= require pages/sessions/show
//= require pages/sessions/edit
//= require pages/sessions/time_adjust
//= require pages/sessions/sessionsList
//= require pages/profile
//= require session_buy_and_purchase_options

//= require video_page/vidyo/proxywrapper
//= require video_page/vidyo/logger
//= require video_page/vidyo/vidyo.client.messages
//= require video_page/vidyo/vidyo.client.private.messages
//= require video_page/vidyo/vidyo.client

//= require pages/profile/stream_options

//= require pages/notifications
//= require pages/dashboard
//= require pages/faq
//= require pages/about
//= require pages/search
//= require pages/billing
//= require pages/payouts

//= require modals/alerts
//= require modals/sign_in_form
//= require modals/sign_up_form
//= require modals/reset_password_form
//= require modals/almost_done_user_form

//= require donate_amount

//= require_tree ./templates/forms
//= require forms/main
//= require forms/payment_form
//= require forms/customer_subscriptions_payment_form
//= require_tree ./templates/wizard
//= require wizard/wizard
//= require channel/channel
//= require channel/landing
//= require pages/landing
//= require company/company

//= require password_helper
//= require quill_links_validation_helper

//= require theoplayer/THEOplayer_lib
//= require theoplayer/theoplayer
//= require theoplayer/bind_ui_buttons
//= require theoplayer/event_logs
//= require theoplayer/usage_logs
//= require_tree ./views/shared

//= require sessions/create/webrtc.github.adapter
//= require pages/sessions/devices

//= require sourcebuster.min
//= require modules/activestorage
//= require modules/aws-sdk.min.js
//= require airbrake
//= require webpush_register
function uid() {
  return '_' + Math.random().toString(36).substr(2, 9);
}

(function() {
  var pageOverlayHide, pageOverlayShow, scroll, scrollListener, verticalAlignSessionContainers;

  Handlebars.registerHelper("debug", function(optionalValue) {
    console.log("Current Context");
    console.log("-----------------------");
    console.log(this);
    if (optionalValue) {
      console.log("Value");
      console.log("-----------------------");
      return console.log(optionalValue);
    }
  });

  Handlebars.registerHelper('equal', function(lvalue, rvalue, options) {
    if (arguments.length < 3) {
      throw new Error("Handlebars Helper equal needs 2 parameters");
    }
    if (lvalue !== rvalue) {
      return options.inverse(this);
    } else {
      return options.fn(this);
    }
  });

  window.copyToClipboard = function(element) {
    var err, input, msg, successful;
    $(element).html('copied');
    setTimeout(function() {
      return $(element).html('copy');
    }, 1500);
    try {
      input = $(element).parent().find('input[type="text"]');
      $(input).select();
      $('.embedIframeCopyBtn').click();
      successful = document.execCommand('copy');
      msg = successful ? 'successful' : 'unsuccessful';
      console.log('Сopy text command was ' + msg);
      $.showFlashMessage('Сopied!', {
        type: "info"
      });
    } catch (error) {
      err = error;
      console.log('Oops, unable to copy');
      $.showFlashMessage('Oops,Сopy text command was ' + msg + '. please do it manually', {
        type: "error"
      });
    }
    return false;
  };

  window.copyToClipboardTextArea = function(element) {
    var err, msg, successful, textarea;
    $(element).html('copied');
    setTimeout(function() {
      return $(element).html('copy');
    }, 1500);
    try {
      textarea = $(element).parents('.copyToClipboardWrapp').find('textarea');
      $(textarea).select();
      $('.embedIframeCopyBtn').click();
      successful = document.execCommand('copy');
      msg = successful ? 'successful' : 'unsuccessful';
      console.log('Сopy text command was ' + msg);
      $.showFlashMessage('Сopied!', {
        type: "info"
      });
    } catch (error) {
      err = error;
      console.log('Oops, unable to copy');
      $.showFlashMessage('Oops,Сopy text command was ' + msg + '. please do it manually', {
        type: "error"
      });
    }
    return false;
  };

  window.copyTextToClipboard = function(text){
      var hiddenCopy = document.createElement('div');
      hiddenCopy.innerHTML = text;
      hiddenCopy.style.position = 'absolute';
      hiddenCopy.style.left = '-9999px';

      //check and see if the user had a text selection range
      var currentRange;
      if(document.getSelection().rangeCount > 0)
      {
        //the user has a text selection range, store it
        currentRange = document.getSelection().getRangeAt(0);
        //remove the current selection
        window.getSelection().removeRange(currentRange);
      }else{
        //they didn't have anything selected
        currentRange = false;
      }

      document.body.appendChild(hiddenCopy);
      //create a new selection range
      var CopyRange = document.createRange();
      //set the copy range to be the hidden div
      CopyRange.selectNode(hiddenCopy);
      //add the copy range
      window.getSelection().addRange(CopyRange);

      try{
          document.execCommand('copy');
          $.showFlashMessage('Copied', {type: 'success'});
      }catch(err){
        $.showFlashMessage('Oops, failed to copy text. please do it manually', {
          type: "error"
        });
      }

      window.getSelection().removeRange(CopyRange);
      document.body.removeChild(hiddenCopy);

      //return the old selection range
      if(currentRange)
      {
          window.getSelection().addRange(currentRange);
      }
  }

  window.hideOrDisplayPayForThisUserOptions = function() {
    if (typeof deliveryMethodsView !== 'undefined') {
      if (deliveryMethodsView.model.get('immersive_free') === true || deliveryMethodsView.model.get('livestream_free') === true) {
        return $('.pay-for-this-user-container').parent('div').hide();
      } else if (deliveryMethodsView.model.get('immersive_free') === false || deliveryMethodsView.model.get('livestream_free') === false) {
        return $('.pay-for-this-user-container').parent('div').show();
      }
    }
  };

  window.redirect_back_to_after_signup = function(href) {
    var cookie_string, expiration_date;
    expiration_date = new Date();
    expiration_date.setFullYear(expiration_date.getFullYear() + 1);
    cookie_string = ("redirect_back_to_after_signup=" + href + "; path=/; expires=") + expiration_date.toGMTString();
    document.cookie = cookie_string;
    return false;
  };

  window.open_after_signup = function(href) {
    var cookie_string, expiration_date;
    expiration_date = new Date();
    expiration_date.setFullYear(expiration_date.getFullYear() + 1);
    cookie_string = ("open_after_signup=" + href + "; path=/; expires=") + expiration_date.toGMTString();
    document.cookie = cookie_string;
    return false;
  };

  window.set_preview_purchase_cookie = function(key) {
    var cookie_string, expiration_date;
    expiration_date = new Date();
    expiration_date.setFullYear(expiration_date.getFullYear() + 1);
    cookie_string = (key + "=1; path=/; expires=") + expiration_date.toGMTString();
    document.cookie = cookie_string;
    return false;
  };

  String.prototype.toHHMMSS = function (short = true) {
      var sec_num = parseInt(this, 10); // don't forget the second param
      var hours   = Math.floor(sec_num / 3600);
      var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
      var seconds = sec_num - (hours * 3600) - (minutes * 60);

      if (seconds < 10) {seconds = "0"+seconds;}
      if (hours || !short) {
          if (hours   < 10) {hours   = "0"+hours;}
          if (minutes < 10) {minutes = "0"+minutes;}
          return hours+':'+minutes+':'+seconds;
      } else {
          return minutes+':'+seconds;
      }
  }

  String.prototype.toSS = function () {
      return parseInt(this.split(':').reduce((acc,time) => (60 * acc) + +time));
  }

  $.fn.single = function() {
    if (this.length !== 1) {
      throw new Error("Expected 1 matching element, found " + this.length);
    }
    return this;
  };

  $.fn.atLeastOnce = function() {
    if (this.length === 0) {
      throw new Error("Expected >=1 matching element, found " + this.length);
    }
    return this;
  };

  _.templateSettings = {
    interpolate: /\[\%\=(.+?)\%\]/g,
    evaluate: /\[\%(.+?)\%\]/g
  };

  $(document).on('click', '.choose.email', function() {
    var email;
    email = $(this).text();
    return $(this).parent().parent().find('input[type=text]').val(email);
  });

  $(document).on('click', '.social-share', function(e) {
    e.preventDefault();
    return $($(this).data()['socialClass']).modal('toggle');
  });

  $(document).on('click', '.confirm_payment', function() {
    var form;
    form = $(this).parents('form');
    $('<input>').attr({
      type: 'hidden',
      name: 'session[confirm_payment]',
      value: 1
    }).appendTo(form);
    $(this).parents('.modal').modal('hide');
    $('form.session').trigger('submit');
  });

  var token = $('meta[name="csrf-token"]').attr('content');
  if (token) {
    $.ajaxSetup({headers: {'X-CSRF-TOKEN': token}});
  } else {
    console.error('ajax, token not found');
  }

  $(document).on('ajax:success', 'a.session_reminder', function() {
    if ($(this).hasClass('active')) {
      $(this).find('span').html('Set reminder');
      return $(this).removeClass('active');
    } else {
      $(this).find('span').html('Reminder set');
      return $(this).addClass('active');
    }
  });

  verticalAlignSessionContainers = function() {
    if (!$('body').hasClass('single_page_sessions_and_channels')) {
      $('.thumbnails').show();
    }
  };

  window.initializeDateTimes = function () {
      $.each($("abbr.datetime"), function () {
          var l2date;
          l2date = new L2date($(this).data("iso8601"), $(this).data("format"));
          $(this).text(l2date.convertUtcToLocalDisplay());
          return;
      });
  };

    window.domReady = function () {
      if (this.location.pathname.includes('landing')) {
        var nav = document.querySelector('.navbar')
        if(!nav) return
        nav.classList.add('transparent');
        window.addEventListener('scroll', function() {
          if (!window.pageYOffset) {
            nav.classList.add('transparent');
          } else {
            nav.classList.remove('transparent');
          }
        });
      }

        var notlim, owl, slidesNumber, youMayAlsoLikeSwitchHandler;
        $(window).on('shown.bs.modal', function () {
            $('body').addClass('modal-open');
            $('.ui-tooltip').remove();
            return false;
        });
        youMayAlsoLikeSwitchHandler = function () {
            $.ajax({
                type: 'PUT',
                url: $(this).parents('form').attr('action'),
                data: 'value=' + $(this).val(),
                complete: function(){
                    window.location.reload();
                }
            });
        };
        $('select[name*=you_may_also_like]').change(youMayAlsoLikeSwitchHandler);

        if ($('.recordingsOverlay').length > 0) {
            $(".recordingsOverlay").hide();
        }
        if ($('.DashboardNavToggle').length > 0) {
            pageOverlayHide();
            $('.DashboardNavToggle').removeClass('DashboardNavToggleActive');
        }
        if ($('.AffixSection').length > 0) {
            affix();
        }
        if ($('.RM-block').length > 0) {
            RMBlockTextToggle();
        }
        if ($('.Reviews').length > 0) {
            ReviewsToggle();
        }
        if ($('body').hasClass('dashboards')) {
            if ($('.owl-lazy').length) {
                notlim = $('.tile-cake');
                $.each(notlim, function () {
                    var imgOBJ, imgOBJItem, itemattr;
                    imgOBJ = void 0;
                    imgOBJItem = void 0;
                    itemattr = void 0;
                    imgOBJ = $(this).find('.owl-lazy');
                    imgOBJItem = $(imgOBJ).get(0);
                    itemattr = $(imgOBJItem).attr('data-src');
                    $(imgOBJItem).css({
                        'background-image': 'url("' + itemattr + '")',
                        'opacity': 1
                    });
                });
                return;
            }
        }
        if (!($('body.channel_landing').length > 0)) {
            owl = void 0;
            owl = $('.TileSlider');
            slidesNumber = 0;
            owl.on('initialize.owl.carousel', function (event) {
                $('.TileSliderWrapp.owlSlider .spinnerSlider').fadeOut();
                $('.TileSlider').addClass('RedyToshow');
                return false;
            });
            owl.on('initialized.owl.carousel', function (event) {
                var items;
                items = event.item.count;
                if (items < 4) {
                    $(this).addClass('notEnoughItem');
                    notlim = event.relatedTarget._items;
                    $.each(notlim, function (intIndex, objValue) {
                        var imgOBJ, imgOBJItem, itemattr;
                        imgOBJ = $(this).find('.owl-lazy');
                        imgOBJItem = $(imgOBJ).get(0);
                        itemattr = $(imgOBJItem).attr('data-src');
                        $(imgOBJItem).css({
                            'background-image': 'url("' + itemattr + '")',
                            'opacity': 1
                        });
                    });
                    return;
                }
            });
            owl.on('refreshed.owl.carousel', function (event) {
                var i, imgsrc, scopeSize;
                scopeSize = event.page.size;
                i = 0;
                while (i < scopeSize) {
                    imgsrc = $(event.target).find('.owl-item').eq(i).find('.tile-imgContainer').attr('data-src');
                    $(event.target).find('.owl-item').eq(i).find('.tile-imgContainer').attr('style', 'background-image: url(' + imgsrc + ');opacity: 1;');
                    i++;
                }
            });
            owl.each(function () {
                if ($(this).hasClass('CreatorsTileSlider')) {
                    slidesNumber = 2;
                } else if ($(this).hasClass('ChannelTileSlider')) {
                    slidesNumber = -1;
                } else if ($(this).hasClass('BrandsTileSlider')) {
                    slidesNumber = 2;
                } else {
                    slidesNumber = 0;
                }
                $(this).owlCarousel({
                    items: 1,
                    loop: false,
                    callbacks: true,
                    autoWidth: false,
                    nav: true,
                    navText: '',
                    margin: 0,
                    lazyLoad: true,
                    autoplay: false,
                    info: true,
                    responsiveClass: true,
                    responsive: {
                        0: {
                            items: 1,
                            nav: false,
                            loop: false,
                            stagePadding: 40
                        },
                        640: {
                            items: 2,
                            nav: false,
                            stagePadding: 40
                        },
                        991: {
                            items: 3 + slidesNumber
                        },
                        1140: {
                            items: 4 + slidesNumber
                        },
                        1940: {
                            items: 5 + slidesNumber
                        },
                        2240: {
                            items: 6 + slidesNumber
                        }
                    }
                });
                return;
            });
        }
        video_checkbox_click();
        $('a[data-remote]').css('visibility', 'visible');
        setTimeout(function () {
            return $('a[data-remote]').css('visibility', 'visible');
        }, 100);
        initializeJoinTimer();
        verticalAlignSessionContainers();
        $('a[data-method=delete]:contains(Remove)').show();
        window.initializeFormsVisibility();
        $('.modal.autodisplay').modal('toggle');
        $('.tag-it').tagit({
            autocomplete: {},
            showAutocompleteOnFocus: false,
            removeConfirmation: false,
            caseSensitive: true,
            allowDuplicates: false,
            readOnly: false,
            tagLimit: null,
            allowSpaces: true,
            singleField: true,
            singleFieldDelimiter: ',',
            singleFieldNode: null,
            tabIndex: null,
            placeholderText: 'Add tags',
            afterTagAdded: function (event, ui) {
                if (ui.tagLabel.length < 2 || ui.tagLabel.length > 100) {
                    $(event.target).effect('highlight');
                    $(ui.tag).effect('highlight');
                    return $(ui.tag).addClass('error');
                }
            }
        });
        $('.maxlength-tooltip').maxlength({
            placement: 'bottom-right',
            alwaysShow: true,
            warningClass: "label label-success",
            limitReachedClass: "label label-important"
        });
        $('body').popover({
            selector: '.has-popover',
            html: true,
            trigger: 'hover',
            placement: function (tipContent, el) {
                var $el, elLeft, elRight, parentLeft, parentRight;
                $el = $(el);
                elLeft = parseInt($el.css('left'));
                elRight = elLeft + $el.width();
                parentLeft = Math.abs(parseInt($el.parent().css('left')));
                parentRight = parentLeft + $el.parent().parent().width();
                if (elLeft >= parentLeft) {
                    return 'left';
                } else if (elRight <= parentRight) {
                    return 'right';
                } else {
                    return 'top';
                }
            },
            container: 'body',
            delay: {
                show: 0,
                hide: 500
            }
        });
        $('#loginPopup').on('hidden.bs.modal', function () {
            return $(this).find('.controls.error').remove();
        });
        window.initializeDateTimes();
        return scrollListener();
    };

  $(document).ready(function() {
    domReady();

    if ($('.DashboardNavToggle').length > 0) {
      $('.DashboardNavToggle').click(function() {
        return $(this).toggleClass('DashboardNavToggleActive');
      });
      $('.info-tabs ul.nav a').click(function(e) {
        var target = $(e.target);
        if ($('.DashboardNavToggle').is(':visible')
            && !(target.is(':disabled') || target.hasClass('disabled') || target.data('toggle') === 'tab')) {
          return pageOverlayShow();
        }
      });
    }
    $("[title]").not("iframe[class^='drift']").tooltip({
      content: function() {
        return $(this).prop('title');
      },
      position: {
        my: 'center top+5',
        at: 'center bottom+5'
      },
      show: false,
      hide: false
    });
  });

  $(function() {
    if ($(".modal-content form#new_replenishment").length === 1) {
      $(".modal-content form#new_replenishment").validate({
        rules: {
          amount: {
            required: true,
            min: {
              param: 1
            }
          }
        }
      });
    }
    $(document).on("hidden.bs.modal", "#social-modal", function() {
      return $("#social-modal").remove();
    });
    return $(document).on("hidden.bs.modal", "#email-modal-share", function() {
      return $("#email-modal-share").remove();
    });
  });

  if (window.location.hash && window.location.hash === '#_=_') {
    if (window.history && history.pushState) {
      window.history.pushState("", document.title, window.location.pathname + window.location.search);
    } else {
      scroll = {
        top: document.body.scrollTop,
        left: document.body.scrollLeft
      };
      window.location.hash = '';
      document.body.scrollTop = scroll.top;
      document.body.scrollLeft = scroll.left;
    }
  }

  window.markVisibleNotificationsAsRead = function() {
    var markNotificationIdsAsRead;
    markNotificationIdsAsRead = [];
    $.each($('li.notification__new'), function() {
      return markNotificationIdsAsRead.push($(this).data('notification-id'));
    });
    if (markNotificationIdsAsRead.length > 0) {
      return $.post('/notifications/bulk_read', {
        'ids': markNotificationIdsAsRead
      });
    }
  };

  $(function() {
    var $notificationsPopup;
    $notificationsPopup = $("#notificationsPopup, #messagesPopup");
    return $notificationsPopup.find('.timeago').timeago();
  });

  // TODO: is it still used?
  $(function() {
    if ($("body").hasClass("sessions-edit-create-form")) {
      return $('.special-block > a').live('click', function() {
        return $(this).toggleClass("opened");
      });
    }
  });

  $(function() {
    var markMatch;
    $('select.styled-select, .selects_block select').select2({
      minimumResultsForSearch: -1
    });
    $('#timezone-select, select.styled-select-search').select2();
    return markMatch = function(result, term, markup) {
      var match, text, tl;
      text = result.text;
      match = text.toUpperCase().indexOf(term.toUpperCase());
      tl = term.length;
      if (match < 0) {
        markup.push(text);
        return;
      }
      markup.push(text.substring(0, match));
      markup.push('<span class=\'select2-match\' data-catId=\'' + result.id + '\'></span>');
      markup.push(text.substring(match, match + tl));
      markup.push(text.substring(match + tl, text.length));
      markup.push('<div class=\'cat-list\' style=\'display:none\'>' + result.element[0]['title'] + '</div>');
    };
  });

  window.initializeFormsVisibility = function() {
    return $('form').not('.initially_hidden').css('visibility', 'visible').show();
  };

  $(function() {
    return initializeFormsVisibility();
  });

  $(document).on('shown.bs.tab', 'a[data-toggle="tab"]', function(e) {
    return window.initializeDateTimes();
  });

  $(function() {
    if ($.rails) {
      setTimeout(function() {
        return $.rails.ajax = function(options) {
          if (!options.timeout) {
            options.timeout = 100000;
          }
          return $.ajax(options);
        };
      }, 300);
    }
  });

  window.scrollTo1stValidationErrorIfPresent = function() {
    if ($(".help-inline").length > 0) {
      return $('html, body').animate({
        scrollTop: $(".help-inline").first().offset().top - 100
      }, 500);
    }
  };

  window.showErrorFromLobby = function(message, type) {
    if (type === 'alert') {
      return alert(message);
    } else {
      return $.showFlashMessage(message, {
        type: "error"
      });
    }
  };

  scrollListener = function() {
    var body, timer;
    if (!$('body').hasClass('mobile_device')) {
      body = document.body;
      timer = void 0;
      return window.addEventListener('scroll', (function() {
        clearTimeout(timer);
        if (!body.classList.contains('disable-hover')) {
          body.classList.add('disable-hover');
        }
        timer = setTimeout((function() {
          body.classList.remove('disable-hover');
        }), 500);
      }), false);
    }
  };

  pageOverlayShow = function() {
    return $('.mainLoadingCover').show();
  };

  pageOverlayHide = function() {
    return $('.mainLoadingCover').hide();
  };

}).call(this);
$(document).ready(function() {
    $('textarea[data-autoresize]').each(function(i, el) {
        Forms.Helpers.resizeTextarea(this);
    });
});

// check and update JWT
var check_jwt_exp = 2 * 60 * 1000
var update_jwt_if_less = 10 * 60 * 1000

if(ConfigFrontend.security && ConfigFrontend.security.jwt.check_jwt_exp) {
  check_jwt_exp = ConfigFrontend.security.jwt.check_jwt_exp * 60 * 1000
}
if(ConfigFrontend.security && ConfigFrontend.security.jwt.update_jwt_if_less) {
  update_jwt_if_less = ConfigFrontend.security.jwt.update_jwt_if_less * 60 * 1000
}

function jwtParse(token) {
  try {
    return JSON.parse(atob(token.split('.')[1]));
  } catch (e) {
    return null;
  }
};

setInterval(function() {
  if(!jwtParse) return;
  var token = getCookie('_unite_session_jwt');
  if(!token || !jwtParse(token)) { updateJWTToken(); return; }
  var tokenExp = +(jwtParse(token).exp) + '000';
  if(+tokenExp - new Date().getTime() < update_jwt_if_less) {
    updateJWTToken()
  }
}, check_jwt_exp)

function updateJWTToken() {
  var refresh = getCookie('_unite_session_jwt_refresh');
  if(refresh) {
    var Rxmlhttp = new XMLHttpRequest();
    Rxmlhttp.open("GET", "/api/v1/auth/user_tokens");
    Rxmlhttp.setRequestHeader("Authorization", "Bearer " + refresh);
    Rxmlhttp.send()
    Rxmlhttp.onload = function() {
      var res = JSON.parse(Rxmlhttp.response).response
      setCookie("_unite_session_jwt", res.jwt_token, +(jwtParse(res.jwt_token).exp + '000'))
      setCookie("_cable_jwt", res.jwt_token, +(jwtParse(res.jwt_token).exp + '000'), location.hostname)
      setCookie("_unite_session_jwt_refresh", res.jwt_token_refresh, +(jwtParse(res.jwt_token_refresh).exp + '000'))
      localStorage.setItem("_unite_session_jwt_refresh", res.jwt_token_refresh);
      window.eventHub.$emit("updateJwt")
    };
  }
}