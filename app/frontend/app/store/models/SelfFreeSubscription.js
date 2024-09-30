import {Model} from '@vuex-orm/core'
import freeSubscriptionTransformer from "@data_transformers/freeSubscriptionTransformer"

export default class SelfFreeSubscription extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'SelfFreeSubscription'

    static fields() {
        return {
            end_date: this.attr(null),
            channel: this.attr(null),
            created_at: this.string(""),
            id: this.attr(null),
            channel_id: this.attr(null),
            months: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getSubscriptions(params = {}) {
                return this.get(`/api/v1/user/channel_free_subscriptions`, {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return freeSubscriptionTransformer.selfFreeSubscriptions({data, headers})
                    }
                })
            }
        }
    }
}