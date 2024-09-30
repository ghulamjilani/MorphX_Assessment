import {Model} from '@vuex-orm/core'
import MbLocation from '@models/mindbodyonline/MbLocation'

export default class MbSite extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_site'

    static fields() {
        return {
            id: this.attr(),
            name: this.string(""),
            logo_url: this.string(""),
            bio: this.string(""),

            locations: this.hasMany(MbLocation, 'mind_body_db_location_id')
        }
    }
}