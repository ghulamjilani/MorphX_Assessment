import {Model} from '@vuex-orm/core'
import Channel from "@models/Channel"
import utils from '@helpers/utils'
import recordingTransformer from "@data_transformers/recordingTransformer"

export default class Recording extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'recording'

    static fields() {
        return {
            id: this.attr(null),
            channel_id: this.attr(null),
            provider: this.string(""),
            vid: this.string(""),
            title: this.string(""),
            description: this.string(""),
            url: this.string(""),
            raw: this.string(""),
            purchase_price: this.number(5), // 0..1000000
            private: this.boolean(false),
            hide: this.boolean(false),
            shares_count: this.number(0),
            short_url: this.string(""),
            referral_short_url: this.string(""),
            cached_votes_total: this.number(0),
            cached_votes_score: this.number(0),
            cached_votes_up: this.number(0),
            cached_votes_down: this.number(0),
            cached_weighted_score: this.number(0),
            promo_start: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            promo_end: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            promo_weight: this.number(0),
            show_on_home: this.boolean(false),
            published: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            status: this.string("found"), // found, ready_to_tr, transcoding, done, error
            hls_main: this.string(""),
            hls_preview: this.string(""),
            main_image_number: this.number(),
            width: this.number(),
            height: this.number(),
            deleted_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            s3_root: this.string(""),
            duration: this.number(),
            fake: this.boolean(false),
            tag_list: this.attr(null),
            relative_path: this.string(""),
            created_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            updated_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            can_share: this.boolean(false),
            is_purchased: this.boolean(false),
            preview_share_relative_path: this.string(""),
            views_count: this.number(0),
            poster_url: this.string(''),
            new_star_rating: this.string(''),
            always_present_title: this.attr(null),
            popularity: this.number(0),
            type: this.attr(null),
            total_views_count: this.attr(0),
            organization: this.attr(null),
            rating: this.number(0),
            raters_count: this.number(0),
            only_ppv: this.boolean(false),
            only_subscription: this.boolean(false),

            // ui only
            sortUid: this.attr(null),
            calendarUid: this.attr(null),
            calendar_component_name: this.attr("recording-calendar-item"),

            // relationship
            user: this.attr(null),
            channel: this.attr(null),
        }
    }

    static apiConfig = {
        actions: {
            search(params = {}) {
                return this.get("/api/v1/public/search/recordings", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return recordingTransformer.search({data, headers})
                    }
                })
            },
            searchApi(params = {}) {
                return this.get("/api/v1/public/search/recordings", {
                    params: params
                })
            },
            fetch(params = {}) {
                return this.get("/api/v1/public/recordings", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoTransformers.fetch({data, headers})
                    }
                })
            }
        }
    }
}