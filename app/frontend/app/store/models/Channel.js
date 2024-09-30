import {Model} from '@vuex-orm/core'
import User from "@models/User"

export default class Channel extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'channel'

    static fields() {
        return {
            id: this.attr(null),
            title: this.string('Title'),
            organization_id: this.attr(null),
            status: this.string(''), // draft, pending_review, approved, rejected
            description: this.string(''),
            shares_count: this.number(0),
            created_at: this.string(""), // 2020-06-30T12:00:00.000Z,
            updated_at: this.string(""), // 2020-06-30T12:00:00.000Z
            image_gallery_url: this.string(""),
            channel_category: this.attr(null),
            relative_path: this.attr(null),
            type: this.attr(null),
            past_sessions_count: this.attr(null),
            subscription_from: this.attr(null),

            organizer_user_id: this.attr(null),
            raters_count: this.number(0),
            user: this.attr(null),

            organizer: this.belongsTo(User, 'organizer_user_id'),
            can_manage_documents: this.attr(false),
            can_add_documents: this.attr(false),

            subscription: this.attr(null),
            organization: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getChannels(params = {}) {
                return this.get(`/api/v1/public/channels`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getChannel(params = {}) {
                return this.get(`/api/v1/organization/channels/${params.id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            defaultOrganizationChannel(params = {}) {
                return this.get(`/api/v1/public/organizations/${params.id}/default_location`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getPublicChannel(params = {}) {
                let id = ""
                if (params.slug) {
                    id = params.slug.replace("/", "").replace("/", "%2F")
                } else {
                    id = params.id
                }
                return this.get(`/api/v1/public/channels/${id}`, {
                    dataTransformer: ({data}) => {
                        return data.response.channel
                    }
                })
            },
            getPublicMembers(params = {}) {
                return this.get(`/api/v1/public/channels/${params.id}/channel_members`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getPublicReviews(params = {}) {
                return this.get(`/api/v1/public/channels/${params.id}/channel_reviews`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getPublicUsers(params = {}) {
                return this.get(`/api/v1/organization/users?organization_id=${params.id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getPublicOrganization(params = {}) {
                return this.get(`/api/v1/public/organizations/${params.id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getCreatorInfo(params = {}) {
                return this.get(`/api/v1/public/users/${params.id}/creator_info`, {
                    params: {...{log_activity: '0'}, ...params},
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getFollowers(params = {}) {
                return this.get(`/api/v1/public/followers/${params.followable_type}/${params.followable_id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getPlans(params = {}) {
                return this.get(`/api/v1/public/channels/${params.id}/channel_subscription_plans`, {})
            },
            SubscribeByPlan(params = {}) {
                return this.post(`/api/v1/user/channel_subscriptions`, params, {})
            },
            archive(params = {}) {
                return this.post(`/channels/${params.id}/archive`, params, {})
            },
            getChannelsForSubscriptions() {
                return this.get(`/api/v1/user/free_subscriptions/new`)
            },
            addNewFreeSubscription(params = {}) {
                if (params.file) {
                    let formData = new FormData()
                    Object.keys(params).forEach(key => {
                            formData.append(key, params[key])
                    })
                    return this.post(`/api/v1/user/free_subscriptions`, formData, {
                        headers: {
                            'Content-Type': 'multipart/form-data'
                        }
                    })
                }
                else {
                    return this.post(`/api/v1/user/free_subscriptions`, params, {})
                }
            },
            getFreeSubscriptions(params = {}) {
                return this.get(`/api/v1/user/free_subscriptions`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            }
        }
    }
}