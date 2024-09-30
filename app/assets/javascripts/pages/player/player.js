//= require_self
//= require pages/player/recording
//= require pages/player/replay
//= require pages/player/session

this.Player = {
    Collections: {},
    Models: {},
    Views: {}
};

_.extend(Player, Backbone.Events);

Player.Models.Session = Backbone.Model.extend({
    model_name: 'session',

    initialize: function () {
        this.on('change:finished', this.checkRateAbility);
        return this.on('change:cancelled change:stopped', this.deactivate);
    },

    checkRateAbility: function () {
        if (this.get('owner')) {
            this.set({
                can_rate: !this.get('immerss_experience_rate_saved')
            });
        } else {
            this.set({
                can_rate: this.get('can_rate') || !Immerss.currentUserId && (this.canAccessLivestream() || $.cookie("livestream_" + this.id))
            });
        }
        return this.get('can_rate');
    },

    deactivate: function () {
        return this.set({
            finished: true,
            upcoming: false,
            running: false,
            started: false
        });
    },

    ratedAndSaved: function () {
        if (this.get('owner')) {
            return this.get('immerss_experience_rate_saved');
        } else {
            return this.get('quality_of_content_rate_saved') && this.get('immerss_experience_rate_saved');
        }
    },

    markAsRated: function () {
        if (this.get('owner')) {
            return this.set({
                overall_experience_comment_saved: true,
                immerss_experience_rate_saved: true
            });
        } else {
            return this.set({
                overall_experience_comment_saved: true,
                quality_of_content_rate_saved: true,
                immerss_experience_rate_saved: true
            });
        }
    },

    isLivestream: function () {
        return this.get('livestream_purchase_price') != null
    },

    canAccessLivestream: function () {
        if (!this.isLivestream())
            return false;
        if (this.get('livestream_obtained') || this.get('livestream_can_view_as_guest')) {
            if (!Immerss.currentUserId && !(this.get('stopped') || this.get('finished'))) {
                $.cookie("livestream_" + this.id, true, {
                    expires: 365,
                    path: '/'
                });
            }
        }
        return this.get('livestream_obtained') || this.get('livestream_can_view_as_guest') || this.get('owner');
    },

    canAccessImmersive: function () {
        return this.get('immersive_obtained');
    },

    immersive_could_be_obtained_and_not_pending_invitee: function () {
        return this.get('immersive_could_be_obtained_and_not_pending_invitee');
    },

    accessibleDeliveryMethods: function() {
        return this.get('accessible_delivery_methods');
    },

    availableDeliveryMethods: function() {
        return this.get('available_delivery_methods');
    },

    onlyLivestreamIsAvailable: function() {
        return this.get('available_delivery_methods').length == 1 &&
               'livestream' == this.get('available_delivery_methods')[0]
    },

    onlyImmersiveIsAvailable: function() {
        return this.get('available_delivery_methods').length == 1 &&
               'immersive' == this.get('available_delivery_methods')[0]
    },

    finished: function () {
        return !this.get('livestream_up') && (this.get('ended') || this.get('stopped'));
    }
});

Player.Models.Replay = Backbone.Model.extend({
    model_name: 'replay'
});

Player.Models.Recording = Backbone.Model.extend({
    model_name: 'recording'
});

Player.Models.Channel = Backbone.Model.extend({});

Player.Models.Company = Backbone.Model.extend({});

Player.Models.List = Backbone.Model.extend({
    constructor: function (options) {
        Backbone.Model.prototype.constructor.apply(this, arguments);
        this.products = new Player.Collections.Products(options.products || []);
    },

    toJSON: function () {
        var data;
        data = Player.Models.List.__super__.toJSON.apply(this, arguments);
        data.products = this.products.toJSON();
        return data;
    }
});

Player.Models.Product = Backbone.Model.extend({
    getModalHtml: function () {
        this.model_html || (this.model_html = HandlebarsTemplates['sessions/player/product_modal'](this.toJSON()));
        return this.model_html;
    }
});

Player.Models.Poll = Backbone.Model.extend({});

Player.Collections.Lists = Backbone.Collection.extend({
    model: Player.Models.List,

    findProduct: function (attrs) {
        var product;
        if (attrs == null) {
            attrs = {};
        }
        if (_.isEmpty(attrs)) {
            return null;
        }
        product = null;
        _.find(this.models, function (list) {
            product = list.products.findWhere(attrs);
            return !!product;
        });
        return product;
    },

    isEnabled: function () {
        return !!this.findWhere({
            selected: true
        });
    }
});

Player.Collections.Products = Backbone.Collection.extend({
    model: Player.Models.Product
});

