//= require actioncable
//= require cookie
//= require websocket/websocket_subscription

class WebsocketConnection {
  constructor() {
    this.consumer = null;
    this.subscriptions = {};
    this.websocketTokensUrl = new URL('/api/v1/auth/websocket_tokens', location.origin);
    this.mountUrlBase = new URL((ActionCable.getConfig('url') || ActionCable.INTERNAL.default_mount_path), location.origin);
    this.authenticate();
  }

  mountUrl(token) {
    this.mountUrlBase.searchParams.set('auth', token);
    return this.mountUrlBase.toString();
  }

  authenticate() {
    var xhr = new XMLHttpRequest();
    var user_jwt, guest_jwt;
    var that = this;
    xhr.open('POST', this.websocketTokensUrl);
    xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
    if (user_jwt = getCookie('_unite_session_jwt')) {
      xhr.setRequestHeader('Authorization', user_jwt);
    } else if (guest_jwt = getCookie('_guest_jwt')) {
      xhr.setRequestHeader('Authorization', guest_jwt);
    }
    xhr.send(JSON.stringify({visitor_id: getCookie('visitor_id')}))
    xhr.onload = function() {
      var res = JSON.parse(xhr.response).response,
          token = ''

      if (xhr.status == 200) {
        token = res.token;
      }
      that.authorize(that.mountUrl(token));
    };
    xhr.onerror = function(e) {
      console.log(e);
    };
  }

  authorize(websocketMountUrl) {
    if (!this.consumer) {
      this.consumer = ActionCable.createConsumer(websocketMountUrl);
      this.consumer.connect();
    }
    else {
      this.consumer.disconnect();
      this.consumer._url = websocketMountUrl;
      this.consumer.connect();
    }
    this.initPendingSubscriptions();
  }

  initPendingSubscriptions() {
    for(const subscriptionHash in this.subscriptions) {
      let subscription = this.subscriptions[subscriptionHash]
      if (subscription.isPending) subscription.initialize();
    }
  }

  subscribe(channelName, config = {}) {
    let subscriptionHash = hashSum(channelName + JSON.stringify(config));
    if (this.subscriptions[subscriptionHash]) return this.subscriptions[subscriptionHash];

    let subscription = new WebsocketSubscription(channelName, config, this);
    this.subscriptions[subscriptionHash] = subscription;
    return subscription;
  }
}
