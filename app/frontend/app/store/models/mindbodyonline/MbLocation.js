import {Model} from '@vuex-orm/core'
import MbSite from '@models/mindbodyonline/MbSite'

export default class MbLocation extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mb_location'

    static fields() {
        return {
            id: this.attr(),
            name: this.string(""),
            average_rating: this.number(),
            mind_body_db_sites_id: this.number(),
            address: this.string(''),
            address2: this.string(''),
            city: this.string(''),
            phone: this.string(''),
            phone_extension: this.string(''),

            site: this.belongsTo(MbSite, 'mind_body_db_sites_id')
        }
    }
}