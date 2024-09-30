import {Model} from '@vuex-orm/core'
import StudioRoom from "@models/StudioRoom"
import studioTransformer from "@data_transformers/studioTransformer"

export default class Studio extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'studio'

    static fields() {
        return {
            id: this.attr(null),
            organization_id: this.attr(null),
            name: this.string(''),
            description: this.string(''),
            address: this.string(''),
            phone: this.string(''),
            created_at: this.string(''),
            updated_at: this.string(''),

            // relationship
            rooms: this.hasMany(StudioRoom, 'studio_id')
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get('/api/v1/user/studios', {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return studioTransformer.multiple({data, headers})
                    }
                })
            },
            create(params = {}) {
                return this.post('/api/v1/user/studios', {
                        studio: params
                    },
                    {
                        dataTransformer: ({data, headers}) => {
                            return studioTransformer.single({data, headers})
                        }
                    })
            },
            update(params = {}) {
                return this.put(`/api/v1/user/studios/${params.id}`, {
                        studio: params
                    },
                    {
                        dataTransformer: ({data, headers}) => {
                            return studioTransformer.single({data, headers})
                        }
                    })
            },
            remove(params = {}) {
                return this.delete(`/api/v1/user/studios/${params.id}`, {save: false})
            }
        }
    }
}