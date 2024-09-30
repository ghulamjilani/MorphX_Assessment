if (document.body.classList.contains('dashboards-mailing')) {

  $(document).on('click', '.contacts-table tbody .contact-cb', function () {
    let checkboxes = $('.contacts-table tbody .contact-cb');
    $('.contacts-table .select-all').prop('checked', checkboxes.length == checkboxes.filter(':checked').length);
    $('#textraText').trigger('change');
  });

  var quill = new Quill('#textraTextEditor', {
    modules: {
      toolbar: [
        [{
          header: [1, 2, false]
        }],
        ['bold', 'italic', 'underline'],
        ['image', 'link']
      ]
    },
    theme: 'snow' // or 'bubble'
  });

  quill.on('text-change', function (delta, old, source) {
    let limit = 2000;
    if (quill.getLength() > limit) {
      quill.deleteText(limit - 5, quill.getLength());
      $.showFlashMessage('max 2000 characters', {
        type: 'error',
        timeout: 5000
      });
    }
    $("textarea#textraText").val(quill.root.innerHTML);
    replacePreviewUsername()
  });

  function replacePreviewUsername() {
    let content = quill.root.innerHTML
    let username = 'Username';
    if ($('.contact-cb').length) {
      if ($('.contact-cb:checked').length) {
        username = $($('.contact-cb:checked')[0]).closest('tr').find('td[data-th="name"]').text().trim();
      } else {
        username = $($('.contact-cb')[0]).closest('tr').find('td[data-th="name"]').text().trim();
      }
    }
    content = content.replace('[username]', username);
    $('#custom_content').html(content).css('white-space', 'pre-wrap');
  }
  
  replacePreviewUsername();

  $(document).on('change', '.emailTemplate select', function () {
    var template = $(this).val(),
      custom_content = 'Hello';
    $.post(Routes.email_preview_dashboard_mailing_index_path(), {
      template: template,
      custom_content: custom_content
    });
  });
}