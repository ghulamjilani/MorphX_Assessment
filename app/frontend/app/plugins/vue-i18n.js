import Vue from 'vue/dist/vue.esm'
import VueI18n from "vue-i18n"
import default_messages from '@locales/en.js'

Vue.use(VueI18n)
// var lang = navigator.language.slice(0, 2)
const lang = 'en'
const i18n = new VueI18n({
    locale: lang,
    fallbackLocale: 'en',
    silentTranslationWarn: process.env.RAILS_ENV === 'production' || process.env.RAILS_ENV === 'qa',
    messages: default_messages
})
window.i18n = i18n

import('@locales/' + lang + ".js").then((res) => {
    i18n.setLocaleMessage(lang, res.default[lang])
})

export default i18n