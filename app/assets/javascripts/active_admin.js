//= require active_admin/base.js
//= require active_admin/mailing
//= require 'ace-src-min-noconflict/ace.js'
//= require 'activeadmin/ace_editor_input.js'
//= require active_admin/config_page.js
//= require chartkick
//= require highcharts

$(document).ready(function() {
  let list = $("#edit_system_theme .theme-variable")
  if(list.length) {
    $(list[0]).prepend($(`<h3 style="margin-top: 30px;"> ${list[0].dataset.group} </h3>`))
    list.each((index, e) => {
      if(index < list.length - 2 && e.dataset.group !== list[index + 1].dataset.group) {
        $(e).append($(`<h3 style="margin-top: 30px; margin-bottom: -20px;"> ${list[index + 1].dataset.group} </h3>`))
      }
    })
  }
})