import {Model} from '@vuex-orm/core'
import followersTransformer from "@data_transformers/followersTransformer"

export default class UserFollows extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'userFollows'

    static fields() {
        return {
            id: this.attr(null),
            avatar_url: this.string(""),
            public_display_name: this.string(""),
            relative_path: this.string(""),
            type: this.string(""),
            count: this.number(null),
            created_at: this.string(""),
            has_booking_slots: this.boolean(false),
            booking_available: this.boolean(false)
        }
    }

    static apiConfig = {
        actions: {
            getFollows(params = {}) {
                return this.get(`/api/v1/public/follows/${params.followable_type}/${params.followable_id}`, {
                    params: {
                        limit: params.limit,
                        offset: params.offset
                    },
                    dataTransformer: ({data, headers}) => {
                        return followersTransformer.userFollows({data, headers})
                    }
                })
            },
            getFollowsApi(params = {}) {
                return this.get(`/api/v1/public/follows/${params.followable_type}/${params.followable_id}`, {
                    params: {
                        limit: params.limit,
                        offset: params.offset
                    }
                })
            }
        }
    }
}