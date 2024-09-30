$('#SessionParticipantsList_modal').on('shown.bs.modal', function (event) {
    var $modal;
    $('.SessionParticipantsList').find('.item').remove();
    $('.LoadingCover').removeClass('hidden');
    $modal = $('#SessionParticipantsList_modal');
    $.ajax({
        type: 'GET',
        dataType: 'json',
        url: Routes.participants_session_path($modal.attr('session')),
        success: function (jsondata) {
            var template;
            $modal.find('.groupTitle').text("Participants" + (jsondata.length > 0 ? " (" + jsondata.length + ")" : ''));
            if (jsondata.length === 0) {
                $modal.find('.SessionParticipantsList').html(I18n.t('sessions.no_participants'));
            } else {
                template = HandlebarsTemplates['sessions/contact'];
                $modal.find('.SessionParticipantsList').html('');
                _.each(jsondata, function (item) {
                    $modal.find('.SessionParticipantsList').append(template(item));
                });
            }
            $('.SessionParticipantsList').removeClass('load');
        },
        complete: function () {
            $('.LoadingCover').addClass('hidden');
        }
    });
});

$('#SessionParticipantsList_modal').on('ajax:success', '.addContactBtn', function (event, xhr, status) {
    if ($(this).hasClass('added')) {
        $(this).text('Add to Contacts');
        $(this).removeClass('btn-white').removeClass('added');
    } else {
        $(this).text('Remove from Contacts');
        $(this).addClass('btn-white').addClass('added');
    }
});

var openRequestNewSessionForm = function (event, obj, parentWidth) {
    var body, container, containerGroup, parentPOs, parentPOs_left, parentPOs_top;
    event.preventDefault();
    parentPOs = $(obj).offset();
    parentPOs_left = Math.round(parentPOs.left) + 10;
    parentPOs_top = Math.round(parentPOs.top);
    containerGroup = $('.RequestNewSessionOverlay');
    container = $('#RequestNewSessionForm');
    body = $('body');
    container.css({
        'width': parentWidth - 5,
        'left': parentPOs_left - 5,
        'top': parentPOs_top
    }).fadeIn();
    containerGroup.fadeIn();
    $(document).mouseup(function (e) {
        if (container.is(':visible')) {
            if (containerGroup.is(e.target) && containerGroup.has(e.target).length === 0) {
                e.stopPropagation();
                container.fadeOut();
                containerGroup.fadeOut();
            }
        }
    });
    $(window).resize(function () {
        if (container.is(':visible')) {
            container.fadeOut();
            containerGroup.fadeOut();
        }
    });
};
