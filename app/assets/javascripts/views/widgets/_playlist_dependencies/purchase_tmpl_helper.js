+function () {
    "use strict";

    var purchaseTmpl = null;
    var getPurchaseTmpl = function () {
        if (!purchaseTmpl) {
            purchaseTmpl = Handlebars.compile($('#purchaseTmpl').text());
        }
        return purchaseTmpl;
    };
    window.putPurchaseTmpl = function (attrs) {
        var template = getPurchaseTmpl();
        var templateData = {};
        var $block = $('#purchase_block');
        templateData.type = attrs.type;
        templateData.absolute_path = attrs.absolute_path;
        if (attrs.type == 'session') {
            templateData.purchase_price = attrs.livestream_purchase_price;
        } else {
            templateData.purchase_price = attrs.recorded_purchase_price;
        }
        if(Immerss && Immerss.user && _.isNumber(Immerss.user.id)){
            templateData.userId = Immerss.user.id;
        }
        $block.html('');
        if (attrs.is_paid) {
            if (!attrs.is_purchased) {
                $block.html(template(templateData));
            }
        }
        return null
    };
}();
