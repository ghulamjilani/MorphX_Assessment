//= require actioncable

class WebsocketSubscription {
  constructor(channelName, config, connection) {
    this.subscription = null;
    this.isPending = true;
    this.pendingEvents = {};
    this.channelName = channelName;
    this.config = config;
    this.configHash = hashSum(channelName + JSON.stringify(config));
    if (!this.config.data) {
      this.config.data = null;
    }
    this.connection = connection;
    this.initialize();
  }

  consumer() {
    this.connection.consumer;
  }

  isConsumerReady() {
    !!this.consumer();
  }

  updateListenersCount(data) {
    this.listenersCount = data.listenersCount;
  }

  initialize() {
    if (!this.connection.consumer) {
      return false;
    }

    let that = this;

    this.subscription = this.connection.consumer.subscriptions.create({
      channel: this.channelName,
      data: this.config.data
    },
    {
      callbacks: {
        'ActionCable:subscribed': {
          defaultCallback: this.updateListenersCount,
        },
        'ActionCable:unsubscribed': {
          defaultCallback: this.updateListenersCount
        }
      },
      is_connected: null,
      connected: function () {
        this.is_connected = true;
        console.log(that.channelName + ' connected');
      },
      disconnected: function () {
        this.is_connected = false;
        console.log(that.channelName + ' disconnected');
      },
      received: function (message) {
        if (message.event && typeof this.callbacks[message.event] == 'object') {
          for (var key in this.callbacks[message.event]) {
            this.callbacks[message.event][key](message.data);
          }
        }
        console.log(that.channelName + ' data received', message);
      },
      bind: function (eventName, callback) {
        var calbackhashSum = hashSum(callback);

        if(!this.callbacks[eventName]){
          this.callbacks[eventName] = {};
        }
        this.callbacks[eventName][calbackhashSum] = callback;
      },
    });

    if (this.bindPendingEvents()) this.isPending = false;
  }

  bind(event, handler) {
    let eventHash = hashSum(event) + hashSum(handler);
    if (!this.subscription) {
      this.pendingEvents[eventHash] = {name: event, handler};
      return;
    }
    else {
      this.subscription.bind(event, handler);
      delete this.pendingEvents[eventHash];
    }
  }

  bindPendingEvents() {
    if (!this.subscription) return false;

    for (const eventHash in this.pendingEvents) {
      const pendingEvent = this.pendingEvents[eventHash];

      this.subscription.bind(pendingEvent.name, pendingEvent.handler);
      delete this.pendingEvents[eventHash];
    }
    return Object.keys(this.pendingEvents).length == 0;
  }
}
