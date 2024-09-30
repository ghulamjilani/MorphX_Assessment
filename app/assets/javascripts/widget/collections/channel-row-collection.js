//= require widget/models/channel-model

window.ChannelCollection = Backbone.Collection.extend({
    url: '/sessions',

    initialize: function(models, options) {
      //options || (options = {});
      //this._reset();
      //this.initialize.apply(this, arguments);
      //if (models) this.reset(models, _.extend({silent: true}, options));
      if (options) {
        this.channel_id = options.channel_id;
      }
    },

    parse: function (response, options) {
        //TODO: Review me! It is not a good place for template and its manipulations!
        var popOverHtmlTemplate = HandlebarsTemplates['application/live_guide/session_popover'];
        return _.map(response.channels, function (channel) {
            channel.sessions = _.map(channel.sessions, function (session) {
                var l2date = new L2date(session.start_at);
                var formatted_start_at;
                var data;

                if (session.popover_data.time_format === "12hour") {
                    formatted_start_at = l2date.toCustomFormat("hh:mm a");
                } else {
                    formatted_start_at = l2date.toCustomFormat("HH:mm");
                }
                data = _(session.popover_data).pick("seats_total",
                                                    "seats_occupied",
                                                    "presenter_name",
                                                    "immersive_purchase_price",
                                                    "livestream_purchase_price",
                                                    "duration",
                                                    "title");
                data.formatted_start_at = formatted_start_at;

                data.is_immersive = session.popover_data.is_immersive;
                if (data.is_immersive) {
                  data.availability = (parseInt(data.seats_total, 10) - parseInt(data.seats_occupied, 10)) + ' of ' + data.seats_total;
                }

                data.is_livestream = session.popover_data.is_livestream;

                session.popover_html_content = popOverHtmlTemplate(data);

                session.start_at = l2date.toCustomFormat("MMM D, YYYY HH:mm:00");
                return session;
            });
            return channel;
        });
    },

    fetchByDate: function (formattedDateString, successCallback) {
        if (successCallback === undefined) {
            var successCallback = function (e) {
                // do nothing
            };
        }

        this.fetch({ data: {date: formattedDateString, organizers: Immerss.organizers, channel_id: this.channel_id },
            success: successCallback
        });
    }
});
