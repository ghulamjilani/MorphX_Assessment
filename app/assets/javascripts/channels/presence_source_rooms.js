const presenceSourceRoomsChannelEvents = {
  made: 'join',
  immersiveParticipantshipStatusChanged: 'immersive_participantship_status_changed',
  memberSubscribed: 'member_subscribed',
  memberUnsubscribed: 'member_unsubscribed',
  activeMembers: 'active_members'
}

function initPresenceSourceRoomsChannel(id) {
  return initChannel('PresenceSourceRoomsChannel', {data: id});
}
