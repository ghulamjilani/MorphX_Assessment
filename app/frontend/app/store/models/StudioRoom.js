import {Model} from '@vuex-orm/core'
import Studio from "@models/Studio"
import VideoSource from "@models/VideoSource"
import studioRoomTransformer from "@data_transformers/studioRoomTransformer"

export default class StudioRoom extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'studio_room'

    static fields() {
        return {
            id: this.attr(null),
            studio_id: this.attr(null),
            name: this.string(''),
            description: this.string(''),
            created_at: this.string(''),
            updated_at: this.string(''),

            // relationship
            studio: this.belongsTo(Studio, 'studio_id'),
            video_source: this.hasOne(VideoSource, 'studio_room_id')
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get('/api/v1/user/studio_rooms', {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return studioRoomTransformer.multiple({data, headers})
                    }
                })
            },
            create(params = {}) {
                return this.post('/api/v1/user/studio_rooms', {
                        studio_room: params,
                        studio_id: params.studio_id
                    },
                    {
                        dataTransformer: ({data, headers}) => {
                            return studioRoomTransformer.single({data, headers})
                        }
                    })
            },
            remove(params = {}) {
                return this.delete(`/api/v1/user/studio_rooms/${params.id}`, {save: false})
            }
        }
    }
}