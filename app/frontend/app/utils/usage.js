import { getCookie, setCookie, deleteCookie } from "@utils/cookies"
import axios from "@plugins/axios.js"

import "./usage/playerUsage"
import "./usage/webrtcUsage"
import "./usage/interactiveUsage"

let api = null
window.usageMessages = []
let sendTime = 15*1000
var checkUsageJwt = () => {
  return new Promise((resolve) => {
    let jwt = getCookie('_usage_jwt')
    if(jwt) {
      api = axios.create({
        baseURL: window.ConfigGlobal.usage.user_messages_url,
        headers: {
          'Content-Type': 'application/json'
        }
      })
      resolve(jwt)
      return true
    }
    else {
      updateUsageJwt().then(newJwt => {
        resolve(newJwt)
      })
    }
  })
}
window.checkUsageJwt = checkUsageJwt

var updateUsageJwt = () => {
  return new Promise((resolve) => {
    let visitor_id = window.getCookie("visitor_id")
    axios.post("/api/v1/auth/usage_tokens", {visitor_id}).then((res) => {
      api = axios.create({
        baseURL: window.ConfigGlobal.usage.user_messages_url,
        headers: {
          'Content-Type': 'application/json'
        }
      })

      let exp = new Date(res.data.response.usage_jwt_exp).getTime()
      setCookie("_usage_jwt", res.data.response.usage_jwt, exp)
      setCookie("_usage_jwt_exp", exp, exp)
      resolve(res.data.response.usage_jwt)
    })
  })
}
window.updateUsageJwt = updateUsageJwt

var postUsage = () => {
  let messages = [].concat(window.usageMessages)
  window.usageMessages = []
  if(messages.length) {
    checkUsageJwt().then(jwt => {
      api.post(window.ConfigGlobal.usage.user_messages_url, { messages }, { headers: { Authorization: jwt } })
    })
  }
}

var initUsage = () => {
  checkUsageJwt().then(() => {
    setInterval(() => {
      postUsage()
    }, sendTime)
  })
}

if(window.ConfigGlobal && window.ConfigGlobal.usage && window.ConfigGlobal.usage.enabled) {
  initUsage()
}

var deleteUsageJwt = () => {
  deleteCookie("_usage_jwt")
  deleteCookie("_usage_jwt_exp")
}

var reloadUsageJwt = () => {
  deleteUsageJwt()
  checkUsageJwt()
}

var subscribeToEvents = () => {
  if(window.eventHub) {
    window.eventHub.$on("authorization", () => {
      if(window.spaMode == "monolith") deleteUsageJwt()
      else reloadUsageJwt()
    })
    window.eventHub.$on("logout", () => {
      if(window.spaMode == "monolith") deleteUsageJwt()
      else reloadUsageJwt()
    })
  }
}

subscribeToEvents()