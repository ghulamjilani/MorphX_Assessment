const usersChannelEvents = {
  joinMember: 'join-member',
  newFlashbox: 'new-flashbox',
  newNotification: 'new-notification',
  backstageUpdateJoin: 'backstage-update-join',
  confirmed: 'confirmed',
  unreadMessagesCount: 'unread-messages-count',
  newBlogComment: 'new-blog-comment',
}

function initUsersChannel() {
  return initChannel('UsersChannel');
}
