(function() {
  $('select#select_list').on('change', function() {
    var list_id;
    list_id = $(this).val();
    if (!!list_id) {
      return $.ajax({
        url: $(this).attr('data-url'),
        type: 'post',
        data: {
          list_id: list_id
        },
        dataType: 'json',
        beforeSend: function() {
          return $('#shop .LoadingCover').show();
        },
        success: function(response) {
          var message;
          $('#shop .LoadingCover, .list_info').hide();
          $("#shop_info_" + list_id).show();
          message = response.message || 'Product Lists panel enabled';
          return $.showFlashMessage(message, {
            type: 'info',
            timeout: 3000
          });
        },
        error: function(response) {
          var message;
          $('#shop .LoadingCover').hide();
          message = response.responseJSON.message || 'Something went wrong';
          return $.showFlashMessage(message, {
            type: 'error',
            timeout: 3000
          });
        }
      });
    } else {
      return $.ajax({
        url: $(this).attr('data-disableUrl'),
        type: 'post',
        dataType: 'json',
        beforeSend: function() {
          return $('#shop .LoadingCover').show();
        },
        success: function(response) {
          var message;
          $('#shop .LoadingCover, .list_info').hide();
          message = response.message || 'Product Lists panel disabled';
          return $.showFlashMessage(message, {
            type: 'info',
            timeout: 3000
          });
        },
        error: function(response) {
          var message;
          $('#shop .LoadingCover').hide();
          message = response.responseJSON.message || 'Something went wrong';
          return $.showFlashMessage(message, {
            type: 'error',
            timeout: 3000
          });
        }
      });
    }
  });

}).call(this);
