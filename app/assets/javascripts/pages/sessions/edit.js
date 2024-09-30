(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function() {
    'use strict';
    var DropboxAsset, DropboxAssetView, DropboxAssets, DropboxAssetsInputsView, DropboxMaterial, DropboxMaterialView, DropboxMaterials, DropboxMaterialsView, MaterialModalView;
    DropboxAsset = (function(superClass) {
      extend(DropboxAsset, superClass);

      function DropboxAsset() {
        return DropboxAsset.__super__.constructor.apply(this, arguments);
      }

      return DropboxAsset;

    })(Backbone.Model);
    DropboxAssets = (function(superClass) {
      extend(DropboxAssets, superClass);

      function DropboxAssets() {
        return DropboxAssets.__super__.constructor.apply(this, arguments);
      }

      DropboxAssets.prototype.model = DropboxAsset;

      DropboxAssets.prototype.url = "/dropbox";

      DropboxAssets.prototype.comparator = function(model) {
        return !model.get('is_dir');
      };

      return DropboxAssets;

    })(Backbone.Collection);
    DropboxMaterial = (function(superClass) {
      extend(DropboxMaterial, superClass);

      function DropboxMaterial() {
        return DropboxMaterial.__super__.constructor.apply(this, arguments);
      }

      DropboxMaterial.prototype.defaults = {
        _destroy: false
      };

      DropboxMaterial.prototype.serializeAttributes = function() {
        var data;
        data = this.toJSON();
        data._destroy = this.get("_destroy").toString();
        return data;
      };

      DropboxMaterial.prototype.remove = function() {
        if (this.isNew()) {
          return this.collection.remove(this);
        } else {
          return this.set({
            _destroy: true
          });
        }
      };

      DropboxMaterial.prototype.getPreviewUrl = function() {};

      return DropboxMaterial;

    })(Backbone.Model);
    DropboxMaterials = (function(superClass) {
      extend(DropboxMaterials, superClass);

      function DropboxMaterials() {
        return DropboxMaterials.__super__.constructor.apply(this, arguments);
      }

      DropboxMaterials.prototype.model = DropboxMaterial;

      DropboxMaterials.prototype.addOrChangeMaterial = function(attrs, options) {
        var alreadyPresentMaterial, isAdded;
        if (options == null) {
          options = {};
        }
        isAdded = options.isAdded;
        delete options.isAdded;
        alreadyPresentMaterial = this.findWhere(_(attrs).pick('path'));
        if (isAdded) {
          if (alreadyPresentMaterial) {
            return alreadyPresentMaterial.set({
              _destroy: false
            });
          } else {
            return this.add(attrs, options);
          }
        } else {
          return alreadyPresentMaterial.remove();
        }
      };

      DropboxMaterials.prototype.serializeAttributes = function() {
        return this.models.map(function(model) {
          return model.serializeAttributes();
        });
      };

      return DropboxMaterials;

    })(Backbone.Collection);
    window.DropboxAssetsView = (function(superClass) {
      extend(DropboxAssetsView, superClass);

      function DropboxAssetsView() {
        return DropboxAssetsView.__super__.constructor.apply(this, arguments);
      }

      DropboxAssetsView.prototype.region = "#dropbox-materials";

      DropboxAssetsView.prototype.listSelector = "tbody";

      DropboxAssetsView.prototype.events = {
        "show.bs.modal #dropbox-materials-modal": "loadAssets",
        "change .select-all": 'selectAllAssets'
      };

      DropboxAssetsView.prototype.initialize = function() {
        this.collection = new DropboxAssets();
        this.dropboxMaterials = new DropboxMaterials(window.Immerss.dropboxMaterials);
        this.isDropboxAuthenticated = window.Immerss.isDropboxAuthenticated;
        this.dropboxAuthUrl = window.Immerss.dropboxAuthUrl;
        this.template = HandlebarsTemplates['application/dropbox_assets'];
        this.$region = $(this.region);
        this.viewsByCid = {};
        this.subviewsByName = {};
        this.listenTo(this.collection, "request", this.showLoadIndicator);
        this.listenTo(this.collection, "sync", this.hideLoadIndicator);
        this.listenTo(this.collection, "sync", this.renderAllItems);
        this.listenTo(this.collection, "error", this.requestErrorHandler);
        this.listenTo(this.collection, "remove", this.removeItem);
        this.subviewsByName.materialsView = new DropboxMaterialsView({
          collection: this.dropboxMaterials,
          parentView: this
        });
        this.subviewsByName.inputsView = new DropboxAssetsInputsView({
          collection: this.dropboxMaterials,
          parentView: this
        });
        return this.render();
      };

      DropboxAssetsView.prototype.getTemplateData = function() {
        var data;
        data = this.collection.toJSON();
        data.isDropboxAuthenticated = this.isDropboxAuthenticated;
        data.dropboxAuthUrl = this.dropboxAuthUrl;
        return data;
      };

      DropboxAssetsView.prototype.renderAllItems = function() {
        var i, item, len, ref, results;
        ref = this.collection.models;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          results.push(this.renderItem(item));
        }
        return results;
      };

      DropboxAssetsView.prototype.renderItem = function(item) {
        var view;
        view = this.viewsByCid[item.cid];
        if (!view) {
          view = new DropboxAssetView({
            model: item,
            dropboxMaterials: this.dropboxMaterials
          });
          this.viewsByCid[item.cid] = view;
        }
        this.$listSelector.append(view.$el);
        return view.render();
      };

      DropboxAssetsView.prototype.removeItem = function(model) {
        return delete this.viewsByCid[model.cid];
      };

      DropboxAssetsView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        this.$listSelector = this.$(this.listSelector);
        this.renderAllItems();
        this.renderSubviews();
        return this.$region.html(this.$el);
      };

      DropboxAssetsView.prototype.loadAssets = function() {
        if (this.isDropboxAuthenticated) {
          return this.collection.fetch();
        }
      };

      DropboxAssetsView.prototype.showLoadIndicator = function() {
        this.$('table').hide();
        this.$('.select-all').attr('checked', null);
        return this.$('.loading').show();
      };

      DropboxAssetsView.prototype.hideLoadIndicator = function() {
        this.$('table').show();
        return this.$('.loading').hide();
      };

      DropboxAssetsView.prototype.requestErrorHandler = function(collection, xhr, options) {
        if (xhr.status === 401) {
          this.isDropboxAuthenticated = false;
          this.$('table').hide();
          this.$('.loading').hide();
          return this.$('.not-authenticated').show();
        } else {
          return $.showFlashMessage("Unexpected response from server (" + xhr.status + "). Please refresh the page and try again.", {
            type: 'error'
          });
        }
      };

      DropboxAssetsView.prototype.renderSubviews = function() {
        var name, ref, results, view;
        ref = this.subviewsByName;
        results = [];
        for (name in ref) {
          view = ref[name];
          results.push(view.render());
        }
        return results;
      };

      DropboxAssetsView.prototype.selectAllAssets = function(event) {
        if (this.$('.select-all').is(":checked")) {
          return this.$('input.select-image').not(":checked").click();
        } else {
          return this.$('input.select-image').filter(":checked").click();
        }
      };

      return DropboxAssetsView;

    })(Backbone.View);
    DropboxAssetView = (function(superClass) {
      extend(DropboxAssetView, superClass);

      function DropboxAssetView() {
        return DropboxAssetView.__super__.constructor.apply(this, arguments);
      }

      DropboxAssetView.prototype.className = 'asset-item';

      DropboxAssetView.prototype.tagName = 'tr';

      DropboxAssetView.prototype.events = {
        'click td.select-image': 'selectItem',
        'click td:not(.select-image)': 'navigate'
      };

      DropboxAssetView.prototype.initialize = function(options) {
        this.dropboxMaterials = options.dropboxMaterials;
        this.disposed = false;
        this.template = HandlebarsTemplates['application/dropbox_asset'];
        return this.listenTo(this.model, 'remove', this.dispose);
      };

      DropboxAssetView.prototype.getTemplateData = function() {
        var data;
        data = this.model.toJSON();
        if (data.modified) {
          data.modified = new L2date(data.modified).toCustomFormat('YYYY-MM-DDTHH:mm:ssZ');
        }
        data.isAlreadyPresentMaterial = this.dropboxMaterials.findWhere({
          path: this.model.get('path'),
          _destroy: false
        }) !== void 0;
        return data;
      };

      DropboxAssetView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        if (this.model.get('modified')) {
          return this.$('.timeago').timeago();
        }
      };

      DropboxAssetView.prototype.navigate = function() {
        if (this.model.get('is_dir')) {
          return this.model.collection.fetch({
            data: {
              root_dir: this.model.get('path')
            }
          });
        }
      };

      DropboxAssetView.prototype.selectItem = function(event) {
        var input;
        input = this.$('input.select-image');
        if (event.target.nodeName.toLowerCase() !== 'input') {
          if (input.is(':checked')) {
            input.attr('checked', null);
          } else {
            input.attr('checked', 'checked');
          }
        }
        return this.dropboxMaterials.addOrChangeMaterial(this.model.pick('path', 'mime_type'), {
          isAdded: input.is(':checked')
        });
      };

      DropboxAssetView.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.$el.remove();
        this.stopListening(this.model);
        properties = ['el', '$el', 'model', 'template', 'dropboxMaterials'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        this.disposed = true;
        return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
      };

      return DropboxAssetView;

    })(Backbone.View);
    DropboxAssetsInputsView = (function(superClass) {
      extend(DropboxAssetsInputsView, superClass);

      function DropboxAssetsInputsView() {
        return DropboxAssetsInputsView.__super__.constructor.apply(this, arguments);
      }

      DropboxAssetsInputsView.prototype.region = 'form.session';

      DropboxAssetsInputsView.prototype.initialize = function() {
        this.$region = $(this.region);
        this.template = HandlebarsTemplates['application/dropbox_assets_inputs'];
        return this.listenTo(this.collection, "add change remove", this.render);
      };

      DropboxAssetsInputsView.prototype.getTemplateData = function() {
        return this.collection.serializeAttributes();
      };

      DropboxAssetsInputsView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        return this.$region.prepend(this.$el);
      };

      return DropboxAssetsInputsView;

    })(Backbone.View);
    DropboxMaterialsView = (function(superClass) {
      extend(DropboxMaterialsView, superClass);

      function DropboxMaterialsView() {
        return DropboxMaterialsView.__super__.constructor.apply(this, arguments);
      }

      DropboxMaterialsView.prototype.region = ".materials-preview";

      DropboxMaterialsView.prototype.initialize = function(options) {
        this.parentView = options.parentView;
        this.viewsByCid = {};
        this.listenTo(this.collection, "remove", this.removeItem);
        return this.listenTo(this.collection, "add change", this.renderItem);
      };

      DropboxMaterialsView.prototype.renderAllItems = function() {
        var i, item, len, ref, results;
        ref = this.collection.models;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          results.push(this.renderItem(item));
        }
        return results;
      };

      DropboxMaterialsView.prototype.renderItem = function(item) {
        var view;
        view = this.viewsByCid[item.cid];
        if (!view) {
          view = new DropboxMaterialView({
            model: item
          });
          this.viewsByCid[item.cid] = view;
        }
        this.$listSelector.append(view.$el);
        return view.render();
      };

      DropboxMaterialsView.prototype.removeItem = function(model) {
        return delete this.viewsByCid[model.cid];
      };

      DropboxMaterialsView.prototype.render = function() {
        this.$region = this.parentView.$(this.region);
        this.$listSelector = this.$el;
        this.renderAllItems();
        return this.$region.html(this.$el);
      };

      return DropboxMaterialsView;

    })(Backbone.View);
    DropboxMaterialView = (function(superClass) {
      extend(DropboxMaterialView, superClass);

      function DropboxMaterialView() {
        return DropboxMaterialView.__super__.constructor.apply(this, arguments);
      }

      DropboxMaterialView.prototype.className = 'material-item';

      DropboxMaterialView.prototype.events = {
        'click .remove': 'removeMaterial',
        'click .preview': 'openPreviewModal'
      };

      DropboxMaterialView.prototype.initialize = function() {
        this.disposed = false;
        this.template = HandlebarsTemplates['application/dropbox_material'];
        return this.listenTo(this.model, 'remove', this.dispose);
      };

      DropboxMaterialView.prototype.getTemplateData = function() {
        var data;
        data = this.model.toJSON();
        data.cid = this.model.cid;
        return data;
      };

      DropboxMaterialView.prototype.render = function() {
        return this.$el.html(this.template(this.getTemplateData()));
      };

      DropboxMaterialView.prototype.openPreviewModal = function(event) {
        event.preventDefault();
        this.previewModalView = new MaterialModalView({
          model: this.model
        });
        return this.previewModalView.render();
      };

      DropboxMaterialView.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.$el.remove();
        this.stopListening(this.model);
        if (this.previewModalView) {
          this.previewModalView.dispose();
        }
        properties = ['el', '$el', 'model', 'template', 'previewModalView'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        this.disposed = true;
        return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
      };

      DropboxMaterialView.prototype.removeMaterial = function(event) {
        event.preventDefault();
        return this.model.remove();
      };

      return DropboxMaterialView;

    })(Backbone.View);
    return MaterialModalView = (function(superClass) {
      extend(MaterialModalView, superClass);

      function MaterialModalView() {
        this.mediaLoadCallback = bind(this.mediaLoadCallback, this);
        this.mediaErrorFallback = bind(this.mediaErrorFallback, this);
        return MaterialModalView.__super__.constructor.apply(this, arguments);
      }

      MaterialModalView.prototype.autoRender = true;

      MaterialModalView.prototype.region = 'alerts';

      MaterialModalView.prototype.initialize = function() {
        this.disposed = false;
        return this.template = HandlebarsTemplates['application/dropbox_material_modal'];
      };

      MaterialModalView.prototype.getTemplateData = function() {
        var data;
        data = this.model.toJSON();
        data.cid = this.model.cid;
        data.isImage = this.model.get('mime_type').indexOf('image') === 0;
        data.isAudio = this.model.get('mime_type').indexOf('audio') === 0 && this.canPlayType();
        data.isVideo = this.model.get('mime_type').indexOf('video') === 0 && this.canPlayType();
        data.isNotSupported = !(data.isImage || data.isAudio || data.isVideo);
        return data;
      };

      MaterialModalView.prototype.render = function() {
        this.$el.html(this.template(this.getTemplateData()));
        this.initPreviewTagCallbacks();
        $('body').append(this.$el);
        return this.initModal();
      };

      MaterialModalView.prototype.initModal = function() {
        this.modal = this.$(".modal");
        this.modal.on("hide.bs.modal", _.bind(this.dispose, this));
        return this.modal.modal();
      };

      MaterialModalView.prototype.initPreviewTagCallbacks = function() {
        var tag;
        tag = this.$('.preview-tag').get(0);
        if (tag) {
          if (tag.nodeName.toLowerCase() === 'img') {
            tag.onerror = this.mediaErrorFallback;
            return tag.onload = this.mediaLoadCallback;
          } else {
            tag.querySelector('source').onerror = this.mediaErrorFallback;
            return tag.oncanplay = this.mediaLoadCallback;
          }
        }
      };

      MaterialModalView.prototype.mediaErrorFallback = function() {
        if (this.disposed) {
          return;
        }
        this.$('.loading').hide();
        return this.$('.fallback').show();
      };

      MaterialModalView.prototype.removePreviewtags = function() {
        var tag;
        tag = this.$('.preview-tag').get(0);
        if (tag) {
          if (tag.nodeName.toLowerCase() === 'img') {
            tag.src = '';
            return tag.removeAttribute('src');
          } else {
            tag.pause();
            tag.querySelector('source').src = 'about:blank';
            return tag.load();
          }
        }
      };

      MaterialModalView.prototype.mediaLoadCallback = function() {
        if (this.disposed) {
          return;
        }
        return this.$('.loading').hide();
      };

      MaterialModalView.prototype.dispose = function() {
        var i, len, prop, properties;
        if (this.disposed) {
          return;
        }
        this.stopListening(this.model);
        this.modal.data("bs.modal").removeBackdrop();
        $('body').removeClass('modal-open');
        this.removePreviewtags();
        this.$el.remove();
        properties = ['el', '$el', 'model', 'template', 'modal'];
        for (i = 0, len = properties.length; i < len; i++) {
          prop = properties[i];
          delete this[prop];
        }
        return this.disposed = true;
      };

      MaterialModalView.prototype.canPlayType = function() {
        var format;
        format = _(_(this.model.get("path").split('/')).last().split(".")).last();
        return _($.jPlayer.prototype.format).keys().indexOf(format) !== -1;
      };

      return MaterialModalView;

    })(Backbone.View);
  })();

}).call(this);
