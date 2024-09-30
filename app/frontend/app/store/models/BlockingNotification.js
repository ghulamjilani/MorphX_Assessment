import {Model} from '@vuex-orm/core'

export default class BlockingNotification extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'blocking_notification'

    static fields() {
        return {
            id: this.attr(null),
            title: this.string(''),
            type: this.string(''),
            html: this.string(''),
            livestream_purchase_price: this.attr(null),
            immersive_purchase_price: this.attr(null)
        }
    }
}