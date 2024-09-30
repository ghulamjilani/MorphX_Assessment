import {Model} from '@vuex-orm/core'

export default class Reports extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'reports'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
          fetch(params = {}) {
            return this.get(`/api/v1/user/reports/network_sales_reports`, {params})
          },
          getOrganizations(params = {}) {
            return this.get(`/api/v1/user/reports/organizations`, {params})
          },
          getChannels(params = {}) {
            return this.get(`/api/v1/user/reports/channels`, {params})
          },
          generateCsv(params = {}) {
            return this.get(`/api/v1/user/reports/network_sales_reports.csv`, {params})
          }
        }
    }
}