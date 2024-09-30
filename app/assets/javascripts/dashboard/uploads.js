//= require templates/dashboard/new_recording
//= require templates/dashboard/progress_bar

//= require dom_purify

var Upload = Backbone.Model.extend({
        defaults: {
            selected: false,
            duration: 0,
            purchase_price: 0
        },
        url: function () {
            return Routes.dashboard_upload_path(this.id);
        },
        initialize: function (options) {
            this.on('file:uploaded', this.parseData);
            this.on('change:purchase_price', this.formatPrice);
            return this;
        },
        formatPrice: function () {
            this.set({price: Number(parseFloat(this.get('price')).toFixed(2))});
        },
        toJSON: function () {
            var data = Backbone.Model.prototype.toJSON.apply(this, arguments);
            data.formatted_date = moment(this.get('created_at')).format('D MMM YYYY');
            data.formatted_time = moment(this.get('created_at')).format('h:mm A');
            data.is_free = this.isFree();
            data.min_price = this.getMinPrice();
            data.max_price = this.getMaxPrice();
            data.min_revenue_price = this.getMinRevenue();
            data.max_revenue_price = this.getMaxRevenue();
            data.revenue = this.getRevenue();
            data.duration = formatDuration(this.get('duration'));
            data.default_poster_url = window.videoDefaultImg;
            return data;
        },
        getDurationInMinutes: function () {
            return parseInt(Number(this.get('duration')) / 60);
        },
        getMinPrice: function () {
            var min_price = ((this.getDurationInMinutes() || 0 / 5 - 2) * 0.05 + 0.99 + this.serviceFee()).toFixed(2);
            return Number(min_price);
        },
        getMaxPrice: function () {
            var max_price = (Immerss.maxRecordedSessionAccessCost + this.serviceFee()).toFixed(2);
            return Number(max_price);
        },
        getRevenue: function () {
            var revenue = ((this.get('purchase_price') || this.getMinPrice()) * this.get('creator_revenue') / 100.0).toFixed(2);
            return Number(revenue);
        },
        getMinRevenue: function () {
            var min_revenue = (this.getMinPrice() * this.get('creator_revenue') / 100.0).toFixed(2);
            return Number(min_revenue);
        },
        getMaxRevenue: function () {
            var max_revenue = (this.getMaxPrice() * this.get('creator_revenue') / 100.0).toFixed(2);
            return Number(max_revenue);
        },
        serviceFee: function () {
            var fee = ((this.getDurationInMinutes() || 0 / 5 - 2) * 0.05).toFixed(2);
            return Number(fee);
        },
        getPriceByRevenue: function (revenue) {
            var price = (revenue * 100.0 / this.get('creator_revenue')).toFixed(2);
            return Number(price);
        },
        isFree: function () {
            return (this.get('purchase_price') == 0 || this.get('purchase_price') == null || this.get('purchase_price') == NaN || this.get('purchase_price') == undefined);
        },
        parseData: function (file) {
            var model = this;
            _.defer(function () {
                var reader;
                if (model.isValid()) {
                    file = model.get("file");
                    reader = new FileReader;
                    reader.onload = function (e) {
                        var img;
                        img = new Image;
                        img.onload = function () {
                            model.set({'base64_img': img.src, img: img});
                            if (model.isValid()) {
                                model.trigger('image:loaded', model);
                            }
                        };
                        return img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);
                }
            });
        },
        crop: function (cropData, croppedCanvas) {
            var that = this
            setTimeout(function () {
                that.set({
                    poster_url: croppedCanvas.toDataURL(),
                    uploaded_poster_url: croppedCanvas.toDataURL(),
                    image: that.get('file'),
                    crop_x: cropData.x.toString(),
                    crop_y: cropData.y.toString(),
                    crop_w: cropData.width.toString(),
                    crop_h: cropData.height.toString(),
                    rotate: cropData.rotate.toString(),
                    source_type: 0,
                    image_saved: false,
                });
                that.trigger('crop:done', that);
                that.saveThumbnailUpload();
                that.clearFile();
            })
        },
        clearFile: function () {
            this.unset('file', {silent: true});
            this.unset('img', {silent: true});
            this.unset('base64_img', {silent: true});
        },
        cropData: function () {
            return {
                cid: this.cid,
                base64_img: this.get('base64_img')
            };
        },
        togglePublish: function () {
            if (!this.collection.can_transcode_videos)
                return false;
            var that = this, data = {};

            if (this.get('crop_seconds'))
                data['crop_seconds'] = this.get('crop_seconds')
            if (this.get('cropped_duration'))
                data['cropped_duration'] = this.get('cropped_duration') * 1000

            $.post(Routes.publish_toggle_dashboard_upload_path(this.id), data).success(function (resp) {
                that.set({published: resp.published, processing: resp.published});
                $.showFlashMessage("Processing started", {type: 'success'});
            }).error(function (resp) {
                $.showFlashMessage(resp.responseJSON.message, {type: 'error'});
            });
        },
        publish: function () {
            if (!this.collection.can_transcode_videos)
                return false;

            var data = {}, that = this;

            if (this.get('crop_seconds'))
                data['crop_seconds'] = this.get('crop_seconds');
            if (this.get('cropped_duration'))
                data['cropped_duration'] = this.get('cropped_duration') * 1000;

            $.post(Routes.publish_dashboard_upload_path(this.id), data).success(function (resp) {
                that.set({published: resp.published, processing: resp.published});
                $.showFlashMessage("Processing started", {type: 'success'});
            }).error(function (resp) {
                $.showFlashMessage(resp.responseJSON.message, {type: 'error'});
            });
        },
        saveThumbnailFrame: function () {
            if (this.image_saving)
                return false
            this.image_saving = true
            let data, that
            that = this
            data = {
                frame_position: this.get('frame_position'),
                remote_image_url: this.get('timeline_poster_url'),
                source_type: 1
            }

            $.ajax({
                url: Routes.save_image_dashboard_upload_path(this.id),
                type: 'POST',
                dataType: 'json',
                data: {recording_image_attributes: data},
                success: function (res, textStatus, jqXHR) {
                    that.set({image_saved: true});
                },
                error: function (res, error) {
                    var message;
                    message = res.responseJSON && (res.responseJSON.error || res.responseJSON.message) || 'Something went wrong';
                    $.showFlashMessage(message, {type: 'error'});
                },
                complete: function (data) {
                    that.image_saving = false
                    that.trigger('saveThumbnailFrame:complete', this);
                }
            });
        },
        saveThumbnailUpload: function () {
            var data, formData;
            data = [];
            data.push(['recording_image_attributes[image]', this.get('image')]);
            data.push(['recording_image_attributes[crop_x]', this.get('crop_x')]);
            data.push(['recording_image_attributes[crop_y]', this.get('crop_y')]);
            data.push(['recording_image_attributes[crop_w]', this.get('crop_w')]);
            data.push(['recording_image_attributes[crop_h]', this.get('crop_h')]);
            data.push(['recording_image_attributes[rotate]', this.get('rotate')]);
            data.push(['recording_image_attributes[source_type]', 0]);

            formData = new FormData;
            _(data).each(function (d) {
                return formData.append.apply(formData, d);
            });

            var that = this;
            $.ajax({
                url: Routes.save_image_dashboard_upload_path(this.id),
                type: 'POST',
                dataType: 'json',
                processData: false,
                contentType: false,
                data: formData,
                success: function (res, textStatus, jqXHR) {
                    that.set({image_saved: true});
                },
                error: function (res, error) {
                    var message;
                    message = res.responseJSON && (res.responseJSON.error || res.responseJSON.message) || 'Something went wrong';
                    $.showFlashMessage(message, {type: 'error'});
                }
            });
        }
    }),

    Uploads = Backbone.Collection.extend({
        limit: 10,
        offset: 0,
        model: Upload,
        url: function () {
            return this.baseUrl + '?' + $.param({limit: this.limit, offset: this.offset});
        },
        filterUrl: function () {
            var filter_url;
            if (this.filters) {
                filter_url = this.url() + '&' + $.param(this.filters);
            } else {
                filter_url = this.url();
            }
            return filter_url;
        },
        initialize: function (models, options) {
            this.channel_id = options.channel_id;
            this.can_upload_videos = options.can_upload_videos;
            this.can_monetize_content = options.can_monetize_content;
            this.can_access_products = options.can_access_products;
            this.can_edit_videos = options.can_edit_videos;
            this.can_transcode_videos = options.can_transcode_videos;
            this.can_delete_videos = options.can_delete_videos;
            this.ppv_enabled = options.ppv_enabled;
            this.baseUrl = Routes.dashboard_uploads_path(this.channel_id);
            return this;
        },
        fetch: function (options) {
            typeof (options) != 'undefined' || (options = {});
            var that = this;
            var success = options.success;
            options.success = function (resp) {
                if (success) {
                    success(that, resp);
                }
            };
            return Backbone.Collection.prototype.fetch.call(this, options);
        },
        parse: function (resp) {
            this.offset = resp.offset;
            this.limit = resp.limit;
            this.total = resp.total;
            return resp.models;
        },
        nextPage: function () {
            if (!this.length >= this.total) {
                return false;
            }
            this.offset = this.offset + this.limit;
            var filter_url;
            if (this.filters) {
                filter_url = this.url() + '&' + $.param(this.filters);
            } else {
                filter_url = this.url();
            }
            return this.fetch({url: filter_url, remove: false});
        },
        filterModels: function () {
            this.offset = 0;
            var filter_url;
            if (this.filters) {
                filter_url = this.url() + '&' + $.param(this.filters);
            } else {
                filter_url = this.url();
            }
            return this.fetch({url: filter_url, remove: true});
        },
        groupPublish: function () {
            var that = this;
            $.post(Routes.group_publish_dashboard_uploads_path(), {ids: that.selectedIds()}).success(function (resp) {
                _(that.models).each(function (d) {
                    d.set({selected: false});
                });
                that.set(resp.models, {merge: true, remove: false});
            }).error(function (resp) {
                $.showFlashMessage(resp.responseJSON && resp.responseJSON.message || resp, {type: 'error'});
            });
        },
        groupDelete: function () {
            var that = this;
            $.post(Routes.group_destroy_dashboard_uploads_path(), {ids: that.selectedIds()}).success(function (resp) {
                var ids = that.selectedIds();
                _(that.models).each(function (d) {
                    d.set({selected: false});
                });
                that.remove(ids);
            }).error(function (resp) {
                $.showFlashMessage(resp.responseJSON && resp.responseJSON.message || resp, {type: 'error'});
            });
        },
        selectedIds: function () {
            return _.map(this.where({selected: true}), function (item) {
                return item.id;
            });
        },
    }),

    UploadItemView = chaplin.View.extend({
        tagName: 'div',
        className: 'video-tile',
        autoRender: true,
        events: {
            'click .multiChoiceBtn': 'toggleSelected',
            'click .delete_tile': 'deleteModel',
            'click .edit_tile': 'editModel',
            'click .toggleVisible_tile': 'toggleVisibility',
            'click .togglePrivate_tile': 'togglePrivate',
            'mouseenter .toggleProcess': 'orangeProcessBtn',
            'mouseleave .toggleProcess': 'whiteProcessBtn',
            'click .toggleProcess': 'process',
        },
        initialize: function () {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#uploadItemTmpl').text());
            this.bindEvents();
        },
        bindEvents: function () {
            this.listenTo(this.model, 'change:hide change:published change:title change:selected change:poster_url', function (data) {
                console.log(['changed', data]);
                this.render();
            });
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            return this;
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            data.move_available = Immerss.channels.length > 1;
            data.can_edit_videos = this.model.collection.can_edit_videos;
            data.can_transcode_videos = this.model.collection.can_transcode_videos;
            data.can_delete_videos = this.model.collection.can_delete_videos;
            return data;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        toggleSelected: function (event) {
            $(event.target).toggleClass('active');
            var active = $(event.target).hasClass('active');
            this.model.set({selected: active});
            return false;
        },
        orangeProcessBtn: function (event) {
            $(event.target).text('Process Video');
            return false;
        },
        whiteProcessBtn: function (event) {
            $(event.target).text('Unprocessed');
            return false;
        },
        process: function (event) {
            if (this.model.collection.can_transcode_videos) {
                $(event.target).toggleClass('active');
                this.model.publish();
            } else {
                $.showFlashMessage('You are not allowed to process video', {type: 'error'});
            }
            return false;
        },
        toggleProcess: function (event) {
            if (this.model.collection.can_transcode_videos) {
                $(event.target).toggleClass('active');
                this.model.togglePublish();
            } else {
                $.showFlashMessage('You are not allowed to process video', {type: 'error'});
            }
            return false;
        },
        togglePrivate: function (event) {
            if (this.model.get('private')) {
                var r = confirm("Are you sure you would you like to post this private video as a public video? (You will not be able to change it back)");
                if (r == true) {
                    $(event.target).addClass('active');
                    this.model.set({private: false}, {silent: true});
                    this.model.save('private', false, {patch: true});
                }
            }
            return false;
        },
        toggleVisibility: function (e) {
            var visibility = $(e.currentTarget).hasClass('active');
            this.model.set({hide: visibility});
            this.model.save('hide', visibility, {patch: true});
            return false;
        },
        deleteModel: function () {
            var r = confirm("Are you sure want to delete this upload?");
            if (r == true)
                this.model.destroy({
                    error: function (model, response) {
                        $.showFlashMessage(response.responseJSON.message, {type: 'error'});
                    },
                    wait: true
                });
            return false;
        },
        editModel: function () {
            var editModal = new EditUploadItemView({
                container: '#editVideo .modal-body',
                model: this.model
            });
            return false;
        },
    }),

    EditUploadItemView = chaplin.View.extend({
        autoRender: true,
        events: {
            'change [name="video[title]"]': 'saveTitle',
            'keyup [name="video[title]"]': 'changeTitle',
            'change [name="video[description]"]': 'saveDescription',
            'keyup [name="video[description]"]': 'changeDescription',

            'change [name="video[list_id]"]': 'saveList',

            'click .toggle_price a': 'toggleSetPrice',
            'change .setPrice .total_cost': 'savePrice',
            'keyup .setPrice .total_cost': 'setPrice',
            'change .setPrice .revenue': 'savePriceByRevenue',
            'keyup .setPrice .revenue': 'setPriceByRevenue',

            'click .toggle_visibility a': 'toggleVisibility',
            'click .toggle_only_ppv a': 'toggleOnlyPPV',
            'click .toggle_only_subscription a': 'toggleOnlySubs',

            'click .set_public': 'setPublic',

            'click .add_custom_image': 'toggleUploadSection',
            'click .add_frame_image': 'toggleFrameSection',
            'click .cancelButton': 'toggleUploadSection',
            'change [name="video[image]"]': 'setImage',
            'dragover .upload-area': function (e) {
                return e.preventDefault()
            },
            'drop .upload-area': 'setImage',
            'click .cropOptions .crop': 'cropImage',
            'click .cropOptions .clear': 'сancelCrop',
            'click .select_frame': 'selectFrame',
            'click .choice_image': 'selectImageSource',

            'click .process_video': 'processVideo',
            'click section.form_V2.no-padding': 'hidePricePopup',
        },
        initialize: function () {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#editModalTmpl').text());
            this.bindEvents();
        },
        bindEvents: function () {
            var that = this;
            $('#editVideo').one('hidden.bs.modal', function () {
                that.remove();
            });
            $('#editVideo').one('shown.bs.modal', function () {
                that.setupVideoPlayer();
            });
            $('#editVideo').on('shown.bs.modal', function () {
                $('.input-block textarea[name=\'video[description]\']').each(function (i, el) {
                    if ($(el).val() && $(el).val().trim().length)
                        Forms.Helpers.resizeTextarea(this);
                });
            });
            this.listenTo(this.model, 'change:purchase_price', function (data) {
                this.updatePrice();
            });
            this.listenTo(this.model, 'change:published', function (data) {
                if (this.model.get('published'))
                    this.$('.process_video').remove();
            });
            this.listenTo(this.model, 'image:loaded', this.showCropper);
            this.listenTo(this.model, 'crop:done', this.cropDone);
            this.listenTo(this.model, 'saveThumbnailFrame:complete', this.saveThumbnailFrameComplete);
        },
        getTemplateData: function () {
            var data = this.model.toJSON();
            data.lists = Immerss.lists;
            data.can_upload_videos = this.model.collection.can_upload_videos;
            data.can_monetize_content = this.model.collection.can_monetize_content;
            data.can_access_products = this.model.collection.can_access_products;
            data.can_edit_videos = this.model.collection.can_edit_videos;
            data.can_transcode_videos = this.model.collection.can_transcode_videos;
            data.can_delete_videos = this.model.collection.can_delete_videos;
            data.ppv_enabled = this.model.collection.ppv_enabled;
            return data;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            var that = this;
            $('#editVideo').on('shown.bs.modal', function () {
                var options = {
                    debug: 'info',
                    modules: {toolbar: '#descriptionToolbar'},
                    theme: 'snow'
                };
                that.editor = new Quill('#descriptionWrapp', options);
                that.editor.on('text-change', function() {
                    that.checkVisitUrlValidation()
                    that.saveDescription()
                });
            })
            $('#editVideo').modal('show');
            return this;
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
            }
        },
        setupTimelineImagePicker: function () {
            var that = this;
            // if (!this.model.get('timeline_poster_url')) {
            //     videoImageDataUrl(this.model.get('original_url'), 0, 310, 0, function (url) {
            //         if (url){
            //             that.$('.addfromtimeline .choice_image').css('background-image', 'url(' + url + ')');
            //         } else {
            //             that.$('.addfromtimeline .choice_image').css('background-image', 'url(' + window.videoDefaultImg + ')');
            //         }
            //     });
            // }
            this.$("#slider-range-timeline").slider({
                range: false,
                min: 0,
                max: this.currentPlayer.duration,
                values: [this.currentPlayer.currentTime],
                slide: function (event, ui) {
                    that.currentPlayer.pause();
                    if ($(ui.handle).hasClass('leftButtonSlider')) {
                        that.currentPlayer.currentTime = ui.value;
                    }
                }
            });
        },
        selectFrame: function () {
            var that = this,
                seconds = this.$("#slider-range-timeline").slider('values')[0],
                video_url = this.model.get('original_url') || this.model.get('blob_file_path')
            $('.addfromtimeline .LoadingCover').removeClass('hidden')
            if (seconds < 1)
                seconds = 1
            videoImageDataUrl(video_url, seconds, 1440, 0, function (url) {
                if (url) {
                    that.$('.addfromtimeline .choice_image').css('background-image', 'url(' + url + ')')
                    that.model.set({
                        poster_url: url,
                        timeline_poster_url: url,
                        frame_position: seconds,
                        source_type: 1
                    })
                    that.model.saveThumbnailFrame()
                } else {
                    that.$('.addfromtimeline .choice_image').css('background-image', 'url(' + window.videoDefaultImg + ')')
                }
            })
            this.toggleFrameSection()
            this.$('.thumbnail_tile').removeClass('active')
            this.$('.thumbnail_tile.addfromtimeline').addClass('active')
            return false
        },
        saveThumbnailFrameComplete: function () {
            $('.addfromtimeline .LoadingCover').addClass('hidden');
        },
        setupVideoPlayer: function () {
            try {
                var video_url = this.model.get('original_url') || this.model.get('blob_file_path')
                this.currentPlayer = initTheOplayer(video_url, '#videoAreaModal_' + this.model.id, {video: this.model.toJSON()});
                var that = this;
                this.currentPlayer.addEventListener('error', function (e) {
                    that.$("#slider-range, .rangeTime, #slider-range-timeline").remove();
                });
                this.currentPlayer.addEventListener('loadedmetadata', function (e) {
                    that.player = this;
                    if (!that.model.get('published')) {
                        var val_first = 0;
                        var val_last = parseInt(that.player.duration);
                        that.$(".leftEditSlider").val(val_first);
                        that.$(".rightEditSlider").val(`${val_last}`.toHHMMSS());
                        that.$("#slider-range").slider({
                            range: true,
                            min: 0,
                            max: that.player.duration,
                            values: [val_first, val_last],
                            slide: function (event, ui) {
                                that.currentPlayer.pause();
                                if ($(ui.handle).hasClass('leftButtonSlider')) {
                                    that.currentPlayer.currentTime = ui.value;
                                    that.$(".leftEditSlider").val(`${ui.value}`.toHHMMSS());
                                }
                                if ($(ui.handle).hasClass('rightButtonSlider')) {
                                    that.currentPlayer.currentTime = ui.value;
                                    that.$(".rightEditSlider").val(`${ui.value}`.toHHMMSS());
                                }
                            }
                        });
                        that.$(".rightEditSlider, .leftEditSlider").on('change', function () {
                            that.currentPlayer.pause();
                            that.currentPlayer.currentTime = $(this).val().toSS();
                        });
                        that.$(".rightEditSlider").on('change', function () {
                            var start_val = that.$(".leftEditSlider").val().toSS();
                            var end_val = $(this).val().toSS();
                            if (end_val <= start_val) {
                                end_val = start_val + 5
                            }
                            if (end_val > val_last) {
                                end_val = val_last
                            }
                            $("#slider-range").slider("values", [start_val, end_val])
                            if ($(this).val() !== `${end_val}`.toHHMMSS()) {
                                $(this).val(`${end_val}`.toHHMMSS())
                            }
                        });
                        that.$(".leftEditSlider").on('change', function () {
                            var start_val = $(this).val().toSS();
                            var end_val = that.$(".rightEditSlider").val().toSS()
                            if (start_val >= end_val) {
                                start_val = end_val - 5
                            }
                            if (start_val < 0) {
                                start_val = 0
                            }
                            $("#slider-range").slider("values", [start_val, end_val])
                            if ($(this).val() !== `${start_val}`.toHHMMSS()) {
                                $(this).val(`${start_val}`.toHHMMSS())
                            }
                        });
                    }
                    that.setupTimelineImagePicker();
                });
            } catch (e) {
                console.log(e);
                that.$("#slider-range-timeline").remove();
            }

        },
        updatePrice: function () {
            if (this.model.isFree()) {
                this.$('.toggle_price .set_price').text('Set Price');
            } else {
                if (this.model.get('purchase_price').toString() == 'NaN') {
                    this.$('.toggle_price .set_price').text('Set Price')
                } else {
                    this.$('.toggle_price .set_price').text('$' + this.model.get('purchase_price'));
                    this.$('.setPrice .total_cost').val(this.model.get('purchase_price'));
                    this.$('.setPrice .revenue').val(this.model.getRevenue());
                }
            }
        },
        toggleSetPrice: function (e) {
            if (!this.model.collection.can_monetize_content)
                return false
            this.$('.toggle_price a').removeClass('active')
            $(e.currentTarget).addClass('active')
            if ($(e.currentTarget).hasClass('set_price')) {
                if (this.model.isFree())
                    this.model.save('purchase_price', this.model.getMinPrice(), {patch: true})
                this.$('.setPrice').toggleClass('hidden')
            } else {
                this.model.save('purchase_price', 0.0, {patch: true})
                this.$('.setPrice').addClass('hidden')
            }
            return false
        },
        hidePricePopup: function (e) {
            if ($(e.target).parents('.setPrice').length || $(e.target).hasClass('setPrice')) {
            } else {
                // Save price on popup close
                if (!this.model.isFree()) {
                    this.model.set({purchase_price: this.$('.setPrice .total_cost').val()})
                    this.model.save('purchase_price', this.model.get('purchase_price'), {patch: true})
                }

                this.$('.setPrice').addClass('hidden')
            }
        },
        setPrice: function () {
            this.model.set({purchase_price: this.$('.setPrice .total_cost').val()})
        },
        savePrice: function () {
            if(this.$('.setPrice .total_cost').val() != '') {
                this.model.save('purchase_price', this.$('.setPrice .total_cost').val(), {patch: true})
            }
            else {
                this.model.save('purchase_price', 0.5, {patch: true})
            }
        },
        setPriceByRevenue: function () {
            if(this.model.getPriceByRevenue($('.setPrice .revenue').val()) != '') {
                this.model.set({purchase_price: this.model.getPriceByRevenue($('.setPrice .revenue').val())})
            }
        },
        savePriceByRevenue: function () {
            this.setPriceByRevenue();
            this.model.save('purchase_price', this.model.get('purchase_price'), {patch: true})
        },

        changeTitle: function (e) {
            this.model.set({title: $(e.currentTarget).val()}, {silent: true});
        },
        saveTitle: function (e) {
            let titleLength = this.model.attributes.title;
            if (titleLength.length < 4) {
                return false;
            } else {
                this.model.save('title', $(e.currentTarget).val(), {patch: true});
                this.model.trigger('change:title', this.model);
            }
        },

        changeDescription: function (e) {
            this.model.set({description: $(e.currentTarget).val()}, {silent: true});
        },
        saveDescription: function (e) {
            this.model.save('description', this.editor.root.innerHTML, {patch: true});
        },

        saveList: function (e) {
            this.model.save('list_id', $(e.currentTarget).val(), {patch: true});
        },

        toggleVisibility: function (e) {
            var visibility = $(e.currentTarget).data('hide');
            this.model.set({hide: visibility});
            this.model.save('hide', visibility, {patch: true});
            this.$('.toggle_visibility a').removeClass('active');
            $(e.currentTarget).addClass('active');
        },
        toggleOnlyPPV: function (e) {
            if (!this.model.collection.can_monetize_content)
                return false
            var only_ppv = $(e.currentTarget).data('only_ppv')
            this.model.set({only_ppv: only_ppv})
            this.model.save('only_ppv', this.model.get('only_ppv'), {patch: true})
            this.$('.toggle_only_ppv a').removeClass('active')
            $(e.currentTarget).addClass('active')
        },
        toggleOnlySubs: function (e) {
            if (!this.model.collection.can_monetize_content)
                return false
            var only_subscription = $(e.currentTarget).data('only_subscription')
            this.model.set({only_subscription: only_subscription})
            this.model.save('only_subscription', this.model.get('only_subscription'), {patch: true})
            this.$('.toggle_only_subscription a').removeClass('active')
            $(e.currentTarget).addClass('active')
        },
        setPublic: function (e) {
            this.$('.modalChoice').removeClass('hidden');
            var that = this;
            this.$('.modalChoice .modalChoice__btns a').one('click', function (ev) {
                if ($(ev.currentTarget).hasClass('yes')) {
                    that.model.set({private: false});
                    that.$('.set_public').text('Public');
                    that.$('.set_public').addClass('active');
                    that.$('.set_public').removeClass('set_public');
                    that.model.save('private', that.model.get('private'), {patch: true});
                }
                that.$('.modalChoice').addClass('hidden');
            });
            return false;
        },
        toggleUploadSection: function (e) {
            this.$('.timeline_image_picker').addClass('hidden');
            this.$('#slider-range').removeClass('hidden');
            this.$('.rangeTime').removeClass('hidden');
            this.$('.crop-wrapp, .main-wrapp').toggleClass('hidden');
            if(!this.$('.crop-wrapp, .main-wrapp').hasClass('hidden')){
                this.$('#slider-range').addClass('hidden');
                this.$('.rangeTime').addClass('hidden');
            }
            return false;
        },
        toggleFrameSection: function () {
            this.$('.crop-wrapp').addClass('hidden')
            this.$('.main-wrapp').removeClass('hidden')
            this.$('.timeline_image_picker').removeClass('hidden')
            this.$('#slider-range').addClass('hidden')
            this.$('.rangeTime').addClass('hidden')
            this.$('#slider-range-timeline').slider({values: [this.currentPlayer.currentTime]})
            return false
        },
        setImage: function (e) {
            e.preventDefault();
            this.showLoader();
            var files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
            if (files && files[0]) {
                this.model.set({file: files[0]});
                this.model.trigger('file:uploaded', this.model);
            } else {
                this.showUploader();
            }
            this.clearFileInput();
        },
        showLoader: function () {
            // this.hideUploader();
            this.$('.upload-area .LoadingCover').removeClass('hidden');
        },
        clearFileInput: function () {
            this.$('input.inputfile').wrap('<form>').closest('form').get(0).reset();
            this.$('input.inputfile').unwrap();
        },
        showCropper: function (item) {
            this.$(this.$('.crop-container')).html(HandlebarsTemplates['wizard/image_cropper'](item.cropData()));
            this.$(this.$('.crop-container')).show('fast');
            this.hideUploader();
            initCrop({aspectRatio: 16 / 9});
            return false;
        },
        hideUploader: function () {
            this.$('.upload-area').hide('fast');
        },
        showUploader: function (e) {
            this.$('.upload-area').show('fast');
            this.$('.LoadingCover').addClass('hidden');
        },
        hideCropper: function () {
            this.$(this.$('.crop-container')).html('');
            this.showUploader();
        },
        cropImage: function (e) {
            var cropData, croppedCanvas;
            e.preventDefault();
            $('.addCustom .LoadingCover').removeClass('hidden');
            cropData = this.$(this.$('.crop-container')).find('#crop-img').cropper('getData');
            croppedCanvas = this.$(this.$('.crop-container')).find('#crop-img').cropper('getCroppedCanvas');
            this.$('.crop-container .crop-images-wrapp').addClass('inactive');
            this.model.crop(cropData, croppedCanvas);
            return false;
        },
        cropDone: function (e) {
            this.$(this.$('.crop-container')).html('');
            this.$('.addCustom .choice_image').attr('style', "background-image: url(" + (this.model.get('poster_url')) + "),url(" + window.videoDefaultImg + ")");
            this.showUploader();
            this.toggleUploadSection();
            this.$('.thumbnail_tile').removeClass('active');
            this.$('.thumbnail_tile.addCustom').addClass('active');
        },
        сancelCrop: function (e) {
            e.preventDefault();
            this.showUploader();
            this.$(this.$('.crop-container')).html('');
            this.model.clearFile();
        },
        selectImageSource: function (e) {
            var parent = this.$(e.currentTarget).parents('.thumbnail_tile');
            // if (parent.hasClass('addCustom') && !parent.hasClass('active')) {
            if (parent.hasClass('addCustom')) {
                this.toggleUploadSection();
                this.model.set({image_type: 'custom'});
                // } else if (parent.hasClass('addfromtimeline') && !parent.hasClass('active')) {
            } else if (parent.hasClass('addfromtimeline')) {
                if (this.currentPlayer && !this.currentPlayer.error) {
                    this.toggleFrameSection();
                    this.model.set({image_type: 'timeline'});
                } else {
                    if (this.model.get('processed') && this.model.get('done')) {
                        alert('Something went wrong');
                    } else {
                        alert('Not available, until video is processed');
                    }
                    return false;
                }
            }
            parent.addClass('active');
            return false;
        },
        processVideo: function () {
            var crop_seconds, duration;
            crop_seconds = parseInt(this.$('.leftEditSlider').val().toSS()) || 0;
            duration = (parseInt(this.$('.rightEditSlider').val().toSS()) || 0) - crop_seconds;
            this.model.set({crop_seconds: crop_seconds, cropped_duration: duration});
            this.model.togglePublish();
            return false;
        },
    }),

    UploadsCollectionView = chaplin.CollectionView.extend({
        autoRender: true,
        itemView: UploadItemView,
        optionNames: chaplin.View.prototype.optionNames.concat(['channel_id']),
        listSelector: '.tileWrapp',
        fallbackSelector: '.emptyResults',
        events: {
            'change input.select_all': 'selectAll'
        },
        initialize: function (options) {
            chaplin.CollectionView.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#uploadsCollectionTmpl').text());
            this.collection.fetch();
            this.bindEvents();
        },
        render: function () {
            chaplin.CollectionView.prototype.render.apply(this, arguments);
            this.subview('groupActions', new GroupUploadsActionsView({
                el: '#channel_' + this.channel_id + ' .groupActionsArea',
                collection: this.collection,
                channel_id: this.channel_id
            }));
            this.subview('filterActions', new FilterUploadsActionsView({
                el: '#channel_' + this.channel_id + ' .filterActionsWrapp',
                collection: this.collection,
                channel_id: this.channel_id
            }));
            this.subview('showMore', new ShowMoreUploadsView({
                el: '#channel_' + this.channel_id + ' .show-more-container',
                collection: this.collection,
                channel_id: this.channel_id
            }));
            return this;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        getTemplateData: function () {
            var data = {};
            data.channel_id = this.channel_id;
            data.length = this.collection.length;
            data.selected_length = this.collection.where({selected: true}).length;
            if ($.cookie('grid_style')) {
                data.grid_style = $.cookie('grid_style');
            } else {
                data.grid_style = 'grid';
            }
            return data;
        },
        bindEvents: function () {
            this.listenTo(this.collection, 'change:selected', function (data) {
                var selected_length = this.collection.where({selected: true}).length,
                    total_length = this.collection.models.length;
                this.$('.select_all').attr('checked', (selected_length === total_length));
            });
        },
        selectAll: function (e) {
            this.collection.each(function (model) {
                model.set({selected: $(e.target).is(':checked')}, {silent: true});
            });
            this.collection.each(function (model) {
                model.trigger('change:selected', model);
            });
        },
    }),

    GroupUploadsActionsView = chaplin.View.extend({
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['channel_id']),
        events: {
            'click .group_publish': 'groupPublish',
            'click .group_delete': 'groupDelete',
        },
        initialize: function (options) {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#uploadsGroupActionsTmpl').text());
            this.bindEvents();
            this.channel_id = options.channel_id;
            this.selected_channel_id = options.channel_id;
            this.collection = options.collection;
        },
        bindEvents: function () {
            this.listenTo(this.collection, 'change:selected', function (data) {
                this.render();
            });
        },
        getTemplateFunction: function () {
            return this.template;
        },
        getTemplateData: function () {
            var data = {};
            data.selected_length = this.collection.where({selected: true}).length;
            data.channel_id = this.channel_id;
            data.channels = Immerss.channels;
            data.move_available = Immerss.channels.length > 1;
            data.can_edit_videos = this.collection.can_edit_videos;
            data.can_transcode_videos = this.collection.can_transcode_videos;
            data.can_delete_videos = this.collection.can_delete_videos;
            return data;
        },
        groupPublish: function () {
            this.collection.groupPublish();
        },
        groupDelete: function () {
            this.collection.groupDelete();
        },
    }),

    FilterUploadsActionsView = chaplin.View.extend({
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['channel_id']),
        events: {
            'click .FilterByBtn': 'toggleFilters',
            'keydown .SearchByTitle input': 'preventEnter',
            'click .tileStyleToggleBtn a': 'toggleStyle',
            'change select#limit_count': 'sortBy',
            'click .searchReplaysUploads': 'searchByTitle',
            'change select#sortBy': 'sortBy',
            'click .apply_filters': 'applyFilters',
            'submit form.filters': 'prependSubmit',
        },
        initialize: function (options) {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#filterActionsTmpl').text());
            this.listenTo(this.collection, 'sync', this.handleSync);
        },
        render: function () {
            chaplin.View.prototype.render.apply(this, arguments);
            this.setupSelect();
            this.setupDatePicker();
            return this;
        },
        getTemplateFunction: function () {
            return this.template;
        },
        getTemplateData: function () {
            var data = {};
            data.channel_id = this.channel_id;
            data.selected_length = this.collection.where({selected: true}).length;
            if ($.cookie('grid_style')) {
                data.grid_style = $.cookie('grid_style');
            } else {
                data.grid_style = 'grid';
            }
            return data;
        },
        setupSelect: function () {
            this.$('select.styled-select').select2({
                minimumResultsForSearch: -1
            });
        },
        handleSync: function () {
            this.$('.totalResult').text(this.collection.total + " results viewed")
        },
        setupDatePicker: function () {
            var dateFormat = "mm/dd/yy",
                from = this.$("#filterDate_from_" + this.channel_id).datepicker({
                    defaultDate: "+0w",
                    changeMonth: true,
                    changeYear: true,
                    numberOfMonths: 1
                }).on("change", function () {
                    to.datepicker("option", "minDate", getDate(this));
                }),
                to = this.$("#filterDate_to_" + this.channel_id).datepicker({
                    defaultDate: "+1w",
                    changeMonth: true,
                    changeYear: true,
                    numberOfMonths: 1
                }).on("change", function () {
                    from.datepicker("option", "maxDate", getDate(this));
                });

            function getDate(element) {
                var date;
                try {
                    date = $.datepicker.parseDate(dateFormat, element.value);
                } catch (error) {
                    date = null;
                }
                return date;
            }
        },
        toggleFilters: function () {
            this.$('.FilterByBtn').toggleClass('active');
            this.$('.filterWrapp').toggleClass('showFilters');
            return false;
        },
        preventEnter: function (e) {
            if (e.keyCode === 13) {
                this.applyFilters();
                return false;
            }
        },
        sortBy: function () {
            this.collection.limit = this.$('#limit_count').val();
            this.collection.offset = 0;
            this.applyFilters();
        },
        toggleStyle: function (e) {
            var type = $(e.currentTarget).data('type');
            if (type == 'list') {
                $('.tileWrapp').addClass('tileInList').removeClass('threeTilesInRow');
                $.cookie('grid_style', 'list');
            } else {
                $('.tileWrapp').addClass('threeTilesInRow').removeClass('tileInList');
                $.cookie('grid_style', 'grid');
            }
            $('.tileStyleToggleBtn a').toggleClass('hidden');
            return false;
        },
        searchByTitle: function (e) {
            var query = $(e.currentTarget).val();
            if (query && query.length < 3)
                return;
            this.applyFilters();
        },
        applyFilters: function () {
            this.collection.filters = this.$('form.filters').serializeArray();
            this.collection.filterModels();
            return false;
        },
        prependSubmit: function () {
            return false;
        }
    }),

    ShowMoreUploadsView = chaplin.View.extend({
        autoRender: false,
        optionNames: chaplin.View.prototype.optionNames.concat(['channel_id']),
        events: {
            'click .show_more': 'showMore'
        },
        initialize: function (options) {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.template = Handlebars.compile($('#showMoreTmpl').text());
            this.bindEvents();
        },
        bindEvents: function () {
            this.listenTo(this.collection, 'sync', function (data) {
                this.render();
            });
        },
        getTemplateFunction: function () {
            return this.template;
        },
        getTemplateData: function () {
            var data = {};
            data.nextPage = !(this.collection.length >= this.collection.total)
            return data;
        },
        showMore: function () {
            this.collection.nextPage();
            return false;
        }
    }),

    UploadsChannelView = chaplin.View.extend({
        autoRender: true,
        optionNames: chaplin.View.prototype.optionNames.concat(['channel_id', 'can_upload_videos', 'can_monetize_content',
            'can_access_products', 'can_edit_videos', 'can_transcode_videos', 'can_delete_videos', 'ppv_enabled']),
        events: {
            'click .rc-b-toggle': 'toggleVisibility',
            'change .upload_video_modal form .file_input': 'handleFile',
            'dragover .upload_video_modal .upload-info': 'dragoverUpload',
            'drop .upload_video_modal .upload-info': 'handleFileDrop',
            'click .move_single_video': 'openMoveSingleVideoModal',
            'click .group_move_to': 'openMoveVideosModal',
        },
        initialize: function (options) {
            chaplin.View.prototype.initialize.apply(this, arguments);
            this.collection = new Uploads([], {
                channel_id: this.channel_id,
                can_edit_videos: this.can_edit_videos,
                can_transcode_videos: this.can_transcode_videos,
                can_delete_videos: this.can_delete_videos,
                can_upload_videos: this.can_upload_videos,
                can_monetize_content: this.can_monetize_content,
                can_access_products: this.can_access_products,
                ppv_enabled: this.ppv_enabled
            });
            this.bindEvents();
            if (options.autoshow)
                this.toggleVisibility();
        },
        render: function () {
            return this;
        },
        bindEvents: function () {
            var that = this;
            $('.upload_video_modal').on('hidden.bs.modal', function () {
                that.reloadCollection()
            });
        },
        file_template: HandlebarsTemplates['dashboard/new_recording'],
        toggleVisibility: function () {
            this.$('.rc-b-toggle').toggleClass('active');
            this.$('.channelSectionBody').toggleClass('hidden');
            if (!this.$('.rc-b-toggle').hasClass('active')) {
                this.$('.load_picker').addClass('hidden');
            } else {
                this.$('.load_picker').removeClass('hidden');
            }
            if (!this.$('.channelSectionBody').hasClass('hidden')) {
                if (this.subview('channelBody')) {
                    this.collection.offset = 0
                    this.subview('channelBody').collection.fetch();
                } else {
                    this.subview('channelBody', new UploadsCollectionView({
                        el: '#channel_' + this.channel_id + ' .channelSectionBody',
                        collection: this.collection,
                        channel_id: this.channel_id
                    }));
                }
            }
            return false;
        },
        createAndUpload: function (file) {
            if (this.$('*[data-filename="' + file.name + '"]').length > 0) {
                return false
            }
            var data = {};
            data.filename = file.name;
            this.$('.Votes-b#file_place').append(this.file_template(data));

            var direct_url = this.$('.upload_video_modal  form .file_input').data('direct-upload-url');
            var form_url = this.$('.upload_video_modal form').attr('action');
            new RecordingUploader(file, direct_url, form_url, this);
        },
        handleFile: function (e) {
            var that = this;
            var videoFormatsAvailableToValidate = ['webm', 'mov', 'mkv', 'mp4'];
            Array.from(e.currentTarget.files).forEach(function (file) {
                if (!that.validateUploadFileSize(file)) {
                    $.showFlashMessage('Maximum file size: 80gb', {
                        type: "error"
                    });
                } else if (!that.validateUploadFileType(file)) {
                    $.showFlashMessage('Wrong video format', {
                        type: "error"
                    });
                } else {
                    if (videoFormatsAvailableToValidate.includes(file.name.split('.').pop())) {
                        that.validateAndUpload(file);
                    } else {
                        that.createAndUpload(file);
                    }
                }
            });
            e.currentTarget.value = null;
        },
        validateUploadFileSize(file) {
            var maxSizeB = 80 * 1024 * 1024 * 1024; // 80 Gb
            return file.size && file.size <= maxSizeB;
        },
        validateUploadFileType(file) {
            return file.type && file.type.startsWith('video/');
        },
        validateAndUpload: function (file) {
            var videoElementId = 'validation_video_elment';
            var videoElement = document.getElementById(videoElementId);
            var that = this;

            if (!videoElement) {
                videoElement = document.createElement('video');
                videoElement.setAttribute('id', videoElementId);
                videoElement.preload = 'metadata';
                videoElement.addEventListener('error', function(event){
                    $.showFlashMessage('Wrong video codec', {type: "error"});
                    // debug info:
                    var error = event;
                    // Chrome v60
                    if (event.path && event.path[0]) {
                        error = event.path[0].error;
                    }

                    // Firefox v55
                    if (event.originalTarget) {
                        error = error.originalTarget.error;
                    }

                    console.log(`Video error: ${error.message}`);
                }, true);

                videoElement.onloadedmetadata = function () {
                    window.URL.revokeObjectURL(videoElement.src);

                    if (videoElement.duration && videoElement.duration > 28800) {
                        $.showFlashMessage('Maximum video length: 8 hours', {
                            type: "error"
                        });
                    } else {
                        that.createAndUpload(file);
                    }

                    // clear video element
                    videoElement.pause();
                    videoElement.removeAttribute('src'); // empty source
                    videoElement.load();
                }
            }

            videoElement.src = URL.createObjectURL(file);
        },
        dragoverUpload: function (e) {
            e.stopPropagation();
            e.preventDefault();
        },
        handleFileDrop: function (e) {
            e.preventDefault();
            var that = this;
            var videoFormatsAvailableToValidate = ['webm', 'mov', 'mkv', 'mp4'];
            var files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
            Array.from(files).forEach(function (file) {
                if (!that.validateUploadFileSize(file)) {
                    $.showFlashMessage('Maximum file size: 80gb', {
                        type: "error"
                    });
                } else if (!that.validateUploadFileType(file)) {
                    $.showFlashMessage('Wrong video format', {
                        type: "error"
                    });
                } else {
                    if (videoFormatsAvailableToValidate.includes(file.name.split('.').pop())) {
                        that.validateAndUpload(file);
                    } else {
                        that.createAndUpload(file);
                    }
                }
            });
        },
        reloadCollection: function () {
            this.collection.offset = 0
            this.collection.fetch();
        },
        openMoveSingleVideoModal: function (e) {
            var video_id = $(e.currentTarget).data('id');
            window.moveRecordingModalView.current_channel_id = parseInt(this.channel_id);
            window.moveRecordingModalView.video_ids = [video_id];
            window.moveRecordingModalView.show();
        },
        openMoveVideosModal: function () {
            window.moveRecordingModalView.current_channel_id = parseInt(this.channel_id);
            window.moveRecordingModalView.video_ids = this.selectedIds();
            window.moveRecordingModalView.show();
        },
        selectedIds: function () {
            return _.map(this.collection.where({selected: true}), function (item) {
                return item.id;
            });
        }
    });

