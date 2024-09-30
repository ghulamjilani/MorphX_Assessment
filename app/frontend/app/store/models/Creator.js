import {Model} from '@vuex-orm/core'
import creatorTransformer from "@data_transformers/creatorTransformer"

export default class Creator extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'creator'

    static fields() {
        return {
            id: this.attr(null),
            name: this.attr(null),
            value: this.attr(null),
            public_display_name: this.attr(null),
            type: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            async search(params = {}) {
                return await this.get("/api/v1/public/search/users", {
                    params: {...params, limit: 15},
                    dataTransformer: ({data, headers}) => {
                        return creatorTransformer.search({data, headers, ...params})
                    }
                })
            },
            searchApi(params = {limit: 15}) {
                return this.get("/api/v1/public/search/users", {
                    params: {...params}
                })
            }
        }
    }

}