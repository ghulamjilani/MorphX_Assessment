(function() {
  var formatPollData;

  formatPollData = function(poll) {
    poll.is_voted = !!$.cookie()[poll.id];
    _(poll.sides).each(function(side, i) {
      return poll.sides[i].is_voted = $.cookie()[poll.id] === side.id;
    });
    return poll;
  };

  $('#polls').delegate('select#select_poll', 'change', function() {
    var poll_id;
    poll_id = $(this).val();
    if (!!poll_id) {
      $.ajax({
        url: $(this).attr('data-url'),
        type: 'post',
        data: {
          poll_id: poll_id
        },
        dataType: 'json',
        beforeSend: function() {
          return $('#polls .LoadingCover').show();
        },
        success: function(response) {
          var message;
          $('#polls .LoadingCover').hide();
          message = response.message || 'Polls panel enabled';
          return $.showFlashMessage(message, {
            type: 'info',
            timeout: 3000
          });
        },
        error: function(response) {
          var message;
          $('#polls .LoadingCover').hide();
          message = response.responseJSON && response.responseJSON.message || 'Something went wrong';
          return $.showFlashMessage(message, {
            type: 'error',
            timeout: 3000
          });
        }
      });
    } else {
      $.ajax({
        url: $(this).attr('data-disableUrl'),
        type: 'post',
        dataType: 'json',
        beforeSend: function() {
          return $('#polls .LoadingCover').show();
        },
        success: function(response) {
          var message;
          $('#polls .LoadingCover').hide();
          $('#polls .Votes-block').addClass('hidden');
          message = response.message || 'Polls panel disabled';
          return $.showFlashMessage(message, {
            type: 'info',
            timeout: 3000
          });
        },
        error: function(response) {
          var message;
          $('#polls .LoadingCover').hide();
          message = response.responseJSON && response.responseJSON.message || 'Something went wrong';
          return $.showFlashMessage(message, {
            type: 'error',
            timeout: 3000
          });
        }
      });
    }
    return false;
  });

  $('#polls').delegate('.save_poll', 'click', function() {
    var $form;
    $form = $('form#new_poll');
    $.ajax({
      url: $form.attr('action'),
      data: $form.serialize(),
      type: 'post',
      dataType: 'json',
      beforeSend: function() {
        return $('#polls .LoadingCover').show();
      },
      success: function(response) {
        var message;
        $('#polls .LoadingCover').hide();
        $form[0].reset();
        $form.find('.removable_answer').remove();
        message = response.message || 'Poll added';
        return $.showFlashMessage(message, {
          type: 'info',
          timeout: 3000
        });
      },
      error: function(response) {
        var message;
        $('#polls .LoadingCover').hide();
        message = response.responseJSON && response.responseJSON.message || 'Something went wrong';
        return $.showFlashMessage(message, {
          type: 'error',
          timeout: 3000
        });
      }
    });
    return false;
  });

  $('#polls').delegate('.add_answer', 'click', function() {
    var count;
    count = $('form#new_poll input[name="poll[sides][][answer]"]').length;
    $('form#new_poll .fields').append("<div class=\"removable_answer\"><input type=\"text\" name=\"poll[sides][][answer]\" required=\"required\" placeholder=\"Answer " + (count + 1) + "\"><a class=\"remove_answer ml20\"><i class=\"GlobalIcon-clear\"></i></a></div>");
    return false;
  });

  $('#polls').delegate('.remove_answer', 'click', function() {
    $(this).closest('.removable_answer').remove();
    return false;
  });

  $('#polls').delegate('.heading', 'click', function() {
    $('form#new_poll').toggleClass('hide');
    return false;
  });

  $('#polls').delegate('.Votes-b a.vote', 'click', function() {
    if (!!$.cookie()[$(this).parents('.Votes-block').data('poll-id')] || $(this).parents('.Votes-b').hasClass('votedIn')) {
      $.showFlashMessage('You have already voted', {
        type: 'info',
        timeout: 3000
      });
      return false;
    }
  });

  $('#polls').delegate('.Votes-b a.vote', 'ajax:before', function() {
    return $('#polls .LoadingCover').show();
  }).delegate('.Votes-b a.vote', 'ajax:success', function() {
    return $('#polls .LoadingCover').hide();
  }).delegate('.Votes-b a.vote', 'ajax:error', function(evt, data, status, xhr) {
    var message;
    $('#polls .LoadingCover').hide();
    message = evt.responseJSON && evt.responseJSON.message || 'Something went wrong';
    return $.showFlashMessage(message, {
      type: 'error',
      timeout: 3000
    });
  });

}).call(this);
