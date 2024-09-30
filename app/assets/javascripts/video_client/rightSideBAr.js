function Video_onSessionPage_UI_Init() {
    $(function () {
        var $mainWrapper = $('.V-VideoContainer'),
            wrapperHeight = $('.MainVideoFrame-wrapper').height();
        $mainWrapper.height(wrapperHeight);
    });
}

//append or remove tile on nav item сlick
function appendBar(element) {
    var panelId = $(element).attr('data-id'),
        $panel = $('#' + panelId),
        $container = $('.V-VideoContainer'),
        sectionCount = $container.find('.visible').length;

    VCloseHoverPanel();
    $container.find('.visible.full-height').removeClass('full-height');

    if ($panel.hasClass('visible')) {
        CloseBar(element);
    } else {
        if (sectionCount == 3) {
            $.showFlashMessage('Too many opened panels', {type: 'error'});
            return false
        } else {
            resizeInit();
            $panel.css('order', sectionCount + 1, 'height', 0).attr('data-count', sectionCount + 1);
            $("[data-id='" + panelId + "']").addClass('active');

            switch (sectionCount) {
                case 0:
                    $container.find('section[data-count="1"]').css('height', '100%');
                    break;
                case 1:
                    $container.find('section[data-count="1"], section[data-count="2"]').css('height', '50%');
                    break;
                case 2:
                    var mainHeight = $container.height(),
                        onePerc = mainHeight * 0.01,
                        minHeight = onePerc * 30,
                        $panel1 = $container.find('section[data-count="1"]'),
                        $panel2 = $container.find('section[data-count="2"]'),
                        el1H = $panel1.height(),
                        el2H = $panel2.height();

                    $panel.css('height', '33.33%');
                    if (el1H <= minHeight || el2H <= minHeight) {
                        if (el1H <= minHeight) {
                            $panel2.css('height', (((el2H - (onePerc * 33.3)) / onePerc) + '%'));
                        }
                        if (el2H <= minHeight) {
                            $panel1.css('height', (((el1H - (onePerc * 33.3)) / onePerc) + '%'));
                        }
                    } else {
                        $panel1.css('height', (((el1H - (onePerc * 15.15)) / onePerc) + '%'));
                        $panel2.css('height', (((el2H - (onePerc * 15.15)) / onePerc) + '%'));
                    }
                    break;
                default:
                    $.showFlashMessage('Too many opened panels', {type: 'error'});
                    return false
            }
            $panel.addClass('visible');
        }
    }
    spaceForPanels();
    resizeInit();
}

function CloseBar(element) {
    var $el = $(element),
        $container = $('.V-VideoContainer'),
        $visibleEl = $container.find('.visible'),
        sectionCount = $visibleEl.length,
        attr = $el.attr('data-id'),
        closedTab_id, $panel, parent, $panelOrder;

    if (typeof attr !== typeof undefined && attr !== false) {
        closedTab_id = $el.attr('data-id');
    } else {
        closedTab_id = $el.parents('section').attr('id');
    }
    $panel = $('#' + closedTab_id);
    $panelOrder = $panel.attr('data-count');

    $el.removeClass('active');
    $panel.removeClass('visible').removeAttr('data-count').css('order', 0);

    $visibleEl.each(function () {
        var curentCount = $(this).attr('data-count');
        if (curentCount > $panelOrder) {
            $(this).css('order', (curentCount - 1)).attr('data-count', (curentCount - 1))
        }
    });

    $("[data-id='" + closedTab_id + "']").removeClass('active');
    $panel.removeClass('visible');

    if (sectionCount == 2) {
        $visibleEl.css('height', '100%', 'order', 1).attr('data-count', 1);
    } else if (sectionCount == 3) {
        var $h1 = $container.find('.visible[data-count="1"]'),
            $h2 = $container.find('.visible[data-count="2"]'),
            $containerHeight = $container.height(),
            onePerc = $containerHeight * 0.01;
        $h2.css('height', (( $containerHeight - $h1.height() - 15) / onePerc) + '%');
    }else{
      $('.showVideo').removeClass('showSidebarLine-1');
    }
}

function spaceForPanels() {
    if ($('.V-VideoContainer .visible').length == 0) {
        $('body').removeClass('showSidebarLine-1');
    } else {
        $('body').addClass('showSidebarLine-1');
    }
}

function resizeInit() {
    var $container = $('.V-VideoContainer'),
        wrapperHeight = $container.height(),
        subTotalHeight, elIndex, elIndexNext;
    $container.find('section.visible').resizable({
        handles: 's',
        distance: 0,
        minHeight: 41,
        resizeWidth: false,
        maxHeight: wrapperHeight - 81,
        start: function (event, ui) {
            elIndex = $(ui.originalElement).attr('data-count');
            elIndexForNext = Number(elIndex) + 1;
            elIndexNext = ui.originalElement.parent().find('[data-count="' + elIndexForNext + '"]');
            subTotalHeight = ui.originalSize.height + elIndexNext.outerHeight();
            $(this).parent().addClass('resizing');
        },
        resize: function (event, ui) {
            // and just subtract it!
            elIndexNext.height(subTotalHeight - ui.size.height);
        },
        stop: function (event, ui) {
            var cellPercentHeight = 100 * ui.originalElement.outerHeight() / container.innerHeight(),
                nextPercentHeight = 100 * elIndexNext.outerHeight() / container.innerHeight();

            ui.originalElement.css('height', cellPercentHeight + '%');
            elIndexNext.css('height', nextPercentHeight + '%');
            // clean up, is this needed?
            // delete this.heightWithNeighbor;
            $(this).parent().removeClass('resizing');
        }
    }).on('resize', function (event) {
        event.stopPropagation();
    });
}

$(document).ready(function () {
    Video_onSessionPage_UI_Init();
    // add stilization for scroll
    // DONT WORK FOR FF or OPERA ON MAC OSX, osx scrollbars settings fuck not webkit browsers (OSX sucks, Jobs come back to us)
    // $('.V-header .styledScroll, .V-right-panel-contaiver .styledScroll ').scrollbar();
    $('.sectionHeader').disableSelection();
    resizeInit();

    $('.V-right-panel-contaiver').mouseenter(function (e) {
        if (!$('.V-toggleBlock').hasClass('open')) {
           $(e.target).parents('a:not([onclick!="VToggleBlock(this)"])').click();
        }
    }).mouseleave(function () {
        VCloseHoverPanel();
    });

    $('.V-toggleBlock').mouseenter(function () {
        VOpenHoverPanel();
    });
});


function ManageAllParticipants_dropDownOpen(e) {
    $(e).parents('.userWrapp').toggleClass('active');
}

function VToggleBlock(element) {
    $(element).parents('section').toggleClass('open');
}

function VCloseHoverPanel() {
    var $container = $('.V-right-panel-contaiver');
    if ($container.hasClass('open')) {
        $container.removeClass('open');
    }

    if ($('.V-VideoContainer section.visible').length < 1) {
      if(!$('body').hasClass('webrtc')){
        $('.VideoClient.showVideo').removeClass('showSidebarLine-1')
      }else{
        $('.VideoClient.showVideo').removeClass('overlay')
      }
    }
    $('.V-toggleBlock').removeClass('open');
}

function VOpenHoverPanel() {
    $('.V-right-panel-contaiver').addClass('open');
    if(!$('body').hasClass('webrtc')) {
      if ($('.V-VideoContainer section.visible').length < 1) {
        $('.VideoClient.showVideo').addClass('showSidebarLine-1');
      }
    }
}

