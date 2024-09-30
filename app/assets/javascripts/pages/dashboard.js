jQuery(document).ready(function(){
  if(jQuery('body').hasClass('dashboards')){
    $('.left-side-bar .nav li a').click(function(){
        $(this).parent().parent().find("li").removeClass("active");
        $(this).parent().addClass("active");
    });
  };

});

function affix(){
  var afixContainer = jQuery('.AffixSection');
  if (afixContainer.length) { // make sure ".sticky" element exists
    var stickyTop = afixContainer.offset().top; // returns number

    $(window).resize(function(){ // scroll event
      //40 is a padding-top + padding-bottom of ".main-content-section"
      if ($(".main-content-section").length){
        var mainContentSection = $(".main-content-section");
        var offset_for_fixed_heder = 40;
      }
      if ($(".MainForm_block_for_AffixSection").length){
        var mainContentSection = $(".MainForm_block_for_AffixSection");
        var offset_for_fixed_heder = 40;
      }
      if ($(".cmk_channel_New .MainForm_block_for_AffixSection").length){
        var mainContentSection = $(".cmk_channel_New .MainForm_block_for_AffixSection");
        var offset_for_fixed_heder = 0;
      }
      if (!mainContentSection) { return false }
      var maxTopPos = mainContentSection.offset().top + mainContentSection.height() + offset_for_fixed_heder - afixContainer.height() -50;
      var windowTop = $(window).scrollTop(); // returns number
      var affixHeightBox = afixContainer.height();
      var mainContentHeight = mainContentSection.height();

      if ($(document).height() <= (affixHeightBox + 200)){return false} //disable affix if not enuf content on page

      if(mainContentHeight > affixHeightBox ){
        if (stickyTop - 106 < windowTop){
          if(windowTop + 106 > maxTopPos){
            afixContainer.offset({ top: maxTopPos });
              afixContainer.addClass('sectionBottomFixed')
          }else{
            afixContainer.css({ position: 'fixed', top: "102px" });
            afixContainer.addClass('sectionFixed');
            afixContainer.removeClass('sectionBottomFixed')
          }
        }
        else {
          afixContainer.css('position','static').removeClass('sectionFixed');
          afixContainer.parent().css('padding-top', '0px')
        }
      }
      else{
        afixContainer.css('position','static');
        afixContainer.parent().css('padding-top', '0px')
      }
    });

    $(window).scroll(function(){ // scroll event
      //40 is a padding-top + padding-bottom of ".main-content-section"
      if ($(".main-content-section").length){
        var mainContentSection = $(".main-content-section");
        var offset_for_fixed_heder = 40;
      }
      if ($(".MainForm_block_for_AffixSection").length){
        var mainContentSection = $(".MainForm_block_for_AffixSection");
        var offset_for_fixed_heder = 40;
      }
      if ($(".cmk_channel_New .MainForm_block_for_AffixSection").length){
        var mainContentSection = $(".cmk_channel_New .MainForm_block_for_AffixSection");
        var offset_for_fixed_heder = 0;
      }
      if (!mainContentSection) { return false }
      var maxTopPos = mainContentSection.offset().top + mainContentSection.height() + offset_for_fixed_heder - afixContainer.height() -50;
      var windowTop = $(window).scrollTop(); // returns number
      var affixHeightBox = afixContainer.height();
      var mainContentHeight = mainContentSection.height();

      if ($(document).height() <= (affixHeightBox + 200)){return false} //disable affix if not enuf content on page

      if(mainContentHeight > affixHeightBox ){
        if (stickyTop - 86 < windowTop){
          if(windowTop + 86 > maxTopPos){
            afixContainer.offset({ top: maxTopPos });
              afixContainer.addClass('sectionBottomFixed')
          }else{
            afixContainer.css({ position: 'fixed', top: "83px" });
            afixContainer.addClass('sectionFixed');
            afixContainer.removeClass('sectionBottomFixed')
          }
        }
        else {
          afixContainer.css('position','static').removeClass('sectionFixed');
          afixContainer.parent().css('padding-top', '0px')
        }
      }
      else{
        afixContainer.css('position','static');
        afixContainer.parent().css('padding-top', '0px')
      }
    });

  }

  affixConteinerWidth(afixContainer);
  jQuery(window).resize(function(){
    affixConteinerWidth(afixContainer);
  })
}

function affixConteinerWidth(afixContainer){
  var widthAffix = afixContainer.parent().width();
  afixContainer.width(widthAffix + "px")
}


window.video_checkbox_click = function (){
    $('.video_on_profile').on('change', function(){
        var data = {video_id: $(this).data('video-id'), video_action: $(this).data('video-action')};
        $.post('/users/video_on_profile', data).error(function (response) {
            $.showFlashMessage("We're sorry, but something went wrong", {type: "error"});
        });

        if ($(this).is(':checked')){
            $(this).data('video-action', 'hide');
        }else{
            $(this).data('video-action', 'show');
        }

    });
}
