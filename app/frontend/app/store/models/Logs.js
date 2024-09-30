import {Model} from '@vuex-orm/core'

export default class Logs extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'logs'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            send(params = {}) {
                return this.post(ConfigGlobal.usage.user_messages_url, params, {})
            }
        }
    }
}