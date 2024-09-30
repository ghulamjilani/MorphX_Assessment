import {Model} from '@vuex-orm/core'

export default class Credentials extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'credentials'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            allCredentials() {
                return this.get('/api/v1/user/access_management/credentials', {
                    save: false
                })
            }
        }
    }
}