(function() {
  $(function() {
    var markNotificationClickCallback;
    if (!$('body').hasClass('notifications-index')) {
      return;
    }
    markNotificationClickCallback = function() {
      if ($('.mark-notification.checked').length > 0) {
        return $('.delete-selected').removeAttr('disabled');
      } else {
        return $('.delete-selected').attr('disabled', 'disabled');
      }
    };
    markNotificationClickCallback();
    $('.mark-notification').bind('mousedown', function(e) {
      var firstEl, lastEl;
      if (!e.shiftKey) {
        return;
      }
      lastEl = $(this).parents('.media');
      firstEl = $(this).parents('.Notifications-wrapp').find(".media:lt(" + (lastEl.index()) + ") .mark-notification:checked").last().parents('.media');
      return $(this).parents('.Notifications-wrapp').find(".media:lt(" + (lastEl.index()) + "):gt(" + (firstEl.index()) + ")").find('.mark-notification').attr('checked', 'checked');
    });
    var marksChecked = false
    $('.mark-all-notification').click(function() {
      var markAll = document.querySelectorAll('.mark-all-notification')
      markAll.forEach(function(mark) {
        if (marksChecked === false) {
          mark.checked = true
        } else {
          mark.checked = false
        }
      })
      var marks = document.querySelectorAll('.mark-notification')
      marks.forEach(function(mark) {
        if (marksChecked === false) {
          mark.setAttribute('checked', 'checked')
          mark.classList.add('checked')
          mark.checked = true
          $(mark).parents('.media').addClass("checked");
        } else {
          mark.removeAttribute('checked')
          mark.classList.remove('checked')
          mark.checked = false
          $(mark).parents('.media').removeClass("checked");
        }
      })
      marksChecked = !marksChecked
    });
    $('.mark-notification').click(function(e) {
      var elem = e.target
      if (elem.getAttribute('checked') === 'checked') {
        elem.removeAttribute('checked')
        elem.classList.remove('checked')
        elem.checked = false
        $(elem).parents('.media').removeClass("checked");
      } else {
        elem.setAttribute('checked', 'checked')
        elem.classList.add('checked')
        elem.checked = true
        $(elem).parents('.media').addClass("checked");
      }
    });
    $('.mark-notification, .mark-all-notification').click(markNotificationClickCallback);
    $('.read_button').tooltip({
      title: function() {
        if ($(this).data('is-read')) {
          return 'Mark as unread';
        } else {
          return 'Mark as read';
        }
      }
    });
    return $('.read_button').click(function(e) {
      var $this, isRead, url;
      e.preventDefault();
      $this = $(this);
      isRead = $this.data('is-read');
      url = isRead ? $this.data('unread-url') : $this.data('read-url');
      return $.post(url).success(function() {
        var count;
        if (isRead) {
          count = Number($('.notification_count').attr('data-count')) + 1;
          isRead = false;
          $this.parents('.notification-item').addClass('new_Notifications');
        } else {
          count = Number($('.notification_count').attr('data-count')) - 1;
          isRead = true;
          $this.parents('.notification-item').removeClass('new_Notifications');
        }
        $('.notification_count').attr('data-count', count > 0 ? count : '');
        $this.data('is-read', isRead);
        if ($this.data('bs.tooltip').$tip && $this.data('bs.tooltip').$tip.is(':visible')) {
          return $this.data('bs.tooltip').show();
        }
      });
    });
  });

  $(function() {
    var $messagesContainer, $messagesPopup, $notificationsContainer, $notificationsPopup, currentMessagesPage, currentNotificationsPage, messagesTemplate, notificationsTemplate, perPage;
    perPage = 3;
    currentNotificationsPage = 1;
    notificationsTemplate = HandlebarsTemplates['application/newest_notification'];
    $notificationsPopup = $('#notificationsPopup');
    $notificationsContainer = $notificationsPopup.find('ul');
    $('#notificationsPopup').on('click', '.closePopup', function(e) {
      e.preventDefault();
      return $('#notificationsPopup').hide();
    });
    $('.NT-wrapper').on('click', '.closePopup', function(e) {
      e.preventDefault();
      return $('.NT-wrapper').hide();
    });
    $('#notificationsPopup').on('click', '.load-more', function(e) {
      e.preventDefault();
      return $.get('/notifications.json', {
        page: ++currentNotificationsPage,
        per_page: perPage
      }).success(function(response) {
        var itemsLength;
        if (response.length === 0) {
          return $notificationsPopup.find('.load-more').addClass('disabled');
        } else {
          $notificationsPopup.find('.fallback').remove();
          _(response).each(function(notification) {
            return $notificationsContainer.append(notificationsTemplate(notification));
          });
          itemsLength = $notificationsContainer.find('li').length;
          $notificationsContainer.scrollTo($notificationsContainer.find("li:eq(" + (itemsLength - perPage) + ")"));
          $notificationsPopup.find("li:gt(" + (itemsLength - perPage - 1) + ")").find('.timeago').timeago();
          return window.markVisibleNotificationsAsRead();
        }
      });
    });
    currentMessagesPage = 1;
    messagesTemplate = HandlebarsTemplates['application/newest_message'];
    $messagesPopup = $('#messagesPopup');
    $messagesContainer = $messagesPopup.find('ul');
    $('.NT-wrapper').on('click', '.closePopup', function(e) {
      e.preventDefault();
      return $('.NT-wrapper').hide();
    });
    return $('#messagesPopup').on('click', '.closePopup', function(e) {
      e.preventDefault();
      return $('#messagesPopup').hide();
    }).on('click', '.load-more', function(e) {
      e.preventDefault();
      return $.get('/messages.json', {
        page: ++currentMessagesPage,
        per_page: perPage
      }).success(function(response) {
        var itemsLength;
        if (response.length === 0) {
          return $messagesPopup.find('.load-more').addClass('disabled');
        } else {
          $messagesPopup.find('.fallback').remove();
          _(response).each(function(message) {
            return $messagesContainer.append(messagesTemplate(message));
          });
          itemsLength = $messagesContainer.find('li').length;
          $messagesContainer.scrollTo($messagesContainer.find("li:eq(" + (itemsLength - perPage) + ")"));
          return $messagesPopup.find("li:gt(" + (itemsLength - perPage - 1) + ")").find('.timeago').timeago();
        }
      });
    });
  });

}).call(this);
