import {Model} from '@vuex-orm/core'

export default class OptIn extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'optin'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getOptInModals(params = {}) {
                return this.get(`/api/v1/user/marketing_tools/opt_in_modals`, {params})
            },
            getOptInModalByModel(params = {}) {
                return this.get(`/api/v1/public/marketing_tools/opt_in_modals`, {params})
            },
            createOptInModals(params = {}) {
                return this.post(`/api/v1/user/marketing_tools/opt_in_modals`, params)
            },
            updateOptInModals(params = {}) {
                return this.put(`/api/v1/user/marketing_tools/opt_in_modals/${params.id}`, params)
            },
            sendForm(params = {}) {
                return this.post(`/api/v1/public/marketing_tools/opt_in_modal_submits`, params)
            },
            trackView(params = {}) {
                return this.put(`/api/v1/public/marketing_tools/opt_in_modals/${params.id}/track_view`)
            },
            removeOptInModals(params = {}) {
                return this.delete(`/api/v1/user/marketing_tools/opt_in_modals/${params.id}`, params)
            },
        }
    }
}