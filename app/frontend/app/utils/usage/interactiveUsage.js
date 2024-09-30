 var sendInteractiveUsage = (params) => {
  let data = { ...params }

  data["event_time"] = new Date().getTime()
  data["client_type"] = "Browser"
  data["visitor_id"] = window.getCookie("visitor_id")
  data["user_agent"] = window.navigator.userAgent

  window.usageMessages.push(data)
}

window.sendInteractiveUsage = sendInteractiveUsage