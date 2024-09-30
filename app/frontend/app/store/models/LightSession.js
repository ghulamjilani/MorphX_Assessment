import {Model} from '@vuex-orm/core'
import lightSessiontransformer from "@data_transformers/lightSessiontransformer"
import utils from '@helpers/utils'

export default class LightSession extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'light_session'

    static fields() {
        return {
            id: this.attr(null),
            start_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z
            end_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z
            title: this.string(""),
            description: this.string(""),

            channel_id: this.attr(null),

            creator_avatar_url: this.string(""),
            creator_first_name: this.string(""),
            creator_last_name: this.string(""),

            // UI data
            calendar_component_name: this.attr("session-calendar-item")
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/public/calendar/sessions", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return lightSessiontransformer.fetch({data, headers})
                    }
                })
            }
        }
    }
}