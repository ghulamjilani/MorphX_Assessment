import {Model} from '@vuex-orm/core'
import followersTransformer from "@data_transformers/followersTransformer"

export default class CompanyFollowers extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'companyFollowers'

    static fields() {
        return {
            id: this.attr(null),
            avatar_url: this.string(""),
            public_display_name: this.string(""),
            relative_path: this.string(""),
            count: this.number(null),
            type: this.string("")
        }
    }

    static apiConfig = {
        actions: {
            getFollowers(params = {}) {
                return this.get(`/api/v1/public/followers/${params.followable_type}/${params.followable_id}`, {
                    params: {
                        limit: params.limit,
                        offset: params.offset
                    },
                    dataTransformer: ({data, headers}) => {
                        return followersTransformer.companyFollowers({data, headers})
                    }
                })
            }
        }
    }
}