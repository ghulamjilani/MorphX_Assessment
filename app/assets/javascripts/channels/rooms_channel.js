const roomsChannelEvents = {
  update: 'update',
  disable: 'disable',
}

function initRoomsChannel(id) {
  return initChannel('RoomsChannel', {data: id});
}