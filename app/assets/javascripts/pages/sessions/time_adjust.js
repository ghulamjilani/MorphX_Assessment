(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function() {
    'use strict';
    var AbsctractSession, ChannelView, DateRangeView, SessionView, hourFormat, mediator;
    mediator = {};
    _.extend(mediator, Backbone.Events);
    if (Immerss.timeFormat === '12hour') {
      hourFormat = 'hh:mm a';
    } else {
      hourFormat = 'HH:mm';
    }
    Handlebars.registerHelper('sectionTitlePosLeft', function(position, itemsNum, lengthPerSection) {
      return position * lengthPerSection + itemsNum * lengthPerSection / 2 - 74 / 2;
    });
    AbsctractSession = (function(superClass) {
      extend(AbsctractSession, superClass);

      function AbsctractSession() {
        return AbsctractSession.__super__.constructor.apply(this, arguments);
      }

      AbsctractSession.prototype.timeZone = Immerss.timezoneOffset;

      AbsctractSession.prototype.defaults = {
        pre_time: 0
      };

      AbsctractSession.prototype.initialize = function(attrs, options) {
        var startAt;
        this.set({
          start_at: moment(attrs.start_at).utcOffset(this.timeZone),
          duration: attrs.duration || 30
        }, {
          silent: true
        });
        return this.on('change:start_at change:duration', this.loadNextPage);
      };

      AbsctractSession.prototype.isOverlaps = function(anotherSession) {
        var anotherEndAt, anotherStartAt, endAt, startAt;
        startAt = this.actualStartAt().toDate();
        endAt = this.actualEndAt().toDate();
        anotherStartAt = anotherSession.actualStartAt().toDate();
        anotherEndAt = anotherSession.actualEndAt().toDate();
        return (startAt - anotherEndAt) * (anotherStartAt - endAt) > 0;
      };

      AbsctractSession.prototype.actualStartAt = function() {
        return this.get('start_at').clone().subtract(this.get('pre_time'), 'm');
      };

      AbsctractSession.prototype.actualEndAt = function() {
        return this.get('start_at').clone().add(this.get('duration'), 'm');
      };

      AbsctractSession.prototype.saveToForm = function() {
        var $form, currentModelName, custom_start_at, hours, minutes, startAt;
        if (this.get('type') !== 'current') {
          return;
        }
        $form = this.collection.$objectForm;
        currentModelName = this.currentModelName();
        startAt = this.get('start_at');
        $form.find("#datepicker1").val((startAt.month() + 1) + "/" + (startAt.date()) + "/" + (startAt.year()));
        $form.find("input[name='" + currentModelName + "[start_at(1i)]']").val(startAt.year());
        $form.find("input[name='" + currentModelName + "[start_at(2i)]']").val(startAt.month() + 1);
        $form.find("input[name='" + currentModelName + "[start_at(3i)]']").val(startAt.date());
        hours = startAt.hour() < 10 ? "0" + startAt.hour() : startAt.hour();
        minutes = startAt.minute() < 10 ? "0" + startAt.minute() : startAt.minute();

        var momentStartAt = moment(startAt);
        momentStartAt.utcOffset(momentStartAt._tzm);
        custom_start_at = momentStartAt.format();
        $form.find("select[name='" + currentModelName + "[start_at(4i)]']").val(hours);
        $form.find("select[name='" + currentModelName + "[start_at(4i)]']").trigger("change");
        $form.find("select[name='" + currentModelName + "[start_at(5i)]']").val(minutes);
        $form.find("select[name='" + currentModelName + "[start_at(5i)]']").trigger("change");
        $form.find("select[name='" + currentModelName + "[custom_start_at]']").val(custom_start_at.toString());
        $form.find("select[name='" + currentModelName + "[custom_start_at]']").trigger("change");
        $form.find("[name='" + currentModelName + "[duration]']").val(this.get('duration'));
        $form.find("[name='" + currentModelName + "[duration]']").trigger('change');
        if (this.isSession()) {
          return $form.find("select[name='" + currentModelName + "[pre_time]']").val(this.get('pre_time'));
        }
      };

      AbsctractSession.prototype.currentModelName = function() {
        return this.get('class').toLocaleLowerCase();
      };

      AbsctractSession.prototype.isSession = function() {
        return this.currentModelName() === 'session';
      };

      AbsctractSession.prototype.isCurrent = function() {
        return this.get('type') === 'current';
      };

      AbsctractSession.prototype.loadNextPage = function() {
        if (this.actualEndAt().diff(this.collection.maxDate(), 'm') >= 0) {
          return this.collection.loadNextPage();
        }
      };

      return AbsctractSession;

    })(Backbone.Model);
    window.AbstractSessions = (function(superClass) {
      extend(AbstractSessions, superClass);

      function AbstractSessions() {
        this.setChannel = bind(this.setChannel, this);
        return AbstractSessions.__super__.constructor.apply(this, arguments);
      }

      AbstractSessions.prototype.model = AbsctractSession;

      AbstractSessions.prototype.minutesPerSection = 30;

      AbstractSessions.prototype.minimumMinutesStep = 15;

      AbstractSessions.prototype.minimumDurationStep = 5;

      AbstractSessions.prototype.minimumDurationValue = window.Immerss.minimumSessionDuration;

      AbstractSessions.prototype.maximumDurationValue = window.Immerss.maximumSessionDuration;

      AbstractSessions.prototype.minimumPretimeValue = 0;

      AbstractSessions.prototype.maximumPretimeValue = window.Immerss.maxPreTime;

      AbstractSessions.prototype.ratio = 3;

      AbstractSessions.prototype.currentPage = 1;

      AbstractSessions.prototype.hoursPerPage = 8;

      AbstractSessions.prototype.initialize = function(models, options) {
        this.$objectForm = options.objectForm;
        this.url = options.url;
        this.on('reset', this.setChannels);
        return this.on('reset', this.setDateRange);
      };

      AbstractSessions.prototype.comparator = function(model) {
        return model.actualStartAt().toDate();
      };

      AbstractSessions.prototype.setChannels = function() {
        var nonCurrentSessions;
        this._channel = 2;
        if (this.length === 0) {
          return;
        }
        this.currentSession().set({
          channel: 1
        }, {
          silent: true
        });
        nonCurrentSessions = this.reject(function(session) {
          return session.get('type') === 'current';
        });
        return _(nonCurrentSessions).each(this.setChannel);
      };

      AbstractSessions.prototype.setChannel = function(session) {
        var channelWithoutOverlaps;
        channelWithoutOverlaps = _.find(_.range(2, this._channel + 1), (function(_this) {
          return function(subChannel) {
            return _(_this.where({
              channel: subChannel
            })).all(function(alreadyPresentSession) {
              return !session.isOverlaps(alreadyPresentSession);
            });
          };
        })(this));
        if (channelWithoutOverlaps) {
          return session.set({
            channel: channelWithoutOverlaps
          }, {
            silent: true
          });
        } else {
          this._channel = this._channel + 1;
          return session.set({
            channel: this._channel
          }, {
            silent: true
          });
        }
      };

      AbstractSessions.prototype.getVisibleDateRange = function() {
        var current, maxDate, minDate, name, position, range;
        minDate = this.minDate();
        maxDate = this.maxDate();
        range = {};
        position = 0;
        while (minDate <= maxDate) {
          current = minDate.clone();
          range[name = current.format('MM/DD/YYYY')] || (range[name] = {
            position: position,
            items: []
          });
          range[current.format('MM/DD/YYYY')].items.push({
            time: current.format(hourFormat),
            position: position
          });
          position += 1;
          minDate.add(this.minutesPerSection, 'm');
        }
        return range;
      };

      AbstractSessions.prototype.minDate = function() {
        this._minDate || (this._minDate = this.firstStartAt().subtract(window.Immerss.maxPreTime, 'm').minute(0).second(0));
        return this._minDate.clone();
      };

      AbstractSessions.prototype.maxDate = function() {
        var lastDate;
        if (!this._maxDate) {
          lastDate = this.lastEndedAt();
          if (lastDate.diff(this.firstStartAt(), 'hours') <= this.hoursPerPage * this.currentPage) {
            this._maxDate = this.minDate().add(this.hoursPerPage * this.currentPage, 'h').minute(0).second(0);
          } else {
            this._maxDate = lastDate.add(1, 'h').minute(0).second(0);
          }
        }
        return this._maxDate.clone();
      };

      AbstractSessions.prototype.lastEndedAt = function() {
        return _(this.sortBy(function(session) {
          return session.actualEndAt().toDate();
        })).last().actualEndAt();
      };

      AbstractSessions.prototype.firstStartAt = function() {
        return this.first().actualStartAt();
      };

      AbstractSessions.prototype.setDateRange = function() {
        if (this.length === 0) {
          return;
        }
        this._maxDate = null;
        this._minDate = null;
        this.maxDate();
        return this.minDate();
      };

      AbstractSessions.prototype.loadNextPage = function() {
        var currentSession, params, prefix, successCallback;
        currentSession = this.findWhere({
          type: "current"
        });
        prefix = currentSession.get("class").toLowerCase();
        params = {};
        params[prefix] = {};
        params[prefix]["start_at"] = currentSession.get("start_at").toJSON();
        params[prefix]["duration"] = currentSession.get("duration");
        params[prefix]["title"] = $("[name=\"" + prefix + "[title]\"]").val();
        params.start_at = this.minDate().toJSON();
        params.end_at = this.currentSession().actualEndAt().add(this.hoursPerPage, 'h').toJSON();
        successCallback = (function(_this) {
          return function(collection) {
            return collection.currentPage += 1;
          };
        })(this);
        return this.fetch({
          reset: true,
          data: params,
          success: successCallback
        });
      };

      AbstractSessions.prototype.isCurrentHasOverlap = function() {
        var currentSession, otherSessions;
        if (this.length === 0) {
          return false;
        }
        currentSession = this.currentSession();
        otherSessions = this.reject(function(session) {
          return session.get("type") === "current";
        });
        return _(otherSessions).any(function(session) {
          return currentSession.isOverlaps(session);
        });
      };

      AbstractSessions.prototype.isOverlapsWith = function(anotherSession) {
        var otherSessions;
        otherSessions = this.reject(function(session) {
          return session.get("type") === "current";
        });
        return _(otherSessions).any(function(session) {
          return anotherSession.isOverlaps(session);
        });
      };

      AbstractSessions.prototype.currentSession = function() {
        return this.findWhere({
          type: "current"
        });
      };

      AbstractSessions.prototype.orderedByChannel = function() {
        return this.sortBy(function(session) {
          return session.get("channel");
        });
      };

      return AbstractSessions;

    })(Backbone.Collection);
    window.SessionsView = (function(superClass) {
      extend(SessionsView, superClass);

      function SessionsView() {
        return SessionsView.__super__.constructor.apply(this, arguments);
      }

      SessionsView.prototype.region = "body";

      SessionsView.prototype.listSelector = ".channels-container";

      SessionsView.prototype.events = {
        'click .save': 'saveChanges'
      };

      SessionsView.prototype.initialize = function() {
        this.template = HandlebarsTemplates['application/overlapped_sessions'];
        this.$region = $(this.region);
        this.viewsByCid = {};
        this.channelsViews = {};
        this.listenTo(this.collection, 'reset', this.reRenderSubviews);
        mediator.on("disable-submit", this.disableDoneButton, this);
        mediator.on("enable-submit", this.enableDoneButton, this);
        return this.render();
      };

      SessionsView.prototype.getTemplateData = function() {
        var data;
        data = this.collection.toJSON();
        data.channels = _.uniq(this.collection.pluck('channel'));
        data.title = window.Immerss.title;
        return data;
      };

      SessionsView.prototype.renderAllItems = function() {
        var i, item, len, ref, results;
        ref = this.collection.orderedByChannel();
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          results.push(this.renderItem(item));
        }
        return results;
      };

      SessionsView.prototype.renderItem = function(item) {
        var view;
        view = this.viewsByCid[item.cid];
        if (!view) {
          view = new SessionView({
            model: item
          });
          this.viewsByCid[item.cid] = view;
        }
        this.getChannelView(item.get('channel')).$el.append(view.$el);
        return view.render();
      };

      SessionsView.prototype.getChannelView = function(channelNum) {
        var view;
        view = this.channelsViews[channelNum];
        if (!view) {
          view = new ChannelView({
            $region: this.$listSelector
          });
        }
        this.channelsViews[channelNum] = view;
        return view;
      };

      SessionsView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        this.$listSelector = this.$(this.listSelector);
        this.adjustWidth();
        this.renderDateRanges();
        this.renderAllItems();
        this.$region.append(this.$el);
        return this.initModal();
      };

      SessionsView.prototype.initModal = function() {
        this.modal = this.$(".modal");
        this.modal.on("hide.bs.modal", _.bind(this.dispose, this));
        this.modal.modal();
        return $('body').addClass('allBlur');
      };

      SessionsView.prototype.dispose = function() {
        var channelNum, cid, i, len, prop, properties, ref, ref1, ref2, view;
        if (this.disposed) {
          return;
        }
        this.stopListening(this.collection);
        this.modal.data("bs.modal").removeBackdrop();
        $('body').removeClass('allBlur');
        $('body').removeClass('modal-open');
        ref = this.viewsByCid;
        for (cid in ref) {
          view = ref[cid];
          view.dispose();
        }
        ref1 = this.channelsViews;
        for (channelNum in ref1) {
          view = ref1[channelNum];
          view.dispose();
        }
        if ((ref2 = this.dateRangeView) != null) {
          ref2['dispose']();
        }
        mediator.off();
        this.off();
        this.$el.remove();
        properties = ['el', '$el', 'collection', 'template', 'modal', '$listSelector', 'viewsByCid', '$region', 'channelsViews', 'dateRangeView'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      SessionsView.prototype.saveChanges = function(event) {
        event.preventDefault();
        this.collection.findWhere({
          type: 'current'
        }).saveToForm();
        return this.dispose();
      };

      SessionsView.prototype.renderDateRanges = function() {
        var ref;
        if ((ref = this.dateRangeView) != null) {
          ref['dispose']();
        }
        return this.dateRangeView = new DateRangeView({
          collection: this.collection,
          $region: this.$(".daterange-container")
        });
      };

      SessionsView.prototype.adjustWidth = function() {
        var dateRange, pixelsPerSection, sectionsTotal;
        dateRange = this.collection.getVisibleDateRange();
        pixelsPerSection = this.collection.ratio * this.collection.minutesPerSection;
        sectionsTotal = _.flatten(_(_(dateRange).values()).pluck('items')).length;
        return this.$(".daterange-container, .channels-container").css({
          width: pixelsPerSection * sectionsTotal
        });
      };

      SessionsView.prototype.reRenderSubviews = function() {
        var channelNum, cid, ref, ref1, view;
        ref = this.viewsByCid;
        for (cid in ref) {
          view = ref[cid];
          view.dispose();
          delete this.viewsByCid[cid];
        }
        ref1 = this.channelsViews;
        for (channelNum in ref1) {
          view = ref1[channelNum];
          view.dispose();
          delete this.channelsViews[channelNum];
        }
        this.adjustWidth();
        this.renderDateRanges();
        return this.renderAllItems();
      };

      SessionsView.prototype.disableDoneButton = function() {
        return this.$(".save").addClass("disabled");
      };

      SessionsView.prototype.enableDoneButton = function() {
        return this.$(".save").removeClass("disabled");
      };

      return SessionsView;

    })(Backbone.View);
    SessionView = (function(superClass) {
      extend(SessionView, superClass);

      function SessionView() {
        this.onResizeDragStart = bind(this.onResizeDragStart, this);
        this.setPretime = bind(this.setPretime, this);
        this.setDuration = bind(this.setDuration, this);
        this.setStartAt = bind(this.setStartAt, this);
        this.getPopoverData = bind(this.getPopoverData, this);
        return SessionView.__super__.constructor.apply(this, arguments);
      }

      SessionView.prototype.className = 'session-item';

      SessionView.prototype.zeroMinuteOffset = 4;

      SessionView.prototype.initialize = function() {
        this.template = HandlebarsTemplates['application/overlapped_session'];
        this.minDate = this.model.collection.minDate();
        this.ratio = this.model.collection.ratio;
        return this.listenTo(this.model, 'change', this.updatePopoverContent);
      };

      SessionView.prototype.getTemplateData = function() {
        var data;
        data = this.model.toJSON();
        data.isCurrent = this.model.isCurrent();
        data.isSession = this.model.isSession();
        return data;
      };

      SessionView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        this.setStyles();
        this.initPopOver();
        if (this.model.isCurrent()) {
          this.allowStartAtChange();
          this.allowDurationChange();
          if (this.model.isSession()) {
            this.allowPretimeChange();
          }
          this.checkOverlaps();
          return this.initStarEndTooltips();
        }
      };

      SessionView.prototype.getPopoverData = function() {
        var data, formatted_start_at, l2date, templateFunc;
        templateFunc = HandlebarsTemplates['application/overlapped_session_popover'];
        l2date = new L2date(this.model.get('start_at'));
        if (Immerss.timeFormat === '12hour') {
          formatted_start_at = l2date.toCustomFormat("hh:mm a");
        } else {
          formatted_start_at = l2date.toCustomFormat("HH:mm");
        }
        data = {
          formattedDateTime: formatted_start_at,
          duration: this.model.get('duration'),
          preTime: this.model.get('pre_time'),
          humanType: this.model.get('human_type'),
          isSession: this.model.isSession()
        };
        return templateFunc(data);
      };

      SessionView.prototype.initPopOver = function() {
        return this.$el.popover({
          html: true,
          trigger: 'hover',
          placement: 'auto bottom',
          container: 'body',
          template: '<div class="popover timeoverlap" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>',
          delay: {
            show: 0,
            hide: 100
          },
          content: this.getPopoverData
        });
      };

      SessionView.prototype.updatePopoverContent = function() {
        var popOver;
        popOver = this.$el.data('bs.popover');
        if (popOver.tip().is(":visible")) {
          return popOver.show();
        }
      };

      SessionView.prototype.setStyles = function() {
        var containerEnd, containerStart, preTimeStart, preTimeWidth, sessionStart, sessionWidth;
        containerStart = this.model.get('start_at').diff(this.minDate, 'minutes') * this.ratio;
        containerEnd = this.model.actualEndAt().diff(this.minDate, 'minutes') * this.ratio - containerStart;
        sessionStart = this.zeroMinuteOffset;
        preTimeStart = this.model.actualStartAt().diff(this.minDate, 'minutes') * this.ratio - containerStart;
        preTimeWidth = preTimeStart * -1 + this.zeroMinuteOffset;
        sessionWidth = containerEnd - sessionStart;
        if (preTimeWidth === 0) {
          preTimeWidth = this.zeroMinuteOffset;
          preTimeStart = preTimeStart - this.zeroMinuteOffset;
        }
        this.$el.css({
          left: containerStart,
          width: sessionWidth
        });
        this.$('.start-at').css({
          left: sessionStart,
          width: sessionWidth
        });
        return this.$('.pre-time').css({
          left: preTimeStart,
          width: preTimeWidth
        });
      };

      SessionView.prototype.allowStartAtChange = function() {
        return this.$el.draggable({
          containment: "parent",
          grid: [this.model.collection.minimumMinutesStep * this.ratio, 0],
          stop: this.setStartAt,
          drag: this.onResizeDragStart
        });
      };

      SessionView.prototype.allowDurationChange = function() {
        var $startAt;
        $startAt = this.$('.start-at');
        return $startAt.resizable({
          grid: [this.model.collection.minimumDurationStep * this.ratio, 0],
          minWidth: this.model.collection.minimumDurationValue * this.ratio - this.zeroMinuteOffset,
          maxWidth: this.model.collection.maximumDurationValue * this.ratio,
          minHeight: $startAt.height(),
          maxHeight: $startAt.height(),
          handles: "e",
          stop: this.setDuration,
          resize: this.onResizeDragStart
        });
      };

      SessionView.prototype.allowPretimeChange = function() {
        var $pretime;
        $pretime = this.$('.pre-time');
        return $pretime.resizable({
          grid: [this.ratio, 0],
          minWidth: this.zeroMinuteOffset,
          maxWidth: this.model.collection.maximumPretimeValue * this.ratio + this.zeroMinuteOffset,
          minHeight: $pretime.height(),
          maxHeight: $pretime.height(),
          handles: "w",
          stop: this.setPretime,
          resize: this.onResizeDragStart
        });
      };

      SessionView.prototype.checkOverlaps = function() {
        var session;
        session = this.getTempSession();
        if (this.model.collection.isOverlapsWith(session)) {
          this.markAsOverlapped();
          return this.disableDoneButton();
        } else {
          this.unmarkAsOverlapped();
          return this.enableDoneButton();
        }
      };

      SessionView.prototype.markAsOverlapped = function() {
        return this.$el.addClass("overlapped");
      };

      SessionView.prototype.unmarkAsOverlapped = function() {
        return this.$el.removeClass("overlapped");
      };

      SessionView.prototype.setStartAt = function(event, ui) {
        this.checkOverlaps();
        this.onResizeDragStop();
        return this.model.set('start_at', this.calcStartAt());
      };

      SessionView.prototype.setDuration = function(event, ui) {
        this.checkOverlaps();
        this.onResizeDragStop();
        this.model.set('duration', this.calcDuration());
        return this.updateItemWidth();
      };

      SessionView.prototype.setPretime = function(event, ui) {
        this.checkOverlaps();
        this.onResizeDragStop();
        return this.model.set('pre_time', this.calcPretime());
      };

      SessionView.prototype.updateItemWidth = function() {
        return this.$el.css({
          width: this.$('.start-at').width()
        });
      };

      SessionView.prototype.calcDuration = function() {
        return (this.$('.start-at').width() + this.zeroMinuteOffset) / this.ratio;
      };

      SessionView.prototype.calcPretime = function() {
        return (this.$('.pre-time').width() - this.zeroMinuteOffset) / this.ratio;
      };

      SessionView.prototype.calcStartAt = function() {
        return this.minDate.clone().add(Math.ceil(Math.round(this.$el.position().left / this.ratio) / 15) * 15, 'm').second(0);
      };

      SessionView.prototype.disableDoneButton = function() {
        return mediator.trigger("disable-submit");
      };

      SessionView.prototype.enableDoneButton = function() {
        return mediator.trigger("enable-submit");
      };

      SessionView.prototype.dispose = function() {
        var i, len, popover, prop, properties;
        if (this.disposed) {
          return;
        }
        this.stopListening(this.model);
        this.off();
        popover = this.$el.data("bs.popover");
        if (popover) {
          popover.tip()['remove']();
          popover.destroy();
        }
        this.$el.remove();
        properties = ['el', '$el', 'model', 'template', 'minDate', 'ratio'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      SessionView.prototype.initStarEndTooltips = function() {
        this.$(".pre-time").tooltip({
          title: (function(_this) {
            return function() {
              var session;
              session = _this.getTempSession();
              return session.actualStartAt().format(hourFormat);
            };
          })(this),
          placement: 'left',
          trigger: 'manual',
          delay: {
            show: 0,
            hide: 100
          }
        });
        return this.$(".start-at").tooltip({
          title: (function(_this) {
            return function() {
              var session;
              session = _this.getTempSession();
              return session.actualEndAt().format(hourFormat);
            };
          })(this),
          placement: 'right',
          trigger: 'manual',
          delay: {
            show: 0,
            hide: 100
          }
        });
      };

      SessionView.prototype.getTempSession = function() {
        var klass, session;
        klass = this.model.get('class');
        session = new AbsctractSession({
          "class": klass
        });
        session.set({
          start_at: this.calcStartAt(),
          duration: this.calcDuration(),
          pre_time: this.calcPretime()
        }, {
          silent: true
        });
        return session;
      };

      SessionView.prototype.onResizeDragStart = function(event, ui) {
        var preTimeTooltip, startAtTooltip;
        this.checkOverlaps();
        preTimeTooltip = this.$(".pre-time").data("bs.tooltip");
        if (!preTimeTooltip) {
          return;
        }
        startAtTooltip = this.$(".start-at").data("bs.tooltip");
        if (!startAtTooltip) {
          return;
        }
        if (preTimeTooltip.tip()['is'](":visible")) {
          preTimeTooltip.tip().find('.tooltip-inner').text(preTimeTooltip.getTitle());
          this.updateTooltipPlacement(preTimeTooltip);
        } else {
          preTimeTooltip.show();
        }
        if (startAtTooltip.tip()['is'](":visible")) {
          startAtTooltip.tip().find('.tooltip-inner').text(startAtTooltip.getTitle());
          return this.updateTooltipPlacement(startAtTooltip);
        } else {
          return startAtTooltip.show();
        }
      };

      SessionView.prototype.onResizeDragStop = function() {
        this.$(".pre-time").tooltip("close");
        return this.$(".start-at").tooltip("close");
      };

      SessionView.prototype.updateTooltipPlacement = function(tooltipObj) {
        var actualHeight, actualWidth, calculatedOffset, placement, pos;
        pos = tooltipObj.getPosition();
        actualWidth = tooltipObj.tip()[0].offsetWidth;
        actualHeight = tooltipObj.tip()[0].offsetHeight;
        placement = tooltipObj.options.placement;
        calculatedOffset = tooltipObj.getCalculatedOffset(placement, pos, actualWidth, actualHeight);
        return tooltipObj.applyPlacement(calculatedOffset, placement);
      };

      return SessionView;

    })(Backbone.View);
    ChannelView = (function(superClass) {
      extend(ChannelView, superClass);

      function ChannelView() {
        return ChannelView.__super__.constructor.apply(this, arguments);
      }

      ChannelView.prototype.className = "channel";

      ChannelView.prototype.initialize = function(options) {
        this.$region = options.$region;
        return this.render();
      };

      ChannelView.prototype.render = function() {
        return this.$region.append(this.$el);
      };

      ChannelView.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.off();
        this.$el.remove();
        properties = ['el', '$el', 'template', '$region'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      return ChannelView;

    })(Backbone.View);
    DateRangeView = (function(superClass) {
      extend(DateRangeView, superClass);

      function DateRangeView() {
        return DateRangeView.__super__.constructor.apply(this, arguments);
      }

      DateRangeView.prototype.initialize = function(options) {
        this.template = HandlebarsTemplates['application/overlapped_session_daterange'];
        this.$region = options.$region;
        return this.render();
      };

      DateRangeView.prototype.getTemplateData = function() {
        var data;
        data = {};
        data.dateRange = this.collection.getVisibleDateRange();
        data.pixelsPerSection = this.collection.ratio * this.collection.minutesPerSection;
        return data;
      };

      DateRangeView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        return this.$region.append(this.$el);
      };

      DateRangeView.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.stopListening(this.collection);
        this.off();
        this.$el.remove();
        properties = ['el', '$el', 'collection', 'template', '$region'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      return DateRangeView;

    })(Backbone.View);
  })();

}).call(this);