MoveRecordingModalView = chaplin.View.extend({
    optionNames: chaplin.View.prototype.optionNames.concat(['current_channel_id', 'video_ids']),
    events: {
        'click .move_to_channel': 'moveToChannel',
    },
    initialize: function (options) {
        chaplin.View.prototype.initialize.apply(this, arguments);
        this.video_ids = options.video_ids;
        this.channels = Immerss.channels;
        this.current_channel_id = options.current_channel_id;
        this.template = Handlebars.compile($('#moveRecordingModalTmpl').text());
    },
    getTemplateFunction: function () {
        return this.template;
    },
    getTemplateData: function () {
        return {
            channels: this.channels,
            current_channel_id: this.current_channel_id,
            video_ids: this.video_ids
        };
    },
    show: function () {
        this.render();
        this.$('#MoveTo').modal('show');
    },
    moveToChannel: function (e) {
        e.preventDefault();
        e.stopPropagation();
        var that = this;
        var selected_channel_id = parseInt(this.$('input[name=channel_id]:checked').val());
        $.post(
            Routes.group_move_dashboard_uploads_path(),
            this.$('#move_to_channel_form').serialize()
        ).success(function (resp) {
            _(window.channelViews[that.current_channel_id].collection.models).each(function (d) {
                d.set({selected: false});
            });
            window.channelViews[selected_channel_id].collection.fetch();
            window.channelViews[that.current_channel_id].collection.fetch();
            if (resp.errors) {
                $(document).one('hidden.bs.modal', '#MoveTo', function () {
                    $.showFlashMessage(resp.errors.join('; '));
                });
            }
        }).error(function (resp) {
            $(document).one('hidden.bs.modal', '#MoveTo', function () {
                $.showFlashMessage(resp.responseJSON && resp.responseJSON.message || resp, {type: 'error'});
            });
        }).complete(function () {
            $('body').removeClass('modal-open');
            $('.modal-backdrop').remove();
            $('#MoveTo').modal('hide');
        });
    },
});

