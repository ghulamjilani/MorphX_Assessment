<template>
    <div class="test" />
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import uikit from "./../../index"
import './../../../validation.js'

import axios from "@plugins/axios.js"

Object.keys(uikit).forEach(e => {
    Vue.component(e, uikit[e])
})

window.axios = axios
axios("http://localhost:3000/api/v1/sandbox/system_themes.json").then((res) => {
    let themes = res.data.response.system_themes
    createColors()

    function createColors() {
        let current_theme = themes.find(e => e.is_default)
        console.log(current_theme)
        current_theme.system_theme_variables.forEach(cus => {
            document.documentElement.style.setProperty('--' + cus.property, cus.value)
        })
    }
})
/**
 * Enter the styleguide app, skip it
 * @example [none]
 * @displayName Morfix UI Kit
 */
Vue.prototype.$img = {}
Vue.prototype.$img['logo_small'] = ``
export default {
    mounted() {
        setTimeout(() => {
            // console.log("--",axios)
        }, 2000)
        //  "/api/v1/user/system_themes/list_of_themes"
    }
}
</script>

<style lang="scss">
@import "./../../../assets/styles/index";
</style>