Player.Collections.Polls = Backbone.Collection.extend({
    model: Player.Models.Poll,
    isEnabled: function () {
        return !!this.findWhere({selected: true});
    }
});

Player.Views.VideoPlayerBottom = Backbone.View.extend({
    el: '#main_container_content .mainVideoSection-sub',

    events: {},

    initialize: function (options) {
        if (!this.model.lists) {
            this.model.lists = new Player.Collections.Lists()
        }
        this.listenTo(this.model.lists, 'sync', this.renderProducts)
        this.listenTo(this.model.lists, 'error', this.handleErrorProducts)
        this.render()
    },

    template: function (data, hbs) {
        var template;
        template = _.template(HandlebarsTemplates[hbs](data));
        return template.apply(this, arguments);
    },

    render: function () {
        this.$el.html(this.template({
            description: this.checkHtmlToText(this.model.get('description')) ? this.model.get('description') : null,
            custom_description: this.checkHtmlToText(this.model.get('custom_description')) ? this.model.get('custom_description') : null
        }, 'recordings/show/bottom_section'));
        this.getProducts();
    },

    checkHtmlToText: function (html) {
        return new DOMParser().parseFromString(html, 'text/html').body.innerText != ""
    },

    getProducts: function (force) {
        if (force == null) {
            force = false;
        }
        if (this.model.lists.length > 0 && !force) {
            this.renderProducts();
        } else {
            this.model.lists.url = Routes.fetch_products_products_path({
                model_type: this.model.model_name,
                model_id: this.model.id
            });
            this.model.lists.fetch();
        }
    },

    handleErrorProducts: function () {
        return setTimeout(((function (_this) {
            return function () {
                return _this.getProducts(true);
            };
        })(this)), 5000);
    },

    renderProducts: function () {
        var data;
        if (this.model.lists.length === 0) {
            this.$('li.shop-tab, #MS_Shop').removeClass('active');
            this.$('li.shop-tab').hide();
            $('.mobileFooterNav.smallScrolls div[data-target="products"]').hide()
        } else {
            data = {
                lists: this.model.lists.toJSON(),
                type: this.model.model_name
            };
            this.$('#MS_Shop').html(this.template(data, 'sessions/player/shop_tab'));
            this.$('li.shop-tab').toggle(this.model.lists.isEnabled());
            $('.mobileFooterNav.smallScrolls div[data-target="products"]').toggle(this.model.lists.isEnabled())
            if (!this.model.lists.isEnabled()) {
                this.$('li.shop-tab, #MS_Shop').removeClass('active');
            }
        }
        this.checkActiveTab();
    },

    checkActiveTab: function () {
        var single_tab;
        this.$el.parent().removeClass('hidden');
        single_tab = this.$('.mainVideoSection-sub-header ul li:visible').length === 1;
        if (single_tab && this.$('.mainVideoSection-sub-header ul li:visible').hasClass('description-tab')) {
            $('.mainVideoSection-about').show();
            this.$('.mainVideoSection-sub-header ul li').hide();
        } else if (single_tab && !this.$('.mainVideoSection-sub-header ul li:visible').hasClass('description-tab')) {
            if (this.$('.mainVideoSection-sub-header ul li.active:visible').length === 0) {
                this.$('.mainVideoSection-sub-header ul li:visible:first a').click();
            }
            this.$('.mainVideoSection-sub-header ul li:visible').toggleClass('single-tab', single_tab);
        } else if (!single_tab && this.$('.mainVideoSection-sub-header ul li:visible').length > 0) {
            $('.mainVideoSection-about').hide();
            if (this.$('.mainVideoSection-sub-header ul li.active:visible').length === 0) {
                this.$('.mainVideoSection-sub-header ul li:visible:nth-child(2) a').click();
            }
            this.$('.mainVideoSection-sub-header ul li:visible').toggleClass('single-tab', false);
        }
        var hide_wrapper = this.$('.mainVideoSection-sub-body .tab-pane:visible').length === 0;
        this.$el.parent().toggleClass('hidden', hide_wrapper);
    },

    showProductModal: function (e) {
        var product;
        e.preventDefault();
        product = this.model.lists.findProduct({
            id: $(e.currentTarget).data('id')
        });
        if (!product) {
            return;
        }
        if (!$("#productGallery" + product.id).length) {
            $('body').append(product.getModalHtml());
        }
        $("#productGallery" + product.id).modal('show');
    }
});

