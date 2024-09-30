//= require widget/models/channel-model
//= require widget/collections/channel-row-collection
//= require widget/views/live-guide-header-view
//= require widget/views/channel-table-row-view
//= require widget/lib/horizontal_scroll

(function() {
  var scrollLeft, scrollRight;

  window.LiveGuide = _.extend({}, Backbone.Events);

  scrollLeft = function(shiftPx) {
    if (shiftPx < 0) {
      throw new Error('shift must be positive');
    }
    return $('.schedule-inner-container').animate({
      left: "+=" + shiftPx
    }, 700, function() {
      return $(window).trigger("hscroll.complete");
    });
  };

  scrollRight = function(shiftPx) {
    if (shiftPx < 0) {
      throw new Error('shift must be positive');
    }
    return $('.schedule-inner-container').animate({
      left: "-=" + shiftPx
    }, 700, function() {
      return $(window).trigger("hscroll.complete");
    });
  };

  window.LiveGuideView = Backbone.View.extend({
    hasRows: false,
    templateSource: "<div id=\"live-guide-header-container\"></div>\n\n<table id=\"channel-table\" class=\"table\">\n  <thead></thead>\n  <tbody></tbody>\n  <tfoot></tfoot>\n</table>",
    visibleTimeIntervalsCount: 6,
    numberOfSectionsPerHour: 2,
    initialize: function(options) {
      var successCallback;
      this.options = options;
      this.container = this.options.container;
      this.template = _.template(this.templateSource);
      this.container.html(this.template());
      this.headerView = new LiveGuideHeaderView({
        subheader_title: options.subheader_title,
        parentView: this,
        container: $('#live-guide-header-container')
      });
      this.collection.on('sync', this.render, this);
      this.collection.on('sync', this.initHScroll, this);
      window.liveGuideView = this;
      LiveGuide.on("dateString:updated", this._dateStringChanged, this);
      this.options.dateString = this.options.currentDateString;
      successCallback = (function(_this) {
        return function() {
          return _this.render();
        };
      })(this);
      this.collection.fetchByDate(this.options.dateString, successCallback);
      return $(window).bind("resize", (function(_this) {
        return function() {
          var currentPosX;
          _this.visibleTimeIntervalsCount = $("#channel-table").width() / _this.originalItemWidth;
          currentPosX = Math.abs(parseInt($('.schedule-inner-container').css("left")));
          if (currentPosX > _this.maxPosX()) {
            return $('.schedule-inner-container').css("left", -1 * _this.maxPosX());
          }
        };
      })(this));
    },
    theadTemplate: function(data) {
      var template;
      template = _.template(HandlebarsTemplates['application/live_guide/channel_table_thead'](data));
      return template.apply(this, arguments);
    },
    tfootTemplate: function(data) {
      var template;
      template = _.template(HandlebarsTemplates['application/live_guide/channel_table_tfoot'](data));
      return template.apply(this, arguments);
    },
    halfHourWidth: function() {
      return $("#channel-table").width() / this.visibleTimeIntervalsCount;
    },
    _timeIndicatorLeftMarginPx: function() {
      var currentHourNumerical;
      if (this._chosenDayIsCurrentDay()) {
        currentHourNumerical = this.options.currentTimeHour + this.options.currentTimeMinute / 60;
        return this.halfHourWidth() * this.numberOfSectionsPerHour * currentHourNumerical;
      } else {
        return null;
      }
    },
    _renderBody: function() {
      var i, len, model, ref, scheduleContainerWidth, self, visibleRowsCount;
      $('#channel-table thead').empty();
      $('#channel-table tbody').empty();
      $('#channel-table tfoot').empty();
      if (this.collection.length === 0) {
        return $('#channel-table tbody').html('<tr><td align="center" style="padding: 12px 0" width="100%"><font style="font-size:18px">' + I18n.t('home.live_guide_blank') + '</font></td></tr>');
      } else {
        $('#channel-table thead').html(this.theadTemplate({
          time_format: Immerss.timeFormat,
          collection: this.collection,
          timeIndicatorLeftMarginPx: this._timeIndicatorLeftMarginPx()
        }));
        $('#channel-table tfoot').html(this.tfootTemplate({
          collection: this.collection,
          timeIndicatorLeftMarginPx: this._timeIndicatorLeftMarginPx()
        }));
        scheduleContainerWidth = $("#channel-table").width();
        $(".time-container").width(this.halfHourWidth());
        this.originalItemWidth = this.halfHourWidth();
        this._setupRowNavigationListeners();
        self = this;
        ref = this.collection.models;
        for (i = 0, len = ref.length; i < len; i++) {
          model = ref[i];
          model;
          self._addRow.call(self, model);
          if (this.collection.length > this.visibleTimeIntervalsCount) {
            visibleRowsCount = this.visibleTimeIntervalsCount;
          } else {
            visibleRowsCount = this.collection.length;
          }
        }
        $.each($('.schedule-item.has-popover'), function() {
          var background;
          background = $(this).css('background-color');
          return $(this).css('color', invertColor(background));
        });
        this.setVerticalNavigationHeight();
        if (this._chosenDayIsCurrentDay()) {
          return this._scrollToCurrentMoment();
        } else {
          return this._scrollToBeginning();
        }
      }
    },
    setVerticalNavigationHeight: function() {
      var heightOfVisibleRowsWithToolbars;
      heightOfVisibleRowsWithToolbars = -2;
      heightOfVisibleRowsWithToolbars += $('.second-header-line').height();
      heightOfVisibleRowsWithToolbars += $('#channel-table tbody').height();
      $(".navig-left").height(heightOfVisibleRowsWithToolbars);
      return $(".navig-right").height(heightOfVisibleRowsWithToolbars);
    },
    render: function() {
      this.visibleTimeIntervalsCount = 6;
      this.headerView.render();
      this._renderBody();
    },
    _dateStringChanged: function() {
      var successCallback;
      successCallback = (function(_this) {
        return function() {
          return _this.headerView.render();
        };
      })(this);
      return this.collection.fetchByDate(this.options.dateString, successCallback);
    },
    _addRow: function(model) {
      var trView;
      trView = new ChannelTableRowView({
        model: model,
        timeIndicatorLeftMarginPx: this._timeIndicatorLeftMarginPx()
      });
      trView.render();
      return $('#channel-table tbody').append(trView.el);
    },
    _navigationRightClicked: function(e) {
      var contentWidth, pos;
      e.preventDefault();
      $('.schedule-inner-container').finish();
      pos = Math.abs(parseInt($('.schedule-inner-container').css("left"), 10));
      contentWidth = this.halfHourWidth() * (this.visibleTimeIntervalsCount / 2);
      if (this.maxPosX() - pos < contentWidth) {
        contentWidth = this.maxPosX() - pos;
      }
      if (pos < this.maxPosX()) {
        return scrollRight(contentWidth);
      }
    },
    _navigationLeftClicked: function(e) {
      var contentWidth, min_pos, pos;
      e.preventDefault();
      $('.schedule-inner-container').finish();
      pos = parseInt($('.schedule-inner-container').css("left"), 10);
      contentWidth = this.halfHourWidth() * (this.visibleTimeIntervalsCount / 2);
      min_pos = contentWidth * -1;
      if (pos <= min_pos) {
        return scrollLeft(contentWidth);
      } else {
        $('.schedule-inner-container').css('left', 0);
        return $(window).trigger("hscroll.complete");
      }
    },
    _setupRowNavigationListeners: function() {
      $(document).off('click', '.navig-right');
      $(document).on('click', '.navig-right', _.bind(this._navigationRightClicked, this));
      $(document).off('click', '.navig-left');
      return $(document).on('click', '.navig-left', _.bind(this._navigationLeftClicked, this));
    },
    _chosenDayIsCurrentDay: function() {
      return this.options.dateString === this.options.currentDateString;
    },
    _virtual_display_based_on_hour: function(currentHourNumerical) {
      return currentHourNumerical * this.numberOfSectionsPerHour / this.visibleTimeIntervalsCount;
    },
    _scrollToCurrentMoment: function() {
      var currentHourNumerical, offset, virtual_display_width;
      currentHourNumerical = this.options.currentTimeHour + this.options.currentTimeMinute / 60;
      virtual_display_width = this.halfHourWidth() * this.visibleTimeIntervalsCount;
      offset = this._virtual_display_based_on_hour(currentHourNumerical);
      offset = offset <= 0.5 ? 0 : offset - 0.5;
      return scrollRight(offset * virtual_display_width);
    },
    _scrollToBeginning: function() {
      return $('.schedule-inner-container').finish().animate({
        left: "0px"
      }, 700);
    },
    maxPosX: function() {
      var visibleAreaWidth;
      visibleAreaWidth = this.halfHourWidth() * this.visibleTimeIntervalsCount;
      return visibleAreaWidth * (this.numberOfSectionsPerHour * 24 / this.visibleTimeIntervalsCount) - visibleAreaWidth;
    },
    initHScroll: function() {
      return this.hScroller = new HorizontalScroll(this);
    }
  });

}).call(this);
