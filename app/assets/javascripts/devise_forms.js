(function() {
  $(function() {
    'use strict';
    var errorCallback;
    errorCallback = function(event, xhr) {
      var errors;
      if (xhr.status === 422) {
        errors = _(xhr.responseJSON.errors).inject(function(res, value, key) {
          key = key[0].toUpperCase() + key.substring(1);
          res.push(key + " " + value[0]);
          return res;
        }, []);
        return $.showFlashMessage(errors.join("<br/>"), {
          type: "error"
        });
      } else {
        return $.showFlashMessage("Internal server error", {
          type: "error"
        });
      }
    };
    $("#confirmationForm").bind("ajax:success", function() {
      $("[name='user[email]']:visible").val('');
      $(".modal:visible").one("hidden.bs.modal", function() {
        return $.showFlashMessage("You will receive an email with instructions about how to confirm your account in a few minutes.", {
          type: "success"
        });
      });
      return $(".modal:visible").modal('hide');
    });
    return $("#confirmationForm").bind("ajax:error", errorCallback);
  });

}).call(this);
