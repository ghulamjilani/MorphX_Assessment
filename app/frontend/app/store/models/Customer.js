import {Model} from '@vuex-orm/core'

export default class Customer extends Model {
    static entity = 'customer'

    static fields() {
        return {

        }
    }

    static apiConfig = {
        actions: {
            getSubscriptions() {
                return this.get("/api/v1/user/customer/subscriptions", {
                    params: {
                        status: ['trialing','active']
                    }
                })
            },
            getFreeSubscriptions() {
                return this.get("/api/v1/user/customer/free_subscriptions", {})
            },
        }
    }

}