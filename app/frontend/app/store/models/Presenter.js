import {Model} from '@vuex-orm/core'
import User from "@models/User"

export default class Presenter extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'presenter'

    static fields() {
        return {
            id: this.attr(null),
            user_id: this.attr(null),

            // relationship
            user: this.belongsTo(User, 'user_id')
        }
    }
}