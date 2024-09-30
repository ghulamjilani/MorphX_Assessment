+function(window){
    "use strict";
    var log = function(){
       if(window.Immerss && window.Immerss.env !== 'production')
           console.log.apply(this, arguments);
    };

    var HandshakeMiddleware = function(client){
        this.client = client;
    };
    HandshakeMiddleware.prototype.call = function(data){
        return this.acceptConnection(data);
    };
    HandshakeMiddleware.prototype.acceptConnection = function(data){
        if(this.client.connected){
            return true;
        }else{
            if(data.eventType === 'connectionAccepted'){
                this.client.serverId = data.serverId;
                this.client.connected = true;
                clearTimeout(this.client.initConnectionInterval);
                this.client.trigger('connected');
                log('ServiceClient#' + this.client.id, 'established connection to server', data.serverId);

                // Clean up after handshake
                new CleanUpMiddleware(this.client).call();
                localStorage.removeItem(this.client.serverChannelName);

                return false;
            }else{
                return true;
            }
        }
    };

    var CleanUpMiddleware = function(client){
        this.client = client;
    };
    CleanUpMiddleware.prototype.call = function(data){
        localStorage.removeItem(this.client.id);
        return true;
    };

    var IdAssertionMiddleware = function(client){
        this.client = client;
    };
    IdAssertionMiddleware.prototype.call = function(data){
        var assertion;
        assertion = data.serverId === this.client.serverId && this.client.id === data.eventData.clientId;
        if(assertion){
            log('ServiceClient#' + this.client.id, ' received message:', JSON.stringify(data));
        }
        return assertion;
    };

    var ServiceMiddleware = function(client){
        this.client = client;
    };
    ServiceMiddleware.prototype.call = function(data){
        var handlerName = data.eventType + 'Handler';
        if(_.isFunction(this.client[handlerName])) {
            this.client[handlerName](data);
            return false;
        }else{
            return true;
        }
    };

    var ImmerssClient = function(){
        this.serverId = null;
        this.id     = _.uniqueId('ServiceClient-' + new Date().getTime().toString() + '-');
        this.initConnectionInterval = null;
        this.connected = false;
        this.serverChannelName = this.getChannelName();
        $(window).unload(this.disconnect.bind(this));
        _.extend(this, Backbone.Events);
        this.listenServer();
        this.connect();
    };
    ImmerssClient.prototype.listenServer = function(){
        $(window).on('storage', this.receiveMessage.bind(this));
    };
    ImmerssClient.prototype.sendMessage = function(eventType, eventData){
        var message = {
            clientId: this.id,
            eventType: eventType,
            eventData: eventData || {}
        };
        message.eventData.serverId = this.serverId;
        localStorage.setItem(this.serverChannelName, JSON.stringify(message));
    };
    ImmerssClient.prototype.connect = function(){
        this.initConnectionInterval = setInterval(function(){
            this.sendMessage('initConnection', null);
        }.bind(this), 500);
    };
    ImmerssClient.prototype.receiveMessage = function(event) {
        var parsedMessage;
        if (event.originalEvent.key !== this.id || _.isEmpty(event.originalEvent.newValue))
            return;
        parsedMessage = JSON.parse(event.originalEvent.newValue);
        if(this.isValidMessage(parsedMessage)){
            this.middleware(parsedMessage);
        }
    };
    ImmerssClient.prototype.isValidMessage = function(parsedMessage){
        var requiredKeys = ['serverId', 'eventType', 'eventData'];
        if(_.isObject(parsedMessage)){
            return _.difference(requiredKeys, _.keys(parsedMessage)).length === 0;
        }else{
            throw 'ServiceClient received unexpected message: ' + JSON.stringify(parsedMessage);
        }
    };
    ImmerssClient.prototype.middleware = function(data){
        var chainCallInterrupted;
        chainCallInterrupted = _.any(
            [HandshakeMiddleware, IdAssertionMiddleware, CleanUpMiddleware, ServiceMiddleware],
            function(middlewareClass){
            return new middlewareClass(this).call(data) === false;
        }.bind(this));

        if(chainCallInterrupted){
            return false;
        }

        this.trigger(data.eventType, data);
        return true;
    };
    ImmerssClient.prototype.getChannelName = function(){
        if(_.isString(window.name) && window.name.length > 0){
            return 'unite-' + window.name;
        }else {
            if(window.Immerss && _.isString(window.Immerss.embedChannelSuffix)){
                return 'unite-channel-' + window.Immerss.embedChannelSuffix;
            }else if(window.frameElement.dataset.name){
                return 'unite-channel-' + window.frameElement.dataset.name.replace(/([a-zA-Z])(\d)/g, '$1-$2');
            }else{
                return 'unite-general-channel';
            }
        }
    };
    ImmerssClient.prototype.disconnect = function(){
        var cleanUpMiddleware = new CleanUpMiddleware(this);
        this.sendMessage('disconnect');
        cleanUpMiddleware.call();
    };

    window.ImmerssClient = ImmerssClient;
}(window);
