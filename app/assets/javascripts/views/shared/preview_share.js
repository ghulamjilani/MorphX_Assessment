
+function(window){
    "use strict";

    // A main purpose of this function is to wrap given html string with "div" tag. This way, when you will be doing
    // something like $(template).html() - you will receive your original template instead of content of a tag inside your
    // template.
    function wrapHtml(html){
        return '<div class="mio_embed">' + html + '</div>';
    }
    function addUrlParam(url, key, value) {
        if(!url) { return; }
        var newParam = key + "=" + value;
        var result = url.replace(new RegExp("(&|\\?)"+key+"=[^\&|#]*"), '$1' + newParam);
        if (result === url) {
            result = (url.indexOf("?") !== -1 ? url.split("?")[0]+"?"+newParam+"&"+url.split("?")[1]
                : (url.indexOf("#") !== -1 ? url.split("#")[0]+"?"+newParam+"#"+ url.split("#")[1]
                    : url+'?'+newParam));
        }
        return result;
    }

    var EmbedCodeModifiers = {
        live: function($template){
            var $player = $template.find('[data-role="vplayer"]'),
                playerUrl = $player.attr('src');

            $player.attr('src', addUrlParam(playerUrl, 'live', 'true'));
        },
        chat: function($template){
            var $additions = $template.find('[data-role="additions"]');
            var url = $additions.attr('src');

            $additions.attr('src', addUrlParam(url, 'chat', 'true'));
        },
        playlist: function($template){
            var $additions = $template.find('[data-role="additions"]'),
                $player = $template.find('[data-role="vplayer"]'),
                additionsUrl = $additions.attr('src'),
                playerUrl = $player.attr('src');

            $additions.attr('src', addUrlParam(additionsUrl, 'external_playlist', 'true'));
            $player.attr('src', addUrlParam(playerUrl, 'external_playlist', 'true'));
        },
        single: function($template){
            var $additions = $template.find('[data-role="additions"]'),
                $player = $template.find('[data-role="vplayer"]'),
                additionsUrl = $additions.attr('src'),
                playerUrl = $player.attr('src');

            $additions.attr('src', addUrlParam(additionsUrl, 'single_item', 'true'));
            $player.attr('src', addUrlParam(playerUrl, 'single_item', 'true'));
        }
    };
    var EmbedCodePreview = function($shareModal){
        this.$el = $shareModal;
        this.initDefaultValues();
        this.bindEvents();
    };
    EmbedCodePreview.prototype.render = function(){
        this.applyRestrictions();
        this.refreshTemplateOptions();
        this.refreshModOptions();
        this.showPreview();
    };
    EmbedCodePreview.prototype.bindEvents = function(){
        this.$el.on('change', '#embedSwitch', function(){
           $(this).closest('#social-modal').toggleClass('embedActive')
        });
        this.$el.on('change', '.template-option, .mod-option', $.proxy(function(){
            this.initDefaultValues();
            this.render();
        }, this));
    };
    EmbedCodePreview.prototype.refreshTemplateOptions = function(){
        var that = this;
        // Collect template options from checked checkboxes
        this.$el.find('.template-option:checked').each(function(){
            var tmplValue = $(this).data('tmpl');
            if(that.tmplOptions.indexOf(tmplValue) === -1) {
                that.tmplOptions.push(tmplValue);
            }
        });
    };
    EmbedCodePreview.prototype.refreshModOptions = function(){
        var that = this;
        // Collect mod options from checked checkboxes
        this.$el.find('.mod-option:checked').each(function(){
            var modValue = $(this).data('mod');
            if(that.modOptions.indexOf(modValue) === -1) {
                that.modOptions.push(modValue);
            }
        });
    };
    EmbedCodePreview.prototype.getTemplate = function(){
        var that = this, templateEl;
        templateEl = _.find(this.$el.find('.widgetEmbeds script').toArray(), function(el){
            var templateTags = $(el).data('template').split(',').sort(), i = 0;
            // Compare two arrays
            return that.tmplOptions.length === templateTags.length && _.every(that.tmplOptions.sort(), function(v) {
                var result = v === templateTags[i];
                i = i + 1;
                return result;
            });
        });
        if(!templateEl){
            throw "Couldn't find template for " + that.tmplOptions.join(',');
        }
        return wrapHtml($(templateEl).text());
    };
    // Get template, applies modifiers and renders result to element with id="embedIframe"(a textarea where user can copy
    // embedded code from) and to element with id="embeddedCodePreview" for iframes preview
    EmbedCodePreview.prototype.showPreview = function(){
        var $template = $(this.getTemplate()),
            htmlToEmbed, htmlToPreview,
            channelScript = "<script src='" + this.$el.find('.widgetEmbeds').data('channel-js-url') + "' defer></script>",
            domainErrorScript = "<script>setTimeout(() => {if(document.querySelector(\"#unite_embed iframe\").name == '') { document.querySelector(\"#unite_embed\").innerHTML = \"<b>Showing this video is not available on this domain</b><br/>\" +document.querySelector(\"#unite_embed\").innerHTML}}, 2000)</script>"

        this.applyModifiers($template);
        // Remove redundant white spaces
        htmlToEmbed = $.trim($template.html().replace(/>\s+</g, "><").replace(/&amp;/g, "&"));

        this.applyPreviewModifier($template);
        // Remove redundant white spaces
        htmlToPreview = $.trim($template.html().replace(/>\s+</g, "><").replace(/&amp;/g, "&"));

        this.$el.find('#embedIframe').val(htmlToEmbed + channelScript + domainErrorScript);
        // show single iframe code only for ['live'] && []
        var options = this.getSingleEmbedOptions();
        if (options.length == 1 && options[0] == 'live' || options.length == 0) {
            this.$el.find('#singleEmbedIframe').val(this.getSingleEmbedCode());
            this.$el.find('.single_item_head, .single_item_wrapp').show()
        } else {
            this.$el.find('.single_item_head, .single_item_wrapp').hide()
        }
        this.$el.find('#embeddedCodePreview').html(htmlToPreview);
    };
    EmbedCodePreview.prototype.getSingleEmbedCode = function(){
        var options = this.getSingleEmbedOptions();
        return "<div class=\"morphx__embed\" id=\"morphx__embed\" style=\"display: block !important; position: relative !important; padding-top: calc(56.25% + 102px) !important;\">" +
            "<iframe class=\"morphx__embed__iframe\" allow=\"encrypted-media\" allowfullscreen=\"\" frameborder=\"0\" name=\"\"" +
            " style=\"display: block !important;width: 100% !important;height: 100% !important;position: absolute  !important;left: 0 !important;top: 0 !important;\"" +
            " src=\"" + this.$el.find('.widgetEmbeds').data('single-iframe-url') +
            "?options=" + options.join(',') + "\"></iframe></div>" +
            "<script>setTimeout(() => {if(document.querySelector(\"#morphx__embed iframe\").name == '') { document.querySelector(\"#morphx__embed\").innerHTML = \"<b>Showing this video is not available on this domain</b><br/>\" +document.querySelector(\"#morphx__embed\").innerHTML}}, 2000)</script>"
    };
    EmbedCodePreview.prototype.getSingleEmbedOptions = function(){
        var opts = [];
        this.modOptions.forEach(function (mod){
            if (mod == 'playlist') {
                opts.push('external_playlist')
            } else if (mod == 'single') {
                opts.push('single_item')
            } else {
                opts.push(mod)
            }
        })
        this.tmplOptions.forEach(function (mod) {
            if (mod == 'shop') {
                opts.push('product')
            }
        })

        return opts
    };
    EmbedCodePreview.prototype.applyModifiers = function($template){
        var that = this;
        this.modOptions.forEach(function(mod){
            EmbedCodeModifiers[mod]($template);
        });
        $template.find('iframe').each(function(){
            $(this).attr('data-name', that.$el.data('type') + that.$el.data('id'));
        });
    };
    // A function that applies additional restrictions for options that user can select.
    EmbedCodePreview.prototype.applyRestrictions = function(){
        // Do not allow to include "playlist" feature if "single item" feature is checked
        var type = this.$el.data('type');
        if(this.$el.find('.mod-option[data-mod="single"]:checked').length === 1) {
            if (type === 'session') {
                this.$el.find('.mod-option[data-mod="playlist"]').attr({checked: null, disabled: 'disabled'}).prop('checked', false);
            }else{
                this.$el.find('.mod-option[data-mod="live"], .mod-option[data-mod="playlist"]').attr({checked: null, disabled: 'disabled'}).prop('checked', false);
            }
        }else{
            if (type === 'session') {
                this.$el.find('.mod-option[data-mod="playlist"]').removeAttr('disabled');
            }else{
                this.$el.find('.mod-option[data-mod="live"], .mod-option[data-mod="playlist"]').removeAttr('disabled');
            }
        }
        // Do not allow to include "chat" feature if "live" feature is not checked
        if(this.$el.find('.mod-option[data-mod="live"]:checked').length === 0) {
            this.$el.find('.mod-option[data-mod="chat"]').attr({checked: null, disabled: 'disabled'}).prop('checked', false);
        }else{
            this.$el.find('.mod-option[data-mod="chat"]').removeAttr('disabled');
        }
        if (type === 'recording') {
            this.$el.find('.template-option:not([data-tmpl="shop"])').attr({checked: null, disabled: 'disabled'}).prop('checked', false);
        }
    };
    EmbedCodePreview.prototype.initDefaultValues = function(){
        // Contains an array of tags that is used to determine needed template for embedded code
        this.tmplOptions = ['video'];
        // Contains an array of modifiers that will be applied to the chosen template. E.g. add params to urls in "src"
        // attributes of iframes. See EmbedCodeModifiers how different mods affects of template;
        this.modOptions = [];
    };
    EmbedCodePreview.prototype.applyPreviewModifier = function($template){
        var timeStamp = new Date().getTime().toString(),
            $templatesContainer = this.$el.find('.widgetEmbeds');
        // Correctly generate prefix of channel name for client/server(is picking form "name attr) for preview
        $template.find('iframe').each(function(){
            $(this).attr('name', 'preview-' + timeStamp);
            $(this).removeAttr('srcdoc');
        });

        // During the embed, we not only allow the user to embed a specific video or live event, we also allow them to
        // select options for future events or videos that have other options than the video/event currently selected.
        // Which means that the missing sections need to be shown as a graphic replacement in next way: show only
        // the sections that are missing. For example: if the product list is present then we show the product list.
        // If the product list is missing, and the user checks the option, show product, then we display the wireframe
        // panel, to indicate to the user where it will be located when it is activated.

        var isLiveEmpty = !$templatesContainer.data('has-live') && this.modOptions.indexOf('live') !== -1;
        var isPlaylistEmpty = !$templatesContainer.data('has-more-videos') && isLiveEmpty;
        var isPlaylistSelected = this.modOptions.indexOf('playlist') !== -1;
        var isChatSelected = this.modOptions.indexOf('chat') !== -1;
        var isProductsEmpty = this.tmplOptions.indexOf('shop') !== -1 && !$templatesContainer.data('has-products');

        // A case when user shares a live upcoming video and unchecks "Live" option
        if(isLiveEmpty){
            $template.find('.unite_embed_videoIframeWrapp').addClass('active');
        }

        // When user selected both - playlist and chat, but playlist appears to be empty. Chat assumes to always be
        // empty
        if(isPlaylistEmpty && isPlaylistSelected && isChatSelected){
            $template.find('.unite_embed_additionsIframeWrapp').addClass('active').addClass('active_all');
        }else{
            // If playlist is selected - only show cover image if playlist is also empty. And no matter if chat is
            // enabled or not
            if(isPlaylistSelected) {
                if(isPlaylistEmpty){
                    $template.find('.unite_embed_additionsIframeWrapp').addClass('active').addClass('active_L');
                }
            }else{
                // If playlist was unchecked but chat is enabled
                if(isChatSelected){
                    $template.find('.unite_embed_additionsIframeWrapp').addClass('active').addClass('active_C');
                }
            }
        }
        // If products list is empty
        if(isProductsEmpty){
            $template.find('.unite_embed_shopIframeWrapp').addClass('active');
        }
    };

    $(document).on('shown.bs.modal', '#social-modal', function(){
        if($(this).find('.withEmbed').length > 0){
            new EmbedCodePreview($(this)).render();
        }
    });
}(this);
