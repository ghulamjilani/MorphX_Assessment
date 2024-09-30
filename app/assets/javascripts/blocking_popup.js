(function() {
  var getCurrentPopupNotificationID, nextPopupMessageClicked, nextVisiblePopupNotificationID, popupNotificationIDs, prevPopupMessageClicked, prevVisiblePopupNotificationID;

  nextPopupMessageClicked = function() {
    var nextID;
    if (!(popupNotificationIDs().length > 0)) {
      return;
    }
    nextID = nextVisiblePopupNotificationID();
    $(".FlashBox").hide();
    return $(".FlashBox[data-id=" + nextID + "]").show();
  };

  $(document).on('click', '.next-popup-notification', nextPopupMessageClicked);

  prevPopupMessageClicked = function() {
    var prevtID;
    if (!(popupNotificationIDs().length > 0)) {
      return;
    }
    prevtID = prevVisiblePopupNotificationID();
    $(".FlashBox").hide();
    return $(".FlashBox[data-id=" + prevID + "]").show();
  };

  $(document).on('click', '.prev-popup-notification', nextPopupMessageClicked);

  getCurrentPopupNotificationID = function() {
    return $('.FlashBox:visible').data('id');
  };

  popupNotificationIDs = function() {
    return _.collect($('.FlashBox'), function(el) {
      return $(el).data('id');
    });
  };

  nextVisiblePopupNotificationID = function() {
    var index;
    index = _.indexOf(popupNotificationIDs(), getCurrentPopupNotificationID());
    if (index === (popupNotificationIDs().length - 1)) {
      return popupNotificationIDs()[0];
    } else {
      return popupNotificationIDs()[index + 1];
    }
  };

  prevVisiblePopupNotificationID = function() {
    var index;
    index = _.indexOf(popupNotificationIDs(), getCurrentPopupNotificationID());
    if (index === 0) {
      return popupNotificationIDs()[popupNotificationIDs().length - 1];
    } else {
      return popupNotificationIDs()[index - 1];
    }
  };

  $(function() {
    return $('.FlashBox:first-child').show();
  });

}).call(this);
