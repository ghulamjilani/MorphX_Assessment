import {Model} from '@vuex-orm/core'
import Room from "@models/Room"
import Session from "@models/Session"

import utils from '@helpers/utils'
import videoTransformers from "@data_transformers/videoTransformer"

export default class Video extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'video'

    static fields() {
        return {
            id: this.attr(null),
            duration: this.number(15),
            filename: this.string(""),
            room_id: this.attr(null),
            channel_id: this.attr(null),
            user_id: this.attr(null),
            created_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            status: this.string(""), // found, transfer, error, ready_to_tr, transcoding, done, downloaded, livestream, pre, rtmp
            show_on_profile: this.boolean(true),
            preview_filename: this.string(""),
            featured: this.boolean(false),
            short_url: this.string(""),
            fake: this.boolean(false),
            show_on_home: this.boolean(false),
            shares_count: this.number(0),
            deleted_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            referral_short_url: this.string(""),
            promo_start: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            promo_end: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            promo_weight: this.number(0),
            ffmpegservice_id: this.string(null),
            ffmpegservice_transcoder_id: this.string(null),
            ffmpegservice_transcoder_name: this.string(null),
            ffmpegservice_state: this.string(null),
            ffmpegservice_reason: this.string(null),
            ffmpegservice_starts_at: this.string(null),
            ffmpegservice_download_url: this.string(null),
            original_name: this.string(null),
            s3_root: this.string(null),
            crop_seconds: this.number(null),
            hls_main: this.string(null),
            hls_preview: this.string(null),
            main_image_number: this.number(null),
            title: this.attr(null),
            transcoding_uptime_id: this.string(null),
            width: this.string(null),
            height: this.string(null),
            published: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            description: this.string(null),
            solr_updated_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z,
            old_id: this.number(null),
            tag_list: this.attr([]),
            poster_url: this.string(""),
            relative_path: this.string('/'),
            views_count: this.number(0),
            popularity: this.number(0),
            type: this.attr(null),
            total_views_count: this.attr(0),
            organization: this.attr(null),
            abstract_session: this.attr(null),
            rating: this.number(0),
            raters_count: this.number(0),
            only_ppv: this.boolean(false),
            only_subscription: this.boolean(false),

            // ui only
            sortUid: this.attr(null),
            calendarUid: this.attr(null),
            calendar_component_name: this.attr("video-calendar-item"),

            // relations
            user: this.attr(null),
            channel: this.attr(null),
            room: this.belongsTo(Room, 'room_id'),
        }
    }

    get always_present_title() {
        if (this.title) {
            return this.title
        } else {
            return Session.find(this.room.abstract_session_id).always_present_title
        }
    }

    static apiConfig = {
        actions: {
            search(params = {}) {
                return this.get("/api/v1/public/search/videos", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoTransformers.search({data, headers})
                    }
                })
            },
            searchApi(params = {}) {
                return this.get("/api/v1/public/search/videos", {
                    params: params
                })
            },
            fetch(params = {}) {
                return this.get("/api/v1/public/videos", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoTransformers.fetch({data, headers})
                    }
                })
            }
        }
    }

}