(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  (function(window) {
    var Company;
    Company = (function(superClass) {
      extend(Company, superClass);

      function Company() {
        return Company.__super__.constructor.apply(this, arguments);
      }

      Company.prototype.el = '.companies-Page';

      Company.prototype.initialize = function(options) {
        return this;
      };

      Company.prototype.render = function() {
        this.$('.channels-company-list .LG-month').owlCarousel({
          nav: true,
          navText: '',
          loop: true,
          autoplay: false,
          items: 1,
          margin: 0,
          stagePadding: 0,
          smartSpeed: 450,
          responsive: {
            992: {
              items: 4
            }
          }
        });
        this.$('.channels-company-list .LG-timeList').jScrollPane({
          verticalDragMinHeight: 50,
          verticalDragMaxHeight: 280,
          horizontalDragMinWidth: 20,
          horizontalDragMaxWidth: 280
        });
        this.$('.LG-sItem').hover((function() {
          var content, pos, posTop, positionPopover, posleft;
          pos = $(this).offset();
          content = $(this).children('.LG-I').clone();
          posTop = pos.top.toFixed(0) - 40;
          posleft = pos.left.toFixed(0) - 320;
          positionPopover = 'leftPOs';
          if (posleft <= 10) {
            posleft = posleft + 347;
            positionPopover = 'rightPOs';
          }
          $('<div class="LG-I-popover ' + positionPopover + '" style=" top:' + posTop + 'px;left:' + posleft + 'px "></div>').appendTo('body').html(content);
        }), (function(_this) {
          return function() {
            _this.$('.LG-I-popover').remove();
          };
        })(this));
      };

      return Company;

    })(Backbone.View);
    return $(function() {
      if ($('.companies-Page').length > 0) {
        Cache.company_view = new Company;
        return Cache.company_view.render();
      }
    });
  })(window);

}).call(this);
