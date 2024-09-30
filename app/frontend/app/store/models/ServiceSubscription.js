import {Model} from '@vuex-orm/core'
import serviceSubscriptionTransformer from "@data_transformers/serviceSubscriptionTransformer"

export default class ServiceSubscription extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'service_subscription'

    static fields() {
        return {
            id: this.attr(null),
            canceled_at: this.string(),
            created_at: this.string(),
            current_period_end: this.string(),
            features: this.attr({}),
            plan: this.attr([]),
            service_status: this.string(),
            status: this.string(),
            plan_package: this.attr({})
        }
    }

    static apiConfig = {
        actions: {
            paymentAction(params = {}) {
                return this.post("/api/v1/user/service_subscriptions", params)
            },
            current(params) {
                return this.get("/api/v1/user/service_subscriptions/current", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return serviceSubscriptionTransformer.single({data, headers})
                    }
                })
            },
            activateSubscription(params) {
                return this.put(`/api/v1/user/service_subscriptions/${params.id}`, params)
            },
            ManuallyPay(params) {
                return this.post(`/api/v1/user/service_subscriptions/${params.id}/pay`, params)
            },
            cancelSubscription(params) {
                return this.delete(`/api/v1/user/service_subscriptions/${params.id}`)
            },
            cancelDeactivation(params) {
                return this.put(`/api/v1/user/service_subscriptions/${params.id}?cancel_at_period_end=false`)
            },
            applyCoupon(params = {}) {
                return this.post(`/api/v1/user/service_subscriptions/apply_coupon`, params)
            }
        }
    }
}