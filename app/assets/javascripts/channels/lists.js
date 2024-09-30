const listsChannelEvents = {
  productAdded: 'product_added'
}

function initListsChannel(id) {
  return initChannel('ListsChannel', {data: id});
}
