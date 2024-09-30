+function () {
    "use strict";
    Wizard.Views.Channel = Backbone.View.extend({
        avatar_modal: '#channel_avatar_modal',
        template: HandlebarsTemplates['wizard/image_cropper'],
        el: 'body.wizard_v2-channel',
        events: {
            'focusout #wizard_channel ul.tagit input': 'focusoutTags',
            'focusin #wizard_channel ul.tagit input': 'focusinTags',
            'change #wizard_channel input': 'checkForm',
            'blur #wizard_channel input': 'checkForm',
            'keyup #wizard_channel input': 'checkForm',
            'change #wizard_channel select': 'checkForm',
            'change #wizard_channel textarea': 'checkForm',
            'dragover [id*="-upload-area"]': function (e) {
                e.preventDefault();
            },
            'click #channel_cover_modal .cropOptions .crop': 'cropCover',
            'click #channel_cover_modal .cropOptions .clear': 'сancelCropCover',
            'change input#channel-cover': 'setImageCover',
            'drop #cover-upload-area': 'setImageCover',
            'submit form#wizard_channel': 'processSubmit',
        },
        initialize: function () {
            this.channel = new Backbone.Model({
                id: this.$('form#wizard_channel [name="channel[id]"]').val(),
                title: this.$('form#wizard_channel [name="channel[title]"]').val(),
                description: this.$('form#wizard_channel [name="channel[description]"]').val(),
                category_id: this.$('form#wizard_channel [name="channel[category_id]"]').val(),
                tag_list: this.$('form#wizard_channel [name="channel[tag_list]"]').val()
            });
            this.cover = new Wizard.ChannelCover();
            this.listenTo(this.cover, 'invalid', this.showUploader);
            this.listenTo(this.cover, 'image:loaded', this.showCropper);
            this.listenTo(this.cover, 'crop:done', this.coverCropDone);

            this.render();
            this.prepareForm();
            return this;
        },
        prepareForm: function () {
            this.crop_container = '.crop-container:visible';
            this.$form = this.$('form#wizard_channel');
            this.$next = this.$('#channel_next_btn');
            this.prepareValidator();
            this.prepareInputs();
            this.checkForm();
            var options = {
                debug: 'info',
                modules: {toolbar: '#descriptionToolbar'},
                theme: 'snow'
            };
            this.editor = new Quill('#descriptionEditor', options);
            var that = this;
            this.editor.on('text-change', function () {
                that.checkVisitUrlValidation()
                that.$('form.wizard_channel_form [name="channel[description]"]').val(that.editor.root.innerHTML)
            });
            $('#channel_tag_list').tagit({
                afterTagAdded: function () {
                    $('#channel_tag_list').trigger('focusout', $('#channel_tag_list'));
                }
            });
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

        focusoutTags: function (e) {
            if ($(e.target).val().length === 0) {
                this.$('#channel_tag_list').trigger('focusout', this.$('#channel_tag_list'));
            }
        },

        focusinTags: function (e) {
            this.$('#channel_tag_list').trigger('focusin', this.$('#channel_tag_list'));
        },

        prepareValidator: function () {
            var $defaults, that;
            that = this;
            $defaults = {
                rules: {
                    "channel[title]": {
                        required: true,
                        minlength: 5,
                        maxlength: 72,
                        remote: {
                            url: Routes.channel_title_remote_validations_path(),
                            data: {
                                id: function () {
                                    return that.channel.id;
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
                    'channel[title]': {
                        remote: 'This name is already in use.'
                    }
                },
                errorElement: 'span',
                ignore: '[type=file], [contenteditable="true"].ql-editor, [contenteditable="true"].ql-clipboard',
                onkeyup: false,
                onclick: false,
                focusCleanup: true,
                errorPlacement: function (error, element) {
                    error.appendTo(element.parents('.input-block, .select-tag-block').find('.errorContainerWrapp')).addClass('errorContainer');
                },
                highlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-tag-block');
                    wrapper.addClass('error').removeClass('valid');
                },
                unhighlight: function (element) {
                    var wrapper;
                    wrapper = $(element).parents('.input-block, .select-tag-block');
                    wrapper.removeClass('error').addClass('valid');
                },
                showErrors: function (errorMap, errorList) {
                    this.defaultShowErrors();
                }
            };
            this.$form.validate($defaults);
            this.validator = this.$form.data('validator');
        },

        prepareInputs: function () {
            var that = this;
            this.$('.input-block').find('input[type=text], textarea').on('blur', function () {
                window.Wizard.Utils.formatInput(this);
            });
            $.each(this.$('.input-block textarea[data-autoresize]'), (function (i, element) {
                window.Wizard.Utils.resizeTextarea(element);
                window.Wizard.Utils.setCount(element);
                $(element).removeAttr('data-autoresize');
            }));
            $.each(this.$('.input-block input.with_counter'), (function (i, element) {
                window.Wizard.Utils.setCount(element);
            }));
            this.$('.input-block textarea, .input-block input.with_counter').on('keydown keyup focus blur change', (function (e) {
                if (that.validator && $(e.target).parents('.input-block').find('.counter_block').length > 0) {
                    if (that.isElementValid(e.target)) {
                        $(e.target).parents('.input-block').find('.counter_block').removeClass('error');
                    } else {
                        $(e.target).parents('.input-block').find('.counter_block').addClass('error');
                    }
                }
                window.Wizard.Utils.setCount(e.target);
            }));
        },

        checkForm: function () {
            if (!this.validator) {
                return;
            }
            if (this.isFormValid()) {
                this.$next.removeAttr('disabled').removeClass('disabled');
            } else {
                this.$next.attr('disabled', true).addClass('disabled');
            }
        },

        vaidateForm: function () {
            if (this.$next.hasClass('disabled')) {
                this.validator.showErrors();
            }
        },

        isFormValid: function () {
            return this.validator.isValid();
        },

        isElementValid: function (el) {
            return this.validator.check(el);
        },
        formData: function () {
            var form_data;
            form_data = new FormData(this.$form[0]);
            if (this.cover.get('image')) {
                _(this.cover.toFormData()).each(function (data) {
                    return form_data.append.apply(form_data, data);
                });
            }
            return form_data;
        },
        processSubmit: function (e) {
            e.preventDefault();
            var that = this;
            if (this.isFormValid()) {
                $.ajax({
                    url: this.$form.attr('action'),
                    data: this.formData(),
                    type: this.$form.attr('method'),
                    processData: false,
                    contentType: false,
                    dataType: 'json',
                    beforeSend: function () {
                        that.$('#channel_next_btn').attr('disabled', true).addClass('disabled').val('Saving...');
                    },
                    success: function (data) {
                        $.showFlashMessage('Channel saved', {type: 'success'});
                        that.$('#channel_next_btn').html('Saved');
                        window.location.href = data.redirect_path;
                    },
                    error: function (data, error) {
                        var msg;
                        msg = data.status >= 500 ? data.statusText : data.responseText;
                        $.showFlashMessage(msg, {type: 'error'});
                        that.$('#channel_next_btn').removeAttr('disabled').removeClass('disabled').val('Next');
                    }
                });
            }
        },

        /* Crop things */

        showUploader: function (e) {
            this.$('.modal:visible .upload-area .row, .modal:visible .upload-info span').show('fast');
            this.$('.modal:visible .upload-info span').show('fast');
            this.$('.modal:visible .LoadingCover').addClass('hidden');
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
            this.showUploader();
        },

        coverCropDone: function (e) {
            this.$('#channel_cover.ChannelCover a').html('Edit');
            this.$('#channel_cover').attr('style', "background-image: url(" + (this.cover.get('img_src')) + ")");
            this.$('#cover-upload-area .upload-info').attr('style', "background-image: url(" + (this.cover.get('img_src')) + ")");
            this.$('#cover-upload-area .dotsWrapp').addClass('hidden');
            this.checkForm();
            // const dT = new DataTransfer();
            // dT.items.add(this.cover.get('image'));
            // this.$form.find('[name="channel[cover_attributes][image]"]')[0].files = dT.files;
            this.showUploader();
        },

        setImageCover: function (e) {
            e.preventDefault();
            e.stopPropagation();
            this.showLoader();
            var files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
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

        cropCover: function (e) {
            var cropData, croppedCanvas;
            e.preventDefault();
            this.showLoader();
            cropData = this.$(this.crop_container).find('#crop-img').cropper('getData');
            croppedCanvas = this.$(this.crop_container).find('#crop-img').cropper('getCroppedCanvas');
            this.$(this.crop_container).html('');
            $('#channel_cover_modal').modal('hide'); //close modal after crop channel cover
            return this.cover.crop(cropData, croppedCanvas);
        },

        сancelCropCover: function (e) {
            e.preventDefault();
            this.showUploader();
            this.$(this.crop_container).html('');
            this.cover.clearFile();
        },

        clearFileInput: function () {
            _.each(this.$('.modal:visible input.inputfile'), function (item) {
                $(item).wrap('<form>').closest('form').get(0).reset();
                $(item).unwrap();
            });
        }
    });

    Wizard.ChannelCover = Backbone.Model.extend({
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
                return 'Cover should be at least 415x115 px';
            }
        },

        parseData: function (file) {
            var that = this;
            _.defer(function () {
                var reader;
                if (that.isValid()) {
                    file = that.get("file");
                    reader = new FileReader;
                    reader.onload = function (e) {
                        var img;
                        img = new Image;
                        img.onload = function () {
                            that.set({
                                'base64_img': img.src,
                                img: img
                            });
                            if (that.isValid()) {
                                that.trigger('image:loaded', that);
                            }
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);
                }
            });
        },

        showErrors: function () {
            $.showFlashMessage(this.validationError, {
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
            this.unset('base64_img', {
                silent: true
            });
        },

        resetAttributes: function () {
            this.set(this.previousAttributes());
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
                aspectRatio: 7 / 3
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
            }
            return data;
        },
    });
}();
