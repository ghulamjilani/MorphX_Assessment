(function() {
  window.ChannelTableRowView = Backbone.View.extend({
    tagName: 'tr',
    initialize: function(options) {
      return this.timeIndicatorLeftMarginPx = options.timeIndicatorLeftMarginPx;
    },
    template: function(data) {
      var template;
      template = _.template(HandlebarsTemplates['application/live_guide/channel_table_tr'](data));
      return template.apply(this, arguments);
    },
    render: function() {
      var data;
      data = this.model.toJSON();
      data.timeIndicatorLeftMarginPx = this.timeIndicatorLeftMarginPx;
      this.$el.html(this.template(data));
      return this.$el.attr('style', 'height: 26px');
    }
  });

}).call(this);
