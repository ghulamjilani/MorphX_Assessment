(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  (function(window) {
    var Alerts, template;
    template = "<div class=\"modal fade alerts-modal\" aria-hidden=\"true\" aria-labelledby=\"overlappedSession\" role=\"dialog\" tabindex=\"-1\">\n    <div class=\"modal-dialog modal-dialog-{{type}}\">\n        <div class=\"modal-content\">\n          <div class=\"modal-header\">\n            <button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-hidden=\"true\">&times;</button>\n          </div>\n          <div class=\"modal-body\">\n            <p>{{{message}}}</p>\n          </div>\n          <div class=\"modal-footer\">\n            {{#with buttons.ok}}\n                <a href=\"javascript: void(0);\" class=\"btn btn-primary b-action_ok\">\n                    {{this}}\n                </a>\n            {{/with}}\n            {{#with buttons.cancel}}\n                <a href=\"javascript: void(0);\" class=\"btn b-action_cancel\">\n                    {{this}}\n                </a>\n            {{/with}}\n          </div>\n        </div>\n    </div>\n</div>";
    Alerts = (function(superClass) {
      extend(Alerts, superClass);

      function Alerts() {
        return Alerts.__super__.constructor.apply(this, arguments);
      }

      Alerts.prototype.autoRender = true;

      Alerts.prototype.region = "body";

      Alerts.prototype.events = {
        "click .b-action_ok": "defaultOkBtnAction",
        "click .b-action_cancel": "defaultCancelBtnAction",
        "keyup": "toggleFocus"
      };

      Alerts.prototype.initialize = function(options) {
        this.template = template;
        this.$region = $(this.region);
        _.defaults(options, {
          btns: {
            ok: "Ok"
          },
          type: 'notice',
          actions: {
            ok: null,
            cancel: null
          },
          focusBtn: "cancel"
        });
        this.options = options;
        if (this.options.shouldCloseOnNavigate) {
          this.on("click", ".alerts-content a", function() {
            _.defer((function(_this) {
              return function() {
                return _this.dispose();
              };
            })(this));
            return true;
          });
        }
        return this.render();
      };

      Alerts.prototype.getTemplateFunction = function() {
        return Handlebars.compile(this.template);
      };

      Alerts.prototype.getTemplateData = function() {
        var data;
        data = {};
        data.buttons = this.options.btns;
        _.extend(data, this.getMessageAndType());
        return data;
      };

      Alerts.prototype.initModal = function() {
        var modalOptions;
        this.modal = this.$(".modal");
        this.modal.on("hide.bs.modal", _.bind(this.dispose, this));
        modalOptions = {};
        if (this.options.block) {
          modalOptions.backdrop = 'static';
          modalOptions.keyboard = false;
        }
        this.modal.modal(modalOptions);
        this.modal.css("z-index", "10500");
        this.modal.data("bs.modal").$backdrop.css("z-index", "10499");
        return this.setFocus(this.options.focusBtn);
      };

      Alerts.prototype.render = function() {
        var html, templateFunc;
        templateFunc = this.getTemplateFunction();
        html = templateFunc(this.getTemplateData());
        this.$el.html(html);
        this.$region.append(this.$el);
        return this.initModal();
      };

      Alerts.prototype.getMessageAndType = function() {
        var message, messageOrXhr, res, type;
        messageOrXhr = this.options.message;
        type = this.options.type;
        if (_.isObject(messageOrXhr)) {
          switch (messageOrXhr.status) {
            case 500:
              return {
                message: "500 Internal Server Error.",
                type: "error"
              };
            case 401:
              return {
                message: "You are not authorized to access this link.",
                type: "error"
              };
            default:
              res = messageOrXhr.responseJSON;
              message = res ? res.message || res.error : "Unexpected response code (" + messageOrXhr.status + "). Try to refresh the page or contact our support.";
              return {
                message: message,
                type: "error"
              };
          }
        } else {
          return {
            message: messageOrXhr,
            type: type
          };
        }
      };

      Alerts.prototype.defaultBtnAction = function(event, callback) {
        event.preventDefault();
        if (_.isFunction(callback)) {
          callback();
        }
        return this.dispose();
      };

      Alerts.prototype.defaultCancelBtnAction = function(event) {
        return this.defaultBtnAction(event, this.options.actions.cancel);
      };

      Alerts.prototype.defaultOkBtnAction = function(event) {
        return this.defaultBtnAction(event, this.options.actions.ok);
      };

      Alerts.prototype.setAfterDisposeCallback = function(callback) {
        return this.afterDisposeCallback = function() {
          if (_.isFunction(callback)) {
            return _.defer(callback);
          }
        };
      };

      Alerts.prototype.afterDisposeCallback = function() {};

      Alerts.prototype.setFocus = function(selectedBtn) {
        var btns;
        btns = _.keys(this.options.btns);
        this.focusedOn = _(btns).find(function(btn) {
          return btn === selectedBtn;
        });
        this.focusedOn || (this.focusedOn = btns[0]);
        switch (this.focusedOn) {
          case "ok":
            return this.$(".b-action_ok").focus();
          case "cancel":
            return this.$(".b-action_cancel").focus();
        }
      };

      Alerts.prototype.toggleFocus = function(event) {
        var btns, currentIndex, nextIndex;
        btns = _.keys(this.options.btns);
        if (_([9, 37, 39]).indexOf(event.keyCode) !== -1) {
          currentIndex = _(btns).indexOf(this.focusedOn);
          switch (event.keyCode) {
            case 39:
            case 9:
              if (currentIndex + 1 > btns.length - 1) {
                nextIndex = 0;
              } else {
                nextIndex = currentIndex + 1;
              }
              break;
            default:
              if (currentIndex - 1 < 0) {
                nextIndex = btns.length - 1;
              } else {
                nextIndex = currentIndex - 1;
              }
          }
          return this.setFocus(btns[nextIndex]);
        }
      };

      Alerts.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.afterDisposeCallback();
        this.modal.data("bs.modal").removeBackdrop();
        $('body').removeClass('modal-open');
        this.$el.remove();
        properties = ['el', '$el', 'template', 'modal', '$region', 'options'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      return Alerts;

    })(Backbone.View);
    return window.Alerts = Alerts;
  })(window);

}).call(this);
