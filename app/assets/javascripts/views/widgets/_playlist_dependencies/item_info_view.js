+function (window) {
    "use strict";
    var HeaderView = Backbone.View.extend({
        tagName: 'div',
        region: '.i__embed_h',
        id: 'playerHeader',
        className: 'clearfix',
        initialize: function () {
            this.template = Handlebars.compile($('#headerTmpl').text());
            this.$region = $(this.region);
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            return data;
        },
        render: function () {
            var data = this.getTemplateData();
            this.$region.html(this.$el);
            this.$el.html(this.template(data));
            return this;
        },
        renderWithModel: function (model, options) {
            this.model = model;
            this.render();
        },
    });
    var FooterView = Backbone.View.extend({
        tagName: 'div',
        region: '.i__embed_f',
        id: 'playerFooter',
        events: {
            'click .shareIcon': 'showShareView',
            'click .showLoginForm': 'toggleLoginView'
        },
        initialize: function () {
            this.template = Handlebars.compile($('#footerTmpl').text());
            this.$region = $(this.region);
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            if(Immerss && Immerss.user && _.isNumber(Immerss.user.id)){
                data.userId = Immerss.user.id;
            }
            return data;
        },
        render: function () {
            var data = this.getTemplateData();
            this.$region.html(this.$el);
            this.$el.html(this.template(data));
            return this;
        },
        renderWithModel: function (model, options) {
            this.model = model;
            this.render();
            this.delegateEvents();
        },
        showShareView: function (e) {
            e.preventDefault();
            this.trigger('showShareView');
        },
        toggleLoginView: function (e) {
            e.preventDefault();
            this.trigger('toggleLoginView');
        }
    });
    var DescriptionView = Backbone.View.extend({
        className: 'description',
        tagName: 'div',
        region: '.description-container',
        id: 'playerDescription',
        initialize: function () {
            this.template = Handlebars.compile($('#descriptionTmpl').text());
            this.$region = $(this.region);
        },
        getTemplateData: function () {
            var data = {
                description: this.model.get('description'),
                custom_description: this.model.get('custom_description')
            };
            return data;
        },
        render: function () {
            var data = this.getTemplateData();
            this.$region.html(this.$el);
            this.$el.html(this.template(data));
            return this;
        },
        renderWithModel: function (model, options) {
            this.model = model;
            this.render();
        },
    });
    var ShareView = Backbone.View.extend({
        tagName: 'div',
        region: '.share-container',
        events: {
            'click .close_modal': 'toggle',
            'click .modal-cover': 'toggle',
            'click .fb-share': 'fbShare',
            'click .twitter-share': 'twitterShare',
            'click .linkedin-share': 'linkedinShare',
            'click .pinterest-share': 'pinterestShare',
            'click .tumblr-share': 'tumblrShare',
            'click .reddit-share': 'redditShare',
            'click .g-share': 'googleShare',
            'click .copy_to_clipboard': 'copyToClipboard',
        },
        initialize: function () {
            this.template = Handlebars.compile($('#shareTmpl').text());
            this.$region = $(this.region);
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            return data;
        },
        render: function () {
            var data = this.getTemplateData();
            this.$region.html(this.$el);
            this.$el.html(this.template(data));
            return this;
        },
        renderWithModel: function (model, options) {
            this.model = model;
            this.render();
            this.delegateEvents();
        },
        toggle: function (options) {
            this.$region.toggleClass('modalShow');
            return false;
        },
        copyToClipboard: function (e) {
            e.preventDefault();
            var btn, err, input, msg, successful;
            btn = this.$('a.copy_to_clipboard span');
            btn.html('copied');
            setTimeout(function () {
                return btn.html('copy');
            }, 1500);
            try {
                input = this.$('.link_Share_block input[type="text"]');
                input.select();
                successful = document.execCommand('copy');
                msg = successful ? 'successful' : 'unsuccessful';
                console.log('Сopy text command was ' + msg);

            } catch (_error) {
                err = _error;
                console.log('Oops, unable to copy' + err);
            }
        },
        fbShare: function (e) {
            e.preventDefault();
            var width = 550,
                height = 450,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.fb-share').attr('href'), 'fbShareWindow', opts);
            return false;
        },
        twitterShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.twitter-share').attr('href'), 'twitter', opts);
            return false;
        },
        linkedinShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.linkedin-share').attr('href'), 'twitter', opts);
            return false;
        },
        pinterestShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.pinterest-share').attr('href'), 'twitter', opts);
            return false;
        },
        tumblrShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.tumblr-share').attr('href'), 'twitter', opts);
            return false;
        },
        redditShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.reddit-share').attr('href'), 'twitter', opts);
            return false;
        },
        googleShare: function (e) {
            e.preventDefault();
            var width = 575,
                height = 400,
                left = ($(window).width() - width) / 2,
                top = ($(window).height() - height) / 2,
                opts = 'status=1' +
                    ',width=' + width +
                    ',height=' + height +
                    ',top=' + top +
                    ',left=' + left +
                    ',toolbar=0,location=0,menubar=0,directories=0,scrollbars=0';
            window.open(this.$('.g-share').attr('href'), 'twitter', opts);
            return false;
        },
    });
    var LoginView = Backbone.View.extend({
        tagName: 'div',
        el: '.modals_wrapp',
        events: {
            'click .closeModal': 'toggle',
            'click .showSignUpForm': 'showSignUpForm',
            'click .showLoginForm': 'showLoginForm',
            'focus form input': 'clearError',
            'submit #modal_sign_in_form': 'handleLogin',
            'submit #modal_sign_up_form': 'handleRegister',
        },
        initialize: function () {
            this.render();
        },
        render: function () {
          this.$loginEl = this.$el.find('#modal_sign_in');
          this.$registerEl = this.$el.find('#modal_sign_up');
          this.$el.find('input[name*="birthdate"]').datepicker({
            showOn: 'focus',
            dateFormat: 'dd MM yy',
            minDate: '-90Y',
            maxDate: '-13Y',
            yearRange: '-90:-13',
            changeYear: true,
            changeMonth: true,
          });
          return this;
        },
        renderWithModel: function (model, options) {
            this.model = model;
            this.render();
            this.delegateEvents();
        },
        toggle: function (options) {
            this.$el.toggleClass('hidden');
            return false;
        },
        showSignUpForm: function (e) {
            this.$loginEl.addClass('hidden');
            this.$registerEl.removeClass('hidden');
            return false;
        },
        showLoginForm: function (e) {
            this.$registerEl.addClass('hidden');
            this.$loginEl.removeClass('hidden');
            return false;
        },
        clearError: function () {
          this.$el.find('.error_container').text('');
        },
        handleLogin: function (e) {
            e.preventDefault();

            var form = this.$loginEl.find('form');
            var url = form.attr('action');
            var _view = this;
            $.ajax({
                type: 'POST',
                url: url,
                data: form.serialize(),
                before: function () {
                  _view.clearError();
                },
                success: function (data) {
                    Immerss.user = data.user;
                    _view.trigger('signedIn');
                    _view.$el.hide();
                },
                error: function (data) {
                    _view.$loginEl.find('.error_container').text(data.responseText);
                }
            });
        },
        handleRegister: function (e) {
            e.preventDefault();

            var form = this.$registerEl.find('form');
            var url = form.attr('action');
            var _view = this;
            $.ajax({
              type: 'POST',
              url: url,
              data: form.serialize(),
              before: function () {
                _view.clearError();
              },
              success: function (data) {
                Immerss.user = data.user;
                _view.trigger('signedIn');
                _view.$el.hide();
              },
              error: function (data) {
                _view.$registerEl.find('.error_container').text(data.responseText);
              }
            });
        }
    });
    window.LoginView = LoginView;

    var ItemInfoView = function (playlist, loginView) {
        this.playlist = playlist;
        this.library = playlist.library;
        this.headerView = new HeaderView();
        this.footerView = new FooterView();
        this.descriptionView = new DescriptionView();
        this.shareView = new ShareView();
        this.bindEvents();
    };
    ItemInfoView.prototype.bindEvents = function () {
        this.library.on('trackChanged remove', function (item) {
            item = this.library.get(item.uniqId());
            if (item) {
                this.showHeaderAndFooter(item);
            } else {
                this.headerView.remove();
                this.footerView.remove();
                this.descriptionView.remove();
                this.shareView.remove();
            }
        }, this);
        this.library.on('change:participants_count change:views_count change:rating', function (item) {
            if(this.footerView.model == item){
                this.footerView.renderWithModel(this.footerView.model);
            }
        }, this);
        this.footerView.on('showShareView', function () {
            this.shareView.toggle();
        }, this);
        this.footerView.on('toggleLoginView', function () {
            window.loginView.toggle();
        }, this);
        window.loginView.on('signedIn', function () {
            this.library.fetch({reset: true});
        }, this);
    };
    ItemInfoView.prototype.showHeaderAndFooter = function (item, options) {
        this.headerView.renderWithModel(item, options);
        this.footerView.renderWithModel(item, options);
        this.descriptionView.renderWithModel(item, options);
        this.shareView.renderWithModel(item, options);
    };

    window.ItemInfoView = ItemInfoView;
}(window);
