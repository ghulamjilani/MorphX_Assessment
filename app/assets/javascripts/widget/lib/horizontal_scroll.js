(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function(window) {
    return window.HorizontalScroll = (function() {
      function HorizontalScroll(pScrollableView) {
        this.scrollToCurrent = bind(this.scrollToCurrent, this);
        this.pScrollableView = pScrollableView;
        this.disposed = false;
        this.$hScroll = $("#schedule-scroll-h .scroll");
        this.$scrollableContainer = $('.schedule-inner-container');
        this.scrollableContainerMaxPosX = 0;
        this.currentOffsetX = 0;
        this.maxPosX = 0;
        this.minPosX = 0;
        this.isMouseDown = false;
        this.initialize();
      }

      HorizontalScroll.prototype.initialize = function() {
        if (this.pScrollableView.collection.length === 0 || this.$hScroll.length === 0) {
          return this.dispose();
        } else {
          this.unbindEvents();
          this.setScrollableContainerWidth();
          this.setScrollWidth();
          this.setMinPosX();
          this.setMaxPosX();
          return this.bindEvents();
        }
      };

      HorizontalScroll.prototype.setScrollWidth = function() {
        var scrollWidth;
        scrollWidth = $("#channel-table").width() / this.scrollableContainerMaxPosX * 100;
        return this.$hScroll.css({
          width: scrollWidth + "%"
        });
      };

      HorizontalScroll.prototype.setScrollableContainerWidth = function() {
        return this.scrollableContainerMaxPosX = this.pScrollableView.maxPosX();
      };

      HorizontalScroll.prototype.setMinPosX = function() {
        return this.minPosX = this.$hScroll.parent().get(0).getBoundingClientRect().left;
      };

      HorizontalScroll.prototype.setCurrentOffsetX = function(posX) {
        return this.currentOffsetX = posX - parseInt(this.$hScroll.css("left")) - this.minPosX;
      };

      HorizontalScroll.prototype.setMaxPosX = function() {
        return this.maxPosX = this.$hScroll.parent().width() - this.$hScroll.width();
      };

      HorizontalScroll.prototype.unbindEvents = function() {
        this.$hScroll.unbind("mousedown").unbind("mouseup");
        return $(window).unbind("mousemove.hscroll").unbind("mouseup.hscroll").unbind("resize.hscroll").unbind("hscroll.complete").unbind("resize.hscroll");
      };

      HorizontalScroll.prototype.bindEvents = function() {
        this.$hScroll.bind("mousedown", (function(_this) {
          return function(e) {
            _this.isMouseDown = true;
            return _this.setCurrentOffsetX(e.pageX);
          };
        })(this));
        $(window).bind("mousemove.hscroll", (function(_this) {
          return function(e) {
            var newXPos;
            if (!_this.isMouseDown) {
              return;
            }
            newXPos = e.pageX - _this.minPosX - _this.currentOffsetX;
            if (newXPos > _this.maxPosX) {
              newXPos = _this.maxPosX;
            } else if (newXPos < 0) {
              newXPos = 0;
            }
            _this.$hScroll.css({
              left: newXPos
            });
            return _this.moveScrollableContainer(newXPos);
          };
        })(this));
        $(window).bind("mouseup.hscroll", (function(_this) {
          return function() {
            return _this.isMouseDown = false;
          };
        })(this));
        $(window).bind("hscroll.complete", _.throttle(this.scrollToCurrent, 10));
        return $(window).bind("resize.hscroll", (function(_this) {
          return function() {
            _this.setScrollableContainerWidth();
            _this.setScrollWidth();
            _this.setMinPosX();
            _this.setMaxPosX();
            return _this.scrollToCurrent();
          };
        })(this));
      };

      HorizontalScroll.prototype.scrollToCurrent = function() {
        var left;
        left = this.maxPosX * Math.abs(parseInt(this.$scrollableContainer.css("left"))) / this.scrollableContainerMaxPosX;
        return this.$hScroll.css({
          left: left
        });
      };

      HorizontalScroll.prototype.moveScrollableContainer = function(posX) {
        var left;
        posX || (posX = parseInt(this.$hScroll.css("left")));
        left = -1 * this.scrollableContainerMaxPosX * posX / this.maxPosX;
        return this.$scrollableContainer.css({
          left: left
        });
      };

      HorizontalScroll.prototype.dispose = function() {
        var i, len, prop, ref;
        if (this.disposed) {
          return;
        }
        this.disposed = true;
        this.unbindEvents();
        ref = ['$hScroll', 'pScrollableView', 'currentOffsetX', 'maxPosX', 'minPosX', 'isMouseDown', 'scrollableContainerMaxPosX', '$scrollableContainer', 'scrollableWidth'];
        for (i = 0, len = ref.length; i < len; i++) {
          prop = ref[i];
          delete this[prop];
        }
        return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
      };

      return HorizontalScroll;

    })();
  })(window);

}).call(this);
