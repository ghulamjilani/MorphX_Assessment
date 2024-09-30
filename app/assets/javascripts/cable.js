// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
//= require hash-sum
//= require websocket/websocket_connection
//= require_self
//= require_tree ./channels

const channelConfigRequired = [];

window.websocketConnection = new WebsocketConnection();

function initChannel(channelName, config = {}) {
  let subscription = websocketConnection.subscribe(channelName, config);
  return subscription;
};

function subscribeCableToEventHub() {
  window.eventHub.$on("authorization", authenticateCableConnection)
  window.eventHub.$on("logout", authenticateCableConnection)
  window.eventHub.$on("updateJwt", authenticateCableConnection)
}

function authenticateCableConnection() {
  window.websocketConnection.authenticate()
}