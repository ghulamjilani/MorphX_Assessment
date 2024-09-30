(function() {
  window.refresh_invite_modal = function() {
    $('#InviteParticipantsWrapp').addClass('Connecting');
    return $.get($('#inCallButtonToggleInvite').data('url')).success(function(response) {
      $('#InviteParticipants').html(window.modalBody);
      return console.log(window);
    });
  };

  $(document).on('click', '.instant-invite-contact-from-video', function(event) {
    var modelId, state, url;
    event.preventDefault();
    if (typeof ($(this).data('session-id')) !== 'undefined') {
      url = "/sessions/:id/instant_invite_user_from_video";
      modelId = $(this).data('session-id');
    } else {
      throw new Error("can not get model id");
    }
    state = $(this).parents('.list-group-item').find('.current-state-status').data('state');
    if (typeof state === 'undefined') {
      state = $(this).data('state');
    }
    if (!$(this).data("disable")) {
      $(this).data("disable", true);
      return $.ajax({
        type: "POST",
        url: url.replace(':id', modelId),
        data: 'email=' + $(this).data('email') + '&state=' + state,
        success: function(data, textStatus, jqXHR) {
          return refresh_invite_modal();
        }
      });
    }
  });

  $(document).on('click', '.instant-remove-invited-user-from-video', function(event) {
    var modelId, url;
    event.preventDefault();
    if (typeof ($(this).data('session-id')) !== 'undefined') {
      url = "/sessions/:id/instant_remove_invited_user_from_video";
      modelId = $(this).data('session-id');
    } else {
      throw new Error("can not get model id");
    }
    return $.ajax({
      type: "POST",
      url: url.replace(':id', modelId),
      data: 'email=' + $(this).data('email'),
      success: function(data, textStatus, jqXHR) {
        return refresh_invite_modal();
      },
      error: function(jqXHR, textStatus, errorThrown) {}
    });
  });

  $(document).on('ajax:before', '.live-participant-form', function(event) {
    return $('#InviteParticipantsWrapp').addClass('Connecting');
  });

  $(document).on('ajax:success', '.live-participant-form', function(event) {
    return refresh_invite_modal();
  });

  $(document).on('keyup', '.live-participant-form input[name=email]', function(event) {
    if ($.trim($(this).val()) === '') {
      return $(".live-participant-form .invite_btn").attr("disabled", "disabled");
    } else {
      if (event.keyCode !== 13) {
        return $(".live-participant-form .invite_btn").removeAttr("disabled");
      }
    }
  });

  $(document).on('ajax:before', '.live-participant-form', function(event) {
    return $(this).find('.liveInviteSubmitButtonVideo').attr("disabled", "disabled");
  });

  $(document).on('keyup', '.live-participant-form input[name=email]', function(event) {
    if ($.trim($(this).val()) === '') {
      return $(".live-participant-form .liveInviteSubmitButtonVideo").attr("disabled", "disabled");
    } else {
      if (event.keyCode !== 13) {
        return $(".live-participant-form .liveInviteSubmitButtonVideo").removeAttr("disabled");
      }
    }
  });

  $(document).on('click', '.addUserToContacts', function(event) {
    var $checkbox;
    event.preventDefault();
    $checkbox = $(this);
    $checkbox.prop('checked', true);
    return $.ajax({
      url: $(this).data('url'),
      type: 'POST',
      dataType: 'html',
      error: function(jqXHR, textStatus, errorThrown) {
        return $checkbox.prop('checked', false);
      },
      success: function(data, textStatus, jqXHR) {
        $checkbox.parents('.addToContacts').slideUp();
        return setTimeout((function() {
          $checkbox.parents('.addToContacts').remove();
        }), 500);
      }
    });
  });

}).call(this);
