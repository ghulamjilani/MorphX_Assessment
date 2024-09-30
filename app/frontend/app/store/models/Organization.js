import {Model} from '@vuex-orm/core'

export default class Organization extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'organization'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getPublicReviews(params = {}) {
                return this.get(`/api/v1/public/channels/${params.id}/channel_reviews`, {params})
            },
            currentOrganization(params = {}) {
                return this.get("/api/v1/user/organizations/current", {params})
            },
            setCurrentOrganization(params = {}) {
                return this.post(`/api/v1/user/organizations/${params.id}/set_current`, {params})
            },
            getOrganizations(params = {}) {
                return this.get(`/api/v1/public/organizations`, {params})
            }
        }
    }
}