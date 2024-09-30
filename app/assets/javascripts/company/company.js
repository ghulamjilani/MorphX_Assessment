window.Company = {
    Collections: {},
    Models: {},
    Views: {},
    edit: function (opts) {
        return new Company.Edit(opts);
    }
};

_.extend(window.Company, Backbone.Events);

Company.Edit = Backbone.View.extend({
    avatar_modal: '#company_logo_modal',
    cover_modal: '#company_cover_modal',
    template: HandlebarsTemplates['wizard/image_cropper'],
    el: 'body.company_form_page',
    events: {
        'dragover [id*="-upload-area"]': function (e) {
            return e.preventDefault();
        },

        // logo
        'click #company_logo_modal .cropOptions .crop': function(e) {
            this.cropImage(e, 'logo')
        },
        'click #company_logo_modal .cropOptions .clear': function(e) {
            this.сancelCropImage(e, 'logo')
        },
        'change input#company_logo_file': function(e) {
            this.setImage(e, 'logo')
        },
        'drop #logo-upload-area': function(e) {
            this.setImage(e, 'logo')
        },

        // cover
        'click #company_cover_modal .cropOptions .crop': function(e) {
            this.cropImage(e, 'cover')
        },
        'click #company_cover_modal .cropOptions .clear': function(e) {
            this.сancelCropImage(e, 'cover')
        },
        'change input#company_cover_file': function(e) {
            this.setImage(e, 'cover')
        },
        'drop #cover-upload-area': function(e) {
            this.setImage(e, 'cover')
        },

        'submit #company_form': 'processSubmit',
        'click #add_mind_body_submit': 'mindBodyActivate',
        'change #stop_no_stream_sessions_checkbox': 'changedStopNoStreamSessions'
    },

    initialize: function (params) {
        this.company = new Backbone.Model({
            id: this.$('form#company_form [name="organization[id]"]').val(),
            name: this.$('form#company_form [name="organization[name]"]').val(),
            description: this.$('form#company_form [name="organization[description]"]').val(),
            website_url: this.$('form#company_form [name="organization[website_url]"]').val()
        });
        this.logo = new Company.Logo();
        this.cover = new Company.Cover();
        // logo
        this.listenTo(this.logo, 'invalid', function() {
            this.showUploader('logo')
        });
        this.listenTo(this.logo, 'image:loaded',  function(item) {
            this.showCropper(item, 'logo')
        });
        this.listenTo(this.logo, 'crop:done', function(e){
            this.imageCropDone(e, 'logo')
        });
        // cover
        this.listenTo(this.cover, 'invalid', function() {
            this.showUploader('cover')
        });
        this.listenTo(this.cover, 'image:loaded',  function(item) {
            this.showCropper(item, 'cover')
        });
        this.listenTo(this.cover, 'crop:done', function(e){
            this.imageCropDone(e, 'cover')
        });

        this.prepareForm();
        this.prepareInputs();
        this.render();
        return this;
    },
    changedStopNoStreamSessions: function(e) {
        if(e.target.checked) {
            $("#stopNoStreamSessions").removeClass("hidden")
            $("#stop_no_stream_sessions_text").val("15")
        }
        else {
            $("#stopNoStreamSessions").addClass("hidden")
            $("#stop_no_stream_sessions_text").val("0")
        }
    },
    processSubmit: function (e) {
        e.preventDefault();
        var that = this;
        $.ajax({
            url: this.$form.attr('action'),
            data: this.formData(),
            type: this.$form.attr('method'),
            processData: false,
            contentType: false,
            dataType: 'json',
            beforeSend: function () {
                return that.$save.attr('disabled', true).addClass('disabled').val('Saving...');
            },
            success: function (data) {
                that.$save.val('Saved');
                window.location.href = data.path;
            },
            error: function (data, error) {
                var msg;
                msg = data.status >= 500 ? data.statusText : data.responseText;
                $.showFlashMessage(msg, {
                    type: 'error'
                });
                that.$save.removeAttr('disabled').removeClass('disabled').val('Save');
            }
        });
    },
    mindBodyActivate: function (e) {
        e.preventDefault();
        if (this.$('input#site_id').val().length < 1) {
            return $.showFlashMessage('Please set business/site id', {
                type: 'error'
            });
        } else {
            var that = this;
            $.ajax({
                url: this.$('#add_mind_body_form').data('action'),
                data: {site_id: this.$('input#site_id').val()},
                type: 'POST',
                dataType: 'json',
                beforeSend: function () {
                    that.$('#add_mind_body_submit').attr('disabled', true).addClass('disabled').val('Saving...');
                },
                success: function (data) {
                    that.$('#add_mind_body_submit').removeAttr('disabled').removeClass('disabled').val('Activate');
                    window.open(data.response.activate_link, '_blank');
                    return true;
                },
                error: function (data, error) {
                    var msg;
                    msg = data.status >= 500 ? data.statusText : data.responseText;
                    $.showFlashMessage(msg, {
                        type: 'error'
                    });
                    that.$('#add_mind_body_submit').removeAttr('disabled').removeClass('disabled').val('Activate');
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
        return form_data;
    },

    prepareForm: function () {
        this.crop_container = '.crop-container:visible';
        this.$form = this.$('form#company_form');
        this.$save = this.$('#company_save_btn');
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
            that.$('form#company_form [name="organization[description]"]').val(that.editor.root.innerHTML)
        });
        this.checkLinks()

        if($("#stop_no_stream_sessions_text").val() != '' && $("#stop_no_stream_sessions_text").val() != '0'){
            $("#stopNoStreamSessions").removeClass("hidden")
            $("#stop_no_stream_sessions_checkbox").prop('checked', true)
        }
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

    prepareValidator: function () {
        var $defaults, $this;
        $this = this;
        $defaults = {
            rules: {
                'organization[name]': {
                    required: true,
                    minlength: 1,
                    maxlength: 50,
                    regex: '^[A-Za-zF0-9].+',
                    remote: {
                        url: Routes.organization_name_remote_validations_path(),
                        data: {
                            id: function () {
                                return $this.company.id;
                            }
                        }
                    }
                },
                'organization[website_url]': {
                    maxlength: 150,
                    url: true
                },
                'organization[embed_domains]': {
                    maxlength: 500,
                    regex: '(?:https:\\/\\/[\\w\\d\\.\\-]{1,}\\.\\w{2,4}\\s?){1,}',
                }
            },
            messages: {
                'organization[name]': {
                    remote: 'This name is already in use.'
                },
                'organization[website_url]': {
                    url: 'Please enter a valid URL (eg: https://example.com)'
                }
            },
            errorElement: 'span',
            ignore: '.ignore',
            onclick: false,
            onkeyup: false,
            focusCleanup: true,
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block').find('.errorContainerWrapp')).addClass('errorContainer');
            },
            highlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.addClass('error').removeClass('valid');
            },
            unhighlight: function (element) {
                var wrapper;
                wrapper = $(element).parents('.input-block');
                return wrapper.removeClass('error').addClass('valid');
            }
        };
        this.$form.validate($defaults);
        this.validator = this.$form.data('validator');
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
        this.$form.find('.input-block textarea, .input-block input.with_counter').on('keydown keyup focus blur change', function (e) {
            if (that.validator && $(e.target).parents('.input-block').find('.counter_block').length > 0) {
                if (that.isElementValid(e.target, that.validator)) {
                    $(e.target).parents('.input-block').find('.counter_block').removeClass('error');
                } else {
                    $(e.target).parents('.input-block').find('.counter_block').addClass('error');
                }
            }
            window.Wizard.Utils.setCount(e.target);
        });
        if(this.$admin_form) {
            this.$admin_form.find('.input-block textarea, .input-block input.with_counter').on('keydown keyup focus blur change', function (e) {
                if (that.admin_validator && $(e.target).parents('.input-block').find('.counter_block').length > 0) {
                    if (that.isElementValid(e.target, that.admin_validator)) {
                        $(e.target).parents('.input-block').find('.counter_block').removeClass('error');
                    } else {
                        $(e.target).parents('.input-block').find('.counter_block').addClass('error');
                    }
                }
                window.Wizard.Utils.setCount(e.target);
            });
        }
    },

    isElementValid: function (el, validator) {
        return validator.check(el);
    },


    /* Crop things */

    showUploader: function (imageType) {
        this.$('#company_' + imageType +  '_modal' + '.modal:visible .upload-area .row, .modal:visible .upload-info span').show('fast');
        this.$('#company_' + imageType +  '_modal' + '.modal:visible .upload-info span').show('fast');
        this.$('#company_' + imageType +  '_modal' + '.modal:visible .LoadingCover').addClass('hidden');
        this.$('#company_' + imageType + '_file').val('');
    },

    showCropper: function (item, imageType) {
        this.$('#company_' + imageType +  '_modal ' + this.crop_container).html(this.template(item.cropData()));
        this.$('#company_' + imageType +  '_modal ' + this.crop_container).show('fast');
        this.hideUploader(imageType);
        initCrop(item.cropperParams());
        return this.$('#company_' + imageType + '_file').val('');
    },

    showLoader: function (imageType) {
        this.$('#company_' + imageType +  '_modal ' + '.upload-info:visible span').hide('fast');
        this.$('#company_' + imageType +  '_modal ' + '.upload-area:visible .row').show('fast');
        return this.$('#company_' + imageType +  '_modal' + '.modal:visible .LoadingCover').removeClass('hidden');
    },

    hideUploader: function (imageType) {
        return this.$('#company_' + imageType +  '_modal ' + '.upload-area:visible .row').hide('fast');
    },

    hideCropper: function () {
        this.$(this.crop_container).html('');
        return this.showUploader(imageType);
    },

    imageCropDone: function (e, imageType) {
        this.$('#company_' + imageType).attr('style', "background-image: url(" + (this[imageType].get('img_src')) + ")");
        this.showUploader(imageType);
        this.$('#company_' + imageType + '_modal').modal('hide');
        return this.$('#company_' + imageType + '_file').val('');
    },

    setImage: function (e, imageType) {
        var files;
        e.preventDefault();
        this.showLoader(imageType);
        files = e.originalEvent.dataTransfer ? e.originalEvent.dataTransfer.files : e.target.files;
        if (files && files[0]) {
            this[imageType].set({
                file: files[0]
            });
            return this[imageType].trigger('file:uploaded', this[imageType]);
        } else {
            return this.showUploader(imageType);
        }
    },

    cropImage: function (e, imageType) {
        var cropData, croppedCanvas;
        e.preventDefault();
        this.showLoader(imageType);
        cropData = this.$('#company_' + imageType +  '_modal ' + this.crop_container).find('#crop-img').cropper('getData');
        croppedCanvas = this.$('#company_' + imageType +  '_modal ' + this.crop_container).find('#crop-img').cropper('getCroppedCanvas');
        this.$('#company_' + imageType +  '_modal ' + this.crop_container).html('');
        return this[imageType].crop(cropData, croppedCanvas);
    },

    сancelCropImage: function (e, imageType) {
        e.preventDefault();
        this.showUploader(imageType);
        this.$('#company_' + imageType +  '_modal ' + this.crop_container).html('');
        return this[imageType].clearFile();
    },
});

Company.Logo = Backbone.Model.extend({
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
            return 'Avatar should be at least 100x100 px';
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
                            return that.trigger('image:loaded', that);
                        }
                    };
                    return img.src = e.target.result;
                };
                return reader.readAsDataURL(file);
            }
        });
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

Company.Cover = Backbone.Model.extend({
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