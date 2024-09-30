(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.Channel.Members = (function(superClass) {
    extend(Members, superClass);

    function Members() {
      this.render = bind(this.render, this);
      return Members.__super__.constructor.apply(this, arguments);
    }

    Members.prototype.el = ".channels-edit_creators";

    Members.prototype.search_template = HandlebarsTemplates['forms/shared/search_item'];

    Members.prototype.member_template = HandlebarsTemplates['forms/channels/member'];

    Members.prototype.events = {
      "click #invite_by_email button.invite": 'inviteByEmail',
      'click .remove_user_item': 'removeMember',
      'submit form#channe_members': 'save',
      "submit #searchByName": 'searchByName',
      "click #searchByName button.clear": 'clearSearch',
      "click #searchResults a.addFromSearch": 'addFromSearch'
    };

    Members.prototype.initialize = function(options) {
      this.collection = new Channel.Creators(options.members);
      this.$form = this.$el.find('#invite_by_email');
      this.$submitBtn = this.$form.find('button');
      this.listenTo(this.collection, 'add', this.renderMember);
      return this.render();
    };

    Members.prototype.render = function() {
      var settings;
      settings = {
        rules: {
          'emails': {
            emailImmerss: true,
            required: true
          }
        }
      };
      return this.validateForm(settings);
    };

    Members.prototype.removeMember = function(e) {
      var email, model;
      email = $(e.currentTarget).parents('.tile').data('email');
      model = this.collection.findWhere({
        email: email
      });
      if (model.id != null) {
        model.set({
          '_destroy': 1
        });
      } else {
        this.collection.remove(model);
      }
      $(e.currentTarget).parents('.tile').hide('fast');
      return $(e.currentTarget).parents('.tile').remove();
    };

    Members.prototype.renderMember = function(item) {
      console.log(['renderMember', item]);
      return $(this.member_template(item.toJSON())).insertAfter(this.$('.tile.add'));
    };

    Members.prototype.searchByName = function(e) {
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

    Members.prototype.clearSearch = function() {
      $('#searchByName')[0].reset();
      $('#searchByName .event-focus').removeClass('event-focus');
      return $('#searchResults').html('');
    };

    Members.prototype.showSearchResults = function(data) {
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

    Members.prototype.addFromSearch = function(e) {
      var $item;
      e.preventDefault();
      e.stopPropagation();
      $item = $(e.target).parents('.tile');
      if (this.collection.where({
        user_id: $item.attr('data-id')
      }).length > 0) {
        $.showFlashMessage('Creator already in list.', {
          type: 'info'
        });
      } else {
        this.collection.add({
          user_id: $item.attr('data-id'),
          full_name: $item.attr('data-name'),
          avatar_url: $item.attr('data-logo'),
          email: $item.attr('data-email'),
          type: 'search'
        });
        $.showFlashMessage('Creator added.', {
          type: 'success'
        });
      }
      return $item.hide('fast');
    };

    Members.prototype.inviteByEmail = function(e) {
      e.preventDefault();
      if ($('#invite_by_email').valid()) {
        if (this.collection.where({
          email: $('#invite_by_email input').val()
        }).length > 0) {
          return $.showFlashMessage('Creator is already in list.', {
            type: 'info'
          });
        } else {
          this.collection.add({
            email: $('#invite_by_email input').val(),
            type: 'email'
          });
          if (!this.$('#add_another_creator_email').is(':checked')) {
            this.$('#add_creator_modal').modal('hide');
          }
          $.showFlashMessage('Creator added.', {
            type: 'success'
          });
          $('#invite_email').val('');
          return $('#invite_email').val('').parents('.input-block').removeClass('event-focus').addClass('state-clear');
        }
      }
    };

    Members.prototype.save = function(e) {
      var formData;
      e.preventDefault();
      e.stopPropagation();
      if (this.collection.toFormDataSet().length > 0) {
        formData = new FormData();
        _(this.collection.toFormDataSet()).each(function(data) {
          return formData.append.apply(formData, data);
        });
      } else {
        formData = '';
      }
      return $.ajax({
        url: this.$('form#channe_members').attr('action'),
        data: formData,
        type: 'POST',
        processData: false,
        contentType: false,
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            return _this.$('form#channe_members .submitButton').addClass('disabled').attr('disabled', true).text('Saving');
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            return window.location = data.path;
          };
        })(this),
        error: function(data, error) {
          return $.showFlashMessage(data.responseText || data.statusText, {
            type: "error"
          });
        },
        complete: (function(_this) {
          return function() {
            return _this.checkForm();
          };
        })(this)
      });
    };

    return Members;

  })(Forms.FormView);

  Channel.Creator = (function(superClass) {
    extend(Creator, superClass);

    function Creator() {
      return Creator.__super__.constructor.apply(this, arguments);
    }

    Creator.prototype.defaults = {
      avatar_url: Immerss.defaultUserLogo
    };

    Creator.prototype.toParams = function() {
      return $.param(this.toJSON());
    };

    return Creator;

  })(Backbone.Model);

  Channel.Creators = (function(superClass) {
    extend(Creators, superClass);

    function Creators() {
      return Creators.__super__.constructor.apply(this, arguments);
    }

    Creators.prototype.model = function(attrs) {
      return new Channel.Creator(attrs);
    };

    Creators.prototype.changed = function() {
      return this.filter(function(model) {
        return model.isNew() || model.hasChanged();
      });
    };

    Creators.prototype.withoutOwner = function() {
      return this.filter(function(model) {
        return model.id !== Immerss.ownerId && !model.get('_destroy');
      });
    };

    Creators.prototype.toFormDataSet = function() {
      var data;
      data = [];
      _(this.changed()).each(function(item, i) {
        if (item.id) {
          data.push(["presenters[" + i + "][id]", item.id]);
        }
        if (item.get('user_id')) {
          data.push(["presenters[" + i + "][user_id]", item.get('user_id')]);
        }
        if (item.get('type')) {
          data.push(["presenters[" + i + "][type]", item.get('type')]);
        }
        if (item.get('email')) {
          data.push(["presenters[" + i + "][email]", item.get('email')]);
        }
        if (item.get('_destroy')) {
          return data.push(["presenters[" + i + "][_destroy]", item.get('_destroy')]);
        }
      });
      return data;
    };

    return Creators;

  })(Backbone.Collection);

}).call(this);
