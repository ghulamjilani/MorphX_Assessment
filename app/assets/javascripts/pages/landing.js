if (screen.width < 1000) {
    var mobSlider = document.querySelector('.homePageBanner__imgWrapp')
    if (mobSlider) {
      mobSlider.style.webkitTransform = `translate3d(0px, 0px, 0px)`

      var startTouchX = 0
      var transform = Number(mobSlider.style.transform.split('(')[1].split(',')[0].replace('px', ''))
      
      mobSlider.addEventListener('touchstart', function (e) {
        startTouchX = e.touches[0].clientX
        transform = Number(mobSlider.style.transform.split('(')[1].split(',')[0].replace('px', ''))
      })
      mobSlider.addEventListener('touchend', function () {
        startTouchX += diff
      })
      mobSlider.addEventListener('touchmove', function(e) {
        var offset
        var diff = 0
        diff = (startTouchX - e.touches[0].clientX) * -1
        offset = transform + diff
        if ((offset * -1) >= 0 && offset * -1 <= mobSlider.offsetWidth - screen.width + 10)
        mobSlider.style.webkitTransform = `translate3d(${offset}px, 0px, 0px)`
      })
    }
  }

  function activateSlider (selector, timer, timeout) {
    var element = $(`${selector} .homePageBanner__img__slider`)
    if (element) {
      var imageHeight = $(`${selector} .homePageBanner__img__slider img:first`).height()
      var elHeight = element.height()
      var position = 0
      var goTop = false
      setTimeout(() => {
        setInterval(function() {
          if (elHeight > Math.abs(position) + imageHeight && !goTop) {
            position += -imageHeight
            goTop = false;
            element.css( { 'top': `${position}px` } )

          } else {
              position += imageHeight
              goTop = true
              element.css( { 'top': `${position}px` } )
              if (position === 0) {
                goTop = false
              }
          }
        }, timer * 1000)
      }, timeout * 1000)
    }
  }

  activateSlider('.first-slider', 6, 1)
  activateSlider('.second-slider', 6, 2)
  activateSlider('.third-slider', 6, 3)
  activateSlider('.fourth-slider', 6, 4)
