//= require chaplin
//= require dashboard/plans
//= require dashboard/uploads
//= require dashboard/replays
//= require dashboard/products
//= require dashboard/mailing
//= require_self

(function () {
    "use strict";

    $(document).on('click', '.dashboard-tab', function (e) {
        $.each($('a.dashboard-tab'), function () {
            return $(this).parent().removeClass('active');
        });
        $(e.target).parent().addClass('active');
        return true;
    });

    $(document).ready(function (e) {
        if ($('.CRsession').length == 1) {
            $('.CRsession').first().find('.toggle-session-list').toggleClass('active');
            $('.CRsession').first().toggleClass('showSessions');
            return false;
        }
    });

    $(document).on('click', '.toggle-session-list', function (e) {
        $(this).toggleClass('active');
        $(this).parents('.CRsession').toggleClass('showSessions');
        return false;
    });

    $(document).on('ajax:before', '.attach-lists form, form.attach_list_to_recording', function () {
        return $(this).find('button').attr('disabled', 'disabled').addClass('disabled');
    }).on('ajax:success', '.attach-lists form, form.attach_list_to_recording', function () {
        $.showFlashMessage('List successfully attached', {
            type: 'success'
        });
        $(this).find('button').removeAttr('disabled').removeClass('disabled');
    }).on('ajax:error', '.attach-lists form, form.attach_list_to_recording', function () {
        $.showFlashMessage('You have no permissions', {
            type: 'error'
        });
        $(this).find('button').removeAttr('disabled').removeClass('disabled');
    });

    $('body').on('click', '.playvideo-link', function (e) {
        var src;
        e.preventDefault();
        src = $(this).data('src');
        $('#playvideo-modal').modal('show');
        $('#playvideo-iframe').attr('src', src);
    });
    $("#playvideo-modal").on('hidden.bs.modal', function () {
        $("#playvideo-modal").find("iframe").attr('src', '');
    });
}).call(this);
