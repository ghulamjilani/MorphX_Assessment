import {Model} from '@vuex-orm/core'
import videoSourceTransformer from "@data_transformers/videoSourceTransformer"
import StudioRoom from "@models/StudioRoom"

export default class VideoSource extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'video_source'

    static fields() {
        return {
            id: this.attr(null),
            custom_name: this.string(''),
            owner_id: this.attr(null),
            owner_type: this.string(''),
            reserved_by_id: this.attr(null),
            reserved_by_type: this.string(''),
            studio_room_id: this.attr(null),
            server: this.string(''),
            port: this.string(''),
            stream_name: this.string(''),
            authentication: this.boolean(null),
            username: this.string(''),
            password: this.string(''),
            hls_url: this.string(''),
            stream_status: this.string(''),
            stream_id: this.attr(null),
            sandbox: this.boolean(null),
            transcoder_type: this.string(''),
            name: this.string(''),
            idle_timeout: this.number(null),
            host_ip: this.string(''),
            delivery_method: this.string(''),
            current_service: this.string(''),
            source_url: this.string(''),
            created_at: this.string(''),
            updated_at: this.string(''),

            // relationship
            studioRoom: this.belongsTo(StudioRoom, 'studio_room_id')
        }
    }

    static apiConfig = {
        actions: {
            reserveFfmpegserviceAccount(params = {}) {
                return this.get('/api/v1/user/ffmpegservice_accounts/new', {
                    params: params,
                    save: false
                })
            },
            assignFfmpegserviceAccount(params = {}) {
                return this.post('/api/v1/user/ffmpegservice_accounts', null, {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoSourceTransformer.single({data, headers})
                    }
                })
            },
            unassignFfmpegserviceAccount(params = {}) {
                return this.delete(`/api/v1/user/ffmpegservice_accounts/${params.id}`, {save: false})
            },
            updateFfmpegserviceAccount(params = {}) {
                return this.put(`/api/v1/user/ffmpegservice_accounts/${params.id}`, null, {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoSourceTransformer.single({data, headers})
                    }
                })
            },
            fetchFfmpegserviceAccounts(params = {}) {
                return this.get('/api/v1/user/ffmpegservice_accounts', {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return videoSourceTransformer.multiple({data, headers})
                    }
                })
            },
            startStreaming(params) {
                return this.post(`/api/v1/user/stream_previews`, {
                    ffmpegservice_account_id: params.id,
                    dataTransformer: ({data, headers}) => {
                        return videoSourceTransformer.startStreaming({data, headers})
                    }
                }, {
                    save: false
                })
            },
            stopStreaming(params) {
                return this.delete(`/api/v1/user/stream_previews/${params.stream_previews_id}`, {
                    save: false
                })
            }
        }
    }
}