import {Model} from '@vuex-orm/core'

export default class BlogComments extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'BlogComments'

    static fields() {
        return {
            id: this.attr(null),
            edited_at: this.attr(null),
        }
    }

    static apiConfig = {
        actions: {
            getPostComments(params = {}) {
                return this.get(`/api/v1/blog/posts/${params.post_id}/comments`, {params})
            },
            getComments(params = {}) {
                return this.get(`/api/v1/blog/comments`, {params})
            },
            sendComment(params = {}) {
                if (params.comment.commentable_type === "Blog::Post") {
                    return this.post(`/api/v1/blog/posts/${params.post_id}/comments`, {comment: params.comment})
                } else {
                    return this.post(`/api/v1/blog/comments`, {comment: params.comment})
                }
            },
            updateComment(params = {}) {
                return this.put(`/api/v1/blog/comments/${params.comment.id}`, {comment: params.comment})
            },
            deleteComment(params = {}) {
                return this.delete(`/api/v1/blog/comments/${params.id}`, {params})
            }
        }
    }
}