import {Model} from '@vuex-orm/core'
import MbClassSchedule from '@models/mindbodyonline/MbClassSchedule'

export default class MbClassDescription extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_class_description'

    static fields() {
        return {
            id: this.attr(),
            category: this.string(""),
            name: this.string(""),

            class_schedules: this.hasMany(MbClassSchedule, "mind_body_db_class_description_id")
        }
    }
}