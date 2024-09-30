//= require_self
//= require ./members
//= require templates/channel/gallery_image
//= require templates/channel/gallery_link

window.Channel = {
    Cache: {},
    Collections: {},
    Models: {},
    Views: {},
    Utils: {
        resizeTextarea: function (element) {
            autosize($(element));
            return $(element).trigger('textarea:resized');
        },
        formatInput: function (element) {
            return $(element).val($(element).val().replace(/[\s]+/, ' ').trim());
        },
        setCount: function (element) {
            var len;
            len = $(element).val().length;
            return $(element).parents('.input-block').find('.counter_block').html(len + "/" + ($(element).attr('max-length')));
        }
    },
    edit: function () {
        return this.Cache.edit_view = new Channel.Edit();
    },
};

_.extend(window.Channel, Backbone.Events);

Channel.Edit = Backbone.View.extend({
    avatar_modal: '#channel_avatar_modal',
    template: HandlebarsTemplates['wizard/image_cropper'],
    el: 'body.channel_form_page',
    events: {
        'focusout #channel_form ul.tagit input': 'focusoutTags',
        'focusin #channel_form ul.tagit input': 'focusinTags',
        'change #channel_form input, #channel_form select, #channel_form textarea': 'validateForm',
        'dragover [id*="-upload-area"]': function (e) {
            return e.preventDefault();
        },
        'click #channel_avatar_modal .cropOptions .crop': 'cropLogo',
        'click #channel_avatar_modal .cropOptions .clear': 'сancelCropLogo',
        'change input#channel-logo': 'setImageLogo',
        'drop #logo-upload-area': 'setImageLogo',
        'click #channel_cover_modal .cropOptions .crop': 'cropCover',
        'click #channel_cover_modal .cropOptions .clear': 'cancelCropCover',
        'change input#channel-cover': 'setImageCover',
        'drop #cover-upload-area': 'setImageCover',
        'change input#channel-gallery': 'addGalleryImage',
        'drop #gallery-upload-area': 'addGalleryImage',
        'click .remove_gallery_image': 'removeGalleryItem',
        'submit #channel_form': 'processSubmit',
        'submit form#addFromUrl': 'addFromUrl'
    },

    initialize: function () {
        this.gallery_image_template = HandlebarsTemplates['channel/gallery_image'];
        this.gallery_link_template = HandlebarsTemplates['channel/gallery_link'];
        this.channel = new Backbone.Model({
            id: this.$('form#channel_form [name="channel[id]"]').val(),
            title: this.$('form#channel_form [name="channel[title]"]').val(),
            description: this.$('form#channel_form [name="channel[description]"]').val(),
            category_id: this.$('form#channel_form [name="channel[category_id]"]').val(),
            tag_list: this.$('form#channel_form [name="channel[tag_list]"]').val()
        });
        this.logo = new Channel.Logo();
        this.listenTo(this.logo, 'invalid', this.showUploader);
        this.listenTo(this.logo, 'image:loaded', this.showCropper);
        this.listenTo(this.logo, 'crop:done', this.logoCropDone);
        this.cover = new Channel.Cover();
        this.listenTo(this.cover, 'invalid', this.showUploader);
        this.listenTo(this.cover, 'image:loaded', this.showCropper);
        this.listenTo(this.cover, 'crop:done', this.coverCropDone);
        this.gallery = new Channel.Gallery([], {
            channel: this.channel
        });
        _.each(this.$('.gallery_tile_list .gallery_tile'), (function (_this) {
            return function (tile) {
                return _this.gallery.add($(tile).data());
            };
        })(this));
        this.listenTo(this.gallery, 'image:loaded', this.showGalleryImage);
        this.listenTo(this.gallery, 'link:fetched', this.showGalleryLink);
        this.listenTo(this.gallery, 'fetch:start', this.disableGalleryForm);
        this.listenTo(this.gallery, 'fetch:complete', this.enableGalleryForm);
        this.prepareForm();
        $('#channel_tag_list').tagit({
            afterTagAdded: function () {
                return $('#channel_tag_list').trigger('focusout', $('#channel_tag_list'));
            }
        });
        this.render();
    },

    render: function () {
        this.prepareInputs();
    },
    prepareForm: function () {
        this.crop_container = '.crop-container:visible';
        this.$form = this.$('form#channel_form');
        this.$save = this.$('#channel_save_btn');
        this.$phone = this.$('#user_user_account_attributes_phone');
        this.prepareValidator();
        var options = {
                debug: 'info',
                modules: {toolbar: '#descriptionToolbar'},
                theme: 'snow'
            };
        this.editor = new Quill('#descriptionEditor', options);
        var that = this;
        this.editor.on('text-change', function () {
            that.checkVisitUrlValidation()
            that.$('form#channel_form [name="channel[description]"]').val(that.editor.root.innerHTML)
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

    focusoutTags: function (e) {
        if ($(e.target).val().length === 0) {
            return this.$('#channel_tag_list').trigger('focusout', this.$('#channel_tag_list'));
        }
    },

    focusinTags: function (e) {
        return this.$('#channel_tag_list').trigger('focusin', this.$('#channel_tag_list'));
    },

    prepareValidator: function () {
        var $defaults, $this;
        $this = this;
        $defaults = {
            rules: {
                'channel[title]': {
                    required: true,
                    minlength: 5,
                    maxlength: 72,
                    remote: {
                        url: Routes.channel_title_remote_validations_path(),
                        data: {
                            id: function () {
                                return $this.channel.id;
                            }
                        }
                    }
                },
                'channel[tagline]': {
                    required: false,
                    minlength: 0,
                    maxlength: 160
                },
                'channel[category_id]': {
                    required: true
                },
                'channel[tag_list]': {
                    required: true,
                    tagsUniqueness: true,
                    tagsLength: {
                        minlength: 1,
                        maxlength: 20
                    },
                    tagLength: {
                        minlength: 2,
                        maxlength: 160
                    }
                }
            },
            messages: {
                'channel[title]': {
                    remote: 'This name is already in use.'
                }
            },
            errorElement: 'span',
            ignore: '.ignore',
            onkeyup: false,
            onclick: false,
            focusCleanup: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block, .select-tag-block, .select-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block, .select-tag-block, .select-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block, .select-tag-block, .select-block');
                return wrapper.removeClass('error').addClass('valid');
            }
        };
        this.$form.validate($defaults);
        return this.validator = this.$form.data('validator');
    },

    prepareInputs: function () {
        this.$('.input-block').find('input[type=text], textarea').on('blur', function () {
            window.Wizard.Utils.formatInput(this);
        });
        $.each(this.$('.input-block textarea[data-autoresize]'), function (i, element) {
            window.Wizard.Utils.resizeTextarea(element);
            window.Wizard.Utils.setCount(element);
            $(element).removeAttr('data-autoresize');
        });
        $.each(this.$('.input-block input.with_counter'), function (i, element) {
            window.Wizard.Utils.setCount(element);
        });
        var that = this;
        this.$('.input-block textarea, .input-block input.with_counter').on('keydown keyup focus blur change', function (e) {
            if (that.validator && $(e.target).parents('.input-block').find('.counter_block').length > 0) {
                if (that.isElementValid(e.target)) {
                    $(e.target).parents('.input-block').find('.counter_block').removeClass('error');
                } else {
                    $(e.target).parents('.input-block').find('.counter_block').addClass('error');
                }
            }
            window.Wizard.Utils.setCount(e.target);
        });
    },

    checkForm: function () {
        if (!this.validator) {
            return;
        }
        return this.isFormValid();
    },

    validateForm: function () {
        if (this.$save.hasClass('disabled')) {
            this.validator.showErrors();
        }
    },

    isFormValid: function () {
        return this.validator.isValid();
    },

    isElementValid: function (el) {
        return this.validator.check(el);
    },


    /* Crop things */

    showUploader: function (e) {
        this.$('.modal:visible .upload-area .row, .modal:visible .upload-info span').show('fast');
        this.$('.modal:visible .upload-info span').show('fast');
        return this.$('.modal:visible .LoadingCover').addClass('hidden');
    },

    showCropper: function (item) {
        this.$(this.crop_container).html(this.template(item.cropData()));
        this.$(this.crop_container).show('fast');
        this.hideUploader();
        initCrop(item.cropperParams());
    },

    showLoader: function () {
        this.$('.upload-info:visible span').hide('fast');
        this.$('.upload-area:visible .row').show('fast');
        this.$('.modal:visible .LoadingCover').removeClass('hidden');
    },

    hideUploader: function () {
        this.$('.upload-area:visible .row').hide('fast');
    },

    hideCropper: function () {
        this.$(this.crop_container).html('');
        return this.showUploader();
    },

    logoCropDone: function (e) {
        this.$('#channel_logo').attr('style', "background-image: url(" + (this.logo.get('img_src')) + ")");
        this.showUploader();
        return this.$('#channel_avatar_modal').modal('hide');
    },

    coverCropDone: function (e) {
        this.$('#channel_cover.ChannelCover a').html('Edit');
        this.$('#channel_cover').attr('style', "background-image: url(" + (this.cover.get('img_src')) + ")");
        this.$('#cover-upload-area .upload-info').attr('style', "background-image: url(" + (this.cover.get('img_src')) + ")");
        this.$('#cover-upload-area .dotsWrapp').addClass('hidden');
        if (!this.$('#channel_logo').attr('logoID') && !this.logo.get('image')) {
            this.$('#channel_logo').attr('style', "background-image: url(" + (this.cover.get('img_src')) + ")");
        }
        return this.showUploader();
    },

    setImageLogo: function (e) {
        var files;
        e.preventDefault();
        this.showLoader();
        files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
        if (files && files[0]) {
            this.logo.set({
                file: files[0]
            });
            this.logo.trigger('file:uploaded', this.logo);
        } else {
            this.showUploader();
        }
        this.clearFileInput();
    },

    setImageCover: function (e) {
        var files;
        e.preventDefault();
        e.stopPropagation();
        this.showLoader();
        files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
        if (files && files[0]) {
            this.cover.set({
                file: files[0]
            });
            this.cover.trigger('file:uploaded', this.cover);
        } else {
            this.showUploader();
        }
        this.clearFileInput();
    },

    cropLogo: function (e) {
        var cropData, croppedCanvas;
        e.preventDefault();
        this.showLoader();
        cropData = this.$(this.crop_container).find('#crop-img').cropper('getData');
        croppedCanvas = this.$(this.crop_container).find('#crop-img').cropper('getCroppedCanvas');
        this.$(this.crop_container).html('');
        return this.logo.crop(cropData, croppedCanvas);
    },

    cropCover: function (e) {
        var cropData, croppedCanvas;
        e.preventDefault();
        this.showLoader();
        cropData = this.$(this.crop_container).find('#crop-img').cropper('getData');
        croppedCanvas = this.$(this.crop_container).find('#crop-img').cropper('getCroppedCanvas');
        this.$(this.crop_container).html('');
        this.cover.crop(cropData, croppedCanvas);
    },

    сancelCropLogo: function (e) {
        e.preventDefault();
        this.showUploader();
        this.$(this.crop_container).html('');
        this.logo.clearFile();
    },

    cancelCropCover: function (e) {
        e.preventDefault();
        this.showUploader();
        this.$(this.crop_container).html('');
        this.cover.clearFile();
    },

    clearFileInput: function () {
        return _.each(this.$('.modal:visible input.inputfile, .modal:visible input.gallery-inputfile'), function (item) {
            $(item).wrap('<form>').closest('form').get(0).reset();
            return $(item).unwrap();
        });
    },

    addGalleryImage: function (e) {
        var files;
        e.preventDefault();
        e.stopPropagation();
        files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
        if (files && files[0]) {
            _.each(files, (function (_this) {
                return function (file) {
                    var image;
                    image = new Channel.GalleryImage({
                        file: file,
                        type: 'image',
                        collection: _this.gallery
                    });
                    if (image.isValid()) {
                        _this.gallery.add(image);
                        return image.trigger('file:uploaded');
                    }
                };
            })(this));
        }
        return this.clearFileInput();
    },

    removeGalleryItem: function (e) {
        var data, item, model;
        e.preventDefault();
        data = $(e.currentTarget).parents('.gallery_tile').data();
        $(e.currentTarget).parents('.gallery_tile').remove();
        if (data.id) {
            item = this.gallery.findWhere({
                id: data.id
            });
            if (item) {
                return item.set({
                    '_destroy': 1
                });
            }
        } else if (data.cid) {
            model = this.gallery.get(data.cid);
            this.gallery.remove(model);
        }
    },

    showGalleryImage: function (item) {
        $(this.gallery_image_template(item.toJSON())).insertBefore(this.$('#gallery-upload-area'));
    },

    showGalleryLink: function (item) {
        this.$('#webAddressTab .gallery_tile_list').append(this.gallery_link_template(item.toJSON()));
    },

    addFromUrl: function (e) {
        var image, url;
        e.stopPropagation();
        e.preventDefault();
        url = this.$("form#addFromUrl input").val();
        image = new Channel.GalleryLink({
            url: url,
            collection: this.gallery
        });
        if (image.isValid() && image.isNew()) {
            return image.fetchLink();
        }
    },

    disableGalleryForm: function () {
        return this.$('form#addFromUrl button').addClass('disabled').attr('disabled', true);
    },

    enableGalleryForm: function () {
        this.$('form#addFromUrl')[0].reset();
        return this.$('form#addFromUrl button').removeClass('disabled').removeAttr('disabled');
    },
    processSubmit: function (e) {
        e.preventDefault();
        if (this.checkForm()) {
            var that = this;
            $.ajax({
                url: this.$form.attr('action'),
                data: this.formData(),
                type: this.$form.attr('method'),
                processData: false,
                contentType: false,
                dataType: 'json',
                beforeSend: function () {
                    that.$save.attr('disabled', true).addClass('disabled').val('Saving...');
                    return that.$('.profile_next_cover').show();
                },
                success: function (data) {
                    that.$save.html('Saved');
                    window.location.href = data.path;
                },
                error: function (data, error) {
                    var msg;
                    msg = data.status >= 500 ? data.statusText : data.responseText;
                    $.showFlashMessage(msg, {
                        type: 'error'
                    });
                    that.$save.removeAttr('disabled').removeClass('disabled').val('Save');
                    that.$('.profile_next_cover').hide();
                }
            });
        }
    },

    formData: function () {
        var form_data;
        form_data = new FormData(this.$form[0]);
        if (this.logo.get('image')) {
            _(this.logo.toFormData()).each(function (data) {
                return form_data.append.apply(form_data, data);
            });
        }
        if (this.cover.get('image')) {
            _(this.cover.toFormData()).each(function (data) {
                return form_data.append.apply(form_data, data);
            });
        }
        _(this.gallery.toFormData()).each(function (data) {
            return form_data.append.apply(form_data, data);
        });
        return form_data;
    }
});


Channel.Logo = Backbone.Model.extend({
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
        if (attrs.img && (attrs.img.width < 100 || attrs.img.height < 100)) {
            return 'Avatar should be at least 100x100 px';
        }
    },

    parseData: function (file) {
        return _.defer((function (_this) {
            return function () {
                var reader;
                if (_this.isValid()) {
                    file = _this.get("file");
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
        this.trigger('crop:done', this);
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
            aspectRatio: 1 / 1
        };
    },

    toFormData: function () {
        var data;
        data = [];
        if (this.get('image')) {
            data.push(['channel[logo_attributes][original]', this.get('image')]);
            data.push(['channel[logo_attributes][crop_x]', this.get('crop_x')]);
            data.push(['channel[logo_attributes][crop_y]', this.get('crop_y')]);
            data.push(['channel[logo_attributes][crop_w]', this.get('crop_w')]);
            data.push(['channel[logo_attributes][crop_h]', this.get('crop_h')]);
            data.push(['channel[logo_attributes][rotate]', this.get('rotate')]);
        }
        return data;
    }
});

Channel.Cover = Backbone.Model.extend({
    initialize: function () {
        this.on('invalid', this.showErrors);
        this.on('invalid', this.clearFile);
        return this.on('file:uploaded', this.parseData);
    },

    validate: function (attrs) {
        if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
            return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
        if (attrs.file && attrs.file.size > 10485760) {
            return "File " + attrs.file.name + " is too large. Maximum allowed file size is 10 megabytes (10485760 bytes).";
        }
        if (attrs.img && (attrs.img.width < 415 || attrs.img.height < 115)) {
            return 'Cover should be at least 415x115 px';
        }
    },

    parseData: function (file) {
        return _.defer((function (_this) {
            return function () {
                var reader;
                if (_this.isValid()) {
                    file = _this.get("file");
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
            aspectRatio: 970 / 266
        };
    },

    toFormData: function () {
        var data;
        data = [];
        if (this.get('image')) {
            data.push(['channel[cover_attributes][image]', this.get('image')]);
            data.push(['channel[cover_attributes][crop_x]', this.get('crop_x')]);
            data.push(['channel[cover_attributes][crop_y]', this.get('crop_y')]);
            data.push(['channel[cover_attributes][crop_w]', this.get('crop_w')]);
            data.push(['channel[cover_attributes][crop_h]', this.get('crop_h')]);
            data.push(['channel[cover_attributes][rotate]', this.get('rotate')]);
            data.push(['channel[cover_attributes][is_main]', true]);
        }
        return data;
    }
});

Channel.GalleryLink = Backbone.Model.extend({

    defaults: {
        type: 'link',
        on_save: false
    },

    initialize: function (options) {
        this.collection = options.collection;
        this.on('invalid', this.showErrors);
        return this.on('invalid', this.dispose);
    },

    validate: function (attrs) {
        if ($.trim(attrs.url) === "") {
            return "Url of supporting material must be present.";
        }
        if (!/^(https?:\/\/)?(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(attrs.url)) {
            return "You must provide a valid url.";
        }
        if (this.collection.where({
            type: "link"
        }).length > 10) {
            return "Link " + attrs.url + " will not be added - maximum 10 links are allowed";
        }
        if (this.collection.where({
            url: attrs.url
        }).length > 0) {
            return "Link with " + attrs.url + " is already in the list";
        }
    },

    fetchLink: function () {
        return $.ajax({
            url: Routes.channel_links_path(),
            data: "channel_link[url]=" + (this.get('url')) + "&width=197",
            type: 'POST',
            dataType: 'json',
            beforeSend: (function (_this) {
                return function () {
                    return _this.collection.trigger('fetch:start');
                };
            })(this),
            success: (function (_this) {
                return function (data) {
                    _this.set(data, {
                        silent: true
                    });
                    if (_this.isValid()) {
                        _this.collection.add(_this);
                        return _this.collection.trigger('link:fetched', _this);
                    }
                };
            })(this),
            error: (function (_this) {
                return function (data, error) {
                    var msg;
                    _this.collection.trigger('fetch:error', _this);
                    _this.collection.remove(_this);
                    msg = data.responseJSON && data.responseJSON.error ? data.responseJSON.error : data.statusText || data.responseText;
                    return $.showFlashMessage(msg, {
                        type: 'error'
                    });
                };
            })(this),
            complete: (function (_this) {
                return function () {
                    return _this.collection.trigger('fetch:complete');
                };
            })(this)
        });
    },

    showErrors: function () {
        return $.showFlashMessage(this.validationError, {
            type: "error"
        });
    },

    toJSON: function () {
        return {
            id: this.id,
            cid: this.cid,
            type: this.get('type'),
            embedded: this.get('embedded'),
            img_src: this.get('img_src')
        };
    }
});

Channel.GalleryImage = Backbone.Model.extend({
    url: Routes.save_channel_gallery_image_become_presenter_steps_path(),

    defaults: {
        type: 'image',
        on_save: false
    },

    initialize: function (options) {
        this.collection = options.collection;
        this.on('file:uploaded', this.parseData);
        return this.on('invalid', this.showErrorsAndRemove);
    },

    validate: function (attrs) {
        if (!/.+\.(jpg|jpeg|png|bmp)$/i.test(attrs.file.name)) {
            return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp';
        }
        if (attrs.img && (attrs.img.width < 300 || attrs.img.height < 150)) {
            return "Gallery image should be at least 300x150px (recommended 2560x1440px)";
        }
        if (this.collection.where({
            type: 'image'
        }).length > 10) {
            return "Image " + attrs.file.name + " will not be added - maximum 10 images are allowed";
        }
    },

    destroy: function () {
        if (this.id) {
            $.ajax({
                url: Routes.remove_channel_image_become_presenter_steps_path(),
                data: {
                    channel_id: this.collection.channel.id,
                    id: this.id
                },
                type: 'DELETE',
                dataType: 'json'
            });
        }
        return this.remove();
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

    showErrorsAndRemove: function () {
        $.showFlashMessage(this.validationError, {
            type: 'error'
        });
        return this.collection.remove(this, {
            silent: true
        });
    },

    toJSON: function () {
        return {
            id: this.id,
            cid: this.cid,
            type: this.get('type'),
            base64_img: this.get('base64_img')
        };
    }
});

Channel.Gallery = Backbone.Collection.extend({

    initialize: function (models, options) {
        this.channel = options.channel;
    },

    model: function (attrs, options) {
        if (attrs.type === 'link') {
            return new Channel.GalleryLink(attrs, options);
        } else {
            return new Channel.GalleryImage(attrs, options);
        }
    },

    toFormData: function () {
        var data;
        if (this.models.length === 0) {
            return [];
        }
        data = [];
        _(this.models).each(function (item, i) {
            if (item.get('type') === 'image' && !item.get('_destroy') && !item.get('file')) {
                return;
            }
            if (item.get('type') === 'image') {
                if (item.get('id')) {
                    data.push(["channel[images_attributes][" + i + "][id]", item.get('id')]);
                }
                if (item.get('file')) {
                    data.push(["channel[images_attributes][" + i + "][image]", item.get('file')]);
                }
                data.push(["channel[images_attributes][" + i + "][is_main]", false]);
                if (item.get('_destroy')) {
                    return data.push(["channel[images_attributes][" + i + "][_destroy]", item.get('_destroy')]);
                }
            } else {
                if (item.get('id')) {
                    data.push(["channel[channel_links_attributes][" + i + "][id]", item.get('id')]);
                }
                if (item.get('url')) {
                    data.push(["channel[channel_links_attributes][" + i + "][url]", item.get('url')]);
                }
                if (item.get('_destroy')) {
                    return data.push(["channel[channel_links_attributes][" + i + "][_destroy]", item.get('_destroy')]);
                }
            }
        });
        return data;
    }
});
