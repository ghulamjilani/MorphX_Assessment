import {Model} from '@vuex-orm/core'

export default class Comments extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'comments'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            sendComment(params = {}) {
                return this.post(`/api/v1/user/comments`, params)
            },
            updateComment(params = {}) {
                return this.put(`/api/v1/user/comments/${params.id}`, params)
            },
            deleteComment(params = {}) {
                return this.delete(`/api/v1/user/comments/${params.id}`, params)
            },
            getPublic(params = {}) {
                return this.get(`/api/v1/public/comments`, {params})
            },
            getUser(params = {}) {
                return this.get(`/api/v1/user/comments`, {params})
            }
        }
    }
}