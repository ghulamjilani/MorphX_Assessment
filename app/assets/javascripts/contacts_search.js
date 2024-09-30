(function() {
  $(function() {
    return $(document).on('keyup', '#contacts-search', function() {
      var $items, currentPattern, searchVal;
      searchVal = $.trim($(this).val());
      $items = $(this).parents('.searchUserBlock').find('.list-group-item');
      console.log(searchVal);
      console.log($items);
      if (searchVal.length) {
        currentPattern = new RegExp($(this).val(), 'i');
        $items.hide().each(function() {
          if (currentPattern.test($(this).data('name')) || currentPattern.test($(this).data('email'))) {
            return $(this).show();
          }
        });
      } else {
        $items.show();
      }
      if ($items.map(function() {
        return $(this).is(':visible');
      }).toArray().indexOf(true) === -1) {
        return $items.parent().find('.fallback').show();
      } else {
        return $items.parent().find('.fallback').hide();
      }
    });
  });

}).call(this);