Player.Views.ReviewDropdown = Backbone.View.extend({
    el: '.mainVideoSection-footer .ratingWrapp',

    events: {
        // 'change .ratingDropDown fieldset.rate input': 'saveScore',
        // 'click .save_rating': 'saveComment',
        'click': 'openModalReview'
    },

    initialize: function (options) {
        console.log('Player.Views.ReviewDropdown::init');
        console.log(options);
        this.klass = options.klass || 'Session';
        $(document).ready(function(){
            if($('html').hasClass('ipad') || $('html').hasClass('tablet') || $('html').hasClass('mobile')){
                $('.ratingWrapp').removeAttr('title');
            }
        })
        return this.render();
    },

    openModalReview: function () {
        if(document.querySelector(".session_feedback_area")) {
            scrollTo(0,0)
        }
        else if (Immerss.currentUserId && this.model){
            if (this.model.get('can_rate') && !this.model.get('upcoming') &&
                (this.klass !== "Session" || this.model.get('started') || this.model.get('finished') || this.model.get('ended') || this.model.get('stopped'))) {
                window.eventHub.$emit('edit-reviewForm');
            } else if (this.klass == "Session" && this.model.get('upcoming') && (!this.model.get('started') || this.model.get('upcoming'))) {
                window.eventHub.$emit('leave-review-not-available');
            } else {
                window.eventHub.$emit('try-leave-reviewForm');
            }
        }
    },

    saveScore: function (e) {
        var $target, data, _this;
        _this = this;
        console.log('saveScore');
        if (Immerss.currentUserId) {
            if (this.model.get('quality_of_content_rate_saved')) {
                return false;
            }
            $target = $(e.currentTarget);
            data = {
                score: $target.val(),
                dimension: 'quality_of_content',
                klass: this.klass,
                dropdown: true
            };
            $.ajax({
                url: Routes.review_rate_path(this.model.id),
                type: 'POST',
                dataType: 'json',
                data: data,
                success: function (res, textStatus, jqXHR) {
                    var obj, obj1;
                    console.log('review_rate:success');
                    _this.model.set((
                        obj = {},
                            obj[data.dimension + "_rate"] = data.score * 1,
                            obj
                    ));
                    _this.model.set((
                        obj1 = {},
                            obj1[data.dimension + "_rate_saved"] = true,
                            obj1
                    ));
                    if (_this.model.get('owner') && _this.model.get('immerss_experience_rate') || !_this.model.get('owner') && _this.model.get('quality_of_content_rate') && _this.model.get('immerss_experience_rate')) {
                        _this.$('#reviewSession textarea, .save_rating').removeClass('disabled').removeAttr('disabled').removeAttr('title');
                    } else {
                        _this.$('#reviewSession textarea, .save_rating').addClass('disabled').attr('disabled', true);
                    }
                    if (res.dropdown) {
                        _this.$el.html($(res.dropdown).html());
                        return _this.render();
                    }
                },
                error: function (res, error) {
                    var message;
                    _this.$('#reviewSession textarea, .save_rating').addClass('disabled').attr('disabled', true);
                    message = res.responseJSON && (res.responseJSON.error || res.responseJSON.message) || 'Something went wrong';
                    return $.showFlashMessage(message, {
                        type: 'error'
                    });
                }
            });
        } else {
            window.eventHub.$emit("open-modal:auth", "login")
            // $('#loginPopup').modal('show');
        }
        return false;
    },

    saveComment: function () {
        var comment, data, type, _this;
        _this = this;
        console.log('saveComment');
        if (Immerss.currentUserId) {
            if (!this.model.get('quality_of_content_rate')) {
                return false;
            }
            type = this.$('textarea').attr('name');
            comment = this.$('textarea').val();
            if (comment.length > 0) {
                data = {
                    skip_flash: 1,
                    comment: {},
                    klass: this.klass,
                    dropdown: true
                };
                data['comment'][type] = comment;
                $.ajax({
                    url: Routes.review_comment_path(this.model.id),
                    type: 'POST',
                    dataType: 'json',
                    data: data,
                    success: function (res, textStatus, jqXHR) {
                        console.log('review_comment:success');
                        var attrs = {};
                        attrs[type] = comment;
                        _this.model.set(attrs);
                        _this.$el.html($(res.dropdown).html());
                        window.eventHub.$emit('fetch-reviews');
                        return _this.render();
                    },
                    error: function (res, error) {
                        return $.showFlashMessage(error, {type: 'error'});
                    }
                });
            } else {
                this.$('.ratingDropDown-f').remove();
            }
        } else {
            window.eventHub.$emit("open-modal:auth", "login")
            // $('#loginPopup').modal('show');
        }
        return false;
    }
});
