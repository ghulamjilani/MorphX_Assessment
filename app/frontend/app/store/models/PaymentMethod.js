import {Model} from '@vuex-orm/core'
import paymentMethodTransformer from "@data_transformers/paymentMethodTransformer"

export default class PaymentMethods extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'pyment_method'

    static fields() {
        return {
            id: this.attr(null),
            last4: this.string(),
            brand: this.string(),
            exp_month: this.number(),
            exp_year: this.number()
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/payment_methods", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return paymentMethodTransformer.multiple({data, headers})
                    }
                })
            }
        }
    }
}