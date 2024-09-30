import {Model} from '@vuex-orm/core'
import MbClassSchedule from '@models/mindbodyonline/MbClassSchedule'

export default class MbStaff extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_staff'

    static fields() {
        return {
            id: this.attr(),
            first_name: this.string(""),
            last_name: this.string(""),
            image_url: this.string(""),
            bio: this.string(""),

            class_schedules: this.hasMany(MbClassSchedule, "mind_body_db_staff_id")
        }
    }
}