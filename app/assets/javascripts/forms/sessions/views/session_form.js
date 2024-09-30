(function () {
    var SessionThumbnail,
        extend = function (child, parent) {
            for (var key in parent) {
                if (hasProp.call(parent, key)) child[key] = parent[key]
            }

            function ctor() {
                this.constructor = child
            }

            ctor.prototype = parent.prototype
            child.prototype = new ctor()
            child.__super__ = parent.prototype
            return child
        },
        hasProp = {}.hasOwnProperty

    window.roundPrice = function (price) {
        price = parseFloat(price) * 100
        if (isNaN(price)) {
            return 0
        }
        return Math.round(price) / 100
    }

    window.immersiveServiceFee = function (duration) {
        return 0.0
    }

    window.livestreamServiceFee = function (duration) {
        return 0.0
    }

    window.recordedServiceFee = function (duration) {
        return 0.0
    }

    window.immersiveMinCost = function (duration) {
        return 4.99
    }

    window.livestreamMinCost = function (duration) {
        return 2.99
    }

    window.recordedMinCost = function (duration) {
        return 0.99
    }

    SessionThumbnail = Backbone.Model.extend({

        initialize: function () {
            this.on('invalid', this.showErrors);
            this.on('invalid', this.clearFile);
            this.on('file:uploaded', this.parseData);
        },

        validate: function (attrs) {
            if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
                return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
            if (attrs.file && attrs.file.size > 10485760) {
                return "File " + attrs.file.name + " is too large. Maximum allowed file size is 10 megabytes (10485760 bytes).";
            }
            if (attrs.img && (attrs.img.width < 415 || attrs.img.height < 115)) {
                return 'Thumbnail should be at least 415x115 px';
            }
        },

        parseData: function (file) {
            return _.defer((function (_this) {
                return function () {
                    var reader;
                    if (_this.isValid()) {
                        file = _this.get('file');
                        reader = new FileReader;
                        reader.onload = function (e) {
                            var img;
                            img = new Image;
                            img.onload = function () {
                                _this.set({
                                    'base64_img': img.src,
                                    img: img
                                });
                                if (_this.isValid()) {
                                    return _this.trigger('image:loaded', _this);
                                }
                            };
                            return img.src = e.target.result;
                        };
                        return reader.readAsDataURL(file);
                    }
                };
            })(this));
        },

        showErrors: function () {
            return $.showFlashMessage(this.validationError, {
                type: 'error'
            });
        },

        crop: function (cropData, croppedCanvas) {
            this.set({
                crop_x: cropData.x.toString(),
                crop_y: cropData.y.toString(),
                crop_w: cropData.width.toString(),
                crop_h: cropData.height.toString(),
                rotate: cropData.rotate.toString(),
                img_src: croppedCanvas.toDataURL(),
                image: this.get('file'),
                saved: false
            });
            this.clearFile();
            return this.trigger('crop:done', this);
        },

        clearFile: function () {
            this.unset('file', {
                silent: true
            });
            this.unset('img', {
                silent: true
            });
            return this.unset('base64_img', {
                silent: true
            });
        },

        resetAttributes: function () {
            return this.set(this.previousAttributes());
        },

        toJSON: function () {
            return {
                id: this.id,
                cid: this.cid,
                img_src: this.get('img_src')
            };
        },

        cropData: function () {
            return {
                cid: this.cid,
                base64_img: this.get('base64_img')
            };
        },

        cropperParams: function () {
            return {
                aspectRatio: 16 / 9
            };
        },

        toFormData: function () {
            var data;
            data = [];
            if (this.get('image')) {
                data.push(['session[cover]', this.get('image')]);
                data.push(['session[crop_x]', this.get('crop_x')]);
                data.push(['session[crop_y]', this.get('crop_y')]);
                data.push(['session[crop_w]', this.get('crop_w')]);
                data.push(['session[crop_h]', this.get('crop_h')]);
                data.push(['session[rotate]', this.get('rotate')]);
            }
            return data;
        },
    });

    window.SessionFormCentralContainer = Backbone.View.extend({
        livestream_price_popup: HandlebarsTemplates['sessions/form/livestream_price_popup'],
        immersive_price_popup: HandlebarsTemplates['sessions/form/immersive_price_popup'],
        recorded_price_popup: HandlebarsTemplates['sessions/form/recorded_price_popup'],
        invited_user: HandlebarsTemplates['sessions/form/invited_user'],
        service_types_options: HandlebarsTemplates['sessions/form/service_types'],
        live_preview_template: HandlebarsTemplates['sessions/form/live_preview'],
        stream_settings_template: HandlebarsTemplates['sessions/form/stream_settings'],
        source_settings_template: HandlebarsTemplates['sessions/form/source_settings'],
        encoder_template: HandlebarsTemplates['sessions/form/encoder_info'],
        ipcam_info_template: HandlebarsTemplates['sessions/form/ipcam_info'],
        ipcam_modal_template: HandlebarsTemplates['sessions/form/ipcam_modal'],
        modals_template: HandlebarsTemplates['sessions/form/modals'],
        el: '#session_form_container',
        initialize: function (options) {
            window.session_form = this;
            this.model = options.model;
            this.original_session_id = options.original_session_id;
            this.channel_presenters = options.channel_presenters;
            this.users = options.users;
            this.channels = options.channels;
            this.previous_sessions = options.previous_sessions;
            this.organizations = options.organizations;
            this.lists = options.lists;
            this.wa_rtmp = options.wa_rtmp;
            this.wa_ipcam = options.wa_ipcam;
            this.zoom_connected = options.zoom_connected;
            this.zoom_paid = options.zoom_paid;
            this.zoom_connect_url = options.zoom_connect_url;
            this.service_logo_url = options.service_logo_url;
            this.zoom_enabled = options.zoom_enabled;
            this.zoom_logo_url = options.zoom_logo_url;
            this.subscription = options.subscription;
            this.feature_parameters = options.feature_parameters;
            this.ppv_enabled = options.ppv_enabled;
            this.crop_container = '.crop-container:visible';
            this.cropper_template = HandlebarsTemplates['wizard/image_cropper'];
            this.thumbnail = new SessionThumbnail();
            this.listenTo(this.thumbnail, 'invalid', this.showUploader);
            this.listenTo(this.thumbnail, 'image:loaded', this.showCropper);
            this.listenTo(this.thumbnail, 'crop:done', this.cropDone);
            this.approximateLivestreamUsersCount = 0;
            this.approximateVodUsersCount = 0;
            this.price_regexp = /^\d{1,4}(?:\.(?=\d{1,2})\d{1,2})?$/;
            this.selectedChannelId = this.model.get('channel_id');
            this.setOrganization();

            var channel_from_id = new URL(window.location.href).searchParams.get("channel_from_id");
            if (this.channels.some(function (channel) {
                return channel.id == channel_from_id
            })) {
                this.selectedChannelId = channel_from_id;
            }

            if (this.users.findWhere({state: 'co-presenter'})) {
                this.model.set({co_hosts: true});
            }
            if (this.model.get('list_ids').length) {
                this.model.set({ecommerce: true});
            }
            Handlebars.registerPartial('PresentersOptions', (function (_this) {
                return function (options) {
                    var template;
                    template = _.template(HandlebarsTemplates['sessions/form/presenters_select'](options));
                    return template.apply(_this, arguments);
                };
            })(this));
            Handlebars.registerPartial('live_preview_template', this.live_preview_template);
            Handlebars.registerPartial('stream_settings_template', this.stream_settings_template);
            Handlebars.registerPartial('source_settings_template', this.source_settings_template);
            Handlebars.registerPartial('encoder_template', this.encoder_template);
            Handlebars.registerPartial('ipcam_info_template', this.ipcam_info_template);
            Handlebars.registerPartial('ipcam_modal_template', this.ipcam_modal_template);
            return this.onInitScripts();
        },
        events: {
            'change [name="session[duration]"]': 'durationChanged',
            'click .streamSettings_H > a:not(#multiroom_setting)': 'setDeviceType',
            'click .showPass': 'showValue',
            'change #IP_Camera_url': 'setIpcamUrl',
            'click .bluriInput_btn': 'ipCamChangeUrlEnabled',
            'click #Edit_Url_modalShow': 'Edit_Url_modal_Show',
            'click #proceed_to_step_2': 'proceed_to_step_2',
            'click #enable_encoder': 'enableEncoder',
            'click #enable_ipcam': 'Edit_Url_modal_Show',
            'click #saveUrl_enable_ipcam': 'enableIpcam',
            // 'click #start_encoder_stream': 'startEncoder',
            // 'click #stop_encoder_stream': 'stopEncoder',
            // 'click #start_ipcam_stream': 'startIpcam',
            // 'click #stop_ipcam_stream': 'stopIpcam',
            'click .toggle_section': 'toggleAdditionalSection',
            'click .additionalInfoToggle': 'toggleAdditionalSections',
            'change #session_channel_id': 'setChannel',
            'click .section_Thumbnail .collaps': 'collapseThumbnail',
            'change input#session_thumbnail': 'setThumbnail',
            'drop #thumbnail_upload_area': 'setThumbnail',
            'dragover #thumbnail_upload_area': function (e) {
                e.preventDefault()
            },
            'click #session_thumbnail_modal .cropOptions .crop': 'cropThumbnail',
            'click #session_thumbnail_modal .cropOptions .clear': 'сancelCropThumbnail',
            'change [name="session[recurring_settings][days][]"]': 'handleRecurringDays',
            'change #recurring_settings-swith': 'recurringSettingsToggle',
            'change #Products-swith': 'productsToggle',
            'focus .input-block #session_title, .input-block textarea': 'focusInput',
            'focusout .input-block #session_title, .input-block textarea': 'unfocusInput',
            'mousedown .tooltipBody.setPrice': 'pricePopoverClicked',
            'change input.price_number': 'formatNumber',
            'keypress input.price_number': 'skipSubmit',
            'keypress input#session_title': 'skipSubmit',
            'change #RecurrenceOptions_After': 'RecurrenceOptions_After_active',
            'change #RecurrenceOptions_On': 'RecurrenceOptions_On_active',
            'click .ChanelPresenter ul li a': 'selectPresenter',
            'click .streamingPlatform ul li': 'selectStreamingPlatform',
            'change #session_livestream': 'setLivestream',
            'change #session_immersive': 'setImmersive',
            'change #session_max_number_of_immersive_participants': 'setParticipantsCount',
            'change #session_co_hosts': 'setCoHost',
            'click .section_Description .collaps': 'collapseDescription',
            'click .section_Instructions .collaps': 'collapseInstructions',
            'change #session_title': 'setTitle',
            'keyup #session_title': 'setTitle',
            // 'change #session_description': 'setDescription',
            // 'keyup #session_description': 'setDescription',
            // 'change #session_instructions': 'setInstructions',
            // 'keyup #session_instructions': 'setInstructions',
            // 'hide.bs.modal #Description_modal': 'checkDescriptionOptionState',
            'change select#session_device_type': 'setLivePreview',
            'click #session_set_public': 'setPublic',
            'click #session_set_private': 'setPrivate',
            'click #session_set_13': 'setAge13',
            'click #session_set_18': 'setAge18',
            'change #session_adult': 'toggleAdult',
            'click #session_set_start_now': 'setStartNow',
            'click #session_set_start_at': 'setStartAt',
            'change #session_start_at_4i': 'setHours',
            'change #session_start_at_5i': 'setMinutes',
            'change #session_pre_time': 'setPreTime',
            'click .dottedCircle': 'showAllMembers',
            'click #session_autostart': 'setAutoStart',
            'click #session_manual': 'setManualStart',
            'change #session_record': 'setRecorded',
            'change [name*=allow_chat]': 'toggleChat',
            'change [name*=ecommerce]': 'switchEcommerceOption',
            'show.bs.modal #InviteViewersAndCoHosts': 'renderInviteModal',
            'click a#session_livestream_free_set': 'setLivestreamFree',
            'click a#session_livestream_paid_set': 'setLivestreamPaid',
            'click a#session_immersive_free_set': 'setImmersiveFree',
            'click a#session_immersive_paid_set': 'setImmersivePaid',
            'click a#session_recorded_free_set': 'setRecordedFree',
            'click a#session_recorded_paid_set': 'setRecordedPaid',
            'change #livestream_total_cost': 'setLivestreamPrice',
            'keyup #livestream_total_cost': 'setLivestreamPrice',
            'change #immersive_total_cost': 'setImmersivePrice',
            'keyup #immersive_total_cost': 'setImmersivePrice',
            'change #recorded_total_cost': 'setRecordedPrice',
            'keyup #recorded_total_cost': 'setRecordedPrice',
            'click #livestream_total_cost': 'setLivestreamPrice',
            'click #immersive_total_cost': 'setImmersivePrice',
            'click #recorded_total_cost': 'setRecordedPrice',
            'change #livestream_revenue': 'setLivestreamPriceFromRevenue',
            'change #immersive_revenue': 'setImmersivePriceFromRevenue',
            'change #recorded_revenue': 'setRecordedPriceFromRevenue',
            'click #livestream_revenue': 'setLivestreamPriceFromRevenue',
            'click #immersive_revenue': 'setImmersivePriceFromRevenue',
            'click #recorded_revenue': 'setRecordedPriceFromRevenue',
            'change #session_list': 'setSessionList',
            'hide.bs.modal #eCommerce_modal': 'checkEcommerceOptionState',
            'click .streamSettings_toggle': 'streamSettings_toggle',
            'input #studio-filter': 'filter_studios',
            'change #studio-filter': 'filter_studios',
            'input #studio-room-filter': 'filter_studio_rooms',
            'change #studio-room-filter': 'filter_studio_rooms',
            'input #ffmpegservice-account-filter': 'filter_ffmpegservice_accounts',
            'change #ffmpegservice-account-filter': 'filter_ffmpegservice_accounts',
            'click .studio_option': 'select_studio',
            'click .studio_room_option': 'select_studio_room',
            'click .ffmpegservice_account_option': 'select_ffmpegservice_account',
            'click #multiroom_setting': 'setFirstMultiroomWa',
            'click .btn-stream-source': 'setActiveSourceButton',
            'click .show-source-details': 'openShowSourceDetailsModal',
            'click #show_video_source_modal .VideoClientIcon-squaresF': 'copyToClipboard',
            'click #show_video_source_modal .show-hide': 'showHideField',
            'click #camera_setting_webrtc': 'switch_webrtc',
            'click #camera_setting_webrtcservice': 'switch_webrtcservice',
            'click #mobile_setting': 'switch_webrtcservice',
            'click #ipcamera_setting': 'switch_ipcam',
            'click #encoder_setting': 'switch_encoder',
            'change #session_template_id': 'load_clone_session',
            'change #layout-grid-switch': 'setRecordingLayout',
            'change #layout-presenter_only-switch': 'setRecordingLayout',
            'change #layout-presenter_focus-switch': 'setRecordingLayout',
        },
        setThumbnail: function (e) {
            var files;
            e.preventDefault();
            this.showLoader();
            files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
            if (files && files[0]) {
                this.thumbnail.set({
                    file: files[0]
                });
                this.thumbnail.trigger('file:uploaded', this.thumbnail);
            } else {
                this.showUploader();
            }
        },
        cropThumbnail: function (e) {
            var cropData, croppedCanvas;
            e.preventDefault();
            this.showLoader();
            cropData = this.$(this.crop_container).find('#crop-img').cropper('getData');
            croppedCanvas = this.$(this.crop_container).find('#crop-img').cropper('getCroppedCanvas');
            this.$(this.crop_container).html('');
            this.thumbnail.crop(cropData, croppedCanvas);
        },
        сancelCropThumbnail: function (e) {
            e.preventDefault();
            this.showUploader();
            this.$(this.crop_container).html('');
            this.thumbnail.clearFile();
        },
        showLoader: function () {
            this.$('.upload-info span').hide('fast');
            this.$('.upload-area .row').show('fast');
            this.$('.LoadingCover').removeClass('hidden');
        },
        showUploader: function (e) {
            this.$('.modal:visible .upload-area .row, .modal:visible .upload-info span').show('fast');
            this.$('.modal:visible .upload-info span').show('fast');
            this.$('.modal:visible .LoadingCover').addClass('hidden');
            this.$('#session_thumbnail').val('');
        },
        showCropper: function (item) {
            this.$(this.crop_container).html(this.cropper_template(item.cropData()));
            this.$(this.crop_container).show('fast');
            this.hideUploader();
            initCrop(item.cropperParams());
            this.$('#session_thumbnail').val('');
        },
        hideUploader: function () {
            this.$('.upload-area:visible .row').hide('fast');
        },
        hideCropper: function () {
            this.$(this.crop_container).html('');
            this.showUploader();
        },
        cropDone: function (e) {
            this.$('.Thumbnail_load').attr('style', "background-image: url(" + (this.thumbnail.get('img_src')) + ")");
            this.showUploader();
            this.$('#session_thumbnail_modal').modal('hide');
            this.$('#session_thumbnail').val('');
            this.$('a.toggle_section.thumbnail').toggleClass('btn-withIcon', true);
            this.$('a.toggle_section.thumbnail .VideoClientIcon-checkmark').toggleClass('hidden', false);
        },
        toggleAdditionalSection: function (e) {
            var btn, active, target;
            btn = $(e.currentTarget)
            target = $(btn.data('target'));
            active = btn.hasClass('active');
            target.toggleClass('active', !active);
            btn.toggleClass('active', !active).blur();
            if (!this.$('.AdditionalInfoBody .toggleBlock').hasClass('active')) {
                $('.AdditionalInfoBody').hide().removeClass('active');
                $('.additionalInfoToggle').removeClass('active');
            } else {
                $('.AdditionalInfoBody').show().addClass('active');
                $('.additionalInfoToggle').addClass('active');
            }
            return false;
        },
        toggleAdditionalSections: function () {
            if (!this.$('.AdditionalInfoBody .toggleBlock').hasClass('active')) {
                $('.toggle_section.description').addClass('active');
                $('.toggleBlock.section_Description').addClass('active');
                $('.AdditionalInfoBody').show();
                $('.additionalInfoToggle').addClass('active');
            } else {
                $('.AdditionalInfoBody').hide().removeClass('active');
                $('.additionalInfoToggle').removeClass('active');
                $('.toggleBlock').removeClass('active');
                $('.toggle_section').removeClass('active');
            }
            return false;
        },
        collapseDescription: function (e) {
            var is_visible;
            is_visible = this.$('.section_Description textarea').is(':visible');
            this.$('.section_Description').find('textarea, .counter_block, .errorContainerWrapp').toggle(!is_visible);
            this.$('.section_Description .input-block').toggleClass('state-clear', !is_visible && this.$('.section_Description textarea').val().length === 0);
            this.$('.section_Description .VideoClientIcon-angle-downF').toggleClass('active', !is_visible);
            return false;
        },
        collapseInstructions: function (e) {
            var is_visible;
            is_visible = this.$('.section_Instructions textarea').is(':visible');
            this.$('.section_Instructions').find('textarea, .counter_block, .errorContainerWrapp').toggle(!is_visible);
            this.$('.section_Instructions .input-block').toggleClass('state-clear', !is_visible && this.$('.section_Instructions textarea').val().length === 0);
            this.$('.section_Instructions .VideoClientIcon-angle-downF').toggleClass('active', !is_visible);
            return false;
        },
        collapseThumbnail: function (e) {
            var is_visible;
            is_visible = this.$('.section_Thumbnail .Thumbnail_load').is(':visible');
            this.$('.section_Thumbnail .Thumbnail_load').toggle(!is_visible);
            this.$('.section_Thumbnail .VideoClientIcon-angle-downF').toggleClass('active', !is_visible);
            return false;
        },
        getLivestreamData: function () {
            var data;
            data = {};
            if (!this.model) {
                return data;
            }
            data.livestreamServiceFee = livestreamServiceFee(this.model.get('duration'));
            data.livestreamTotalMinCost = roundPrice(livestreamMinCost(this.model.get('duration')) + data.livestreamServiceFee);
            data.livestreamTotalMaxCost = roundPrice(Immerss.maxLivestreamSessionAccessCost + data.livestreamServiceFee);
            data.livestreamTotalPurchasePrice = roundPrice(this.model.get('livestream_access_cost') * 1 + data.livestreamServiceFee);
            data.livestreamRevenue = roundPrice(this.model.get('livestream_access_cost') * Immerss.revenueSplitMultiplier);
            data.livestreamRevenueMin = roundPrice(livestreamMinCost(this.model.get('duration')) * Immerss.revenueSplitMultiplier);
            data.livestreamRevenueMax = roundPrice(Immerss.maxLivestreamSessionAccessCost * Immerss.revenueSplitMultiplier);
            return data;
        },
        getImmersiveData: function () {
            var data;
            data = {};
            if (!this.model) {
                return data;
            }
            data.immersiveServiceFee = immersiveServiceFee(this.model.get('duration'));
            data.immersiveTotalMinCost = roundPrice(immersiveMinCost(this.model.get('duration')) + data.immersiveServiceFee);
            data.immersiveTotalMaxCost = roundPrice(Immerss.maxGroupImmersiveSessionAccessCost + data.immersiveServiceFee);
            data.immersiveTotalPurchasePrice = roundPrice(this.model.get('immersive_access_cost') * 1 + data.immersiveServiceFee);
            data.immersiveRevenue = roundPrice(this.model.get('immersive_access_cost') * Immerss.revenueSplitMultiplier);
            data.immersiveRevenueMin = roundPrice(immersiveMinCost(this.model.get('duration')) * Immerss.revenueSplitMultiplier);
            data.immersiveRevenueMax = roundPrice(Immerss.maxGroupImmersiveSessionAccessCost * Immerss.revenueSplitMultiplier);
            return data;
        },
        getRecordedData: function () {
            var data;
            data = {};
            if (!this.model) {
                return data;
            }
            data.recordedServiceFee = recordedServiceFee(this.model.get('duration'));
            data.recordedTotalMinCost = roundPrice(recordedMinCost(this.model.get('duration')) + data.recordedServiceFee);
            data.recordedTotalMaxCost = roundPrice(Immerss.maxRecordedSessionAccessCost + data.recordedServiceFee);
            data.recordedTotalPurchasePrice = roundPrice(this.model.get('recorded_access_cost') * 1 + data.recordedServiceFee);
            data.recordedRevenue = roundPrice(this.model.get('recorded_access_cost') * Immerss.revenueSplitMultiplier);
            data.recordedRevenueMin = roundPrice(recordedMinCost(this.model.get('duration')) * Immerss.revenueSplitMultiplier);
            data.recordedRevenueMax = roundPrice(Immerss.maxRecordedSessionAccessCost * Immerss.revenueSplitMultiplier);
            return data;
        },
        renderLivestreamPricePopup: function () {
            var data;
            if (!this.model) {
                return;
            }
            data = this.model.toJSON();
            data.revenueSplitTitle = Immerss.revenueSplitTitle;
            $.extend(data, this.getLivestreamData());
            this.$('#LivestreamPricePopup').html(this.livestream_price_popup(data));
        },
        renderImmersivePricePopup: function () {
            var data;
            if (!this.model) {
                return;
            }
            data = this.model.toJSON();
            data.revenueSplitTitle = Immerss.revenueSplitTitle;
            $.extend(data, this.getImmersiveData());
            this.$('#ImmersivePricePopup').html(this.immersive_price_popup(data));
        },
        renderRecordedPricePopup: function () {
            var data;
            if (!this.model) {
                return;
            }
            data = this.model.toJSON();
            data.revenueSplitTitle = Immerss.revenueSplitTitle;
            $.extend(data, this.getRecordedData());
            this.$('#RecordedPricePopup').html(this.recorded_price_popup(data));
        },
        render: function () {
            let data = this.model.toJSON()
            data.serviceTypeRtmp = data.service_type === 'rtmp'
            $.extend(data, this.getImmersiveData())
            $.extend(data, this.getLivestreamData())
            $.extend(data, this.getRecordedData())
            data.approximateLivestreamUsersCount = this.approximateLivestreamUsersCount
            data.approximateVodUsersCount = this.approximateVodUsersCount
            data.hideLivestreamFreeTrialBlock = !data.livestream || data.livestream_free || !data.livestream_free_trial || data["private"]
            data.hideImmersiveFreeTrialBlock = !data.immersive || data.immersive_free || !data.immersive_free_trial || data["private"]
            data.revenueSplitTitle = Immerss.revenueSplitTitle
            data.timeSelectFormat = Immerss.timeFormat === '12hour' ? 'hh:mm A' : 'HH:mm'
            data.has_youtube_access = Immerss.hasYoutubeAccess
            data.channel_presenters = this.channel_presenters
            data.users = this.users.toJSON()
            data.users_count = this.users.length
            data.invited_users_attributes = JSON.stringify(this.users)
            data.channels = this.channels
            data.previous_sessions = this.previous_sessions
            data.original_session_id = this.original_session_id
            data.organization = this.model.get('organization')
            data.lists = this.lists
            data.wa_rtmp = this.wa_rtmp
            data.wa_ipcam = this.wa_ipcam
            data.zoom_connected = this.zoom_connected
            data.zoom_paid = this.zoom_paid
            data.zoom_connect_url = this.zoom_connect_url
            data.service_logo_url = this.service_logo_url
            data.zoom_logo_url = this.zoom_logo_url
            data.zoom_enabled = this.zoom_enabled
            data.interactive_allowed = this.getInteractiveParam()
            data.private_allowed = this.getPrivateParam()
            data.instream_shopping = this.getInstreamShoppingParam()
            data.i18n_ipcam_modal = I18n.t('assets.javascripts.session_form.i18n_ipcam_modal')
            data.max_number_of_immersive_participants = this.getMaxInteractiveParticipants()
            data.max_number_of_immersive_participants_with_sources = this.getMaxInteractiveParticipants()
            data.selectedChannelId = this.selectedChannelId
            data.ppv_enabled = this.ppv_enabled
            if (this.wa_ipcam) {
                this.model.set({
                    ipcam_url: this.wa_ipcam.source_url,
                    silent: true
                });
            }
            this.$('#fields_region').html(this.template(data));
            this.$('#modals_container').html(this.modals_template(data));
            this.initDatepicker();
            this.initValidator();
            this.initDurationSlider();
            this.afterRender();
            this.prepareForm();
            this.prepareDescription();
            this.setChannel()
            this.setDescription()
            this.setInstructions()
        },
        template: function (data) {
            var template;
            template = _.template(HandlebarsTemplates['sessions/form/fields'](data));
            return template.apply(this, arguments);
        },
        subscriptionStatus: function () {
            if (this.subscription == "split_revenue_plan") {
                return 'split_revenue_plan'
            } else {
                return this.subscription.service_status
            }
        },
        checkPrivacy: function () {
        },
        skipSubmit: function (e) {
            return e.keyCode !== 13;
        },
        showAllMembers: function (e) {
            e.preventDefault();
            this.$('.memberList').toggleClass('showAllMembers');
        },
        pricePopoverClicked: function (e) {
            return e.stopPropagation();
        },
        isValid: function () {
            if (this.validator) {
                return this.validator.isValid();
            }
        },
        setCount: function (e) {
            var element, len;
            element = e.currentTarget;
            len = $(element).val().length;
            $(element).parents('.input-block').find('.counter_block').html(len + "/" + ($(element).attr('maxlength')));
        },
        detectNotNumKey: function (e) {
            var charCode, element, price;
            element = e.currentTarget;
            price = $(element).val();
            charCode = e.charCode || e.keyCode || e.which || 0;
            if (!price.match(/\.|,/) && (charCode === 44 || charCode === 46 || e.key === '.')) {
                return;
            }
            if (charCode > 31 && (charCode < 48 || charCode > 57)) {
                return false;
            }
        },
        formatNumber: function (e) {
            var charCode, element, max, min, price, valid_price;
            element = e.currentTarget;
            price = parseFloat($(element).val());
            min = parseFloat($(element).attr('mincost'));
            max = parseFloat($(element).attr('maxcost'));
            if (e.type === 'keyup' && price < min) {
                return;
            }
            charCode = e.charCode || e.keyCode || e.which || 0;
            if (e.type === 'keyup' && (price < max && (!price.toString().match(/\./) && (charCode === 44 || charCode === 46 || e.key === '.')))) {
                return;
            }
            valid_price = this.getValidPrice(price, min, max);
            if (valid_price !== price) {
                return $(element).val(roundPrice(valid_price));
            }
        },
        getValidPrice: function (price, min, max) {
            if (isNaN(price) || price < min) {
                return min;
            } else if (price > max) {
                return max;
            } else {
                return roundPrice(price);
            }
        },
        initValidator: function () {
            var _this;
            _this = this;
            this.validator = $('form.session_form').validate({
                rules: {
                    'session[title]': {
                        required: true,
                        minlength: 5,
                        maxlength: 70
                    },
                    'session[custom_description_field_value]': {
                        required: false,
                        minlength: 5,
                        maxlength: 2000
                    },
                    'session[ffmpegservice_account_id]': {
                        required: ['rtmp', 'ipcam'].includes(this.model.get('service-type')),
                    }
                },
                ignore: '.ignore, [type=email]',
                focusCleanup: true,
                focusInvalid: false,
                errorElement: 'div',
                errorClass: 'errorContainer',
                errorPlacement: function (error, element) {
                    var error_container;
                    var organization = _this.model.get('organization').multiroom_enabled;
                    var device_type = _this.model.get('device_type');
                    if ($(element).is('#ffmpegservice_account_id')) {
                        if (device_type == 'studio_equipment' || device_type == 'ipcam') {
                            if (organization.multiroom_enabled) {
                                $('#multiroom-device').addClass('error');
                                $('.ffmpegservice_account_validation_message .required-message').hide();
                                $('.ffmpegservice_account_validation_message .error-message').removeClass('hidden').show();
                            } else {
                                _this.streamSettings_expand();
                                if ('ipcam' == device_type) {
                                    error_message = 'IP Camera is not configured yet. Click "Enable" button and setup your stream settings to start using IP Camera.';
                                } else {
                                    error_message = 'Encoder is not enabled yet. Click "Enable" button and configure your equipment to start using encoder.';
                                }
                                return $.showFlashMessage(error_message, {
                                    type: 'error',
                                    timeout: 6000
                                });
                            }
                        }
                    } else {
                        error_container = element.parents('.input-block, .select-block').find('.errorContainerWrapp');
                        if (error_container.length) {
                            return error.appendTo(error_container);
                        } else {
                            return $.showFlashMessage(error.text(), {
                                type: 'error',
                                timeout: 6000
                            });
                        }
                    }
                },
                highlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-block');
                    if (wrapper.length) {
                        return wrapper.addClass('error').removeClass('valid');
                    } else {
                        return $(element).addClass('error').removeClass('valid');
                    }
                },
                unhighlight: function (element) {
                    var wrapper;
                    $(element).removeClass('error').addClass('valid');
                    wrapper = $(element).parents('.input-block, .select-block');
                    return wrapper.removeClass('error').addClass('valid');
                },
                showErrors: function (errorMap, errorList) {
                    this.defaultShowErrors();
                    if (!_this.isValid()) {
                        return $('#sessionAboutEdit').modal('show');
                    }
                }
            });
        },
        startAtLimit: function () {
            var endDate;
            if (typeof (this.subscription) == 'object') {
                if (this.subscription.service_status == 'active' || this.subscription.service_status == 'trial') {
                    endDate = new Date(this.subscription.current_period_end);
                } else if (this.subscription.service_status == 'grace') {
                    var grace_at = new Date(this.subscription.grace_at);
                    var grace_days = _.find(this.feature_parameters, function (fp) {
                        return fp.code == 'grace_days';
                    }).value
                    endDate = moment(grace_at).add(grace_days, 'days').toDate();
                }
            } else {
                endDate = moment().add(2, 'months').toDate();
            }
            return endDate;
        },
        initDatepicker: function () {
            var model, startDate, endDate, timeFormat;
            startDate = moment().toDate();
            endDate = this.startAtLimit();
            model = this.model;
            this.$(".RecurrenceOptions_datePicker").datepicker({
                minDate: startDate,
                maxDate: endDate,
                numberOfMonths: 1
            });
            this.$('#session_start_at_datepicker').datepicker({
                showOn: 'both',
                minDate: startDate,
                maxDate: endDate,
                onSelect: function () {
                    var date;
                    date = $('#session_start_at_datepicker').datepicker('getDate');
                    $('[id*=start_at_1i]').val(date.getFullYear());
                    model.set({
                        start_at_year: date.getFullYear()
                    });
                    $('[id*=start_at_2i]').val(date.getMonth() + 1);
                    model.set({
                        start_at_month: date.getMonth() + 1
                    });
                    $('[id*=start_at_3i]').val(date.getDate());
                    model.set({
                        start_at_day: date.getDate()
                    });
                    return;
                }
            });
            this.$('#session_start_at_datepicker').datepicker('setDate', new Date(this.model.get('start_at_date')));
            this.$('button.ui-datepicker-trigger').hide();
            timeFormat = Immerss.timeFormat === '12hour' ? 'hh:mm p' : 'HH:mm';
        },
        focusInput: function (e) {
            return $(e.currentTarget).parents('.input-block').addClass('state-derty').removeClass('state-clear');
        },
        unfocusInput: function (e) {
            if (($(e.currentTarget).val() || $(e.currentTarget).text()).length === 0) {
                return $(e.currentTarget).parents('.input-block').addClass('state-clear').removeClass('state-derty');
            }
        },
        setRecorded: function () {
            var is_recorded;
            is_recorded = this.$('#session_record').is(':checked');
            this.model.set({
                record: is_recorded
            });
            if (is_recorded) {
                if (this.model.get('immersive')) this.$('.Rlayout').show();
                this.$('#layout-grid-switch').prop('checked', true);
                this.$('#toggle_recorded_modal').removeAttr('onclick').removeAttr('disabled').removeClass('disabled');
                if (this.model.get('can_change_recorded_access_cost')) {
                    this.$('#set_recorded_price_btns, #set_recorded_price_btns a').removeAttr('disabled').removeClass('disabled');
                }
                this.$('#session_recorded_free_set').removeAttr('disabled').removeClass('disabled');
                if (!this.$('[name*=recorded_access_cost]').val()) {
                    this.model.set({
                        recorded_free: true,
                        recorded_access_cost: 0.0
                    });
                    this.$('a#session_recorded_free_set').addClass('active');
                    this.$('a#session_recorded_paid_set').removeClass('active');
                    this.$('#session_recorded_paid_set').html('Set Price');
                    this.$('[name*=recorded_free]').val(1);
                    this.$('[name*=recorded_access_cost]').val(0.0);
                }
            } else {
                this.$('.Rlayout').hide();
                this.$('#set_recorded_price_btns, #session_recorded_free_set, #session_recorded_paid_set').attr('disabled', true).addClass('disabled');
                this.$('[name*=recorded_free]').val(0);
                this.$('[name*=recorded_access_cost]').val(null);
                this.$('#toggle_recorded_modal').attr('onclick', 'return false;').attr('disabled', true).addClass('disabled');
            }
            return false;
        },
        setRecordingLayout: function () {
            var layout;
            layout = this.$('.Rlayout__check:checked').val();
            if (layout) {
                this.model.set({
                    recording_layout: layout
                });
            }
            return false;
        },
        setLivestreamFree: function () {
            if (this.$('a#session_livestream_free_set').hasClass('active')) {
                return false;
            }
            this.model.set({
                livestream_free: true,
                livestream_access_cost: 0.0
            });
            this.checkFreeSessionsCount();
            this.$('a#session_livestream_free_set').addClass('active');
            this.$('a#session_livestream_paid_set').removeClass('active');
            this.$('#LivestreamPricePopup').addClass('hide').parents('.tooltipWrapp').removeClass('tooltipShow');
            this.$('#session_livestream_paid_set').html('Set Price');
            this.$('[name*=livestream_free]').val(1);
            return false;
        },
        setImmersiveFree: function () {
            if (this.$('a#session_immersive_free_set').hasClass('active')) {
                return false;
            }
            this.model.set({
                immersive_free: true,
                immersive_access_cost: 0.0
            });
            this.checkFreeSessionsCount();
            this.$('a#session_immersive_free_set').addClass('active');
            this.$('a#session_immersive_paid_set').removeClass('active');
            this.$('#ImmersivePricePopup').addClass('hide').parents('.tooltipWrapp').removeClass('tooltipShow');
            this.$('#session_immersive_paid_set').html('Set Price');
            this.$('[name*=immersive_free]').val(1);
            return false;
        },
        setRecordedFree: function () {
            if (this.$('a#session_recorded_free_set').hasClass('active')) {
                return false;
            }
            this.model.set({
                recorded_free: true,
                recorded_access_cost: 0.0
            });
            this.$('a#session_recorded_free_set').addClass('active');
            this.$('a#session_recorded_paid_set').removeClass('active');
            this.$('#RecordedPricePopup').addClass('hide').parents('.tooltipWrapp').removeClass('tooltipShow');
            this.$('#session_recorded_paid_set').html('Set Price');
            this.$('[name*=recorded_free]').val(1);
            return false;
        },
        setLivestreamPaid: function () {
            var btn;
            btn = this.$('a#session_livestream_paid_set');
            if (!btn.hasClass('active')) {
                btn.addClass('active');
                this.$('a#session_livestream_free_set').removeClass('active');
                this.model.set({
                    livestream_free: false,
                    livestream_access_cost: livestreamMinCost(this.model.get('duration'))
                });
            }
            this.checkFreeSessionsCount();
            this.$('[name*=livestream_free]').val(0);
            this.renderLivestreamPricePopup();
            this.$('#LivestreamPricePopup').toggleClass('hide').parents('.tooltipWrapp').toggleClass('tooltipShow');
            this.$('#livestream_total_cost').trigger('change');
            return false;
        },
        setImmersivePaid: function () {
            var btn;
            btn = this.$('a#session_immersive_paid_set');
            if (!btn.hasClass('active')) {
                btn.addClass('active');
                this.$('a#session_immersive_free_set').removeClass('active');
                this.model.set({
                    immersive_free: false,
                    immersive_access_cost: immersiveMinCost(this.model.get('duration'))
                });
            }
            this.checkFreeSessionsCount();
            this.$('[name*=immersive_free]').val(0);
            this.renderImmersivePricePopup();
            this.$('#ImmersivePricePopup').toggleClass('hide').parents('.tooltipWrapp').toggleClass('tooltipShow');
            this.$('#immersive_total_cost').trigger('change');
            return false;
        },
        setRecordedPaid: function () {
            var btn;
            btn = this.$('a#session_recorded_paid_set');
            if (!btn.hasClass('active')) {
                btn.addClass('active');
                this.$('a#session_recorded_free_set').removeClass('active');
                this.model.set({
                    recorded_free: false,
                    recorded_access_cost: recordedMinCost(this.model.get('duration'))
                });
            }
            this.$('[name*=recorded_free]').val(0);
            this.renderRecordedPricePopup();
            this.$('#RecordedPricePopup').toggleClass('hide').parents('.tooltipWrapp').toggleClass('tooltipShow');
            this.$('#recorded_total_cost').trigger('change');
            return false;
        },
        setActiveSourceButton: function (e) {
            e.preventDefault();
            var button_clicked = $(e.target);
            var section = button_clicked.data('target');
            $('.btn-stream-source').removeClass('active').addClass('btn-borderred-grey');
            $('.source-details').removeClass('active').addClass('hidden');
            button_clicked.addClass('active').removeClass('btn-borderred-grey');
            if (section) {
                $(section).addClass('active').removeClass('hidden');
            }
        },
        setDeviceType: function (e) {
            this.model.set({
                device_type: $(e.target).data('value')
            });
            this.model.set({
                service_type: $(e.target).data('service-type')
            });
            if (this.model.get('device_type') === 'mobile') {
                this.$('#session_set_start_now').attr('disabled', true).addClass('disabled');
                this.$('#session_set_start_now').attr('onclick', 'return false;');
                if (!this.$('#session_set_start_at').hasClass('active')) {
                    this.setStartAt();
                }
            } else {
                this.$('#session_set_start_now').removeAttr('disabled').removeClass('disabled');
                this.$('#session_set_start_now').removeAttr('onclick');
            }
            return false;
        },
        showValue: function (e) {
            var input;
            input = $(e.currentTarget).data('id');
            $(e.currentTarget).toggleClass('active');
            if (this.$("#" + input).attr('type') === 'text') {
                this.$("#" + input).attr('type', 'password');
            } else {
                this.$("#" + input).attr('type', 'text');
            }
            return false;
        },
        enableEncoder: function (e) {
            $.ajax({
                url: Routes.create_ffmpegservice_accounts_path({
                    organization_id: this.model.get('organization_id'),
                    service_type: 'rtmp'
                }),
                type: 'POST',
                dataType: 'json',
                beforeSend: (function (_this) {
                    return function () {
                        $(e.target).addClass('disabled').attr('disabled', true);
                        return $(e.target).text('Processing...');
                    };
                })(this),
                success: (function (_this) {
                    return function (data) {
                        var options;
                        _this.wa_rtmp = data;
                        _this.$('#ffmpegservice_account_id').val(data.id);
                        _this.model.set({ffmpegservice_account: data});
                        _this.model.set({ffmpegservice_account_id: data.id});
                        options = _this.encoder_template({
                            wa_rtmp: _this.wa_rtmp
                        });
                        _this.$('#Encoder_section').html(options);
                        return _this.$el.find('.thoplayer_rtmp_off').show();
                    };
                })(this),
                error: function (data, error) {
                    return $.showFlashMessage(data.responseText || data.statusText, {
                        type: 'error'
                    });
                },
                complete: (function (_this) {
                    return function () {
                        $(e.target).removeClass('disabled').removeAttr('disabled');
                        return $(e.target).text('Enable');
                    };
                })(this)
            });
            return false;
        },
        enableIpcam: function (e) {
            var that = this;
            $.ajax({
                url: Routes.create_ffmpegservice_accounts_path({
                    organization_id: this.model.get('organization_id'),
                    service_type: 'ipcam'
                }),
                data: {ipcam_url: this.model.get('ipcam_url')},
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    $(e.target).addClass('disabled').attr('disabled', true);
                    $(e.target).text('Processing...');
                    $('#Change_IP_Camera_url_modal').modal('hide');
                },
                success: function (data) {
                    var options;
                    that.wa_ipcam = data;
                    that.$('#ffmpegservice_account_id').val(data.id);
                    that.model.set({ffmpegservice_account: data});
                    that.model.set({ffmpegservice_account_id: data.id});
                    options = that.ipcam_info_template({
                        wa_ipcam: that.wa_ipcam
                    });
                    that.$el.find('#IP_Camera').html(options);
                    options = that.ipcam_modal_template({
                        wa_ipcam: that.wa_ipcam
                    });
                    that.$el.find('#IP_Camera_modal').html(options);
                    that.$el.find('.thoplayer_ipcam_off').show();
                },
                error: function (data, error) {
                    $.showFlashMessage(data.responseText || data.statusText, {type: 'error'});
                },
                complete: function () {
                    that.closeModal();
                    $(e.target).removeClass('disabled').removeAttr('disabled');
                    $(e.target).text('Enable');
                }
            });
            return false;
        },
        startEncoder: function (e) {
            var that = this;
            $.ajax({
                url: Routes.start_stream_ffmpegservice_account_path(this.model.get('ffmpegservice_account_id')),
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    $(e.target).addClass('disabled').attr('disabled', true);
                    $(e.target).text('Processing...');
                    $(e.target).addClass('btn-grey-solid');
                },
                success: function (data) {
                    that.$el.find('.thoplayer_rtmp_off .step2').show();
                    that.$el.find('.thoplayer_rtmp_off#start_encoder_stream').hide();
                    that.$el.find('.thoplayer_rtmp_on#stop_encoder_stream').show();
                },
                error: function (data, error) {
                    $.showFlashMessage(data.message || data.statusText, {type: 'error'});
                },
                complete: function () {
                    $(e.target).removeClass('disabled').removeAttr('disabled');
                    $(e.target).text('Test stream');
                    $(e.target).removeClass('btn-grey-solid');
                }
            });
            return false;
        },
        stopEncoder: function (e) {
            var that = this;
            $.ajax({
                url: Routes.stop_stream_ffmpegservice_accounts_path(this.model.get('ffmpegservice_account_id')),
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    $(e.target).addClass('disabled').attr('disabled', true);
                    $(e.target).text('Processing...');
                    $(e.target).addClass('btn-grey-solid');
                },
                success: function (data) {
                    that.$el.find('.thoplayer_rtmp_off').show();
                    that.$el.find('.thoplayer_rtmp_on').hide();
                },
                error: function (data, error) {
                    $.showFlashMessage(data.message || data.statusText, {type: 'error'});
                },
                complete: function () {
                    $(e.target).removeClass('disabled').removeAttr('disabled');
                    $(e.target).text('Stop Stream');
                    $(e.target).removeClass('btn-grey-solid');
                }
            });
            return false;
        },
        startIpcam: function (e) {
            var that = this;
            $.ajax({
                url: Routes.start_stream_ffmpegservice_account_path(this.model.get('ffmpegservice_account_id')),
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    $(e.target).addClass('disabled').attr('disabled', true);
                    $(e.target).text('Processing...');
                },
                success: function (data) {
                    that.$el.find('.thoplayer_ipcam_off .step2').show();
                    that.$el.find('.thoplayer_ipcam_off#start_ipcam_stream').hide();
                    that.$el.find('.thoplayer_ipcam_on#stop_ipcam_stream').show();
                },
                error: function (data, error) {
                    $.showFlashMessage(data.message || data.statusText, {type: 'error'});
                },
                complete: function () {
                    $(e.target).removeClass('disabled').removeAttr('disabled');
                    $(e.target).text('Test stream');
                }
            });
            return false;
        },
        stopIpcam: function (e) {
            var that = this;
            $.ajax({
                url: Routes.stop_stream_ffmpegservice_accounts_path(this.model.get('ffmpegservice_account_id')),
                data: "ipcam_url=" + (this.model.get('ipcam_url')),
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    $(e.target).addClass('disabled').attr('disabled', true);
                    $(e.target).text('Processing...');
                },
                success: function (data) {
                    that.$el.find('.thoplayer_ipcam_off').show();
                    that.$el.find('.thoplayer_ipcam_on').hide();
                },
                error: function (data, error) {
                    $.showFlashMessage(data.message || data.statusText, {type: 'error'});
                },
                complete: function () {
                    $(e.target).removeClass('disabled').removeAttr('disabled');
                    $(e.target).text('Stop stream');
                }
            });
            return false;
        },
        setIpcamUrl: function (e) {
            return this.model.set({
                ipcam_url: this.$('#IP_Camera_url').val()
            });
        },
        ipCamChangeUrlEnabled: function (e) {
            this.$('.bluriInput_btn').toggleClass('active');
            this.$('.blurInput').toggleClass('active');
            return false;
        },
        proceed_to_step_2: function (e) {
            this.$('.block_1_btns, .block_2_btns').toggleClass('hide');
            this.$('.block_1, .block_2').toggleClass('hide');
            return false;
        },
        Edit_Url_modal_Show: function (e) {
            this.$('#Change_IP_Camera_url_modal').modal('show');
        },
        closeModal: function (e) {
            $('body').removeClass('modal-open');
            this.$('.block_1_btns, .block_2_btns').toggleClass('hide');
            this.$('.block_1, .block_2').toggleClass('hide');
            return false;
        },
        setLivePreview: function () {
            var options, select;
            select = this.$('#live_preview');
            options = this.live_preview_template({
                device_type: this.model.get('device_type'),
                stream_m3u8_url: this.model.get('stream_m3u8_url')
            });
            select.html(options);
            return select.trigger('change');
        },
        setParticipantsCount: function () {
            this.model.set({
                max_number_of_immersive_participants: this.$('#session_max_number_of_immersive_participants').val()
            });
        },
        setPublic: function (e) {
            this.model.set({private: false});
            this.checkFreeSessionsCount();
            $(e.target).addClass('active');
            $('#session_set_private').removeClass('active');
            $('#session_private').val(false);
            return false;
        },
        setPrivate: function (e) {
            this.model.set({private: true});
            this.checkFreeSessionsCount();
            $(e.target).addClass('active');
            $('#session_set_public').removeClass('active');
            $('#session_private').val(true);
            return false;
        },
        setAge13: function (e) {
            $(e.target).parents('.ages').find('.active').removeClass('active');
            $(e.target).addClass('active');
            this.model.set({
                age_restrictions: 0,
                adult: false
            });
            this.$('#session_age_restrictions').val(0);
            this.$('#session_adult').parents('label').hide();
            return false;
        },
        setAge18: function (e) {
            $(e.target).parents('.ages').find('.active').removeClass('active');
            $(e.target).addClass('active');
            this.model.set({
                age_restrictions: 1,
                adult: true
            });
            this.$('#session_age_restrictions').val(1);
            this.$('#session_adult').parents('label').show();
            return false;
        },
        toggleAdult: function (e) {
            var is_adult;
            is_adult = this.$('#session_adult').is(':checked');
            this.model.set({
                adult: is_adult
            });
            if (is_adult) {
                this.$('#session_set_13').attr('disabled', true).addClass('disabled').removeClass('active');
                this.$('#session_set_18').addClass('active');
                this.$('#session_age_restrictions').val(1);
                return this.model.set({
                    age_restrictions: 1
                });
            } else {
                return this.$('#session_set_13').removeAttr('disabled').removeClass('disabled');
            }
        },
        setStartNow: function () {
            var btn;
            btn = this.$('#session_set_start_now');
            if (btn.hasClass('active')) {
                return;
            }
            this.model.set({
                start_now: true
            });
            this.$('#session_start_now').val(true);
            this.$('#session_set_start_at').removeClass('active');
            this.$('#start_at_section').addClass('hidden');
            btn.addClass('active');
            this.$('button[type=submit]').text('Go Live');
            $('.RecurrenceSection').hide();
            return false;
        },
        setStartAt: function () {
            var btn;
            btn = this.$('#session_set_start_at');
            if (btn.hasClass('active')) {
                return;
            }
            this.model.set({
                start_now: false
            });
            this.$('#session_start_now').val(false);
            this.$('#session_set_start_now').removeClass('active');
            this.$('#start_at_section').removeClass('hidden');
            btn.addClass('active');
            if (this.model.get('id')) {
                this.$('button[type=submit]').text('Update');
            } else {
                this.$('button[type=submit]').text('Schedule live stream');
            }
            $('#recurring_settings-swith').prop('checked', false);
            $('.RecurrenceSection').show();
            $('.RecurrenceOptions').hide();
            return false;
        },
        setAutoStart: function () {
            this.model.set({
                autostart: true
            });
            this.$('#session_autostart, #session_manual').toggleClass('active');
            return false;
        },
        setManualStart: function () {
            this.model.set({
                autostart: false
            });
            this.$('#session_autostart, #session_manual').toggleClass('active');
            return false;
        },
        toggleChat: function () {
            return this.model.set({
                allow_chat: this.$('[name*=allow_chat]').is(':checked')
            });
        },
        setSessionList: function () {
            var val;
            if (!this.$('#replay_list').val().length) {
                this.$('#replay_list').val(this.$('#session_list').val());
                this.$('#replay_list').trigger('change');
            }
            val = this.$('#session_list').val().length ? [this.$('#session_list').val()] : [];
            return this.model.set({
                list_ids: val
            });
        },
        checkEcommerceOptionState: function () {
            if (this.model.get('list_ids').length === 0) {
                this.$('[name*=ecommerce]').attr('checked', false);
                return this.$('[href="#eCommerce_modal"]').attr('disabled', true).addClass('disabled').attr('onclick', 'return false');
            }
        },
        switchEcommerceOption: function () {
            if (this.$('[name*=ecommerce]').is(':checked')) {
                this.$('[href="#eCommerce_modal"]').removeAttr('disabled').removeClass('disabled').removeAttr('onclick');
                this.$('#session_list').val(this.model.get('list_ids')[0]);
                return this.$('#eCommerce_modal').modal('show');
            } else {
                this.$('#session_list, #replay_list').val('');
                return this.$('[href="#eCommerce_modal"]').attr('disabled', true).addClass('disabled').attr('onclick', 'return false');
            }
        },
        renderInviteModal: function () {
            if (window.invite_modal) {
                return window.invite_modal.render();
            }
        },
        setTitle: function (e) {
            return this.model.set({
                title: e.currentTarget.value
            });
        },
        setDescription: function (e) {
            var ready;
            this.model.set({description: this.editor.root.innerHTML});
            this.$('input[name="session[description]"]').val(this.editor.root.innerHTML)
            ready = this.editor.root.innerHTML.length > 0;
            this.$('a.toggle_section.description .VideoClientIcon-checkmark').toggleClass('hidden', !ready);
        },
        setInstructions: function (e) {
            var ready;
            this.model.set({instructions: this.instructionsEditor.root.innerHTML});
            this.$('input[name="session[custom_description_field_value]"]').val(this.instructionsEditor.root.innerHTML)
            ready = this.instructionsEditor.root.innerHTML > 0
            this.$('a.toggle_section.instructions').toggleClass('btn-withIcon', ready);
            this.$('a.toggle_section.instructions .VideoClientIcon-checkmark').toggleClass('hidden', !ready);
        },
        checkDescriptionOptionState: function () {
            if (this.model.get('description') === null || this.model.get('description').length === 0) {
                this.$('.description_switch').attr('checked', false);
                return this.$('[href="#Description_modal"]').attr('disabled', true).toggleClass('disabled', true).attr('onclick', 'return false');
            }
        },
        setHours: function () {
            var val;
            val = parseInt(this.$('#session_start_at_4i').val());
            return this.model.set({
                start_at_hours: val
            });
        },
        setMinutes: function () {
            var val;
            val = parseInt(this.$('#session_start_at_5i').val());
            return this.model.set({
                start_at_minutes: val
            });
        },
        setPreTime: function () {
            var val;
            val = parseInt(this.$('#session_pre_time').val());
            return this.model.set({
                pre_time: val
            });
        },
        recurringSettingsToggle: function (e) {
            if ($(e.target).is(':checked')) {
                return $('#RecurrenceOptions').show();
            } else {
                return $('#RecurrenceOptions').hide();
            }
        },
        productsToggle: function (e) {
            if ($(e.target).is(':checked')) {
                return $('#ProductsOptions').show();
            } else {
                return $('#ProductsOptions').hide();
            }
        },
        RecurrenceOptions_After_active: function (e) {
            if ($(e.target).is(':checked')) {
                $('#occurenceNumber_input').prop('disabled', false);
                return $('.RecurrenceOptions_datePicker').prop('disabled', true);
            }
        },
        RecurrenceOptions_On_active: function (e) {
            if ($(e.target).is(':checked')) {
                $('#occurenceNumber_input').prop('disabled', true);
                return $('.RecurrenceOptions_datePicker').prop('disabled', false);
            }
        },
        setLivestreamPrice: function (e) {
            var access_cost, fee, revenue, total_cost;
            // this.formatNumber(e);
            fee = livestreamServiceFee(this.model.get('duration'));
            total_cost = roundPrice(this.$('#livestream_total_cost').val());
            access_cost = roundPrice(total_cost - fee);
            revenue = roundPrice(access_cost * Immerss.revenueSplitMultiplier);
            this.model.set({
                livestream_access_cost: access_cost
            });
            this.$("[name='session[livestream_access_cost]']").val(access_cost);
            this.$('#livestream_revenue').val(revenue);
            this.$('#session_livestream_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                return $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        setImmersivePrice: function (e) {
            var access_cost, fee, revenue, total_cost;
            // this.formatNumber(e);
            fee = immersiveServiceFee(this.model.get('duration'));
            total_cost = roundPrice(this.$('#immersive_total_cost').val());
            access_cost = roundPrice(total_cost - fee);
            revenue = roundPrice((total_cost - fee) * Immerss.revenueSplitMultiplier);
            this.model.set({
                immersive_access_cost: access_cost
            });
            this.$("[name='session[immersive_access_cost]']").val(access_cost);
            this.$('#immersive_revenue').val(revenue);
            this.$('#session_immersive_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                return $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        setRecordedPrice: function (e) {
            var access_cost, fee, revenue, total_cost;
            // this.formatNumber(e);
            fee = recordedServiceFee(this.model.get('duration'));
            total_cost = roundPrice(this.$('#recorded_total_cost').val());
            access_cost = roundPrice(total_cost - fee);
            revenue = roundPrice((total_cost - fee) * Immerss.revenueSplitMultiplier);
            this.model.set({
                recorded_access_cost: access_cost
            });
            this.$("[name='session[recorded_access_cost]']").val(access_cost);
            this.$('#recorded_revenue').val(revenue);
            this.$('#session_recorded_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                return $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        setLivestreamPriceFromRevenue: function (e) {
            var access_cost, fee, revenue, total_cost;
            this.formatNumber(e);
            fee = livestreamServiceFee(this.model.get('duration'));
            revenue = this.$('#livestream_revenue').val();
            access_cost = roundPrice(revenue / Immerss.revenueSplitMultiplier);
            total_cost = roundPrice(access_cost + fee);
            this.model.set({
                livestream_access_cost: access_cost
            });
            this.$("[name='session[livestream_access_cost]']").val(access_cost);
            this.$('#livestream_total_cost').val(total_cost);
            this.$('#session_livestream_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        setImmersivePriceFromRevenue: function (e) {
            var access_cost, fee, revenue, total_cost;
            this.formatNumber(e);
            fee = immersiveServiceFee(this.model.get('duration'));
            revenue = this.$('#immersive_revenue').val();
            access_cost = roundPrice(revenue / Immerss.revenueSplitMultiplier);
            total_cost = roundPrice(access_cost + fee);
            this.model.set({
                immersive_access_cost: access_cost
            });
            this.$("[name='session[immersive_access_cost]']").val(access_cost);
            this.$('#immersive_total_cost').val(total_cost);
            this.$('#session_immersive_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        setRecordedPriceFromRevenue: function (e) {
            var access_cost, fee, revenue, total_cost;
            this.formatNumber(e);
            fee = recordedServiceFee(this.model.get('duration'));
            revenue = this.$('#recorded_revenue').val();
            access_cost = roundPrice(revenue / Immerss.revenueSplitMultiplier);
            total_cost = roundPrice(access_cost + fee);
            this.model.set({
                recorded_access_cost: access_cost
            });
            this.$("[name='session[recorded_access_cost]']").val(access_cost);
            if (total_cost) this.$('#recorded_total_cost').val(total_cost);
            this.$('#session_recorded_paid_set').html('$' + total_cost);
            if (e.keyCode === 13) {
                $(e.currentTarget).parents('.setPrice').addClass('hide');
                $('.tooltipShow').removeClass('tooltipShow');
            }
        },
        selectPresenter: function (e) {
            this.$('.ChanelPresenter ul li').removeClass('active');
            $(e.currentTarget).parents('li').addClass('active');
            this.setPresenter();
        },
        setPresenter: function () {
            var pid;
            pid = this.$('.ChanelPresenter ul li.active a').data('user-id');
            this.model.set({presenter_id: pid});
            if (this.$('.ChanelPresenter ul li').length > 1) {
                $('.ChanelPresenter i').removeClass('hidden');
                $('.ChanelPresenter').removeClass('noHover');
            } else {
                $('.ChanelPresenter i').addClass('hidden');
                $('.ChanelPresenter').addClass('noHover');
            }
            this.$('#session_presenter_id').val(pid);
            this.$('#selected_presenter_info').html(this.$('.ChanelPresenter ul li.active').html());
            this.setWa();
        },
        selectStreamingPlatform: function (e) {
            if (this.zoom_paid) {
                this.$('.streamingPlatform ul li').removeClass('active');
                $(e.currentTarget).addClass('active');
                this.$('#selected_streamingPlatform_info').html(this.$('.streamingPlatform ul li.active').html());
            }
            this.setStreamingPlatform();
        },
        setStreamingPlatform: function () {
            var streamingPlatform = this.$('.streamingPlatform ul li.active a').data('streaming-platform');
            var immersiveParticipantsCountEl = $('#session_max_number_of_immersive_participants');
            var immersiveParticipantsCountCount = immersiveParticipantsCountEl.val();

            if (!this.zoom_paid) {
                streamingPlatform = 'main'
            }
            if (streamingPlatform == 'main') {
                this.model.set({
                    device_type: 'studio_equipment',
                    service_type: 'rtmp'
                });

                $('.disabledSection label.checkbox').removeClass('hidden');
                $('.disabledSection').removeClass('disabledSection');
                $('.disabledSection__content').addClass('hidden');
                $('.controll-wrapper').removeClass('disabledSection__wrapper');
                $('.streamSettings__title').removeClass('hidden');
                $('.zoom_immersive_participants_count').addClass('hidden');
                $('#session_autostart, #session_manual').removeClass('disabled');
                this.setAutoStart();
                immersiveParticipantsCountEl.attr('max', Immerss.maxNumberOfWebrtcserviceParticipants);
                immersiveParticipantsCountEl.val(Immerss.maxNumberOfImmersiveParticipants);

                if (immersiveParticipantsCountCount > Immerss.maxNumberOfWebrtcserviceParticipants) {
                    immersiveParticipantsCountCount = Immerss.maxNumberOfWebrtcserviceParticipants;
                    immersiveParticipantsCountEl.val(immersiveParticipantsCountCount)
                    this.model.set({
                        max_number_of_immersive_participants: immersiveParticipantsCountCount
                    });
                    this.$('.numberOfSlots a.select2-choice span.select2-chosen').html(immersiveParticipantsCountCount);
                }
            } else if (streamingPlatform == 'zoom') {
                $('.disabled-zoom-option').addClass('disabledSection');
                $('.disabled-zoom-option .disabledSection__content').removeClass('hidden');
                $('.disabled-zoom-option .controll-wrapper').addClass('disabledSection__wrapper');
                $('.disabled-zoom-option label.checkbox').addClass('hidden');
                $('.disabled-zoom-option .streamSettings__title').addClass('hidden');
                $('.zoom_immersive_participants_count').removeClass('hidden');
                $('#session_autostart, #session_manual').addClass('disabled');
                this.setManualStart();
                immersiveParticipantsCountEl.attr('max', Immerss.maxNumberOfZoomParticipants);
                immersiveParticipantsCountEl.val(Immerss.maxNumberOfZoomParticipants);
                this.$('#session_livestream').prop('checked', false);
                this.$('#session_immersive').prop('checked', true);
                this.$('#session_livestream').prop('checked', false);
                this.setImmersive();
                this.setLivestream();
                this.model.set({
                    device_type: 'zoom',
                    service_type: 'zoom',
                    livestream: false,
                    immersive: true,
                    max_number_of_immersive_participants: Immerss.maxNumberOfZoomParticipants
                });
            }
        },
        setWa: function () {
            if (!['webrtc', 'rtmp', 'ipcam', 'mobile'].includes(this.model.get('service_type'))) {
                this.unsetWa();
                return false
            }
            var data = {
                presenter_id: this.model.get('presenter_id'),
                channel_id: this.model.get('channel_id'),
                service_type: this.model.get('service_type'), // webrtc, webrtcservice, mobile, rtmp, ipcam
                id: this.model.get('ffmpegservice_account_id')
            }
            var that = this;
            var url = Routes.find_or_assign_ffmpegservice_accounts_path();
            var error_message = null;
            if ('rtmp' == data.service_type) {
                error_message = 'Encoder is not enabled yet. Click "Enable" button and configure your equipment to start using encoder.';
            } else if ('ipcam' == data.service_type) {
                error_message = 'IP Camera is not configured yet. Click "Enable" button and setup your stream settings to start using IP Camera.';
            }
            $.ajax({
                url: url,
                type: 'POST',
                data: data,
                dataType: 'json',
                success: function (data) {
                    that.$('#ffmpegservice_account_id').val(data.id);
                    that.model.set({ffmpegservice_account: data});
                    that.model.set({ffmpegservice_account_id: data.id});
                },
                error: function (data, error) {
                    that.$('#ffmpegservice_account_id').val('');
                    that.model.set({ffmpegservice_account: null});
                    that.model.set({ffmpegservice_account_id: null});
                    $.showFlashMessage(error_message || data.responseText || data.statusText, {type: 'error'});
                }
            });
        },
        unsetWa: function () {
            this.$('#ffmpegservice_account_id').val(null);
            this.model.set({ffmpegservice_account: null});
            this.model.set({ffmpegservice_account_id: null});
        },
        setFirstMultiroomWa: function () {
            this.clickFirstFfmpegserviceAccount();
        },
        setLivestream: function () {
            var is_livestream;
            is_livestream = this.$('#session_livestream').is(':checked');
            if (!this.getInteractiveParam()) {
                is_livestream = true
                this.$('#session_livestream').attr('checked', true).prop('checked', 'checked');
            }
            this.model.set({livestream: is_livestream, immersive: !is_livestream});
            if (is_livestream) {
                this.$('.Rlayout').hide();
                this.$('#camera_setting_webrtc').show();
                this.$('#camera_setting_webrtcservice').hide();
                this.$('#camera_setting_webrtc, #encoder_setting, #ipcamera_setting, #multiroom_setting').removeClass('disabled').removeAttr('disabled');
                this.$('#mobile_setting').addClass('disabled').attr('disabled', true);
                this.$('#session_immersive').attr('checked', false);
                this.$('#session_immersive').prop('checked', '').trigger('change');
                if (this.$('#multiroom_setting') && !this.$('#multiroom_setting').hasClass('active')) {
                    this.$('#multiroom_setting').click();
                } else if (this.$('#encoder_setting') && !this.$('#encoder_setting').hasClass('active')) {
                    this.$('#encoder_setting').click();
                }
                if (this.model.get('can_change_max_number_of_livestream_participants')) {
                    this.$('#session_max_number_of_livestream_participants').removeAttr('disabled').removeAttr('readonly').removeAttr('onclick');
                }
                this.$('#set_livestream_price_btns, #session_livestream_free_set').removeAttr('disabled').removeClass('disabled');
                if (!this.model.get('livestream_access_cost')) {
                    this.model.set({
                        livestream_free: true,
                        livestream_access_cost: 0.0,
                    });
                    this.$('[name*=livestream_free]').val(1);
                }
                this.$('[name*=livestream_access_cost]').val(this.model.get('livestream_access_cost'));
                if (this.model.get('can_change_livestream_access_cost')) {
                    this.$('#set_livestream_price_btns, #session_livestream_free_set, #session_livestream_paid_set').removeAttr('disabled').removeClass('disabled');
                }
            } else {
                if (this.model.get('record')) this.$('.Rlayout').show();
                this.$('#camera_setting_webrtc').hide();
                this.$('#camera_setting_webrtcservice').show();
                this.$('#session_max_number_of_livestream_participants').attr('disabled', true).attr('readonly', true).attr('onclick', 'return false');
                this.$('#set_livestream_price_btns, #session_livestream_free_set, #session_livestream_paid_set').attr('disabled', true).addClass('disabled');
                this.$('[name*=livestream_free]').val(0);
                this.$('[name*=livestream_access_cost]').val(null);
                if (!this.$('#session_immersive').is(':checked')) {
                    this.$('#session_immersive').attr('checked', true);
                    this.$('#session_livestream').attr('checked', false);
                    $('#session_immersive').prop('checked', 'checked').trigger('change');
                    $('#session_livestream').prop('checked', '').trigger('change');
                }
            }
        },
        setImmersive: function () {
            var is_immersive;
            if (this.model.get('service_type') == 'zoom' && !this.$('#session_immersive').is(':checked')) {
                this.$('#session_livestream').removeAttr('checked')
                this.$('#session_immersive').attr('checked', true)
                this.$('#session_immersive').prop('checked', 'checked').trigger('change');
                return false
            }
            is_immersive = this.$('#session_immersive').is(':checked');
            this.model.set({livestream: !is_immersive, immersive: is_immersive});
            if (is_immersive) {
                if (this.model.get('record')) this.$('.Rlayout').show();
                this.model.set({immersive_type: 'group'});
                if (this.model.get('service_type') != 'zoom') {
                    this.$('#camera_setting_webrtc').hide();
                    this.$('#camera_setting_webrtcservice').show();
                    this.$('#camera_setting_webrtcservice, #mobile_setting').removeClass('disabled').removeAttr('disabled');
                    this.$('#camera_setting_webrtcservice').click();
                    this.$('#encoder_setting, #ipcamera_setting, #multiroom_setting').addClass('disabled').attr('disabled', true);
                    this.$('#session_livestream').attr('checked', false);
                    this.$('#session_livestream').prop('checked', '').trigger('change');
                }
                if (this.model.get('can_change_max_number_of_immersive_participants')) {
                    this.$('#session_max_number_of_immersive_participants').removeAttr('disabled').removeAttr('readonly').removeAttr('onclick');
                }
                this.$('#set_immersive_price_btns, #session_immersive_free_set').removeAttr('disabled').removeClass('disabled');
                if (!this.model.get('immersive_access_cost')) {
                    this.model.set({
                        immersive_free: true,
                        immersive_access_cost: 0.0,
                    });
                    this.$('[name*=immersive_free]').val(1);
                }
                this.$('[name*=immersive_access_cost]').val(this.model.get('immersive_access_cost'));
                if (this.model.get('can_change_immersive_access_cost')) {
                    this.$('#set_immersive_price_btns, #session_immersive_free_set, #session_immersive_paid_set').removeAttr('disabled').removeClass('disabled');
                }
                this.checkFreeSessionsCount()
            } else {
                this.$('.Rlayout').hide();
                this.model.set({
                    immersive_type: null,
                    immersive_free: false,
                });
                this.$('#camera_setting_webrtc').show();
                this.$('#camera_setting_webrtcservice').hide();
                this.$('#encoder_setting, #ipcamera_setting').removeClass('disabled').removeAttr('disabled');
                this.$('#mobile_setting').addClass('disabled').attr('disabled', true);
                if (this.$('#encoder_setting') && !this.$('#encoder_setting').hasClass('active')) {
                    this.$('#encoder_setting').click();
                }
                this.$('#session_max_number_of_immersive_participants').attr('disabled', true).attr('readonly', true).attr('onclick', 'return false');
                this.$('#set_immersive_price_btns, #session_immersive_free_set, #session_immersive_paid_set').attr('disabled', true).addClass('disabled');
                this.$('[name*=immersive_free]').val(0);
                this.$('[name*=immersive_access_cost]').val(null);
                if (!this.$('#session_livestream').is(':checked')) {
                    this.$('#session_livestream').attr('checked', true);
                    $('#session_livestream').prop('checked', 'checked').trigger('change');
                }
            }
        },
        setCoHost: function () {
            this.model.set({co_hosts: this.$('#session_co_hosts').is(':checked')});
        },
        checkFreeSessionsCount: function () {
            if (!Immerss.canCreateFreePrivateSessionsWithoutPermission &&
                Immerss.freePrivateSessionsWithoutAdminApprovalLeftCount < 1 &&
                this.model.get('private') && this.model.get('immersive_access_cost') == 0) {
                $('.unobtrusive-flash-container').html('')
                $.showFlashMessage(I18n.t('sessions.free_limit_message'), {type: "error", timeout: 0})
            } else {
                $('.unobtrusive-flash-container').html('');
            }
        },
        checkDeviceTypeSelect: function () {
            var options, select;
            select = this.$('#session_device_type');
            options = this.service_types_options({
                immersive: this.model.get('immersive'),
                livestream: this.model.get('livestream'),
                co_hosts: this.model.get('co_hosts'),
                device_type: this.model.get('device_type')
            });
            select.html(options);
            select.trigger('change');
        },
        setChannel: function () {
            var channel_id, html, valid_presenter;
            channel_id = this.$('#session_channel_id').val();
            this.model.set({channel_id: channel_id});
            valid_presenter = false;
            $.each(this.channel_presenters[channel_id], (function (_this) {
                return function (i, presenter) {
                    if (presenter.id === _this.model.get('presenter_id')) {
                        valid_presenter = true;
                    }
                };
            })(this));
            if (!valid_presenter) {
                this.model.set({
                    presenter_id: this.channel_presenters[channel_id][0].id
                });
            }
            html = Handlebars.partials.PresentersOptions({
                channel_presenters: this.channel_presenters,
                channel_id: channel_id,
                presenter_id: this.model.get('presenter_id')
            });
            this.$('.ChanelPresenter ul').html(html);
            this.setOrganization();
            this.renderStreamSettings();
            return this.setPresenter();
        },
        setOrganization: function () {
            var channel_id;
            channel_id = this.model.get('channel_id');
            for (let channel of this.channels) {
                if (channel.id == channel_id) {
                    this.model.set({organization_id: channel.organization_id});
                    this.model.set({organization: this.organizations[channel.organization_id]});
                    break;
                }
            }
        },
        setDuration: function (value) {
            this.$('[name="session[duration]"]').val(value);
            this.model.set({
                duration: value
            });
            if (!this.model.get('livestream_free') && this.model.get('can_change_livestream')) {
                this.renderLivestreamPricePopup();
                this.$('#livestream_total_cost').trigger('change');
            }
            if (!this.model.get('immersive_free') && this.model.get('can_change_immersive')) {
                this.renderImmersivePricePopup();
                this.$('#immersive_total_cost').trigger('change');
            }
            if (!this.model.get('recorded_free') && this.model.get('can_change_recorded_access_cost')) {
                this.renderRecordedPricePopup();
                return this.$('#recorded_total_cost').trigger('change');
            }
        },
        durationChanged: function (e) {
            var duration;
            duration = Math.ceil(this.$('[name="session[duration]"]').val());
            this.setDuration(duration);
            this.$('#Duration_slider').slider('value', duration);
            return this.$('#Duration_slider_handle').text(duration);
        },
        validateBeforeSubmit: function () {
            if (this.model.get('device_type') == 'studio_equipment' && !this.model.get('ffmpegservice_account')) {
                $.showFlashMessage('Encoder is not enabled yet. Click "Enable" button and configure your equipment to start using encoder.', {
                    type: "error"
                });
                return false
            } else if (this.model.get('device_type') == 'ipcam' && !this.model.get('ffmpegservice_account')) {
                $.showFlashMessage('IP Camera is not configured yet. Click "Enable" button and setup your stream settings to start using IP Camera.', {
                    type: "error"
                });
                return false
            }
            return true
        },
        submitForm: function (event) {
            if (!this.validateBeforeSubmit())
                return false
            var data, method, url;
            var that = this;
            data = this.formData();
            method = this.$form.attr('method');
            url = this.$form.attr('action');
            $.ajax({
                url: url,
                data: data,
                type: method,
                processData: false,
                contentType: false,
                dataType: 'json',
                beforeSend: function () {
                    that.$form.find('.LoadingCover').removeClass('hide');
                },
                success: function (data) {
                    return window.location = data.path;
                },
                error: function (data, error) {
                    $.showFlashMessage(data.responseText || data.statusText, {
                        type: "error"
                    });
                    that.$form.find('.LoadingCover').addClass('hide');
                },
                complete: function () {
                }
            });
            return false;
        },
        formData: function () {
            var form_data;
            form_data = new FormData(this.$form[0]);
            if (this.thumbnail.get('image')) {
                _(this.thumbnail.toFormData()).each(function (data) {
                    return form_data.append.apply(form_data, data);
                });
            }
            _(this.getSessionData()).each(function (data) {
                return form_data.append.apply(form_data, data);
            });
            return form_data;
        },
        getSessionData: function () {
            var data;
            data = [];
            data.push(['session[level]', this.model.get('level')]);
            data.push(['session[presenter_id]', this.model.get('presenter_id')]);
            data.push(['session[autostart]', this.model.get('autostart')]);
            data.push(['session[device_type]', this.model.get('device_type')]);
            data.push(['session[duration]', this.model.get('duration')]);
            data.push(['session[service_type]', this.model.get('service_type')]);
            data.push(['session[immersive]', this.model.get('immersive')]);
            data.push(['session[livestream]', this.model.get('livestream')]);
            data.push(['session[record]', this.model.get('record')]);
            data.push(['session[recording_layout]', this.model.get('recording_layout')]);
            data.push(['session[device_type]', this.model.get('device_type')]);
            if (this.model.get('device_type') === 'ipcam') {
                data.push(['session[ipcam_url]', this.model.get('ipcam_url')]);
            }
            if (this.model.get('immersive') === true) {
                data.push(['session[immersive_type]', this.model.get('immersive_type')]);
            }
            if (this.original_session_id) {
                data.push(['original_session_id', this.original_session_id]);
            }
            return data;
        },
        saveError: function (e, a, b) {
            $('form.session_form .LoadingCover').addClass('hide');
        },
        onInitScripts: function () {
            $(window).on('mousedown keyup', function (event) {
                if (event.type === 'keyup' && event.keyCode !== 27 || event.type === 'mousedown' && event.button === 2) {
                    return;
                }
                if (event.type === 'mousedown' && $(event.target).data('tooltipToggle') === ("#" + ($('.tooltipBody:visible').attr('id')))) {
                    return;
                }
                $('.tooltipBody.setPrice:visible').addClass('hide');
                $('.tooltipShow').removeClass('tooltipShow');
            });
            $('.site-overlay').click(function () {
                return $('body').removeClass('pushy-active-left');
            });
            return $('.mobileShow').click(function () {
                return $('body').addClass('pushy-active-left');
            });
        },
        prepareDescription: function () {
            var options = {
                    debug: 'info',
                    modules: {toolbar: '#descriptionToolbar'},
                    theme: 'snow'
                },
                instructionsOptions = {
                    debug: 'info',
                    modules: {toolbar: '#instructionsToolbar'},
                    theme: 'snow'
                };
            this.editor = new Quill('#session_description', options);
            this.instructionsEditor = new Quill('#session_instructions', instructionsOptions);
            var that = this;
            this.editor.on('text-change', function () {
                that.checkVisitUrlValidation()
                that.setDescription()
            });
            this.instructionsEditor.on('text-change', function () {
                that.setInstructions()
            });
            this.checkLinks()
        },

        checkVisitUrlValidation() {
            var delta = this.editor.editor.delta
            var changed = false
            delta.ops.forEach(el => {
                if(el && el.attributes && el.attributes.link) {
                    if(!(el.attributes.link.includes("https://") || el.attributes.link.includes("http://"))) {
                        el.attributes.link = "https://" + el.attributes.link
                        changed = true
                    }
                }
            })
            if(changed)  {
                this.editor.setContents(delta)
                console.log("added https:// to links");
            }
        },

        checkLinks() {
            let inputTest = document.querySelector('.ql-tooltip input');
            if(inputTest) {
                inputTest.addEventListener('input', (event) => { validateLinks(event) })
                inputTest.addEventListener('focus', (event) => { validateLinks(event) })
                inputTest.addEventListener('blur', (event) => { clearLinks(event) })
            }
        },

        prepareForm: function () {
            var $submitButton, $view;
            this.$form = $('form.session_form');
            $submitButton = this.$form.find('button[type=submit]');
            $view = this;
            this.$form.on('submit.time_overlap', function (event) {
                var params, url;
                if (!$view.isValid()) {
                    return false;
                }
                event.preventDefault();
                url = $(this).attr('action') + '/pre_time_overlap.json';
                params = _.inject($view.$form.serializeArray(), function (res, val) {
                    res[val.name] = val.value;
                    return res;
                }, {});
                delete params._method;
                return $.post(url, params).success(function (response) {
                    var sessions;
                    sessions = new window.AbstractSessions(response, {
                        silent: false,
                        objectForm: $view.$form,
                        url: url
                    });
                    if (sessions.isCurrentHasOverlap()) {
                        new window.SessionsView({
                            collection: sessions
                        });
                        $view.$form.find('.LoadingCover').addClass('hide');
                        $('#session_set_start_at').click();
                    } else {
                        $view.$form.unbind('submit.time_overlap');
                        $view.$form.on('submit', function (event) {
                            return $view.submitForm(event);
                        });
                        return $view.$form.submit();
                    }
                }).complete(function () {
                    return $submitButton.removeAttr('disabled');
                }).error(function (xhr) {
                    if (xhr.status === 422) {
                        $.showFlashMessage(xhr.responseJSON.message, {type: 'error'});
                        return $view.$form.find('.LoadingCover').addClass('hide');
                    } else {
                        $view.$form.unbind('submit.time_overlap');
                        $view.$form.on('submit', function (event) {
                            return $view.submitForm(event);
                        });
                        return $view.$form.submit();
                    }
                });
            });
            this.$form.on('error', (function (_this) {
                return function (e, a, b) {
                    return _this.$form.find('.LoadingCover').addClass('hide');
                };
            })(this));
        },
        afterRender: function () {
            var $stickySubmit, $topLine, $topLineWrapp, TopOfset, setBtnPOs;
            var $stickyLabel;
            $stickySubmit = $('.topLine .btn');
            $stickyLabel = $('.topLine span');
            TopOfset = $('.header.responsive.fixed-top').height() - 19;
            $topLine = $('.topLine');
            $topLineWrapp = $('.topLine_wrapp');
            $(window).resize(function () {
                return setBtnPOs();
            });
            $(window).scroll(function () {
                return setBtnPOs();
            });
            setBtnPOs = function () {
                var $tp_w_offset, $tp_w_width, stickySubmitRight, windowWidth;
                var stickySubmitLeft;
                $tp_w_offset = $topLineWrapp.offset();
                $tp_w_width = $topLineWrapp.outerWidth();
                windowWidth = $(window).width();
                stickySubmitRight = windowWidth - ($tp_w_offset.left + $tp_w_width);
                stickySubmitLeft = windowWidth - ($tp_w_offset.left + $tp_w_width + 20);
                if ($(this).scrollTop() >= TopOfset) {
                    $stickySubmit.addClass('stickytop');
                    $stickySubmit.css('right', stickySubmitRight);
                    $stickyLabel.addClass('stickyLabel');
                    $stickyLabel.css('left', stickySubmitLeft);
                    return $topLine.addClass('stickyTopLine');
                } else {
                    $stickySubmit.removeClass('stickytop');
                    $stickyLabel.removeClass('stickyLabel');
                    return $topLine.removeClass('stickyTopLine');
                }
            };
            this.setOrganization();
            this.renderStreamSettings();
            this.setPresenter();
            $(document).on('show.bs.modal', function (event) {
                var $button, $modalTarget, blurMarker;
                $button = $(event.relatedTarget);
                blurMarker = $button.attr('data-blurMarker');
                $modalTarget = $(event.target);
                $('body').addClass(blurMarker);
                $modalTarget.attr('data-blurMarker', blurMarker);
                if ($('body').hasClass('pushy-active-left')) {
                    return $('body').removeClass('pushy-active-left');
                }
            });
            $('select').select2({
                minimumResultsForSearch: -1,
                formatResult: function (item) {
                    return $('<div>', {title: item.element[0].title}).text(item.text);
                },
            });
            return $(document).on('hide.bs.modal', function (event) {
                var $modalTarget, blurMarker;
                $modalTarget = $(event.target);
                blurMarker = $modalTarget.attr('data-blurMarker');
                $('body').removeClass(blurMarker);
                return $modalTarget.attr('data-blurMarker', '');
            });
        },
        getPrivateParam: function () {
            if (this.subscription == "split_revenue_plan") {
                return true
            } else if (this.feature_parameters && this.feature_parameters.length) {
                var res = _.find(this.feature_parameters, function (fp) {
                    return fp.code == 'private_sessions';
                })
                if(res) return res.value == 'true'
                else return false
            } else {
                return false
            }
        },
        getMaxDurationParam: function () {
            return _.find(this.feature_parameters, function (fp) {
                return fp.code == 'max_session_duration';
            }).value
        },
        getInteractiveParam: function () {
            if (this.subscription == "split_revenue_plan") {
                return true
            } else if (this.feature_parameters && this.feature_parameters.length) {
                return _.find(this.feature_parameters, function (fp) {
                    return fp.code == 'interactive_stream';
                }).value == 'true'
            } else {
                return false
            }
        },
        getInstreamShoppingParam: function () {
            if (this.subscription == "split_revenue_plan") {
                return true
            } else if (this.feature_parameters && this.feature_parameters.length) {
                return _.find(this.feature_parameters, function (fp) {
                    return fp.code == 'instream_shopping';
                }).value == 'true'
            } else {
                return false
            }
        },
        getMaxInteractiveParticipants: function () {
            if (this.subscription == "split_revenue_plan") {
                return this.model.get('max_number_of_immersive_participants_with_sources')
            } else if (this.feature_parameters && this.feature_parameters.length) {
                return _.find(this.feature_parameters, function (fp) {
                    return fp.code == 'max_interactive_participants';
                }).value
            } else {
                return 5
            }
        },
        initDurationSlider: function () {
            var is_immersive = this.$('#session_immersive').is(':checked');
            var id = this.model.get("id")
            var started = this.model.get("started")

            var that = this;
            var max_duration;
            if (this.subscription == "split_revenue_plan") {
                max_duration = Immerss.canCreateSessionsWithMaxDuration
            } else if (this.subscription.service_status == 'trial') {
                max_duration = 45
            } else {
                max_duration = this.getMaxDurationParam()
            }
            this.$('#Duration_slider').slider({
                value: this.model.get('duration'),
                step: 5,
                min: 15,
                max: max_duration,
                create: function () {
                    $('#Duration_slider_handle').text($(this).slider('value'));
                },
                slide: function (event, ui) {
                    if(is_immersive && id && started) {
                        $('#Duration_slider_handle').text(that.model.get('duration'));
                    }
                    else {
                        $('#Duration_slider_handle').text(ui.value);
                        that.setDuration(ui.value);
                    }
                }
            });

            if(is_immersive && id && started) {
                $('#Duration_slider').css("pointer-events", "none")
                $('#Duration_slider_handle').css("opacity", "0.3")
            }
        },
        handleRecurringDays: function (e) {
            if (this.$('[name="session[recurring_settings][days][]"]:checked').length === 0) {
                return $(e.target).prop('checked', true);
            }
        },
        load_clone_session: function (e) {
            var session_id = $(e.target).val();
            if (session_id == "0") {
                return window.location = Routes.sessions_new_path();
            }
            var channel_id = $(e.target).find(':selected').data('channel-id');
            return window.location = Routes.clone_channel_session_path(channel_id, session_id);
        },
        setInvitedUsersAttributes: function (users) {
            var data;
            this.users = users;
            data = JSON.stringify(this.users);
            this.$('[name*=invited_users_attributes]').val(data);
            this.model.set({
                invited_users_attributes: data
            });
            return this.$('.memberList').html(this.invited_user({
                users: this.users.toJSON(),
                users_count: this.users.length
            }));
        },
        streamSettings_toggle: function (e) {
            this.$('.streamSettings_B').toggle();
            $(e.target).toggleClass('active');
            return false;

        },
        streamSettings_expand: function (e) {
            this.$('.streamSettings_B').show();
            $('.streamSettings_toggle').addClass('active');
            return false;
        },
        switch_webcam: function (e) {
            if (this.$('#session_livestream').is(':checked')) {
                this.switch_webrtc();
            } else {
                this.switch_webrtcservice();
            }
        },
        switch_webrtc: function () {
            this.setWa();
            this.renderStreamSettings();
            this.setLivePreview();
        },
        switch_webrtcservice: function (e) {
            this.unsetWa();
            this.renderStreamSettings();
            this.setLivePreview();
        },
        switch_ipcam: function (e) {
            this.setWa();
            this.wa_ipcam = this.model.get('ffmpegservice_account');
            this.renderStreamSettings();
            this.streamSettings_expand();
        },
        switch_encoder: function (e) {
            this.setWa();
            this.wa_rtmp = this.model.get('ffmpegservice_account');
            this.renderStreamSettings();
            this.streamSettings_expand();
        },
        renderStreamSettings: function (e) {
            var organization = this.model.get('organization');
            var device_type = this.model.get('device_type') || 'webrtcservice';
            var isSessionImmersive = this.$('#session_immersive').is(':checked');
            if (!this.getInteractiveParam()) {
                isSessionImmersive = false;
                this.$('#session_livestream').attr('checked', true).prop('checked', 'checked');
            }
            this.model.set({livestream: !isSessionImmersive, immersive: isSessionImmersive});
            this.$('#streamSettings__wrapper').html(this.stream_settings_template({
                organization: organization,
                device_type: device_type,
                wa_rtmp: organization.wa_rtmp,
                wa_ipcam: organization.wa_ipcam,
                new_source_path: Routes.dashboard_video_sources_path()
            }));
            $('select').select2({
                minimumResultsForSearch: -1
            });
            if (organization.multiroom_enabled && (device_type == 'studio_equipment' || device_type == 'ipcam')) {
                // preselect first available WA
                var selected_ffmpegservice_account = this.$('.ffmpegservice_account_option').filter('[data-id="' + this.model.get('ffmpegservice_account_id') + '"]').first()
                if (!selected_ffmpegservice_account.length) {
                    selected_ffmpegservice_account = this.$('.ffmpegservice_account_option').filter('[data-device-type="' + device_type + '"]').first()
                }
                if (selected_ffmpegservice_account.length) {
                    selected_ffmpegservice_account.click();
                } else if (this.$('.ffmpegservice_account_option').length) {
                    this.$('.ffmpegservice_account_option').first().click();
                }
            }
            if (isSessionImmersive) {
                if (this.model.get('record')) this.$('.Rlayout').show();
                this.$('#camera_setting_webrtcservice').show();
                this.$('#camera_setting_webrtc').hide();
                this.$('#encoder_setting, #ipcamera_setting, #multiroom_setting').addClass('disabled').attr('disabled', true);
                this.model.set({
                    allow_chat: false
                })
                this.$('#encoder_setting, #ipcamera_setting, #multiroom_setting').removeClass('active');
            } else {
                this.$('.Rlayout').hide();
                this.$('#camera_setting_webrtc').show();
                this.$('#camera_setting_webrtcservice').hide();
                this.$('#mobile_setting').addClass('disabled').attr('disabled', true);
                this.$('#mobile_setting').removeClass('active');
            }
        },
        filter_studios: function (e) {
            var search = this.$('#studio-filter').val().toLowerCase(),
                studioOptions = this.$('.studio_option').not('.studio_option_all');

            studioOptions.show();
            if (search.length == 0) {
                return false;
            }
            studioOptions.not('[data-name*="' + search + '"]').not('.studio_option_all').hide();
            return false;
        },
        filter_studio_rooms: function (e) {
            var search = this.$('#studio-room-filter').val().toLowerCase(),
                studioRoomOptions = this.$('.studio_room_option').not('.studio_room_option_all').not('.studio_room_option_unassigned'),
                selectedStudioId = parseInt(this.$('.studio_option.active').data('id'));

            studioRoomOptions.show();

            if (!isNaN(selectedStudioId) && selectedStudioId != -1) {
                studioRoomOptions.not('[data-studio-id="' + selectedStudioId + '"]').hide();
            }

            if (search.length > 0) {
                studioRoomOptions.not('[data-name*="' + search + '"]').hide();
            }

            return false;
        },
        filter_ffmpegservice_accounts: function (e) {
            var search = this.$('#ffmpegservice-account-filter').val().toLowerCase(),
                ffmpegserviceAccountOptions = this.$('.ffmpegservice_account_option'),
                selectedStudioRoomId = parseInt(this.$('.studio_room_option.active').data('id'));

            ffmpegserviceAccountOptions.show();

            if (!isNaN(selectedStudioRoomId) && selectedStudioRoomId != -1) {
                ffmpegserviceAccountOptions.not('[data-studio-room-id="' + selectedStudioRoomId + '"]').hide()
            }

            if (search.length > 0) {
                ffmpegserviceAccountOptions.not('[data-name*="' + search + '"]').hide();
            }
            return false;
        },
        select_studio: function (e) {
            var selectedInput = this.$(e.target);
            this.$('.studio_option').removeClass('active');
            selectedInput.addClass('active');
            this.$('#studio-room-filter').trigger('change');
        },
        select_studio_room: function (e) {
            var selectedInput = this.$(e.target);
            this.$('.studio_room_option').removeClass('active');
            selectedInput.addClass('active');
            this.$('#ffmpegservice-account-filter').trigger('change');
            this.clickFirstVisibleFfmpegserviceAccount();
        },
        clickFirstFfmpegserviceAccount: function (e) {
            if (this.$('.ffmpegservice_account_option').length) {
                this.$('.ffmpegservice_account_option')[0].click();
            }
        },
        clickFirstVisibleFfmpegserviceAccount: function (e) {
            if (this.$('.ffmpegservice_account_option:visible').length) {
                this.$('.ffmpegservice_account_option:visible')[0].click();
            }
        },
        select_ffmpegservice_account: function (e) {
            var selectedInput = this.$(e.target);
            var selectedId = selectedInput.data('id');
            this.$('.ffmpegservice_account_option').removeClass('active');
            selectedInput.addClass('active');
            this.model.set({service_type: selectedInput.data('service-type')});
            this.model.set({device_type: selectedInput.data('device-type')});
            this.model.set({ffmpegservice_account_id: selectedId});
            this.$('#ffmpegservice_account_id').val(selectedId);
            this.$('#multiroom-device').removeClass('error');
            this.$('.ffmpegservice_account_validation_message .error-message').hide();
            this.$('.ffmpegservice_account_validation_message .required-message').show();
            this.setWa();
        },
        openShowSourceDetailsModal: function (e) {
            var organization = this.model.get('organization');

            if (organization && organization.sources) {
                var videoSourceId = $(e.target).parents('li').data('id');
                var videoSource = organization.sources.filter(function (videoSource) {
                    return videoSource.id == videoSourceId
                })[0]

                if (videoSource) {
                    var sourveIpCamEl = $('#show_video_source_modal .ipcam');
                    var sourveRtmpEl = $('#show_video_source_modal .rtmp');

                    var showModalDataSelectors = [
                        'name', 'source_url', 'server', 'port', 'stream_name', 'username', 'password'
                    ];
                    var equipmentFields = {
                        ipcam: ['name', 'source_url'],
                        rtmp: ['name', 'server', 'port', 'stream_name', 'username', 'password']
                    };

                    if (videoSource.current_service == 'ipcam') {
                        sourveIpCamEl.show();
                        sourveRtmpEl.hide();
                    } else {
                        sourveIpCamEl.hide();
                        sourveRtmpEl.show();
                    }

                    for (var i = 0; i < showModalDataSelectors.length; i++) {
                        var selector = showModalDataSelectors[i];
                        var el = $('#show_video_source_modal .' + selector);
                        if (equipmentFields[videoSource.current_service].includes(selector)) {
                            el.show();
                            if (videoSource[selector]) {
                                var dispayText = $(el).find('.show-hide').length > 0 ? '*'.repeat(videoSource[selector].length) : videoSource[selector]
                                $(el).find('span').html(dispayText);
                                $(el).find('span').data('field-value', videoSource[selector]);
                                $(el).find('.VideoClientIcon-squaresF').data('clipboard-text', videoSource[selector]);
                            } else {
                                $(el).find('.VideoClientIcon-eye').hide()
                                $(el).find('.VideoClientIcon-squaresF').hide()
                            }
                        } else {
                            el.hide();
                        }
                    }
                }
            }
        },
        copyToClipboard: function (e) {
            var textToCopy = $(e.target).data('clipboard-text');
            if (textToCopy) {
                copyTextToClipboard(textToCopy);
            }
        },
        showHideField(e) {
            var trgetEl = $(e.target);
            var valueEl = trgetEl.prev();
            var fieldValue = valueEl.data('field-value');

            if (trgetEl.hasClass('VideoClientIcon-eye')) {
                valueEl.html(fieldValue)
                trgetEl.removeClass('VideoClientIcon-eye').addClass('VideoClientIcon-eye-off')
            } else {
                valueEl.html('*'.repeat(fieldValue.length))
                trgetEl.removeClass('VideoClientIcon-eye-off').addClass('VideoClientIcon-eye')
            }
        },
    });

}).call(this);
