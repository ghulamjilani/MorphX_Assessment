$(document).ready(function(){
    if($('body').hasClass('FAQ')){
        $(document).on('click', '.info-tabs a', function() {
          closeBr();
          $('.firstLinenav').css('opacity', 1);
          $('.left-side-bar').first().css('min-height', ($('.secondLinenav').first().outerHeight() + 20) + 'px');
          $('.left-side-bar').last().css('min-height', ($('.secondLinenav').last().outerHeight() + 20) + 'px');
          $('.firstLinenav').css('min-height', 0);
          $('.firstLinenav').css('height', 'auto');
        });
        $(document).on('click', '.ensure-link-style', function() {
          $('.left-side-bar').first().css('min-height', ($('.secondLinenav').first().outerHeight() + 20) + 'px');
          $('.left-side-bar').last().css('min-height', ($('.secondLinenav').last().outerHeight() + 20) + 'px');
        });
        $(document).on('click', '.contentList .ensure-link-style', function() {
          $('.firstLinenav').css('opacity', 0);
        });
        $('.firstLinenav a').click(function(e){
            e.preventDefault();
            setTimeout(function(){
              $('.firstLinenav').css('min-height', $(".left-side-bar .secondLinenav")[1].offsetHeight + 'px');
              $('.firstLinenav').css('height', $(".left-side-bar .secondLinenav")[1].offsetHeight + 'px');
            },200)
            $('.firstLinenav').css('opacity', 0);
            showcontent(this);
        });
        $('.backButton').click(function(e){
            e.preventDefault();
            setTimeout(function(){
              $('.firstLinenav').css('min-height', 0);
              $('.firstLinenav').css('height', 'auto');
              $('.left-side-bar').each(function(){
                $(this).css('min-height', '');
              });
            },200)
            $('.firstLinenav').css('opacity', 1);
            closeBr();
        });
        $('.secondLinenav a').click(function(e){
           if (!$(this).hasClass('backButton')){
               e.preventDefault();
               $('.secondLinenav a').removeClass('active');
               $(this).addClass('active');
               $('.content-box').removeClass('show');
               var $contentShow = $(this).attr('data-id-text');
               $('.content-box[data-id-text-box="' + $contentShow + '"] ').addClass('show');
               $('.contentList').hide();
           }
        });
        $('.contentList a').click(function(e){
            var $dataIdParentNav = $(this).attr('data-id-parentNav');
            var $dataIdText = $(this).attr('data-id-text');
            e.preventDefault();
            $('.content-box').removeClass('show');
            showcontent(this);
            $('.secondLinenav div.nav[data-nav="' + $dataIdParentNav + '"] ').addClass('openClild');
            $('.contentList').hide();
            $('.secondLinenav a[data-id-text="' + $dataIdText + '"]').addClass('active');
            $('.content-box[data-id-text-box="' + $dataIdText + '"] ').addClass('show');

        });
    }
});


function closeBr(){
    $('.openClild').removeClass('openClild');
    $('.secondLinenav').removeClass('open');
    $('.slideBox').removeClass('slide-left');
    $('.content-box').removeClass('show');
    $('.contentList').show();
    $('.secondLinenav a').removeClass('active');

}

function showcontent(elmnt){
    var $DataId = jQuery(elmnt).attr("data-id");
    var $showNAv = jQuery('.secondLinenav div[data-nav="' + $DataId + '"]');


    closeBr();

    $showNAv.addClass('openClild');
    jQuery('.secondLinenav').addClass('open');
    jQuery('.left-side-bar').first().css('min-height', (jQuery('.secondLinenav').first().outerHeight() + 20) + 'px');
    jQuery('.left-side-bar').last().css('min-height', (jQuery('.secondLinenav').last().outerHeight() + 20) + 'px');
    jQuery('.slideBox').toggleClass('slide-left');

    return false;
}
