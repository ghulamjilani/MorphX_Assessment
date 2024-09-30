const publicLivestreamRoomsChannelEvents = {
  brb: 'brb',
  brbOff: 'brb-off',
  joinAll: 'join-all',
  enableChat: 'enable-chat',
  disableChat: 'disable-chat',
  enableList: 'enable-list',
  disableList: 'disable-list',
  livestreamUp: 'livestream-up',
  livestreamDown: 'livestream-down',
  livestreamStarting: 'livestream-starting',
  livestreamOff: 'livestream-off',
  livestreamEnded: 'livestream-ended',
  memberSubscribed: 'member_subscribed',
  memberUnsubscribed: 'member_unsubscribed',
  activeMembers: 'active_members',
  ratingUpdated: 'rating_updated',
  livestreamMembersCount: 'livestream_members_count',
  totalParticipantsCountUpdated: 'total_participants_count_updated',
  productScanned: 'product_scanned',
  roomUpdated: 'room_updated'
}

function initPublicLivestreamRoomsChannel(id) {
  return initChannel('PublicLivestreamRoomsChannel', {data: id});
}
