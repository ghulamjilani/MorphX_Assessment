import {Model} from '@vuex-orm/core'
import planPackageTransformer from "@data_transformers/planPackageTransformer"

export default class PlanPackage extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'plan_package'

    static fields() {
        return {
            id: this.attr(null),
            name: this.string(),
            custom: this.boolean(),
            active: this.boolean(),
            recommended: this.boolean(),
            isEnterprise: this.boolean(false),
            description: this.string(),
            position: this.number(),
            plans: this.attr([]),
            features: this.attr([]),
            platform_split_revenue_percent: this.string(),
            owner_split_revenue_percent: this.string()
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/public/plan_packages", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return planPackageTransformer.multiple({data, headers})
                    }
                })
            },
            current(params) {
                return this.get("/api/v1/user/service_subscriptions/current", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return planPackageTransformer.single({data, headers})
                    }
                })
            }
        }
    }

}