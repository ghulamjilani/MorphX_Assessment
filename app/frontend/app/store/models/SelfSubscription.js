import {Model} from '@vuex-orm/core'
import subscriptionTransformer from "@data_transformers/subscriptionTransformer"

export default class SelfSubscription extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'SelfSubscription'

    static fields() {
        return {
            canceled_at: this.attr(null),
            channel: this.attr(null),
            created_at: this.string(""),
            current_period_end: this.string(""),
            id: this.attr(null),
            plan: this.attr(null),
            status: this.string(""),
            channel_id: this.attr(null),
            plan_id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getSubscriptions(params = {}) {
                return this.get(`/api/v1/user/channel_subscriptions`, {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return subscriptionTransformer.selfSubscriptions({data, headers})
                    }
                })
            },
            checkEmail(params = {}) {
                return this.post(`/api/v1/user/channel_subscriptions/${params.id}/check_recipient_email`, params)
            },
            sendGift(params = {}) {
                return this.post(`/stripe/subscriptions/1/check_recipient_email`, params)
            }
        }
    }
}