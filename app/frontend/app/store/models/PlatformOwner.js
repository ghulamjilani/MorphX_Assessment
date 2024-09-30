import {Model} from '@vuex-orm/core'
import User from "@models/User"

export default class PlatformOwner extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'PlatformOwner'

    static apiConfig = {
      actions: {
        hideOnHome(params = {}) {
          return this.post('/api/v1/user/home_entity_params/hide_on_home', params)
        },
        setPromoWeight(params = {}) {
          return this.post('/api/v1/user/home_entity_params/set_weight', params)
        }
      }
    }
}