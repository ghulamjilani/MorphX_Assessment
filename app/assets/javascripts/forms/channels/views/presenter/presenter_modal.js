(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.PresentersModalView = (function(superClass) {
    extend(PresentersModalView, superClass);

    function PresentersModalView() {
      this.render = bind(this.render, this);
      return PresentersModalView.__super__.constructor.apply(this, arguments);
    }

    PresentersModalView.prototype.el = "#ReadyToInviteAdditional";

    PresentersModalView.prototype.search_template = HandlebarsTemplates['forms/shared/search_item'];

    PresentersModalView.prototype.events = {
      "click #invite_by_email button.invite": 'inviteByEmail',
      "submit #searchByName": 'searchByName',
      "click #searchByName button.clear": 'clearSearch',
      "click #searchResults a.addFromSearch": 'addFromSearch'
    };

    PresentersModalView.prototype.initialize = function(options) {
      this.$form = this.$('#invite_by_email');
      this.$submitBtn = this.$form.find('button');
      return this.render();
    };

    PresentersModalView.prototype.render = function() {
      return this.validateForm({
        rules: {
          'emails': {
            emailImmerss: true,
            required: true
          }
        }
      });
    };

    PresentersModalView.prototype.showModal = function() {
      return this.$el.modal('show');
    };

    PresentersModalView.prototype.searchByName = function(e) {
      var query;
      e.preventDefault();
      e.stopPropagation();
      query = $('#searchByName #query').val();
      if (query.length > 0) {
        $('#searchByName button.search').attr('disabled', true);
        return $.ajax({
          url: Routes.search_presenter_become_presenter_steps_path(),
          data: "query=" + query,
          type: 'POST',
          dataType: 'json',
          success: (function(_this) {
            return function(data) {
              return _this.showSearchResults(data);
            };
          })(this),
          error: function(data, error) {
            return $.showFlashMessage(data.responseText || data.statusText, {
              type: "error"
            });
          },
          complete: function() {
            return $('#searchByName button.search').removeAttr('disabled');
          }
        });
      }
    };

    PresentersModalView.prototype.clearSearch = function() {
      $('#searchByName')[0].reset();
      $('#searchByName .event-focus').removeClass('event-focus');
      return $('#searchResults').html('');
    };

    PresentersModalView.prototype.showSearchResults = function(data) {
      $("#searchResults").html('');
      if (data.length === 0) {
        return $("#searchResults").append("<span>No users found</span>");
      } else {
        return $.each(data, (function(_this) {
          return function(i, user) {
            if (!_this.collection.where({
              user_id: user.id
            }).length) {
              return $("#searchResults").append(_this.search_template(user));
            }
          };
        })(this));
      }
    };

    PresentersModalView.prototype.addFromSearch = function(e) {
      var $item;
      e.preventDefault();
      e.stopPropagation();
      $item = $(e.target).parents('.tile');
      this.collection.add({
        user_id: $item.attr('data-id'),
        full_name: $item.attr('data-name'),
        logo: $item.attr('data-logo'),
        type: 'search'
      });
      return $item.hide('fast');
    };

    PresentersModalView.prototype.inviteByEmail = function(e) {
      e.preventDefault();
      if ($('#invite_by_email').valid()) {
        this.collection.add({
          email: $('#invite_by_email input').val(),
          type: 'email'
        });
        $('#invite_email').val('');
        return $('#invite_email').val('').parents('.input-block').removeClass('event-focus');
      }
    };

    return PresentersModalView;

  })(Forms.FormView);

}).call(this);
