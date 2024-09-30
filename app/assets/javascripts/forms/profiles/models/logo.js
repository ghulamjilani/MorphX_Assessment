Forms.Profiles.Models.Logo = Forms.UploadedImage.extend({

    validate: function (attrs) {
        console.log('validate')
        Forms.Profiles.Models.Logo.__super__.validate.apply(this, arguments);
        if (attrs.file && !/^image\/(jpg|jpeg|png|bmp)/.test(attrs.file.type))
            return 'This format is not supported. Please use one of the following: jpg, jpeg, png, bmp'
        if (attrs.img && (attrs.img.width < 280 || attrs.img.height < 280))
            return "Avatar should be at least 280x280 px";
    },

    saveToUser: function () {
        var that = this
        $.ajax({
            url: Routes.save_logo_profile_path(),
            data: this.getFormData(),
            type: 'POST',
            processData: false,
            contentType: false,
            dataType: 'json',
            beforeSend: function () {
                that.autosaveStart();
            },
            success: function (data) {
                that.set(data);
                var userAvatarEl = $('.user-avatar.main');
                if (userAvatarEl)
                    userAvatarEl.removeClass('processing');

                $.showFlashMessage("Avatar has been successfully updated.", {
                    type: "success"
                });
                that.markAsSaved();
            },
            error: function (data, error) {
                that.set(that.previous('logo'));
                that.markAsChanged();
                that.trigger('logo:failed');
                $.showFlashMessage(data.responseText || data.statusText, {
                    type: "error"
                });
            },
            complete: function () {
                that.autosaveStop();
            }
        });
    },

    toFormData: function () {
        var data;
        if (this.get("saved") || !this.get("image")) {
            return [];
        }
        data = [];
        if (this.get("image")) {
            data.push(["user_account[logo][original_image]", this.get("image")]);
        }
        if (this.get("x")) {
            data.push(["user_account[logo][crop_x]", this.get("x")]);
        }
        if (this.get("y")) {
            data.push(["user_account[logo][crop_y]", this.get("y")]);
        }
        if (this.get("width")) {
            data.push(["user_account[logo][crop_w]", this.get("width")]);
        }
        if (this.get("height")) {
            data.push(["user_account[logo][crop_h]", this.get("height")]);
        }
        if (this.get("rotate")) {
            data.push(["user_account[logo][rotate]", this.get("rotate")]);
        }
        return data;
    }
})
