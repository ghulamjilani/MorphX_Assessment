const pollsChannelEvents = {
  addPoll: "add-poll",
  stopPoll: "stop-poll",
  startPoll: "start-poll",
  votePoll: "vote-poll"
}

function initPollsChannel(data = null) {
  return initChannel('PollsChannel', {data: data});
}
