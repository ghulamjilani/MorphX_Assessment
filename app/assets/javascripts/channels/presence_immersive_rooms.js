const presenceImmersiveRoomsChannelEvents = {
  activeMembers: 'active_members', // Todo igor присылать список id пользователелей в этом канале
  addPoll: 'add-poll',
  allowControl: 'allow_control',
  backstageChanged: 'backstage-changed',
  banKick: 'ban-kick',
  brb: 'brb',
  brbOff: 'brb-off',
  clientMediaPlayerStart: 'client-media-player-start',
  disableChat: 'disable-chat',
  disableControl: 'disable_control',
  disableList: 'disable-list',
  disablePoll: 'disable-poll',
  enableChat: 'enable-chat',
  enableList: 'enable-list',
  enablePoll: 'enable-poll',
  join: 'join',
  livestreamMembersCount: 'livestream_members_count',
  memberSubscribed: 'member_subscribed', // Todo igor присылать id присоеденившегося пользователя
  memberUnsubscribed: 'member_unsubscribed', // Todo igor присылать id отсоеденившегося пользователя
  micChanged: 'mic-changed',
  newMember: 'new_member',
  newQuestion: 'new-question',
  noPresenterStopScheduled: 'no_presenter_stop_scheduled',
  pinnedUsers: 'pinned_users',
  presenterJoined: 'presenter_joined',
  productScanned: 'product_scanned',
  remoteControl: 'remote_control',
  roomActive: 'room_active',
  roomUpdated: 'room_updated',
  screenShareAbilityChanged: 'screen-share-ability-changed',
  sessionEnded: 'session-ended',
  setPresenterMode: 'set_presenter_mode',
  videoChanged: 'video-changed',
  votePoll: 'vote-poll'
}

function initPresenceImmersiveRoomsChannel(id) {
  return initChannel('PresenceImmersiveRoomsChannel', {data: id});
}
