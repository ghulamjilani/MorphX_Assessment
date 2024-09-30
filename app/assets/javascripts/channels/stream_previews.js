const streamPreviewsChannelEvents = {
  streamStatus: 'stream_status'
}

function initStreamPreviewsChannel(id) {
  return initChannel('StreamPreviewsChannel', {data: id});
}
