import {Model} from '@vuex-orm/core'
import nearestSessionTransformer from "@data_transformers/nearestSessionTransformer"

export default class NearestSession extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'nearest_session'

    static fields() {
        return {
            id: this.attr(null),
            title: this.string(''),
            relative_path: this.string(''),
            room_id: this.attr(null),
            organizer_id: this.attr(null),
            start_at: this.string(''), // "2020-12-26T07:55:00.000+02:00"
            presenter: this.boolean(false),
            type: this.string(''),
            existence_path: this.string(''),
            show_page_paths: this.attr([]),
            service_type: this.string('')
        }
    }

    static apiConfig = {
        actions: {
            GET(params = {}) {
                return this.get("/api/v1/user/sessions/nearest_session", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return nearestSessionTransformer.single({data, headers})
                    }
                })
            }
        }
    }
}