//= require_self

//= require ./business
//= require ./channel

(function () {
    window.Wizard = {
        Cache: {},
        Collections: {},
        Models: {},
        Views: {},
        Utils: {
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
        },
        business_load: function () {
            return this.Cache.business_view = new window.Wizard.Views.Business();
        },
        channel_load: function () {
            return this.Cache.channel_view = new window.Wizard.Views.Channel();
        }
    };

    _.extend(window.Wizard, Backbone.Events);

    $(function () {

        /* Timezone things */
        var timestamp;
        timestamp = moment().tz(Intl.DateTimeFormat().resolvedOptions().timeZone).format('Z');
            if (timestamp) {
              $.cookie('tzinfo', timestamp);
              return $('[name="user[tzinfo]"]').val(timestamp);
            }
        return $("select").tooltip({
            disabled: true
        });
    });

}).call(this);
