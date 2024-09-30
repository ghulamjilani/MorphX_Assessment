+function () {
    "use strict";
    window.Wizard.Views.Business = Backbone.View.extend({
        settings: {
            rules: {
                'organization[name]': {
                    required: true,
                    minlength: 2,
                    maxlength: 50,
                    regex: '^[A-Za-zF0-9].+',
                    remote: {
                        url: Routes.organization_name_remote_validations_path(),
                        data: {
                            id: function () {
                                var id = $('input[name="organization[id]"]').val();
                                if (!id.length)
                                    id = null;
                                return id;
                            }
                        }
                    }
                },
                'organization[website_url]': {
                    maxlength: 150,
                    url: true
                },
                'organization[social_links_attributes][0][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][0][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][0][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][1][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][1][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][1][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][2][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][2][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][2][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][3][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][3][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][3][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][4][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][4][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][4][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][5][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][5][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][5][provider]"]').val();
                            },
                        }
                    }
                },
                'organization[social_links_attributes][6][link]': {
                    remote: {
                        url: Routes.social_link_remote_validations_path(),
                        data: {
                            link: function () {
                                return $('input[name="organization[social_links_attributes][6][link]"]').val();
                            },
                            provider: function () {
                                return $('input[name="organization[social_links_attributes][6][provider]"]').val();
                            },
                        }
                    }
                },
            },
            messages: {
                'organization[name]': {
                    remote: 'This name is already in use.'
                },
                'organization[website_url]': {
                    url: 'Please enter a valid URL (eg: https://example.com)'
                },
                'organization[social_links_attributes][0][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][1][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][2][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][3][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][4][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][5][link]': {remote: 'This does not seem to be a valid URL'},
                'organization[social_links_attributes][6][link]': {remote: 'This does not seem to be a valid URL'},
            }
        },
        logo_modal: '#business_logo_modal',
        cover_modal: '#business_cover_modal',
        template: HandlebarsTemplates['wizard/image_cropper'],
        el: 'body.wizard_v2-business',
        events: {
            'change input, textarea': 'checkForm',
            'click #business_logo_modal .cropOptions .crop': function(e) {
                this.cropImage(e, 'logo')
            },
            'click #business_logo_modal .cropOptions .clear': function(e){
                this.cancelCropping(e, 'logo')
            },
            'change #business_logo_modal .inputfile': function(e){
                this.setImage(e, 'logo')
            },
            'dragover  #logo-upload-area': function (e) {
                return e.preventDefault(e, 'logo');
            },
            'drop #business_logo_modal .upload-info': function(e){
                this.setImage(e, 'logo')
            },

            'click #business_cover_modal .cropOptions .crop': function(e) {
                this.cropImage(e, 'cover')
            },
            'click #business_cover_modal .cropOptions .clear': function(e){
                this.cancelCropping(e, 'cover')
            },
            'change #business_cover_modal .inputfile': function(e){
                this.setImage(e, 'cover')
            },
            'dragover  #cover-upload-area': function (e) {
                return e.preventDefault(e, 'cover');
            },
            'drop #business_cover_modal .upload-info': function(e){
                this.setImage(e, 'cover')
            },
            'submit form.wizard_business_form': 'processSubmit',
        },

        initialize: function () {
            this.logo = new Wizard.BusinessLogo();
            this.listenTo(this.logo, 'invalid', function() {
                this.showUploader('#logo-upload-area')   
            });
            this.listenTo(this.logo, 'image:loaded', function() {
                this.showCropper('logo')   
            });
            this.listenTo(this.logo, 'crop:done', function() {
                this.cropDone('logo')
            });

            this.cover = new Wizard.BusinessCover();
            this.listenTo(this.cover, 'invalid', function() {
                this.showUploader('#cover-upload-area')   
            });
            this.listenTo(this.cover, 'image:loaded', function() {
                this.showCropper('cover')   
            });
            this.listenTo(this.cover, 'crop:done', function() {
                this.cropDone('cover')   
            });

            this.render();
            this.prepareForm();
        },

        prepareForm: function () {
            this.$logoCrop = this.$('#business_logo_modal .crop-container');
            this.$coverCrop = this.$('#business_cover_modal .crop-container');
            this.$form = this.$('form.wizard_business_form');
            this.$next = this.$('#business_next_btn');
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
                that.$('form.wizard_business_form [name="organization[description]"]').val(that.editor.root.innerHTML)
            });
            this.checkLinks()
        },

        checkLinks() {
            let inputTest = document.querySelector('.ql-tooltip input');
            if(inputTest) {
                inputTest.addEventListener('input', (event) => { validateLinks(event) })
                inputTest.addEventListener('focus', (event) => { validateLinks(event) })
                inputTest.addEventListener('blur', (event) => { clearLinks(event) })
            }
        },

        prepareValidator: function () {
            console.log('prepareValidator');
            var $defaults, $this;
            $this = this;
            $defaults = {
                rules: {},
                errorElement: 'span',
                ignore: '[type=file], [contenteditable="true"].ql-editor, [contenteditable="true"].ql-clipboard',
                onkeyup: false,
                onclick: false,
                focusCleanup: true,
                errorPlacement: function (error, element) {
                    error.appendTo(element.parents('.input-block').find('.errorContainerWrapp')).addClass('errorContainer');
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
            $.extend($defaults, this.settings);
            this.$form.validate($defaults);
            this.$form.on('validation:remote:start', function () {
                $this.$next.attr('disabled', true).addClass('disabled');
            });
            this.validator = this.$form.data('validator');
        },

        prepareInputs: function () {
            this.$('.input-block').find('input[type=text], textarea').on('blur', function () {
                window.Wizard.Utils.formatInput(this);
            });
            var that = this;
            $.each(this.$('.input-block textarea[data-autoresize]'), function (i, element) {
                window.Wizard.Utils.resizeTextarea(element);
                window.Wizard.Utils.setCount(element);
                $(element).removeAttr('data-autoresize');
            });
            $.each(this.$('.input-block input.with_counter'), function (i, element) {
                return window.Wizard.Utils.setCount(element);
            });
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
            console.log('checkForm');
            if (!this.validator) {
                return;
            }
            if (this.isFormValid()) {
                return this.$next.removeAttr('disabled').removeClass('disabled');
            } else {
                return this.$next.attr('disabled', true).addClass('disabled');
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

        getTemplateData: function (cropper) {
            if(!cropper){ cropper = 'logo'}
            return {
                cid: this[cropper].cid,
                base64_img: this[cropper].get('base64_img')
            };
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
                        that.$('#business_next_btn').attr('disabled', true).addClass('disabled').val('Saving...');
                    },
                    success: function (data) {
                        $.showFlashMessage('Business saved', {type: 'success'});
                        that.$('#business_next_btn').html('Saved');
                        window.location.href = data.redirect_path;
                    },
                    error: function (data, error) {
                        var msg;
                        msg = data.status >= 500 ? data.statusText : data.responseText;
                        $.showFlashMessage(msg, {type: 'error'});
                        that.$('#business_next_btn').removeAttr('disabled').removeClass('disabled').val('Next');
                    }
                });
            }
        },
        /* logo, cover upload & crop */
        showUploader: function (container) {
            this.$(container + ' .row, .upload-info span').show('fast');
            this.$(container + ' .upload-info span').show('fast');
            this.$('.LoadingCover').addClass('hidden');
        },

        showCropper: function (cropper) {
            this['$' + cropper + 'Crop'].html(this.template(this.getTemplateData(cropper)));
            this['$' + cropper + 'Crop'].show('fast');
            this.hideUploader('#business_' + cropper + '_modal');
            initCrop(this[cropper].cropperParams());
        },

        showLoader: function (container) {
            this.$(container + ' .upload-info span').hide('fast');
            this.$(container + ' .upload-area .row').show('fast');
            this.$(container + ' .LoadingCover').removeClass('hidden');
        },

        hideUploader: function (container) {
            this.$(container + ' .upload-area .row').hide('fast');
        },

        hideCropper: function () {
            this.$logoCrop.html('');
            this.showUploader();
        },

        cropDone: function (cropper) {
            this.$('#business_' + cropper).attr('style', 'background-image: url(' + this[cropper].get('img_src') + ')');
            this.$form.find('[name="organization[' + cropper + '_attributes][crop_x]"]').val(this[cropper].get('crop_x'));
            this.$form.find('[name="organization[' + cropper + '_attributes][crop_y]"]').val(this[cropper].get('crop_y'));
            this.$form.find('[name="organization[' + cropper + '_attributes][crop_w]"]').val(this[cropper].get('crop_w'));
            this.$form.find('[name="organization[' + cropper + '_attributes][crop_h]"]').val(this[cropper].get('crop_h'));
            this.$form.find('[name="organization[' + cropper + '_attributes][rotate]"]').val(this[cropper].get('rotate'));
            // const dT = new DataTransfer();
            // dT.items.add(this.logo.get('image'));
            // this.$form.find('[name="organization[logo_attributes][image]"]')[0].files = dT.files;
            this.showUploader('#' + cropper + '-upload-area');
            this.$('#business_' + cropper + '_modal').modal('hide');
        },

        setImage: function (e, cropper) {
            var files;
            e.preventDefault();
            this.showLoader('#business_' + cropper + '_modal');
            files = e.originalEvent && e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
            if (files && files[0]) {
                this[cropper].set({
                    file: files[0]
                });
                this[cropper].trigger('file:uploaded', this[cropper]);
            } else {
                this.showUploader('#' + cropper + '-upload-area');
            }
            this.clearFileInput();
        },

        cropImage: function (e, cropper) {
            var cropData, croppedCanvas;
            e.preventDefault();
            this.showLoader('#business_' + cropper + '_modal');
            cropData = this['$' + cropper + 'Crop'].find('#crop-img').cropper('getData');
            croppedCanvas = this['$' + cropper + 'Crop'].find('#crop-img').cropper('getCroppedCanvas');
            this['$' + cropper + 'Crop'].html('');
            this[cropper].crop(cropData, croppedCanvas);
        },

        cancelCropping: function (e, cropper) {
            e.preventDefault();
            this.showUploader('#' + cropper + '-upload-area');
            this['$' + cropper + 'Crop'].html('');
            this[cropper].clearFile();
        },

        clearFileInput: function () {
            var resetForms = this.$('input.inputfile').wrap('<form>').closest('form');
            for (var index = 0; index < resetForms.length; index++) {
                resetForms[index].reset();
            }
            this.$('input.inputfile').unwrap();
        }
    });

    window.Wizard.BusinessLogo = Backbone.Model.extend({

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
            if (attrs.img && (attrs.img.width < 100 || attrs.img.height < 100)) {
                return 'Logo should be at least 100x100px';
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
                        return img.src = e.target.result;
                    };
                    return reader.readAsDataURL(file);
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
                img_src: this.get('img_src'),
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
                data.push(['organization[logo_attributes][image]', this.get('image')]);
                data.push(['organization[logo_attributes][crop_x]', this.get('crop_x')]);
                data.push(['organization[logo_attributes][crop_y]', this.get('crop_y')]);
                data.push(['organization[logo_attributes][crop_w]', this.get('crop_w')]);
                data.push(['organization[logo_attributes][crop_h]', this.get('crop_h')]);
                data.push(['organization[logo_attributes][rotate]', this.get('rotate')]);
            }
            return data;
        },
    });

    Wizard.BusinessCover = Backbone.Model.extend({
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
                data.push(['organization[cover_attributes][image]', this.get('image')]);
                data.push(['organization[cover_attributes][crop_x]', this.get('crop_x')]);
                data.push(['organization[cover_attributes][crop_y]', this.get('crop_y')]);
                data.push(['organization[cover_attributes][crop_w]', this.get('crop_w')]);
                data.push(['organization[cover_attributes][crop_h]', this.get('crop_h')]);
                data.push(['organization[cover_attributes][rotate]', this.get('rotate')]);
            }
            return data;
        },
    });

}();
