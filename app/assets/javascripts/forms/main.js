//= require_self

//= require ./shared/base/mixin
//= require_tree ./helpers

//= require_tree ./shared/base
//= require_tree ./shared/views
//= require_tree ./shared/models

//= require ./channels/app
//= require ./presenters/app
//= require ./profiles/app
//= require ./sessions/app

//= require ./number_input.js

(function () {
    this.Forms = {
        Models: {},
        Views: {},
        Helpers: {
            resizeTextarea: function (element) {
                autosize($(element));
                return $(element).trigger('textarea:resized');
            },
            formatInput: function (element) {
                return $(element).val($(element).val().replace(/[\s]+/, ' ').trim());
            },
            setCount: function (element) {
                var len;
                len = $(element).val().length;
                return $(element).parents('.input-block').find('.counter_block').html(len + "/" + ($(element).attr('max-length')));
            }
        }
    };

    _.extend(Forms, Backbone.Events);

    $(function () {
        var elements;
        elements = '.form_V2 .select-block select,' + '.form_V2 .input-block textarea,' + '.form_V2 .input-block input[type=text],' + '.form_V2 .input-block input[type=password],' + '.form_V2 .input-block input[type=email],' + '.form_V2 .input-block input[type=tel]';
        $(elements).each(function() {
          if ($(this).val() != "") {
            $(this).parents('.select-block, .input-block').addClass('event-focus');
          }
        });
        return $('body:not(.session-form)').on('focus', elements, function (e) {
            return $(this).parents('.select-block, .input-block').addClass('event-focus');
        }).on('blur', elements, function (e) {
            $(this).parents('.input-block, .select-block').removeClass('event-focus');
            if ($(this).val() || $(this).attr('placeholder')) {
                return $(this).parents('.input-block').removeClass('state-clear');
            } else {
                return $(this).parents('.input-block').addClass('state-clear');
            }
        }).on('keydown keyup focus blur change', '.input-block textarea', function (e) {
            Forms.Helpers.resizeTextarea(this);
            return Forms.Helpers.setCount(this);
        });
    });
}).call(this);
