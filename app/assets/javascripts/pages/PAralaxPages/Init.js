
function scrollerInit(){
    let mvc = $('.main-video-container'),
        mVS = $('.mainVideoSection-content_block');
    var mvcoffsetTop = mvc.offset().top,
        mvcHeight = mvc.height();

    if((jQuery('body').hasClass('mobile_device'))){
        return false
    }

    if (!(mvc.hasClass('init'))){
        mvc.addClass('init')
    }
    else {
        return false
    }

    var mainVideoSectionBody = $('.mainVideoSection-body');
    var videoFormat = 1.777777778;
    function mainVideoSectionBodyHeight() {
        let width = mainVideoSectionBody.width();
        mainVideoSectionBody.css('min-height', (width/videoFormat).toFixed(2)+'px');
    }

    $( window ).resize(function() {
        mainVideoSectionBodyHeight();
        mvcoffsetTop = mvc.offset().top;
        mvcHeight = mvc.height();
    });

    $(window).scroll(function(){
        mainVideoSectionBodyHeight();

        if (jQuery('body').hasClass('curtainActive')){
            return false
        }

        if ($(window).scrollTop() >= (mvcoffsetTop + mvcHeight*0.92)){
            mvc.removeClass('skrollable-before').addClass('skrollable-after')
            mVS.hide();

            // Get the block element we want to move
            const block = mvc[0];

            let isDragging = false; // Flag indicating the state of the move
            let initialX; // Start X position when clicked
            let initialY; // Initial Y position when clicked
            let offsetX = 0; // X offset relative to start position
            let offsetY = 0; // Y offset from start position

            block.addEventListener('mousedown', (e) => {
                isDragging = true;
                const rect = block.getBoundingClientRect();
                initialX = e.clientX - rect.left;
                initialY = e.clientY - rect.top;
            });

            // Move event handler (mouse held down)
            document.addEventListener('mousemove', (e) => {
                if (!isDragging) return;

                const rect = block.getBoundingClientRect();
                offsetX = e.clientX - rect.left - initialX;
                offsetY = e.clientY - rect.top - initialY;

                block.style.left = rect.left + offsetX + 'px';
                block.style.top = rect.top + offsetY + 'px';
            });

            // Move end event handler (mouse button release)
            document.addEventListener('mouseup', () => {
                isDragging = false;
            });



        } else {
            mvc.addClass('skrollable-before').removeClass('skrollable-after')
            mVS.show();
        }
    });
};