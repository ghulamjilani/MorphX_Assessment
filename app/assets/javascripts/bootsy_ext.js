$(function(){
    if (Bootsy.areas){
        $.each(Bootsy.areas, function(name, bootsy){
            bootsy.editor.on("load", function(){
                if($(bootsy.editor.textareaElement).attr("maxlength")){
                    $(bootsy.editor.composer.element).attr("size", $(bootsy.editor.textareaElement).attr("maxlength"));
                    $(bootsy.editor.composer.element).maxlength({
                        placement: 'bottom-right',
                        alwaysShow: true,
                        warningClass: "label label-success",
                        limitReachedClass: "label label-danger",
                        bootsy: bootsy.editor,
                        discardHtmlTags: $(bootsy.editor.textareaElement).data('discard-html-tags-length')
                    });
                }
            });
        });
    }
});
