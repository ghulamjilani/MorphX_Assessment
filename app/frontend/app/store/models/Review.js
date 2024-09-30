import {Model} from '@vuex-orm/core'

export default class Review extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'review'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getPublic(params = {}) {
                return this.get(`/api/v1/public/reviews`, {params})
            },
            getUserParams(params = {}) {
                return this.get(`/api/v1/user/reviews`, {params})
            },
            createReview(params = {}) {
                return this.post(`/api/v1/user/reviews`, params)
            },
            updateReview(params = {}) {
                return this.put(`/api/v1/user/reviews/${params.id}`, params)
            },
            destroyReview(params = {}) {
                return this.delete(`/api/v1/user/reviews/current`, {params})
            },
            getReview(params = {}) {
                return this.get(`/api/v1/user/reviews/current`, {params})
            }
        }
    }
}