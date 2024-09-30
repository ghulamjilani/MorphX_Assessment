$(document).on("click", ".header-search-submit", function(){
    let headerSearchInput
    let input
    let headerSearchForm
    screen.width > 768 ? headerSearchInput = document.querySelector('.header-search-wrapper.desc-search') : headerSearchInput = document.querySelector('.header-search-wrapper.mobile-search')
    screen.width > 768 ? input = document.querySelector('.header-search-wrapper.desc-search input') : input = document.querySelector('.header-search-wrapper.mobile-search input')
    screen.width > 768 ? headerSearchForm = document.querySelector('.header-search-form.desctop-search') : headerSearchForm = document.querySelector('.header-search-form.mobile-search')
    
    if (headerSearchInput.classList.contains('active') && input.value) {
        console.log('sub')
        headerSearchForm.submit()
    } else {
        headerSearchInput.classList.add('active')
        input.focus()
    }
});

$(document).on("mouseover", ".header-search-wrapper", function(){
  $('.header-search-wrapper').addClass('active');
  /*-- === hide next session button === --*/
  $('.NextSession').addClass('active');
  /*-- === hide go live / schedule live stream button === --*/
  $('.topLine_wrapp button').addClass('activited');
  /*-- === hide complete channel/business/start creating button === --*/
  $('.bapBtn').addClass('active');
});

$(document).on("mouseleave", ".header-search-wrapper", function(){
    var inputField = $(".desctop-search .header-search-input");
    if(inputField.val() !== ''){
        return false;
    }
    else{
        $('.header-search-wrapper').removeClass('active');
        $('.header-search.desctop').addClass('active');
        setTimeout(function(){
            $('.NextSession').removeClass('active');
            $('.topLine_wrapp button').removeClass('activited');
            $('.bapBtn').removeClass('active');
            $('.header-search.desctop').removeClass('active');
        }, 1000);
    }
});
