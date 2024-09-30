var sendPlayerUsage = (params) => {
  let data = { ...params }

  data["event_time"] = new Date().getTime()
  data["client_type"] = window.spaMode == "embed" ? "Embed" : "Browser"
  data["user_agent"] = window.navigator.userAgent
  if(window.spaMode == "embed") {
    data["domain"] = new URL(document.referrer)?.origin
  }

  if(window.Immerss && window.Immerss.channel)
    data["channel_id"] = window.Immerss.channel.id

  if(window.Immerss && window.Immerss.organization)
    data["organization_id"] = window.Immerss.organization.id

  if(window.Immerss.session) {
    data["model_type"] = "Session"
    data["model_id"] = window.Immerss.session.id
  }
  if(window.Immerss.replay) {
    data["model_type"] = "Video"
    data["model_id"] = window.Immerss.replay.id
  }
  if(window.Immerss.recording) {
    data["model_type"] = "Recording"
    data["model_id"] = window.Immerss.recording.id
  }

  window.usageMessages.push(data)
}

window.sendPlayerUsage = sendPlayerUsage