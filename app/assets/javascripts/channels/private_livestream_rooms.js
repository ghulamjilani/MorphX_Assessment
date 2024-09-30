const privateLivestreamRoomsChannelEvents = {
  joinAll: 'join-all',
  livestreamUp: 'livestream-up',
  livestreamDown: 'livestream-down',
  livestreamOff: 'livestream-starting',
  livestreamOff: 'livestream-off',
  livestreamEnded: 'livestream-ended',
  livestreamMembersCount: 'livestream_members_count',
  onlineUsers: 'online_users',
  totalParticipantsCountUpdated: 'total_participants_count_updated',
  enablePoll: 'enable-poll',
  disablePoll: 'disable-poll',
  addPoll: 'add-poll',
  votePoll: 'vote-poll',
  enableList: 'enable-list',
  disableList: 'disable-list',
  productScanned: 'product_scanned',
  screenShareAbilityChanged: 'screen-share-ability-changed',
  roomUpdated: 'room_updated',
  newMember: 'new_member',
  enableChat: 'enable-chat',
  disableChat: 'disable-chat',
  brb: 'brb',
  brbOff: 'brb-off',
  ratingUpdated: 'rating_updated',
  joinMember: 'join-member'
}

function initPrivateLivestreamRoomsChannel(data = null) {
  return initChannel('PrivateLivestreamRoomsChannel', {data: data});
}