RecordingUploader = function (file, direct_url, server_url, channel_view) {
    var parent = this;
    this.file = file;
    this.server_url = server_url;

    var upload = new window.ActiveStorage.DirectUpload(file, direct_url, this);

    upload.create(function (error, blob) {
        if (error) {
            parent.progress_bar(0, 'red', 100)
        } else {
            $.post(
                parent.server_url, {
                    recording: {
                        file: {
                            blob: blob.signed_id,
                            filename: parent.file.name
                        }
                    }
                }
            ).done(function () {
                $.showFlashMessage(`Video "${blob.filename}" successfully uploaded`, {
                    type: "success",
                    timeout: 6000
                });
                parent.progress_bar(100, 'green', 100);
                channel_view.$('.close_upload_video_modal').show();
                channel_view.reloadCollection()
            }).fail(function (e) {
                console.log(e);
                parent.progress_bar(0, 'red', 100);
                $.showFlashMessage('Error: please, try again', {type: "error", timeout: 6000});
                channel_view.$('.error_upload_video_modal').show();
            }).always(function () {
            });
        }
    });
    this.directUploadWillStoreFileWithXHR = function (request) {
        request.upload.addEventListener("progress", function (event) {
            parent.directUploadDidProgress(event)
        });
    };

    this.directUploadUploadPercent = function(percent) {
        this.progress_bar(percent, '#F23535', percent)
    }

    this.directUploadDidProgress = function (event) {
        var percent = Math.ceil((event.loaded * 100) / event.total);
        this.progress_bar(percent, '#F23535', percent)
    };

    this.progress_bar = function (percent, color, progress) {
        var data = {};
        data.percent = percent;
        data.progress = progress;
        data.color = color;
        channel_view.$('*[data-filename="' + file.name + '"] #file_score').html(HandlebarsTemplates['dashboard/progress_bar'](data));
    };
};

window.UploadsChannelView = UploadsChannelView;
