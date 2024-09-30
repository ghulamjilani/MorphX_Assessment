const roomMembersChannelEvents = {
}

function initRoomMembersChannel(id) {
  return initChannel('RoomMembersChannel', {data: id});
}
