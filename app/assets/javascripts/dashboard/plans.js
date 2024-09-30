+function () {
    const PLANS_MAX_COUNT = 12;
    "use strict";
    var Plans = Backbone.Collection.extend({
        comparator: 'im_enabled',
        enabled: function () {
            return this.where({im_enabled: true});
        },
        available: function () {
            return this.filter(function (i) {
                return i.get('im_enabled') != false;
            });
        },
        notSaved: function () {
            return this.newPlans().filter(function (i) {
                return i.get('im_enabled') != true;
            });
        },
        newPlans: function () {
            return this.filter(function (i) {
                return !i.get('id');
            });
        }
    });
    window.PlansCollection = Plans;
    var SubscriptionPlanForm = Backbone.View.extend({
        el: 'body.dashboards-subscriptions',
        events: {
            'click #add_new_plan': 'addNewPlan',
            'click .enable_subscription': 'toggleSubscription',
            'keyup #subscription_description': 'setCount',
            'submit form.subscription_form': 'submitSubscription'
        },
        initialize: function (options) {
            this.collection.sort();
            this.collection.on('change:im_enabled', this.updatePlansCount, this);
            this.collection.on('change:im_enabled', this.renderPlans, this);
            this.collection.on('add', this.renderPlans, this);
            this.plan_views = {};
            this.action = options.action;
            this.render();
            return this;
        },
        render: function () {
            this.$form = this.$('form.subscription_form');
            this.renderPlans();
            this.setupValidator();
        },
        getRandomColor: function () {
            return '#' + Math.random().toString(16).slice(2, 8);
        },
        addNewPlan: function (e) {
            e.preventDefault();
            if (this.collection.enabled().length == PLANS_MAX_COUNT || this.collection.available().length == PLANS_MAX_COUNT) {

                $.showFlashMessage(I18n.t('subscriptions.create.max_count_reached', {max_count: PLANS_MAX_COUNT}), {
                    type: 'error',
                    timeout: 6000
                });
                return;
            } else if (this.collection.notSaved().length > 0 || this.collection.newPlans().length == PLANS_MAX_COUNT) {
                $.showFlashMessage(I18n.t('subscriptions.create.complete_message'), {
                    type: 'error',
                    timeout: 6000
                });
                return;
            }
            this.collection.add({
                im_name: 'New Plan',
                im_color: this.getRandomColor(),
                interval: 'day',
                interval_count: 21,
                im_livestreams: true,
                im_interactives: false,
                im_replays: true,
                im_uploads: true,
                im_documents: true,
                im_channel_conversation: false,
                autorenew: true,
                trial_period_days: 0,
                stripe_subscriptions_count: 0,
            })
        },
        renderPlans: function () {
            var that = this;
            this.collection.each(function (item, index) {
                that.addPlanView(item);
            });
        },
        addPlanView: function (item) {
            if (this.plan_views[item.cid] == null) {
                this.plan_views[item.cid] = new PlanFieldsView({model: item});
            }
            this.plan_views[item.cid].render();
        },
        setupValidator: function () {
            this.validator || (this.validator = this.$form.validate({
                rules: {
                    'subscription[description]': {
                        required: true,
                        maxlength: 2000
                    },
                    'subscription[channel_id]': {
                        required: true,
                        channelListedRequred: true,
                        subscriptionRequred: true
                    }
                },
                ignore: '.ignore',
                errorElement: 'span',
                errorPlacement: function (error, element) {
                    $.showFlashMessage('Please, fill the required fields', {type: "danger"});
                    return error.appendTo(element.parents('.input-block, .select-block, .sectionBlock').find('.errorContainerWrapp')).addClass('errorContainer');
                },
                highlight: function (element) {
                    return $(element).parents('.input-block, .select-block, .sectionBlock').addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    return $(element).parents('.input-block, .select-block, .sectionBlock').removeClass('error').addClass('valid');
                }
            }));
        },

        setCount: function (e) {
            var len;
            len = $(e.target).val().length;
            return $(e.target).parents('.input-block').find('.counter_block').html(len + "/" + ($(e.target).attr('max-length')));
        },

        submitSubscription: function (e) {
            if (!(this.collection.enabled().length > 0)) {
                $.showFlashMessage('Enable plans (Min. 1 plan is required)', {
                    type: 'error',
                    timeout: 6000
                });
                return false;
            } else if (this.collection.length !== this.collection.enabled().length && !$('#submit-warn-modal').is(':visible')) {
                $('#submit-warn-modal').modal()
                return false;
            } else {
                return true;
            }
        },

        toggleSubscription: function (e) {
            var checkbox;
            checkbox = this.$form.find('.enable_subscription_checkbox');
            if (checkbox.prop('checked')) {
                checkbox.prop('checked', false);
                $(e.currentTarget).html('Enable');
            } else {
                checkbox.prop('checked', true);
                $(e.currentTarget).html('Disable');
            }
            return false;
        },

        updatePlansCount: function (e) {
            this.$form.find(".plans_length").html(this.collection.enabled().length + `/${PLANS_MAX_COUNT}`);
        }
    });

    window.SubscriptionPlanForm = SubscriptionPlanForm;

    var PlanFieldsView = Backbone.View.extend({
        tagName: 'div',
        className: 'longTile_mk2',
        events: {
            'click .edit_subscription_img': 'editColor',
            'keyup input[name*="[trial_period_days]"]': 'validateTrialPeriodDays',
            'keyup input[name*="[amount]"]': 'validateAmount',
            'keyup input[name*="[revenue_amount]"]': 'validateRevenueAmount',
            'paste input[name*="[trial_period_days]"]': 'validateTrialPeriodDays',
            'paste input[name*="[amount]"]': 'validateAmount',
            'paste input[name*="[revenue_amount]"]': 'validateRevenueAmount',
            'change .free_trial': 'toggleFreeTrial',
            'change .colorpicker': 'setColor',
            'change input[name*="[im_name]"]': 'setImName',
            // 'change select[name*="[im_months]"]': 'setImMonths',
            'change select[name*="[interval]"]': 'setInterval',
            'change input[name*="[interval_count]"]': 'setIntervalCount',
            'change input[name*="[amount]"]': 'setAmount',
            'change input[name*="[revenue_amount]"]': 'setRevenueAmount',
            'change input[name*="[im_livestreams]"]': 'setImLivestreams',
            'change input[name*="[im_interactives]"]': 'setImInteractives',
            'change input[name*="[im_replays]"]': 'setImReplays',
            'change input[name*="[im_uploads]"]': 'setImUploads',
            'change input[name*="[im_channel_conversation]"]': 'setImChannelConversation',
            'change input[name*="[im_documents]"]': 'setImFiles',
            'change input[name*="[autorenew]"]': 'setAutorenew',
            'change input[name*="[trial_period_days]"]': 'setTrialPeriodDays',
            'click .plan_off': 'disablePlan',
            'click .plan_on': 'enablePlan',
        },
        initialize: function () {
            this.template = Handlebars.compile($('#planFieldsTmpl').text());
            this.model.set("revenue_percent", window.revenue_percent == 100 ? null : window.revenue_percent);
            this.calculateRevenueAmount(null, this.model.get("amount"));
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            var serviceConversationsEnabled = ConfigGlobal.instant_messaging.enabled && ConfigGlobal.instant_messaging.conversations.channels.enabled;
            data.subscriptions_mono_image = window.subscriptions_mono_image;
            data.index = this.model.collection.indexOf(this.model);
            data.disabled = this.model.get('id') && !this.model.get('im_enabled');
            data.restorable = this.model.get('id') && !this.model.get('im_enabled') && this.model.previousAttributes().im_enabled;
            data.im_conversation_enabled = serviceConversationsEnabled && this.model.get('id') && !this.model.get('im_enabled');
            data.available_intervals = ['day', 'month'];
            return data;
        },
        getRegion: function () {
            var region;
            if (this.model.get('id') && !this.model.get('im_enabled')) {
                region = '#disabled_plans_tab'
            } else {
                region = '#plans_tab'
            }
            return $(region);
        },
        render: function () {
            var data = this.getTemplateData();
            var $region = this.getRegion();
            $region.append(this.$el);
            this.$el.html(this.template(data));
            return this;
        },

        editColor: function (e) {
            var colorPicker;
            colorPicker = $(e.currentTarget).next('.colorpicker');
            $(colorPicker).click();
            return false;
        },
        toggleFreeTrial: function (e) {
            var free_trial_enabled = $(e.target).is(':checked');
            var $input = $(e.target).parents('.subscriptionTerm').find('.DayCountWrapp input');
            if (free_trial_enabled) {
                // allow to edit if enabled
                $input.removeClass('disabled');
                $input.removeAttr('disabled');
                $input.focus();
            } else {
                // disable and set to 0
                $input.val(0);
                $input.addClass('disabled');
                $input.attr('disabled', 1);
                this.model.set({trial_period_days: 0});
            }
        },

        setColor: function (e) {
            this.model.set({im_color: $(e.currentTarget).val()});
            $(e.currentTarget).parents('.img_wrapp').find('rect').attr('fill', this.model.get('im_color'));
        },
        setImName: function (e) {
            this.model.set({im_name: $(e.currentTarget).val()});
        },
        setImMonths: function (e) {
            this.model.set({im_months: parseInt($(e.currentTarget).val())});
        },
        setInterval: function (e) {
            this.model.set({interval: $(e.currentTarget).val()});
        },
        setIntervalCount: function (e) {
            this.model.set({interval_count: parseInt($(e.currentTarget).val())}).toString();
        },
        setAmount: function (e) {
            this.model.set({amount: parseFloat($(e.currentTarget).val().replace(',', '.'))});
            // $(e.currentTarget).val(this.model.get('amount'))
        },
        setRevenueAmount: function (e) {
            this.model.set({revenue_amount: parseFloat($(e.currentTarget).val().replace(',', '.'))});
        },
        calculateRevenueAmount: function (e = null, amount = null) {
            if(e == null && amount == null) return;

            var value = 0;
            if(e) value = parseFloat($(e.currentTarget).val().replace(',', '.'));
            if(amount) value = amount;

            if(this.model.get('revenue_percent')) {
                var revenue_amount = value * (this.model.get('revenue_percent') / 100)
                revenue_amount = revenue_amount.toFixed(2).replace(".00", "")
                if(revenue_amount && !isNaN(value)) {
                    this.model.set({revenue_amount: revenue_amount})
                    if(e) $("#" + e.target.id.replace("amount", "revenue_amount")).val(revenue_amount)
                }
                else {
                    this.model.set({revenue_amount: null})
                    if(e) $("#" + e.target.id.replace("amount", "revenue_amount")).val("")
                }
            }
        },
        calculateAmount(e) {
            var value = parseFloat($(e.currentTarget).val().replace(',', '.'));
            if(this.model.get('revenue_percent')) {
                var amount = value / (this.model.get('revenue_percent') / 100)
                amount = amount.toFixed(2).replace(".00", "")
                if(amount && !isNaN(value)) {
                    this.model.set({amount: amount})
                    $("#" + e.target.id.replace("revenue_amount", "amount")).val(amount)
                }
                else {
                    this.model.set({amount: null})
                    $("#" + e.target.id.replace("revenue_amount", "amount")).val("")
                }
            }
        },
        validateAmount: function (e) {
            // skip for , and .
            if (e.which && (e.which == 188 || e.which == 190))
                return true
            var value = parseFloat($(e.currentTarget).val().replace(',', '.'));
            var max = 999999.99
            if (isNaN(value) || value < 0) {
                $(e.currentTarget).val("")
                this.calculateRevenueAmount(e)
                return false
            } else if (value > max) {
                $(e.currentTarget).val(max)
                this.calculateRevenueAmount(e)
                return false
            }
            this.calculateRevenueAmount(e)
            $(e.currentTarget).val(value)
        },
        validateRevenueAmount: function (e) {
            // skip for , and .
            if (e.which && (e.which == 188 || e.which == 190))
                return true
            var value = parseFloat($(e.currentTarget).val().replace(',', '.'));
            var max = 999999.99
            if(this.model.get('revenue_percent')) {
                max = max * (this.model.get('revenue_percent') / 100)
                max = max.toFixed(2)
            }
            if (isNaN(value) || value < 0) {
                $(e.currentTarget).val("")
                this.calculateAmount(e)
                return false
            } else if (value > max) {
                $(e.currentTarget).val(max)
                this.calculateAmount(e)
                return false
            }
            this.calculateAmount(e)
            $(e.currentTarget).val(value)
        },
        setImLivestreams: function (e) {
            this.model.set({im_livestreams: $(e.currentTarget).is(':checked')});
        },
        setImInteractives: function (e) {
            this.model.set({im_interactives: $(e.currentTarget).is(':checked')});
        },
        setImReplays: function (e) {
            this.model.set({im_replays: $(e.currentTarget).is(':checked')});
        },
        setImUploads: function (e) {
            this.model.set({im_uploads: $(e.currentTarget).is(':checked')});
        },
        setImChannelConversation: function (e) {
            this.model.set({im_channel_conversation: $(e.currentTarget).is(':checked')});
        },
        setImFiles: function (e) {
            this.model.set({im_documents: $(e.currentTarget).is(':checked')});
        },
        setAutorenew: function (e) {
            this.model.set({autorenew: $(e.currentTarget).is(':checked')});
        },
        setTrialPeriodDays: function (e) {
            this.model.set({trial_period_days: parseInt($(e.currentTarget).val())});
        },
        validateTrialPeriodDays: function (e) {
            var value = parseInt($(e.currentTarget).val());
            if (isNaN(value) || value < 0) {
                $(e.currentTarget).val(0)
                return false
            } else if (value > 30) {
                $(e.currentTarget).val(30)
                return false
            }
            // format days, eg: 03 => 3
            $(e.currentTarget).val(value)
        },
        disablePlan: function (e) {
            e.preventDefault();
            $(e.currentTarget).parents('.btns-group').find('a').removeClass('active');
            $(e.currentTarget).addClass('active');
            this.$('.im_enabled').removeAttr('checked');
            this.model.set({im_enabled: false});
        },
        enablePlan: function (e) {
            e.preventDefault();
            if (this.model.get('im_enabled'))
                return false
            if (!this.model.get('amount')) {
                this.$('input[name*="[amount]"]').focus();
                this.$('input[name*="[amount]"]').effect('highlight', {color: '#ff9ea3'}, 300);
                return
            }
            if (this.$('input[name*="[interval_count]"]').length) {
                this.model.set({
                    interval_count: parseInt(this.$('input[name*="[interval_count]"]').val()).toString(),
                    interval: this.$('select[name*="[interval]"]').val()
                });
                if (this.model.collection.where({
                    im_enabled: true,
                    interval: this.model.get('interval'),
                    interval_count: this.model.get('interval_count'),
                    im_replays: this.model.get('im_replays'),
                    im_uploads: this.model.get('im_uploads'),
                    im_livestreams: this.model.get('im_livestreams'),
                    im_interactives: this.model.get('im_interactives'),
                    im_documents: this.model.get('im_documents'),
                    im_channel_conversation: this.model.get('im_channel_conversation')
                }).length > 0) {
                    $.showFlashMessage('Plan with the same settings already exists', {
                        type: 'error',
                        timeout: 6000
                    });
                    this.$('input[name*="[interval_count]"]:visible').focus();
                    this.$('input[name*="[interval_count]"]:visible').effect('highlight', {color: '#ff9ea3'}, 300);
                    return
                }
            }
            $(e.currentTarget).parents('.btns-group').find('a').removeClass('active');
            $(e.currentTarget).addClass('active');
            this.$('.im_enabled').attr('checked', true);
            this.model.set({im_enabled: true});
        }
    });
}();
