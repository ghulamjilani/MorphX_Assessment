import {Model} from '@vuex-orm/core'
import MbClassSchedule from '@models/mindbodyonline/MbClassSchedule'

export default class MbClassRoom extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_class_room'

    static fields() {
        return {
            id: this.attr(),
            active: this.boolean(),
            is_canceled: this.boolean(),
            is_available: this.boolean(),
            start_date_time: this.string(""),
            end_date_time: this.string(""),
            mind_body_db_class_schedule_id: this.number(),

            // relations
            class_schedule: this.belongsTo(MbClassSchedule, 'mind_body_db_class_schedule_id')
        }
    }
}