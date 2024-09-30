import {Model} from '@vuex-orm/core'

export default class Share extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'share'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get('/api/v1/public/share', {
                    params: params
                })
            },
            shareEmail(params = {}) {
                return this.post('/api/v1/public/share/email', params, {})
            }
        }
    }
}