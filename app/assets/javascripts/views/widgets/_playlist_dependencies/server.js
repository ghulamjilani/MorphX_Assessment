+function(window){
    "use strict";

    var log = function(){
        if(window.Immerss && window.Immerss.env !== 'production') {
            console.log.apply(this, arguments);
        }
    };

    var HandshakeMiddleware = function(server){
        this.server = server;
    };
    HandshakeMiddleware.prototype.call = function(data){
        return this.initConnection(data);
    };
    HandshakeMiddleware.prototype.initConnection = function(data){
        if(this.server.clientsIds.indexOf(data.clientId) !== -1){
            return true;
        }else{
            if(data.eventType === 'initConnection'){
                this.server.clientsIds.push(data.clientId);
                this.server.sendMessage('connectionAccepted', { clientId: data.clientId });
                this.server.trigger('clientAdded', { clientId: data.clientId });
                log('Accepted connection from client', data.clientId);
                return false;
            }else{
                return true;
            }
        }
    };

    var CleanUpMiddleware = function(server){
        this.server = server;
    };
    CleanUpMiddleware.prototype.call = function(data){
        localStorage.removeItem(this.server.channelName);
        return true;
    };

    var IdAssertionMiddleware = function(server){
        this.server = server;
    };
    IdAssertionMiddleware.prototype.call = function(data){
        var assertion;
        assertion = this.server.clientsIds.indexOf(data.clientId) !== -1 && this.server.id === data.eventData.serverId;
        if(assertion){
            log('ImmerssServer#' + this.server.id, ' received message:', JSON.stringify(data));
        }
        return assertion;
    };

    var ServiceMiddleware = function(server){
        this.server = server;
    };
    ServiceMiddleware.prototype.call = function(data){
        var handlerName = data.eventType + 'Handler';
        if(_.isFunction(this.server[handlerName])) {
            this.server[handlerName](data);
            return false;
        }else{
            return true;
        }
    };

    var ImmerssServer = function(){
        var cleanUpMiddleware = new CleanUpMiddleware(this);
        this.clientsIds = [];
        this.id      = _.uniqueId('ImmerssServer-' + new Date().getTime().toString() + '-');
        this.channelName = this.getChannelName();
        $(window).unload(cleanUpMiddleware.call.bind(cleanUpMiddleware));
        _.extend(this, Backbone.Events);
        this.listenClients();
    };
    ImmerssServer.prototype.listenClients = function(){
        $(window).on('storage', this.receiveMessage.bind(this));
        localStorage.removeItem(this.channelName);
    };
    ImmerssServer.prototype.sendMessage = function(eventType, eventData){
        var message = {
            serverId: this.id,
            eventType: eventType,
            eventData: eventData
        };
        if(!_.isString(eventData.clientId)){
            log("Server: Don't know whom to send a message - no clientId is is defined: ", JSON.stringify(message));
            return;
        }
        localStorage.setItem(eventData.clientId, JSON.stringify(message));
    };
    ImmerssServer.prototype.sendMessageToAllClients = function(eventType, eventData){
        _.each(this.clientsIds, function(clientId){
            this.sendMessage(eventType, _.extend({ clientId: clientId }, eventData));
        }.bind(this));
    };
    ImmerssServer.prototype.receiveMessage = function(event) {
        var parsedMessage,
        clientsAndServerChannels = _.union([this.channelName], this.clientsIds);
        if (clientsAndServerChannels.indexOf(event.originalEvent.key) === -1 || _.isEmpty(event.originalEvent.newValue))
            return;
        parsedMessage = JSON.parse(event.originalEvent.newValue);
        if(this.isValidMessage(parsedMessage)){
            this.middleware(parsedMessage);
        }
    };
    ImmerssServer.prototype.isValidMessage = function(parsedMessage){
        var requiredKeys = ['clientId', 'eventType', 'eventData'];
        if(_.isObject(parsedMessage)){
            return _.difference(requiredKeys, _.keys(parsedMessage)).length === 0;
        }else{
            throw 'ImmerssServer received unexpected message: ' + JSON.stringify(parsedMessage);
        }
    };
    ImmerssServer.prototype.middleware = function(data){
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
    ImmerssServer.prototype.getChannelName = function(){
        if(_.isString(window.name) && window.name.length > 0){
            return 'unite-' + window.name;
        }else {
            if(window.Immerss && _.isString(window.Immerss.embedChannelSuffix)){
                return 'unite-channel-' + window.Immerss.embedChannelSuffix;
            }else{
                return 'unite-general-channel';
            }
        }
    };
    ImmerssServer.prototype.disconnectHandler = function(data){
        this.clientsIds = _.without(this.clientsIds, data.clientId);
    };

    window.ImmerssServer = ImmerssServer;
}(window);
