$( document ).ready(function() {
  setTimeout(function() {
    $('.number-input .number-arrows i').click(function(e){
      var input = $(e.target).parents('.number-input').find('input');

      if(input.attr('disabled')) { 
        return 
      }

      if($(e.target).attr('class').includes('up')){
        inc(input);
      }else{
        dec(input);
      }
    });

    $('.number-input input').change(function(e) {
      var input = $(e.target);
      var val = parseInt(input.val()) || 0;
      var max = parseInt(input.attr('max'));
      var min = parseInt(input.attr('min'));

      val = val > max ? max : val;
      val = val < min ? min : val;

      input.val(val);
    })
  }, 500)

  function inc(input) {
    var val = (parseInt(input.val()) || 0) + 1;
    var max = parseInt(input.attr('max'));
    if(val > max) { val = max }

    input.val(val);
    input.trigger('change');
  }

  function dec(input) {
    var val = (parseInt(input.val()) || 0) - 1;
    var min = parseInt(input.attr('min'));
    if(val < min) { val = min }

    input.val(val);
    input.trigger('change');
  }
})