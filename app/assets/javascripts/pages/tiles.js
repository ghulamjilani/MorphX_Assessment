//= require_self

(function() {
  var loopCounter, prepareSessionTile;

  prepareSessionTile = function(el) {
    var $tile, $timer, $timer_btn, attrs, presenter;
    $tile = $(el);
    $timer_btn = $tile.find('a.timeCount.timer');
    if ($timer_btn.length === 0) {
      return;
    }
    attrs = $timer_btn.data();
    presenter = typeof attrs.presenter !== 'undefined';
    $timer_btn.on('countEnd', function() {
      $tile.find('div.remind_me').addClass('hidden');
      $timer_btn.addClass('hidden');
      $tile.find('.tile-type').remove();
      $tile.find('.sessionStatus').removeClass('hidden');
    });
    if (attrs.status === 'cancelled') {
      return $timer_btn.addClass('btn-red').removeClass('btn-borderred-grey');
    } else if (attrs.status === 'completed') {
      return $timer_btn.addClass('btn-green').removeClass('btn-borderred-grey');
    } else if (attrs.status === 'running' || (presenter && attrs.status === 'started')) {
      $timer_btn.removeClass('btn-borderred-grey').removeAttr('disabled');
      if (attrs.type === 'immersive') {
        return $timer_btn.attr('href', '#').attr('onclick', attrs.onclick);
      }
    } else if (attrs.status === 'upcoming') {
      $timer = $timer_btn.find('span.time-to-start');
      return uiTimeLeft($timer, 2);
    } else {
      return $timer_btn.text(attrs.text);
    }
  };

  window.uiTimeLeft = function(elements, size) {
    var element, log, parent, timerEndAtInSeconds, update_timer;
    if (size == null) {
      size = 2;
    }
    if (elements.length === 0) {
      return;
    }
    element = elements.first();
    timerEndAtInSeconds = parseInt(element.data('timer-end-at-in-seconds'));
    parent = elements.parents('.timer');
    parent.attr('disabled', true);
    update_timer = function() {
      if ($(element).parents('body').length > 0 && !$(element).data('stop_timer')) {
        return timerEndAtInSeconds = parseInt(element.data('timer-end-at-in-seconds'));
      } else {
        return false;
      }
    };
    log = function(text) {
      element.show();
      if (text !== 'countEnd' && text.length > 0) {
        element.html('<span>' + text + '</span>');
      } else {
        if (!parent.hasClass('btn-red')) {
          parent.find('.session-start-at-counter_wrapp').html('Session will be starting soon');
        }
        if (element.hasClass('tileStatus')) {
          element.hide();
          element.parents('.tile-cake-sidebarrr').find('.time.tileTimeStatus-now').show();
          element.parents('.tile-cake-sidebarrr').find('.time.date_text').hide();
        }
        parent.trigger('countEnd');
      }
    };
    element.addClass('timer-init');
    loopCounter(timerEndAtInSeconds, log, size, update_timer);
  };

  loopCounter = function(timerEndAtInSeconds, log, size, update_timer) {
    var day, dayStr, formattedDate, hour, hourStr, items, minute, minuteStr, secStr, secondsLeft, secondsRemaining, timer;
    if (size == null) {
      size = 2;
    }
    if (typeof update_timer === 'function') {
      timer = update_timer();
      timerEndAtInSeconds = timer;
    }
    if (!timerEndAtInSeconds) {
      return;
    }
    secondsLeft = timerEndAtInSeconds - window.serverDate.nowInSeconds();
    if (secondsLeft >= 0) {
      items = [];
      secondsRemaining = (secondsLeft * 1000) / 1000;
      day = parseInt(secondsRemaining / (3600 * 24));
      secondsRemaining -= day * 3600 * 24;
      if (day > 0) {
        dayStr = day < 10 ? "0" + day : day;
        dayStr += day === 1 ? ' Day' : ' Days';
        items.push(dayStr);
      }
      hour = parseInt(secondsRemaining / 3600);
      secondsRemaining -= hour * 3600;
      if (hour > 0 || day > 0) {
        hourStr = hour < 10 ? "0" + hour : hour;
        hourStr += hour === 1 ? ' Hr' : ' Hrs';
        items.push(hourStr);
      }
      minute = parseInt(secondsRemaining / 60);
      secondsRemaining -= minute * 60;
      if (minute > 0 || hour > 0 || day > 0) {
        minuteStr = minute < 10 ? "0" + minute : minute;
        minuteStr += ' Min';
        items.push(minuteStr);
      }
      secondsRemaining = parseInt(secondsRemaining);
      if (secondsRemaining > 0 || minute > 0 || hour > 0 || day > 0) {
        secStr = secondsRemaining < 10 ? "0" + secondsRemaining : secondsRemaining;
        secStr += ' Sec';
        items.push(secStr);
      }
      formattedDate = items.slice(0, size).join(' ');
      log(formattedDate);
      return setTimeout(function() {
        return loopCounter(timerEndAtInSeconds, log, size, update_timer);
      }, 1000);
    } else if (secondsLeft < 0) {
      return log('countEnd');
    }
  };

  if ($('body.home-index, body.channel_landing').length > 0) {
    _.each($('section.tile-cake.session-tile'), function(el) {
      return prepareSessionTile($(el));
    });
  }

}).call(this);
