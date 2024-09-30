(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Forms.Channels.Views.ChannelForm = (function(superClass) {
    extend(ChannelForm, superClass);

    function ChannelForm() {
      return ChannelForm.__super__.constructor.apply(this, arguments);
    }

    ChannelForm.prototype.region = "#channel_form_region";

    ChannelForm.prototype.presenters_region = "#presenters";

    ChannelForm.prototype.template = HandlebarsTemplates['forms/channels/form'];

    ChannelForm.prototype.events = {
      "change [name*=channel]": 'checkForm',
      "change form:visible [name*=tag_list]": 'checkTags',
      "focusout form:visible .tagit input": 'checkTags',
      "click a.CoverImage-demo": 'showCoverModal',
      "click .channel_avatar_block a": 'showLogoModal',
      "click a.addGalleryImage": 'showGalleryModal',
      "click a.ReadyToInviteAdditional": 'showReadyToInviteAdditionalModal',
      "click .submitButton": 'saveChannel',
      "click .User-listImage.you": 'showEditUserAccountModal',
      'validation:remote:stop form': 'checkForm'
    };

    ChannelForm.prototype.initialize = function(options) {
      this.$region = $(this.region);
      this.$presenters_region = $(this.presenters_region);
      this.tilesByCid = {};
      this.presentersViews = {};
      this.form_changed = false;
      this.gallery = this.model.gallery;
      this.cover = this.model.cover;
      this.logo = this.model.logo;
      this.presenters = options.presenters;
      this.url = options.url;
      this.action = options.action;
      this.listenTo(this.gallery, 'crop:done', this.renderTile);
      this.listenTo(this.gallery, 'fetch:success', this.renderTile);
      this.listenTo(this.gallery, 'remove', this.removeViewForItem);
      this.listenTo(this.gallery, 'change:description', this.checkForm);
      this.listenTo(this.cover, 'crop:done', this.checkForm);
      this.listenTo(this.cover, 'crop:done', this.renderCover);
      this.listenTo(this.logo, 'crop:done', this.renderLogo);
      this.presentersViews = {};
      this.listenTo(this.presenters, "remove", this.removePresenter);
      this.listenTo(this.presenters, "change:_destroy", this.removePresenter);
      this.listenTo(this.presenters, "add", this.renderPresenter);
      this.listenTo(this.presenters, "add", this.checkForm);
      return this.render();
    };

    ChannelForm.prototype.render = function() {
      this.$el.html(this.template(this.getTemplateData()));
      this.$region.html(this.$el);
      this.$form = this.$region.find('#channel_form');
      this.$submitBtn = this.$('.submitButton');
      this.renderGallery();
      this.prepareForm();
      return this.renderPresenters();
    };

    ChannelForm.prototype.renderPresenters = function() {
      var i, item, len, ref, results;
      ref = this.presenters.models;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        results.push(this.renderPresenter(item));
      }
      return results;
    };

    ChannelForm.prototype.renderPresenter = function(item) {
      var view;
      view = this.presentersViews[item.cid];
      if (!view) {
        view = new Forms.Channels.Views.PresenterTileView({
          model: item
        });
        return this.presentersViews[item.cid] = view;
      }
    };

    ChannelForm.prototype.removePresenter = function(item) {
      var view;
      this.checkForm();
      view = this.presentersViews[item.get('id')];
      if (view) {
        view.dispose();
        return delete this.presentersViews[item.get('id')];
      }
    };

    ChannelForm.prototype.showReadyToInviteAdditionalModal = function() {
      return this.invite_presenters_modal || (this.invite_presenters_modal = new Forms.Channels.Views.PresentersModalView({
        collection: this.presenters
      }));
    };

    ChannelForm.prototype.renderCover = function() {
      this.$region.find('.CoverImage-demo').attr('style', "background-image: url('" + (this.cover.get('img_src')) + "')").attr('data-hover-text', 'Change Image');
      if (this.logo.isNew() && !this.logo.get('img_src')) {
        return this.$region.find('#channel_logo').attr('style', "background-image: url('" + (this.cover.get('img_src')) + "')");
      }
    };

    ChannelForm.prototype.renderLogo = function() {
      return this.$region.find('#channel_logo').attr('style', "background-image: url('" + (this.logo.get('img_src')) + "')");
    };

    ChannelForm.prototype.renderGallery = function() {
      var i, item, len, ref, results;
      ref = this.gallery.models;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        results.push(this.renderTile(item));
      }
      return results;
    };

    ChannelForm.prototype.renderTile = function(item) {
      var base, name;
      (base = this.tilesByCid)[name = item.cid] || (base[name] = new Forms.Channels.Views.GalleryItemTileView({
        model: item,
        region: this.$region.find('.Gallery-list')
      }));
      return this.tilesByCid[item.cid].render();
    };

    ChannelForm.prototype.showEditUserAccountModal = function() {
      this.edit_user_modal_view || (this.edit_user_modal_view = new Forms.Channels.Views.EditUserAccountModal);
      return this.edit_user_modal_view.render();
    };

    ChannelForm.prototype.checkTags = function(e) {
      if (this.$('.tagit input').is(':focus')) {
        return;
      }
      return this.$('[name*=tag_list]').valid();
    };

    ChannelForm.prototype.checkForm = function() {
      if (this.$form.validate().checkForm() && this.model.cover.readyToSave() && (Immerss.userInfoReady || this.presenters.withoutOwner().length > 0)) {
        return this.$submitBtn.removeAttr('disabled').removeClass('disabled');
      } else {
        return this.$submitBtn.attr('disabled', true).addClass('disabled');
      }
    };

    ChannelForm.prototype.saveChannel = function() {
      var form_data, type;
      if (!Immerss.userInfoReady && this.presenters.withoutOwner().length === 0) {
        $.showFlashMessage(I18n.t('wizard.step3.presenter_info_error'), {
          type: "error"
        });
        return false;
      }
      form_data = this.getFormData();
      type = this.action === 'new' ? "POST" : "PUT";
      return $.ajax({
        url: this.url,
        data: form_data,
        type: type,
        processData: false,
        contentType: false,
        dataType: 'json',
        beforeSend: (function(_this) {
          return function() {
            return _this.disableNextButton();
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

    ChannelForm.prototype.prepareForm = function() {
      var settings;
      settings = {
        rules: {
          'owner_type': {
            required: true
          },
          'channel[title]': {
            required: true,
            minlength: 5,
            maxlength: 72,
            remote: {
              url: Immerss.channelTitleRemoteValidationsPath,
              data: {
                id: function() {
                  return Forms.Channels.Cache.channel.id;
                }
              }
            }
          },
          'channel[description]': {
            minlength: 0,
            maxlength: 2000
          },
          'channel[category_id]': {
            required: true
          },
          'channel[tagline]': {
            minlength: 8,
            maxlength: 160
          },
          'channel[tag_list]': {
            required: true,
            maxlength: 160,
            tagsUniqueness: true,
            tagsLength: {
              minlength: 1,
              maxlength: 20
            },
            tagLength: {
              minlength: 2,
              maxlength: 100
            }
          }
        },
        messages: {
          "channel[title]": {
            remote: "This name is already in use."
          }
        },
        showErrors: (function(_this) {
          return function(errorMap, errorList) {
            _this.$form.validate().defaultShowErrors();
            return _this.checkForm();
          };
        })(this)
      };
      this.validateForm(settings);
      this.prepareInputs();
      this.setupTags();
      this.setupTagline();
      return this.checkForm();
    };

    ChannelForm.prototype.getFormData = function() {
      var formData;
      formData = new FormData(this.$form[0]);
      if (!this.model.isNew()) {
        formData.append("channel[id]", this.model.id);
      }
      _(this.cover.toFormData()).each(function(data) {
        return formData.append.apply(formData, data);
      });
      _(this.logo.toFormData()).each(function(data) {
        return formData.append.apply(formData, data);
      });
      _(this.gallery.toFormData()).each(function(data) {
        return formData.append.apply(formData, data);
      });
      _(this.presenters.toFormDataSet()).each(function(data) {
        return formData.append.apply(formData, data);
      });
      if (this.$('#list_upon_approval').is(":checked")) {
        formData.append('list_upon_approval', true);
      }
      return formData;
    };

    ChannelForm.prototype.removeViewForItem = function(item) {
      var view;
      view = this.tilesByCid[item.cid];
      if (view) {
        view.dispose();
        return delete this.tilesByCid[item.cid];
      }
    };

    ChannelForm.prototype.showCoverModal = function() {
      return this.cover_view || (this.cover_view = new Forms.Channels.Views.ChannelCoverModal({
        model: this.cover
      }));
    };

    ChannelForm.prototype.showLogoModal = function() {
      return this.logo_view || (this.logo_view = new Forms.Channels.Views.ChannelLogoModal({
        model: this.logo
      }));
    };

    ChannelForm.prototype.showGalleryModal = function() {
      return this.gallery_view || (this.gallery_view = new Forms.Channels.Views.ChannelGalleryModal({
        collection: this.gallery
      }));
    };

    ChannelForm.prototype.disableNextButton = function() {
      return this.$submitBtn.attr('disabled', true);
    };

    ChannelForm.prototype.getTemplateData = function() {
      var data;
      data = this.model.toJSON();
      data.page_title = I18n.t("channels." + this.action + ".title");
      if (this.action === 'new') {
        data.page_description = I18n.t("channels." + this.action + ".description");
      }
      return data;
    };

    return ChannelForm;

  })(Forms.FormView);

}).call(this);
