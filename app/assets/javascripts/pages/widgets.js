$(function() {
    var $iframe         = $('#widget_live_iframe');
    var $iframe_wrapper = $('#widget_live_iframe_wrapper');
    var $code           = $('#widget_live_code');

    $('#widget_live_width').on('keyup', function(){
        $iframe.css('width', $(this).val());
        $code.html($.trim($iframe_wrapper.html()));
    });

    $('#widget_live_height').on('keyup', function(){
        $iframe.css('height', $(this).val());
        $code.html($.trim($iframe_wrapper.html()));
    });

    $('.widget_live_checkbox_user').on('click', function(){
        var link  = $code.data('link');
        var val   = $('.widget_live_checkbox_user:checked').map(function() {
            return $(this).data('value');
        }).get();

        if (val.length > 0){ link = link + '?organizers=' + val.join(',')};
        $iframe.attr('src', link);
        $code.html($.trim($iframe_wrapper.html()));
    });
});

function RMBlockTextToggle(){
    jQuery('.RM-block').each(function(){
        var $this = jQuery(this),
            blockHeight = jQuery('.RM-block-text').height();

        if(blockHeight >= 52){
            $this.addClass('TextHiden')
        }
        $this.click(function(){
            $this.toggleClass('TextHidenInit');
        });
    });
}
