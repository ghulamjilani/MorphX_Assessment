import {getCookie} from "../../utils/cookies"
import {Model} from '@vuex-orm/core'
import Presenter from "@models/Presenter"
import Room from "@models/Room"
import utils from '@helpers/utils'
import sessionTransformers from "@data_transformers/sessionTransformer"

export default class Session extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'session'

    static fields() {
        return {
            id: this.attr(null),
            channel_id: this.attr(null),
            presenter_id: this.attr(null),
            duration: this.number(15), // from 15 to 180 step 5
            start_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z
            end_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            immersive_type: this.string(""), // group, one_on_one
            title: this.string(""), // Live Session,
            cancelled_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            status: this.string(""), // unpublished, ublished, requested_free_session_approved, requested_free_session_pending, requested_free_session_rejected
            stopped_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            pre_time: this.number(0),
            description: this.string(""),
            donations_goal: this.number(null),
            start_now: this.boolean(false),
            autostart: this.boolean(false),
            service_type: this.string("vidyo"),
            device_type: this.string("desktop_basic"), // desktop_basic, mobile, desktop_advanced, professional, studio_equipment, ipcam
            allow_chat: this.boolean(false),
            livestream_free: this.boolean(false),
            immersive_free: this.boolean(false),
            recorded_free: this.boolean(false),
            livestream_purchase_price: this.number(null),
            immersive_purchase_price: this.number(null),
            recorded_purchase_price: this.number(null),
            created_at: this.string(value => {
                utils.dateToTimeZone(value)
            }), // 2020-06-30T12:00:00.000Z
            watchers_count: this.number(0),
            type: this.attr(null),
            total_views_count: this.attr(0),
            views_count: this.attr(0),
            small_cover_url: this.string("/assets/channels/default_cover-238a756a6c5900804711f3881eb627eb308b79d96e1bdf273597da62faab8a25.jpg"),
            relative_path: this.string("/"),
            preview_share_relative_path: this.string("/gurhard-johnson/guitar/24-jun-07-00-gurhard-johnson-live-session/preview_share"),
            can_share: this.boolean(true),
            line_slots_left: this.number(null),
            always_present_title: this.string(''),
            new_star_rating: this.string(''),
            raters_count: this.number(0),
            opt_out_as_recorded_member: this.boolean(false),
            access_replay_as_subscriber: this.boolean(false),
            join_as_participant: this.boolean(false),
            join_as_livestreamer: this.boolean(false),
            access_as_subscriber: this.boolean(false),
            url_params: this.attr({}),
            channel_image_preview_url: this.string(''),
            popularity: this.number(0),
            max_number_of_immersive_participants: this.number(0),
            organization: this.attr(null),
            only_ppv: this.boolean(false),
            only_subscription: this.boolean(false),

            // ui only
            sortUid: this.attr(null),
            calendarUid: this.attr(null),
            calendar_component_name: this.attr("session-calendar-item"),

            // relations
            user: this.attr(null),
            presenter: this.belongsTo(Presenter, 'presenter_id'),
            channel: this.attr(null),
            room: this.hasOne(Room, 'abstract_session_id')
        }
    }

    static apiConfig = {
        actions: {
            search(params = {}) {
                return this.get("/api/v1/public/search/sessions", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return sessionTransformers.search({data, headers})
                    }
                })
            },
            searchApi(params = {}) {
                return this.get("/api/v1/public/search/sessions", {
                    params: params
                })
            },
            fetch(params = {}) {
                return this.get("/api/v1/public/sessions", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return sessionTransformers.fetch({data, headers})
                    }
                })
            },
            getSessionsForUser(params = {}) {
                return this.get("/api/v1/user/sessions", {
                    params: params
                })
            },
            getInteractiveToken(params = {}) {
                let token = getCookie('_unite_session_jwt')
                if (token) {
                    return this.get(`/api/v1/user/interactive_access_tokens`, {
                        params: params,
                        dataTransformer: ({data}) => {
                            return data.response
                        }
                    })
                } else {
                    return new Promise((res, rej) => {
                        rej()
                    })
                }
            },
            getSessionBySlug(params = {}) {
                return this.get(`/api/v1/public/sessions/${params.slug}`)
            },
            getSessionById(params = {}) {
                return this.get(`/api/v1/public/sessions/${params.id}`)
            }
        }
    }
}