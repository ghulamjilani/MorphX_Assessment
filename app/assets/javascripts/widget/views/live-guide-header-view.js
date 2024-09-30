(function() {
  window.LiveGuideHeaderView = Backbone.View.extend({
    tagName: 'div',
    templateSource: "" +
        "<h3 class=\"title\">Live Guide" +
          "<a href=\"#\" data-toggle=\"modal\" data-target=\"#calendar_view\" class=\"vertical-midle calendarShow\" style=\"display:none\">" +
            "<i class=\"VideoClientIcon-classic-calendar-view\"></i>" +
          "</a>" +
          "<span class=\"SubHeader\">[%= subheader_title %]</span>" +
        "</h3>" +
        "<div class=\"schedule-header-opts\">" +
          "<div id=\"date-select-wrapper\">" +
            "<input type=\"text\" id=\"select-date\" name=\"select-date\">" +
            "<input type=\"text\" id=\"alternate\" readonly size=\"10\" value=\"[%= dateString %]\">" +
          "</div>" +
          "<div id=\"timezone-wrapper\">" +
            "<aside title=\"Your current time zone is [%= Immerss.timezone %] [%= timezoneText %] UTC\">" +
              "<label for=\"timezone\" >Timezone: </label>" +
              "<div id=\"timezone_text\" > (UTC[%= timezoneText %]) [%= Immerss.timezone %]</div>" +
            "</aside>" +
          "<div class='switch-container'>" +
            "<div class='switch-wrapper'>" +
              "<div class='switch'>" +
                "<span class='format btn1 [%= active12h %]' data-on-text=\"12h\" data-format='12hour'>12h</span>" +
              "</div>" +
              "<div class='switch'>" +
                "<span class='format btn2 [%= active24h %]' data-off-text=\"24h\" data-format='24hour'>24h</span>" +
              "</div>" +
            "</div>" +
          "</div></div>" +
        "</div>" +
        "<div class=\"clearfix\"></div>" +
        "<div id=\"week-days-container\"></div>" +
        "<div class=\"clearfix\"></div>",
    initialize: function(options) {
      this.parentView = options.parentView;
      this.template = _.template(this.templateSource);
      this.subheader_title = options.subheader_title;
      this.container = options.container;
      $(document).on('click', '.format', _.bind(this.sendTimeFormat, this));
      $(document).on('click', '.week_day', _.bind(this._weekDayClicked, this));
      $(document).on('click', ".format", function() {
        $(".format").removeClass('active');
        $(this).addClass('active');
      });
    },
    sendTimeFormat: function(event){
      event.preventDefault();
      event.stopPropagation();
      let format = $(event.target).data('format');
      console.log(event.target);
      $.ajax({
        type: "POST",
        data: { _method: 'PUT', time_format: format},
        url: 'time_format',
        success: function() {
            location.reload();
        }
      })
    },
    weekDaysTemplate: function(data) {
      var template;
      template = _.template(HandlebarsTemplates['application/live_guide/week_days'](data));
      template.apply(this, arguments);
    },
    render: function() {
      this.container.html(this.template({
        subheader_title: this.subheader_title,
        time_format: Immerss.timeFormat,
        active12h: ('12hour' == Immerss.timeFormat ? 'active' : ''),
        active24h: ('24hour' == Immerss.timeFormat ? 'active' : ''),
        timezoneText: this.parentView.options.timezoneText,
        dateString: this.parentView.options.dateString
      }));
      this._activateDatePicker();
      if ($('body').hasClass('channel_landing')) {
        $('a.calendarShow').single().show();
      }
      $('#week-days-container').single().html(this.weekDaysTemplate({
        dateString: this.parentView.options.dateString
      }));
    },
    _activateDatePicker: function() {
      var options, self;
      self = this;
      options = {
        altFormat: "MM dd, yy",
        altField: "#alternate",
        showOn: "button",
        buttonText: '<i class="VideoClientIcon-calendarF"></i>',
        dateFormat: "MM dd, yy",
        beforeShow: function(input, inst) {
          return _.defer(function() {
            return inst.dpDiv.css({
              "z-index": 999
            });
          });
        },
        onSelect: function() {
          var dateString;
          dateString = $(this).val();
          self.parentView.options.dateString = dateString;
          return LiveGuide.trigger('dateString:updated');
        }
      };
      return $('#select-date').single().attr('readonly', 'readonly').datepicker(options);
    },
    _weekDayClicked: function(eventOrDateString) {
      var dateString, dayButtons, event;
      event = null;
      dateString = null;
      if (typeof eventOrDateString === 'object') {
        event = eventOrDateString;
        dateString = $(event.currentTarget).data('value');
        event.preventDefault();
      } else {
        dateString = eventOrDateString;
      }
      dayButtons = $('#week-days-container').single().find('a:not(".jumpTo")');
      dayButtons.removeClass('active');
      dayButtons.filter('[data-value="' + dateString + '"]').addClass('active');
      this.parentView.options.dateString = dateString;
      LiveGuide.trigger('dateString:updated');
      return $('#select-date').single().datepicker("setDate", dateString);
    }
  });

}).call(this);
