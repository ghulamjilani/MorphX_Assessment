var userEmails = [];
$(document).ready(function() {
  userEmails = $('#contacts_list option').clone();
});
$(document).on('click', '#contacts_list option', function() {
  val = $('#emails_list').val().trim() + "\n" + $(this).val();
  $('#emails_list').val(val.trim());
});
$(document).on('input change', '#contact_filter', function() {
  var filteredOptions = [];
  filter = $(this).val().toLowerCase();
  userEmails.each(function() {
    if ($(this).text().toLowerCase().includes(filter)) {
      filteredOptions.push($(this));
    }
  });
  $('#contacts_list').html(filteredOptions);
});
