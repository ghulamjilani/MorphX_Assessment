// function liveStream_onSessionPage_UI_Init() {
//     $(window).resize(function () {
//         videoIframeWidthSet();
//     });
//
//     $(function () {
//         var $mainWrapper = $('#WholeLivestreamDiv'),
//             wrapperHeight = $('.MainVideoFrame-wrapper').height();
//             $mainWrapper.height(wrapperHeight);
//         videoIframeWidthSet();
//     });
//
// }
//append tile on nav item
function appendBar(element) {
    var subjectId = $(element).attr("data-id"),
        $subject = $("#" + subjectId),
        panels_size = $("#sectionWrapp section:visible").length,
        itemCount = false;

    if ($('body').hasClass('mobile_device')){
      $(".sectionWrapp section.active").removeClass('active');
      $(".WLS-right-sideBar a.active").removeClass('active');
    }
    if ($('#' + subjectId + ':visible').length == 0) {
        $(element).addClass('active');
        $subject.addClass('active');

        //if tile are second, add new with height= wrapperHeight - firstTile
        var height = 0;
        if ($(".sectionWrapp section:visible").length > 0) {
          height = 98 / $(".sectionWrapp section:visible").length;
        }
        $(".sectionWrapp section:visible").css('height', height + '%');

        // videoIframeWidthSet();
    } else {
        CloseBar(element);
    }

}

function CloseBar(element) {

    var $el = $(element),
        attr = $el.attr('data-id');

    if (typeof attr !== typeof undefined && attr !== false) {
        closedTab_id = $el.attr("data-id");
    } else {
        closedTab_id = $el.parents("section").attr("id");
    }
    //$panel = $('.connectedBar #' + closedTab_id);
    $panel = $('#' + closedTab_id);
    parent = $panel.parent();

    //$panel.remove();
    $(parent).children('section').css('height', '98%');
    //$("[data-id='" + closedTab_id + "']").removeClass('active');
    $el.removeClass('active');
    $panel.removeClass('active');
    var height = 0;
    if ($(".sectionWrapp section:visible").length > 0) {
      height = 98 / $(".sectionWrapp section:visible").length;
    }
    $(".sectionWrapp section:visible").css('height', height + '%');

    // videoIframeWidthSet();
}
// function videoIframeWidthSet() {
//     var $wrapper = $('.WholeLivestreamDivWrapp'),
//         wrapperWidth = $wrapper.width(),
//         $iframeWrapper = $('.MainVideoFrame-wrapper'),
//         iframeWrapperWidth = $iframeWrapper.width(),
//         $sideBarWrapper = $('.sideBarWrapper'),
//         sideBarWrapperrWidth = $sideBarWrapper.width();
//
//     var maxWidth = wrapperWidth - sideBarWrapperrWidth - 50;
//     if ((iframeWrapperWidth + sideBarWrapperrWidth + 50) > wrapperWidth || iframeWrapperWidth < 1170) {
//         $iframeWrapper.width(maxWidth)
//     }
// }
function resizeInit() {
    var wrapperHeight = $('.sideBarWrapper').height();
    //console.log(wrapperHeight);
    //$(".connectedBar section").filter(function (index) {
    $(".sideBarWrapper section").filter(function (index) {
        var parent = $(this).parents('.sectionWrapp')

        return ($(parent).find('section').length === 1)
    }).resizable({
        handles: 's',
        distance: 0,
        minHeight: wrapperHeight * 0.02,
        maxHeight: wrapperHeight * 0.98,
        start: function (event, ui) {
            // just remember the total width of self + neighbor
            this.heightWithNeighbor = ui.originalSize.height + ui.element.next().outerHeight();
            // fix FF resizing issue sometimes cause div to overflow
            $(this).parent().addClass("resizing");
        },
        resize: function (event, ui) {
            // and just subtract it!
            ui.element.next().height(this.heightWithNeighbor - ui.size.height);
        },
        stop: function (event, ui) {
            // clean up, is this needed?
            delete this.heightWithNeighbor;
            $(this).parent().removeClass("resizing");
        }
    }).on('resize', function (event) {
        event.stopPropagation();
    });
    // videoIframeWidthSet();
}
