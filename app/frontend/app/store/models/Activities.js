import {Model} from '@vuex-orm/core'
import activitiesTransformer from "@data_transformers/activitiesTransformer"

export default class Activities extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'activity'

    static fields() {
        return {
            id: this.attr(null),
            key: this.string(null),
            created_at: this.string(), // 2020-06-30T12:00:00.000Z
            updated_at: this.string(), // 2020-06-30T12:00:00.000Z
            trackable: this.attr({
                id: this.attr(null),
                type: this.string(null),
                name: this.string(null),
                short_url: this.string(null),
                poster_url: this.string(""),
                logo_url: this.string(""),
                price: this.number(0),
                purchased: this.boolean(false),
                following: this.boolean(false)
            })
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/activities", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return activitiesTransformer.multiple({data, headers})
                    }
                })
            },
            deleteAll() {
                return this.post("/api/v1/user/activities/destroy_all", {}, {save: false})
            },
            deleteByDateRange(params = {}) {
                return this.delete('/api/v1/user/activities', {
                    data: {
                        date_from: params.date_from,
                        date_to: params.date_to
                    },
                    save: false
                })
            }
        }
    }
}