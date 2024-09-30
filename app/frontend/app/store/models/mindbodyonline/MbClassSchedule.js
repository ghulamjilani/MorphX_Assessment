import {Model} from '@vuex-orm/core'
import MbStaff from '@models/mindbodyonline/MbStaff'
import MbLocation from '@models/mindbodyonline/MbLocation'
import MbClassDescription from '@models/mindbodyonline/MbClassDescription'
import MbClassRoom from '@models/mindbodyonline/MbClassRoom'
import mbMbClassScheduleTransformer from "@data_transformers/mbMbClassScheduleTransformer"

export default class MbClassSchedule extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_class_schedule'

    static fields() {
        return {
            id: this.attr(),
            day_monday: this.boolean(),
            day_tuesday: this.boolean(),
            day_wednesday: this.boolean(),
            day_thursday: this.boolean(),
            day_friday: this.boolean(),
            day_saturday: this.boolean(),
            day_sunday: this.boolean(),
            end_date: this.string(""),
            end_time: this.string(""),
            is_available: this.boolean(),
            start_date: this.string(""),
            start_time: this.string(""),
            mind_body_db_staff_id: this.number(),
            mind_body_db_location_id: this.number(),
            mind_body_db_class_description_id: this.number(),

            // ui only
            calendar_component_name: this.attr("mb-schedule-item"),

            // relations
            staff: this.belongsTo(MbStaff, "mind_body_db_staff_id"),
            location: this.belongsTo(MbLocation, "mind_body_db_location_id"),
            class_description: this.belongsTo(MbClassDescription, "mind_body_db_class_description_id"),
            class_rooms: this.hasMany(MbClassRoom, "mind_body_db_class_schedule_id")
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                // todo: andrey fix org id
                return this.get("/api/v1/public/organizations/1/mind_body/class_schedules", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return mbMbClassScheduleTransformer.fetch({data, headers})
                    }
                })
            }
        }
    }
}