const imConversationsChannelEvents = {
  newMessage: 'new_message',
  messageUpdated: 'message_updated',
  messageDeleted: 'message_deleted',
  channelConversationDisabled: 'channel_conversation_disabled'
}

function initImConversationsChannel(id) {
  return initChannel('::Im::ConversationsChannel', {data: id})
}
