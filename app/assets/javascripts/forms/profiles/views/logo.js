Forms.Profiles.Views.Logo = Forms.ImageUploaderModal.extend({
    el: '#publicLogoModal',

    cropper_params: {
        aspectRatio: 1 / 1
    },

    initialize: function () {
        this.model = new Forms.Profiles.Models.Logo;
        Forms.Profiles.Views.Logo.__super__.initialize.apply(this, arguments);
        return this;
    },

    render: function () {
        this.listenTo(this.model, 'crop:done', this.updatePreview);
    },

    autosave: function () {
        this.model.saveToUser();
    },

    updatePreview: function () {
        var userAvatarEl = $('.user-avatar.main');
        if (userAvatarEl) {
            userAvatarEl.css('background-image', "url('" + (this.model.get('img_src')) + "')");
            userAvatarEl.addClass('processing');
        }
        $('[id=profile-pic]:visible').css('background-image', "url('" + (this.model.get('img_src')) + "')");
    }
})
