import {Model} from '@vuex-orm/core'
import paymentTransactionTransformer from "@data_transformers/paymentTransactionTransformer"
import utils from '@helpers/utils'

export default class PaymentTransaction extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'payment_transaction'

    static fields() {
        return {
            id: this.attr(null),
            pid: this.string(),
            status: this.string(),
            credit_card_last_4: this.string(),
            card_type: this.string(),
            provider: this.string(),
            amount: this.number(),
            tax: this.number(),
            total_amount: this.number(),
            checked_at: this.string(value => {
                utils.dateToTimeZone(value)
            }),
            purchased_item_name: this.string()
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/payment_transactions", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return paymentTransactionTransformer.multiple({data, headers})
                    }
                })
            }
        }
    }
}