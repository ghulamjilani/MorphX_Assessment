import {Model} from '@vuex-orm/core'
import notificationTransformer from "@data_transformers/notificationTransformer"

export default class Notification extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'notification'

    static fields() {
        return {
            id: this.attr(null),
            body: this.string(''),
            subject: this.string(''),

            sender: this.attr({
                id: this.attr(null)
            }),

            is_read: this.boolean(false),

            created_at: this.string(''),
            updated_at: this.string('')
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/notifications", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return notificationTransformer.multiple({data, headers})
                    }
                })
            },

            mark_as_read(params) {
                return this.post("/api/v1/user/notifications/mark_as_read", {
                    ...params
                }, {
                    save: false
                })
            },

            remove(params) {
                return this.delete("/api/v1/user/notifications", {
                    data: {
                        ...params
                    },
                    save: false
                })
            }
        }
    }
}