const linkPreviewsChannelEvents = {
  linkParsed: 'link_parsed',
  linkParseFailed: 'link_parse_failed'
}

function initLinkPreviewsChannel(id) {
  return initChannel('LinkPreviewsChannel', {data: id});
}
