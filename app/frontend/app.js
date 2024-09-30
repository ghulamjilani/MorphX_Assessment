import Vue from 'vue/dist/vue.esm'

import {i18n, RailsConfig} from '@plugins/index'

import store from '@store/store'
import router from '@/routes/router'
import VueTimeago from 'vue-timeago'
import filtersV2 from '@helpers/filtersv2' // TODO: check filters
import filters from '@helpers/filters' // TODO: check filters
import VueScrollactive from 'vue-scrollactive'
import VTooltip from 'v-tooltip'
import VueCookies from 'vue-cookies'

Vue.use(VueCookies)

import eventHub from "@helpers/eventHub.js"

import device from "current-device"

Vue.prototype.$device = device
window.device = device

/* TODO: check filters */
Vue.filter('timeToSession', filtersV2.timeToSession)
Vue.filter('datetimeToSession', filtersV2.datetimeToSession)
Vue.filter('dateTimeWithZeros', filtersV2.dateTimeWithZeros)
Vue.filter('formattedDate', filters.formattedDate)
Vue.filter('formattedTime', filters.formattedTime)
Vue.filter('lowercase', filters.lowercase)
Vue.filter('minsToHours', filters.minsToHours)
Vue.filter('dateToformat', filters.dateToformat)
Vue.filter('formattedPrice', filtersV2.formattedPrice)
/* TODO: check filters */

import uikit from "@uikit/index"

Object.keys(uikit).forEach(e => {
    Vue.component(e, uikit[e])
})

import Ad from 'app/components/adbutler/ad.vue'
Vue.component('AdButler', Ad)

import img from "app/assets/images/_index"

Vue.prototype.$img = img

Vue.prototype.$eventHub = eventHub
window.eventHub = eventHub

window.subscribeCableToEventHub()

import 'app/validation.js'

import App from '@pages/App'

Vue.use(VueTimeago, {
    locale: 'en' // Default locale
})

import Clipboard from 'v-clipboard'

Vue.use(Clipboard)

Vue.use(VTooltip, {
    // defaultClass: 'v-tooltip',
    defaultTemplate:
        `<div class="v-tooltip" role="tooltip">
            <div class="v-tooltip-arrow"></div>
            <div class="v-tooltip-inner"></div>
        </div>`,

    defaultArrowSelector: '.v-tooltip-arrow',
    defaultInnerSelector: '.v-tooltip-inner',

    popover: {
        defaultPlacement: 'top',
        defaultBaseClass: 'v-tooltip popover'
    }
})

if (window.location.href.includes('/rooms/')) {
    VTooltip.enabled = device.desktop()
} else {
    VTooltip.enabled = window.innerWidth >= 320
}

import VEmojiPicker from 'v-emoji-picker'
// Vue.config.productionTip = false;
Vue.use(VEmojiPicker)

import Vue2TouchEvents from 'vue2-touch-events'

Vue.use(Vue2TouchEvents)

Vue.filter('formatPrice', filters.formatPrice)
Vue.filter('shortNumber', filters.shortNumber)
// Vue.filter('formattedDate', filters.formattedDate)
// Vue.filter('formattedTime', filters.formattedTime)
// Vue.filter('capitalize', filters.capitalize)
// Vue.filter('lowercase', filters.lowercase)

// import "@/assets/styles/index"

// Global helpers
Vue.prototype.goTo = (url, newTab = false) => {
    if (newTab) {
        window.open(url, '_blank')
    } else {
        window.location.href = url
    }
}
Vue.prototype.uid = () => {
    return '_' + Math.random().toString(36).substr(2, 9)
}
Vue.prototype.randInt = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min
}
// TODO: refactor?
window.last = function last(array, n) {
    if (array == null) return void 0;
    if (n == null) return array[array.length - 1];
    return array.slice(Math.max(array.length - n, 0));
};

// todo: andrey remove(refactor calendar)
window.uid = () => {
    return '_' + Math.random().toString(36).substr(2, 9)
}
window.randInt = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min
}
window.last = function last(array, n) {
    if (array == null) return void 0;
    if (n == null) return array[array.length - 1];
    return array.slice(Math.max(array.length - n, 0));
};

import "quill-mention/dist/quill.mention.css";
import 'vue-cal/dist/vuecal.css'

import PinchZoom from 'vue-pinch-zoom';

Vue.component('pinch-zoom', PinchZoom);

var adapter = require('webrtc-adapter');
window.adapter = adapter.default

// Init Vue App
const event = (typeof Turbolinks == 'object' && Turbolinks.supported) ? 'turbolinks:load' : 'DOMContentLoaded'

window.spaMode = "spa"

document.addEventListener('DOMContentLoaded', function () {
    let tdc = document.querySelector('#togle-debug-console');
    if (tdc) {
        tdc.addEventListener('click', function (event) {
            event.preventDefault();
            let dc = document.querySelector('#debug-console')
            dc.style.display = dc.style.display === 'none' ? '' : 'none';
        })
    }
});

document.addEventListener('DOMContentLoaded', () => {
    let tdc = document.querySelector('#togle-customization-console');
    if (tdc) {
        tdc.addEventListener('click', (event) => {
            event.preventDefault();
            eventHub.$emit("open-customization")
        })
    }
});

import Logs from "@models/Logs"

Vue.prototype.$logs = (service, eventName, data) => {
    if (!RailsConfig.frontend.log_events || RailsConfig.frontend.log_events?.disable) return
    Logs.api().send(JSON.stringify({service, page: window.location.href, event: eventName, data}))
}
Vue.prototype.$twlogs = (eventName, data) => {
    if (!RailsConfig.frontend.log_events || RailsConfig.frontend.log_events?.disable) return
    Logs.api().send(JSON.stringify({service: "webrtcservice", page: window.location.href, event: eventName, data}))
}

require("@utils/usage")

import VueVirtualScroller from 'vue-virtual-scroller'
Vue.use(VueVirtualScroller)

document.addEventListener(event, () => {
    window.app = new Vue({
        router,
        store,
        i18n,
        render: h => h(App)
    }).$mount('[data-behavior="vue"]')
})
Vue.use(VueScrollactive);