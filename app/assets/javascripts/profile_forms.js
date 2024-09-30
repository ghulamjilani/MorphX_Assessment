(function() {
  $(function() {
    window.onload = function() {
      let el = document.querySelector('#s2id_phone-country');
      if(el){
        el.removeAttribute('title');
      }
    };
    var containerForm, containerFormValidate;
    if ($('body.presenter_steps').length > 0) {
      containerForm = $('.main-content form.presenter_steps_user_profile_form');
    }
    if (containerForm) {
      containerFormValidate = containerForm.validate({
        rules: {
          "profile[email]": {
            emailImmerss: true,
            required: true
          },
          "profile[gender]": {
            required: true
          },
          "profile[first_name]": {
            required: true,
            minlength: 2,
            maxlength: 50,
            regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\\s.\']+'
          },
          "profile[last_name]": {
            required: true,
            minlength: 2,
            maxlength: 50,
            regex: '^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\\s.\']+'
          }
        },
        "profile[birthdate(1i)]": {
          required: true
        },
        "profile[birthdate(2i)]": {
          required: true
        },
        "profile[birthdate(3i)]": {
          required: true
        },
        "profile[manually_set_timezone]": {
          required: true
        },
        "profile[user_account_attributes][country]": {
          required: true
        },
        errorElement: "span",
        errorPlacement: function(error, element) {
          return error.addClass("help-inline").appendTo(element.parents(".controls"));
        },
        highlight: function(element) {
          return $(element).parents('.borderedInput').addClass('error').removeClass('valid');
        },
        unhighlight: function(element) {
          return $(element).parents('.borderedInput').removeClass('error').addClass('valid');
        }
      });
      if ($(containerForm).data("validator")) {
        $(containerForm).data("validator").settings.ignore = "";
      }
      var timestamp;
      timestamp = moment().tz(Intl.DateTimeFormat().resolvedOptions().timeZone).format('Z');
          if (timestamp) {
              $.cookie('tzinfo', timestamp);
              return $('[name="user[tzinfo]"]').val(timestamp);
          }
      containerForm.on("ajax:beforeSend", function() {
        return window.disableUnobtrusiveFlash = true;
      });
      containerForm.on("ajax:success", function(event, data, status) {
        return window.location.href = data.location || data.response.location;
      });
      return containerForm.on("ajax:error", function(event, xhr, status) {
        window.disableUnobtrusiveFlash = false;
        if (xhr.status === 422) {
          return containerFormValidate.showErrors(xhr.responseJSON.errors, "user");
        }
      });
    }
  });

}).call(this);
