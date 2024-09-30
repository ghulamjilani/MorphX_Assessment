const sessionsChannelEvents = {
  livestreamUp: 'livestream-up',
  livestreamDown: 'livestream-down',
  livestreamStarting: 'livestream-starting',
  livestreamOff: 'livestream-off',
  sessionStarted: 'session-started',
  sessionStopped: 'session-stopped',
  sessionCancelled: 'session-cancelled',
  totalParticipantsCountUpdated: 'total_participants_count_updated',
  chatMemberBanned: 'chat_member_banned',
  livestreamMembersCount: 'livestream_members_count',
  liveGuideForceRefresh: 'force-refresh-live-guide',
  newVideoPublished: 'new_video_published'
}

function initSessionsChannel(data = null) {
  return initChannel('SessionsChannel', {data: data});
}
