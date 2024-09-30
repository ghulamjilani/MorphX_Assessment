import {Model} from '@vuex-orm/core'
import lightVideotransformer from "@data_transformers/lightVideotransformer"
import utils from '@helpers/utils'

export default class LightVideo extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'light_video'

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
            calendar_component_name: this.attr("video-calendar-item")
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/public/calendar/videos", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return lightVideotransformer.fetch({data, headers})
                    }
                })
            }
        }
    }
}