import {Model} from '@vuex-orm/core'

export default class PageBuilder extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'PageBuilder'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            fetchTemplatesApi(params = {}) {
                return this.get("/api/v1/user/page_builder/system_templates", {params})
            },
            fetchTemplateApi(params = {}) {
                return this.get("/api/v1/public/page_builder/system_templates/template", {params})
            },
            createTemplateApi(params = {}) {
                return this.post("/api/v1/user/page_builder/system_templates", params)
            },
            fetchAdvertisementBanners(params = {}) {
                return this.get("/api/v1/public/page_builder/ad_banners", {params})
            },
            bannerClick(params = {}) {
                return this.post(`/api/v1/public/ad_clicks?ad_banner_id=${params.id}`)
            }
        }
    }
}