import {Model} from '@vuex-orm/core'

export default class Themes extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'themes'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getThemes(params = {}) {
                return this.get('/api/v1/user/system_themes', {
                    params: params
                })
            },
            getTheme(params = {}) {
                return this.get('/api/v1/user/system_themes/' + params.id, {
                    params: params
                })
            },
            updateTheme(params = {}) {
                return this.put('/api/v1/user/system_themes/' + params.id, {
                    theme: params
                })
            }
        }
    }
}