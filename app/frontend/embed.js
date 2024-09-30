import Vue from 'vue/dist/vue.esm'
import {i18n} from '@plugins/index'

import store from '@store/store'
import filters from '@helpers/filters'
import filtersv2 from '@helpers/filtersv2'
import utils from '@helpers/utils'
// import router from '@/routes/router'
import Clipboard from 'v-clipboard'
import 'app/validation.js'
import VueScrollactive from 'vue-scrollactive'
import User from '@models/User'

import VTooltip from 'v-tooltip'

// import CompWrapper from '@components/CompWrapper.vue'
// import ReviewFormNotModal from '@components/modals/review-form/ReviewFormNotModal.vue'
import ChatWrapper from '@components/pageparts/chat/ChatWrapper'

User.api().currentUser().then(res => {
    store.dispatch("Users/setCurrents", res.response.data.response)
}).catch(err => {
    console.log(err)
})

Vue.filter('formatPrice', filters.formatPrice)
Vue.filter('shortNumber', filters.shortNumber)
Vue.filter('formattedDate', filters.formattedDate)
Vue.filter('formattedTime', filters.formattedTime)
Vue.filter('capitalize', filters.capitalize)
Vue.filter('lowercase', filters.lowercase)
Vue.filter('datetimeToSession', filtersv2.datetimeToSession)
Vue.filter('dateToformat', filters.dateToformat)
Vue.filter('minsToHours', filters.minsToHours)
Vue.filter('timeToSession', filtersv2.timeToSession)

Vue.use(VTooltip, {
    defaultHtml: true,
    defaultPlacement: 'bottom',
    defaultTemplate:
        `<div class="v-tooltip" role="tooltip">
            <div class="v-tooltip-arrow"></div>
            <div class="v-tooltip-inner"></div>
        </div>`,
    defaultArrowSelector: '.v-tooltip-arrow',
    defaultInnerSelector: '.v-tooltip-inner'
})
Vue.use(Clipboard)

import device from "current-device"

Vue.prototype.$device = device
window.device = device

import uikit from "@/uikit/index"

Object.keys(uikit).forEach(e => {
    Vue.component(e, uikit[e])
})

import img from "app/assets/images/_index"

Vue.prototype.$img = img

import VueTimeago from 'vue-timeago'

Vue.use(VueTimeago, {
    locale: 'en', // Default locale
})
import VEmojiPicker from 'v-emoji-picker'
Vue.use(VEmojiPicker)

import eventHub from "@helpers/eventHub.js"

Vue.prototype.$eventHub = eventHub
window.eventHub = eventHub

Vue.prototype.goTo = (url, newTab = false) => {
    if (newTab) {
        window.open(url, '_blank')
    } else {
        window.location.href = url
    }
}
window.uid = () => {
    return '_' + Math.random().toString(36).substr(2, 9)
}
window.randInt = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min
}
window.last = function last(array, n) {
    if (array == null) return void 0
    if (n == null) return array[array.length - 1]
    return array.slice(Math.max(array.length - n, 0))
}

Vue.prototype.$flash = utils.debounce((msg, type = 'error', timeout = 6000) => {
    $.showFlashMessage(msg, {type, timeout})
}, 200)

require("@utils/usage")

// init app
const event = (typeof Turbolinks == 'object' && Turbolinks.supported) ? 'turbolinks:load' : 'DOMContentLoaded'

document.addEventListener(event, () => {
  if (document.querySelector('#embed-vue-chat')) {
    setTimeout(() => {
      window.app = new Vue({
          store,
          i18n,
          render: h => h(ChatWrapper)
      }).$mount('#embed-vue-chat')
    }, 3000)
    }
})
Vue.use(VueScrollactive);

window.spaMode = "embed"