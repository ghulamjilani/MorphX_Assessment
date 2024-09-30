const systemChannelEvents = {
  serverTime: 'server_time'
}

function initSystemChannel(options) {
  return initChannel('SystemChannel', {options: options});
}
