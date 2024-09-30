(function(){
    function isLegacyShopIframe(iframeEl){
        return iframeEl.id === 'unite_embed_shop';
    }
    try{
        var id = new Date().getTime().toString(),
            roles = ['vplayer', 'additions', 'shop'],
            iframes;
        iframes = document.getElementsByTagName('iframe');
        for(var i = 0; i < iframes.length; i++){
            if(iframes[i].name === '' && ( roles.indexOf(iframes[i].dataset.role) !== -1 || isLegacyShopIframe(iframes[i]))){
                iframes[i].name = iframes[i].dataset.name + '-' + id;
                iframes[i].removeAttribute('srcdoc');
                iframes[i].setAttribute('name', iframes[i].dataset.name + '-' + id);
                iframes[i].outerHTML = iframes[i].outerHTML;
            }
        }
    }catch(e){
        console.log(e);
    }
}());
