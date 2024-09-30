import {Model} from '@vuex-orm/core'

export default class Blog extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'blog'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            search(params = {}) {
                return this.get("/api/v1/blog/posts", {params})
            },
            getPost(params = {}) {
                return this.get(`/api/v1/blog/posts/${params.slug}`, {params: {slug: `1`}})
            },
            create(params = {}) {
                let formData = new FormData()
                if (params.post_cover)
                    formData.append("post[cover_attributes][image]", params.post_cover)
                Object.keys(params).forEach(key => {
                    if (key !== 'post_cover')
                        formData.append(`post[${key}]`, params[key])
                })
                return this.post("/api/v1/blog/posts", formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                })
            },
            update(params = {}) {
                let formData = new FormData()
                if (params.post_cover)
                    formData.append("post[cover_attributes][image]", params.post_cover)
                Object.keys(params).forEach(key => {
                    if (key !== 'post_cover')
                        formData.append(`post[${key}]`, params[key])
                })
                return this.put(`/api/v1/blog/posts/${params.id}`, formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                })
            },
            changeStatus(params) {
                let data = {
                    post: {
                        status: params.status,
                        published_at: params.published_at
                    }
                }
                return this.put(`/api/v1/blog/posts/${params.id}`, data, {})
            },
            like(params = {}) {
                return this.post(`/api/v1/blog/posts/${params.id}/vote`, {}, {})
            },
            remove(params = {}) {
                return this.delete(`/api/v1/blog/posts/${params.id}`, {params})
            },
            sendImage(params = {}) {
                return this.post(`/api/v1/blog/images`, params, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                })
            },
            parseLink(params = {}) {
                return this.post("/api/v1/blog/link_previews", params, {})
            },
            new(params = {}) {
                return this.get("/api/v1/blog/posts/new", {
                    data: params,
                    save: false
                })
            }
        }
    }
}