const channelsTranscodeProgressChannelEvents = {
  transcodeProgressChanged: 'transcode_progress_changed',
  transcodeCompleted: 'transcode_completed',
}

function initChannelsTranscodeProgressChannel(id) {
  return initChannel('ChannelsTranscodeProgressChannel', {data: id})
}
