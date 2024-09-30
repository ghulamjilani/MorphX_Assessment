import {Model} from '@vuex-orm/core'

export default class Members extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'members'

    static fields() {
        return {
            id: this.attr(null),
            avatar_url: this.string(""),
            public_display_name: this.string(""),
            relative_path: this.string(""),
            has_booking_slots: this.boolean(false),
            booking_available: this.boolean(false)
        }
    }

    static apiConfig = {
        actions: {
            getPublicChannelMembers(params = {}) {
                return this.get(`/api/v1/public/channels/${params.id}/channel_members`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response.channel_members
                    }
                })
            },
            getPublicOrganizationMembers(params = {}) {
                return this.get(`/api/v1/public/organizations/${params.id}/organization_members`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response.organization_members
                    }
                })
            }
        }
    }
}