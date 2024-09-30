import {Model} from '@vuex-orm/core'

export default class Feed extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'feed'

    static fields() {
        return {
        }
    }

    static apiConfig = {
        actions: {
            getRecordings(params = {}) {
                return this.get(`/api/v1/user/feed/recordings`, {params})
            },
            getReplays(params = {}) {
                return this.get(`/api/v1/user/feed/videos`, {params})
            },
            getDocuments(params = {}) {
                return this.get(`/api/v1/user/feed/documents`, {params})
            },
            getSessions(params = {}) {
                return this.get(`/api/v1/user/feed/sessions`, {params})
            },
        }
    }
}