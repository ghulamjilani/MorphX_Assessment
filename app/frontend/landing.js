import Vue from 'vue/dist/vue.esm'
import store from '@store/store'

import landing from '@components/landing/enklav.vue'


// init app
const event = (typeof Turbolinks == 'object' && Turbolinks.supported) ? 'turbolinks:load' : 'DOMContentLoaded'

document.addEventListener(event, () => {
    window.app = new Vue({
        el: '#landing-vue-app',
        store: store,
        components: {landing}
    })
})