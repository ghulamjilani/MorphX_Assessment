import {Model} from '@vuex-orm/core'
import followersTransformer from "@data_transformers/followersTransformer"

export default class SelfFollowers extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'selfFollows'

    static fields() {
        return {
            id: this.attr(null),
            type: this.string(""),
            avatar_url: this.string(""),
            public_display_name: this.string(""),
            relative_path: this.string("")
        }
    }

    static apiConfig = {
        actions: {
            getFollows(params = {}) {
                return this.get(`/api/v1/user/follows`, {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return followersTransformer.selfFollows({data, headers})
                    }
                })
            }
        }
    }
}