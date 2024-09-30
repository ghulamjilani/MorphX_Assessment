import Vue from 'vue/dist/vue.esm'

const railsConfig = {
    global: window.ConfigGlobal,
    frontend: window.ConfigFrontend
}

Vue.prototype.$railsConfig = railsConfig

export default railsConfig