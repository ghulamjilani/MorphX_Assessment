window.PingService = function(url, callback) {
    if (!this.inUse) {
        this.status = 'unchecked';
        this.inUse = true;
        this.callback = callback;
        var _that = this;
        this.img = new Image();
        this.img.onload = function () {
            var ms = new Date().getTime() - _that.start
            _that.inUse = false;
            _that.callback(ms);

        };
        this.img.onerror = function (e) {
            if (_that.inUse) {
                _that.inUse = false;
                _that.callback(1500);
            }

        };
        this.start = new Date().getTime();
        this.img.src = url;
        this.timer = setTimeout(function () {
            if (_that.inUse) {
                _that.inUse = false;
                _that.callback(1500);
            }
        }, 1500);
    }
};

window.pingPong = function (self) {
    setInterval(function(){
        clear_cache = new Date().getTime();
        PingService(self.cache.pingImageUrl+'?clear_cache='+ clear_cache, function(ms){
            var $ping = $('.SignalLevel');
            $ping.removeAttr('class').addClass('SignalLevel');
            if(ms < 300){
                $ping.addClass('level-3');
            }else if (ms < 1000){
                $ping.addClass('level-2');
            }else if (ms < 1500){
                $ping.addClass('level-1');
            }else{
                $ping.addClass('level-0');
            }
        });
    },3000);
};