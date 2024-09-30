import {Model} from '@vuex-orm/core'

export default class Files extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'files'

    static fields() {
        return {
        }
    }

    static apiConfig = {
        actions: {
            saveHomeBannerImage(params = {}) {
                return this.post(`/api/v1/user/page_builder/home_banners`, params, {})
            }
        }
    }
}