import {Model} from '@vuex-orm/core'

export default class Mail extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'mail'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getTemplates(params = {}) {
                return this.get("/api/v1/user/mailing/templates", {
                    template_id: params.template_id,
                    contact_ids: params.contact_ids,
                    body: params.body,
                    subject: params.subject
                })
            },
            getPreview(params = {}) {
                return this.post("/api/v1/user/mailing/emails/preview", params)
            },
            sendEmail(params = {}) {
                return this.post(`/api/v1/user/mailing/emails`, {
                    template_id: params.template_id,
                    contact_ids: params.contact_ids,
                    body: params.body,
                    subject: params.subject
                })
            }
        }
    }

}