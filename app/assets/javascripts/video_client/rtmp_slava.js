(function() {
  window.copyToClipboard = function(element) {
    var input;
    $(element).html('copied');
    setTimeout((function(_this) {
      return function() {
        return jQuery(element).html('copy');
      };
    })(this), 1500);
    input = $(element).parent().find('input[type="text"]');
    $(input).select();
    document.execCommand("copy");
    return false;
  };

}).call(this);
