$(document).ready(function() {
  TabAceEditors();
  bind_env_select();
});


var TabAceEditors = function() {
  var editors = document.querySelectorAll('.ace-editor-container');

  for (var i = 0; i < editors.length; i++) {
    let thisElement = editors[i];
    let thisEditor = ace.edit(thisElement);
    thisEditor.setOptions({tabSize: 2});
    if ($(thisElement).attr('id') == 'service_current_config_editor'){
      thisEditor.setReadOnly(true)
    }
  }
};

var bind_env_select = function () {
  $('#active_config_env').on('change', function(){
    var url = new URL(window.location.href);
    url.searchParams.set("env", this.value);
    window.location.href = url;
  });
};