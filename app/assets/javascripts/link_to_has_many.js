//= require contacts_search

(function() {
  window.displayParticipantsInForm = function() {
    var content, el;
    $('#disposable').remove();
    content = $('#invite-user-modal .RightBlock.users_list').clone();
    $(content).remove('.removable');
    $(content).find('.removable').remove();
    el = $('<div/>', {
      id: "disposable",
      html: content.html(),
      "class": 'invited-users'
    });
    return $('#invite-user-modal').after(el);
  };

  window.displayUsersInForm = function() {
    var content, el;
    $('#disposable').remove();
    content = $('#invite-user-modal .RightBlock.users_list').clone();
    $(content).remove('.removable');
    $(content).find('.removable').remove();
    el = $('<div/>', {
      id: "disposable",
      html: content.html(),
      "class": 'invited-users'
    });
    return $('#invite-user-modal').after(el);
  };

  window.displaySessionSourcesInForm = function() {
    var content, el;
    $('#disposable-session-sources').remove();
    content = $('.session_sources_list').clone();
    $(content).remove('.removable');
    $(content).find('.removable').remove();
    el = $('<div/>', {
      id: "disposable-session-sources",
      html: content.html(),
      "class": 'invited-users'
    });
    return $('#session-sources-modal').after(el);
  };

  window.displayEmployeesInForm = function() {
    var content, el;
    $('#disposable-employees').remove();
    content = $('.employees_list').clone();
    $(content).remove('.removable');
    $(content).find('.removable').remove();
    el = $('<div/>', {
      id: "disposable-employees",
      html: content.html(),
      "class": 'invited-users'
    });
    return $('#employees-modal').after(el);
  };

  $(function() {
    $('#session-sources-modal').on('close hidden hidden.bs.modal', function() {
      displaySessionSourcesInForm();
      return $('.contacts-search').val('');
    });
    return $('#employees-modal').on('close hidden hidden.bs.modal', function() {
      displayEmployeesInForm();
      return $('.contacts-search').val('');
    });
  });

  $(document).on('click', '.modal_add_contact', function(event) {
    var email, state;
    event.preventDefault();
    email = $(event.target).parents('.list-group-item').find('strong').attr('title');
    state = $(event.target).parents('.list-group-item').find('.current-state-status').data('state');
    sessionInviteUserModalView.inviteContactClicked(email, state);
    return false;
  });

  $(function() {
    return $('.session_sources_member_input').each(function(i, obj) {
      return $("a[data-email='" + $(obj).val() + "'][data-target-input='session_sources']").closest('.list-group-item').hide();
    });
  });

  $(document).on('click', 'form .remove_session_sources', function(event) {
    var email;
    email = $(this).parents('.list-group-item').find('.session_sources_member_input').val();
    if (email) {
      $("a[data-email='" + email + "'][data-target-input='session_sources']").closest('.list-group-item').show();
    }
    $(this).closest('.list-group-item').remove();
    return event.preventDefault();
  });

  $(document).on('keypress', 'form #session_sources_new_input', function(event) {
    if (event.keyCode === 13) {
      $('form .add_session_sources').click();
      return event.preventDefault();
    }
  });

  $(document).on('click', 'form .add_session_sources', function(event) {
    var data, friend, input, inputType, regexp, time, value;
    event.preventDefault();
    value = $.trim($('#session_sources_new_input').val());
    if (!value) {
      return;
    }
    inputType = $('#session_sources_new_input').attr('type');
    switch (inputType) {
      case 'email':
        input = document.createElement('input');
        input.type = 'email';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        if (value === $.trim($('#session_sources_new_input').data('organizer'))) {
          return;
        }
        break;
      case 'url':
        input = document.createElement('input');
        input.type = 'url';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        break;
      case 'source':
        if (value === '') {
          return;
        }
        break;
      default:
        throw new Error('can not interpret ' + inputType);
    }
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    data = $(this).data('session-sources').replace(regexp, time);
    regexp = new RegExp('stub_link_to_has_many', 'g');
    data = data.replace(regexp, value);
    if (inputType === 'email') {
      friend = $("a[data-email='" + value + "'][data-target-input='session_sources']");
      if (friend.length > 0) {
        data = $(data);
        data.children('.friend_input_content').hide();
      }
    }
    $('.session_sources_list .invited').prepend(data);
    console.log("Check This Dasha");
    if ($('input[name*=immersive_free]:checked').val() === 'true' || $('input[name*=livestream_free]:checked').val() === 'true') {
      $('input[name*=paid_by_organizer_user]').prop('disabled', true);
    }
    $('#session_sources_new_input').val('');
    $("a[data-email='" + value + "'][data-target-input='session_sources']").closest('.list-group-item').hide();
    return window.hideOrDisplayPayForThisUserOptions();
  });

  $(function() {
    return $('.contacts_member_input').each(function(i, obj) {
      return $("a[data-email='" + $(obj).val() + "'][data-target-input='contacts']").closest('.list-group-item').hide();
    });
  });

  $(document).on('click', 'form .remove_contacts', function(event) {
    var email;
    email = $(this).parents('.list-group-item').find('.contacts_member_input').val();
    if (email) {
      $("a[data-email='" + email + "'][data-target-input='contacts']").closest('.list-group-item').show();
    }
    $(this).closest('.list-group-item').remove();
    return event.preventDefault();
  });

  $(document).on('keypress', 'form #contacts_new_input', function(event) {
    if (event.keyCode === 13) {
      $('form .add_contacts').click();
      return event.preventDefault();
    }
  });

  $(document).on('click', 'form .add_contacts', function(event) {
    var data, friend, input, inputType, regexp, time, value;
    event.preventDefault();
    value = $.trim($('#contacts_new_input').val());
    if (!value) {
      return;
    }
    inputType = $('#contacts_new_input').attr('type');
    switch (inputType) {
      case 'email':
        input = document.createElement('input');
        input.type = 'email';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        if (value === $.trim($('#contacts_new_input').data('organizer'))) {
          return;
        }
        break;
      case 'url':
        input = document.createElement('input');
        input.type = 'url';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        break;
      case 'source':
        if (value === '') {
          return;
        }
        break;
      default:
        throw new Error('can not interpret ' + inputType);
    }
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    data = $(this).data('contacts').replace(regexp, time);
    regexp = new RegExp('stub_link_to_has_many', 'g');
    data = data.replace(regexp, value);
    if (inputType === 'email') {
      friend = $("a[data-email='" + value + "'][data-target-input='contacts']");
      if (friend.length > 0) {
        data = $(data);
        data.children('.friend_input_content').hide();
      }
    }
    $('.contacts_list .invited').prepend(data);
    console.log("Check This Dasha");
    if ($('input[name*=immersive_free]:checked').val() === 'true' || $('input[name*=livestream_free]:checked').val() === 'true') {
      $('input[name*=paid_by_organizer_user]').prop('disabled', true);
    }
    $('#contacts_new_input').val('');
    $("a[data-email='" + value + "'][data-target-input='contacts']").closest('.list-group-item').hide();
    return window.hideOrDisplayPayForThisUserOptions();
  });

  $(function() {
    return $('.employees_member_input').each(function(i, obj) {
      return $("a[data-email='" + $(obj).val() + "'][data-target-input='employees']").closest('.list-group-item').hide();
    });
  });

  $(document).on('click', 'form .remove_employees', function(event) {
    var email;
    email = $(this).parents('.list-group-item').find('.employees_member_input').val();
    if (email) {
      $("a[data-email='" + email + "'][data-target-input='employees']").closest('.list-group-item').show();
    }
    $(this).closest('.list-group-item').remove();
    return event.preventDefault();
  });

  $(document).on('keypress', 'form #employees_new_input', function(event) {
    if (event.keyCode === 13) {
      $('form .add_employees').click();
      return event.preventDefault();
    }
  });

  $(document).on('click', 'form .add_employees', function(event) {
    var data, friend, input, inputType, regexp, time, value;
    event.preventDefault();
    value = $.trim($('#employees_new_input').val());
    if (!value) {
      return;
    }
    inputType = $('#employees_new_input').attr('type');
    switch (inputType) {
      case 'email':
        input = document.createElement('input');
        input.type = 'email';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        if (value === $.trim($('#employees_new_input').data('organizer'))) {
          return;
        }
        break;
      case 'url':
        input = document.createElement('input');
        input.type = 'url';
        input.value = value;
        if (!input.checkValidity() || value === '') {
          return;
        }
        break;
      case 'source':
        if (value === '') {
          return;
        }
        break;
      default:
        throw new Error('can not interpret ' + inputType);
    }
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    data = $(this).data('employees').replace(regexp, time);
    regexp = new RegExp('stub_link_to_has_many', 'g');
    data = data.replace(regexp, value);
    if (inputType === 'email') {
      friend = $("a[data-email='" + value + "'][data-target-input='employees']");
      if (friend.length > 0) {
        data = $(data);
        data.children('.friend_input_content').hide();
      }
    }
    $('.employees_list .invited').prepend(data);
    console.log("Check This Dasha");
    if ($('input[name*=immersive_free]:checked').val() === 'true' || $('input[name*=livestream_free]:checked').val() === 'true') {
      $('input[name*=paid_by_organizer_user]').prop('disabled', true);
    }
    $('#employees_new_input').val('');
    $("a[data-email='" + value + "'][data-target-input='employees']").closest('.list-group-item').hide();
    return window.hideOrDisplayPayForThisUserOptions();
  });

}).call(this);
