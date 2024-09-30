import {Model} from '@vuex-orm/core'
import conversationTransformer from "@data_transformers/conversationTransformer"
import Message from "@models/Message"

export default class Сonversation extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'conversation'

    static fields() {
        return {
            id: this.attr(null),
            created_at: this.string(''), // 2020-06-30T12:00:00.000Z
            updated_at: this.string(''), // 2020-06-30T12:00:00.000Z
            originator_id: this.attr(null),
            is_read: this.boolean(false),

            // relationship
            messages: this.hasMany(Message, 'conversation_id')
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/conversations", {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return conversationTransformer.multiple({data, headers})
                    }
                })
            },
            fetchOne(id) {
                return this.get(`/api/v1/user/conversations/${id}`, {
                    dataTransformer: ({data, headers}) => {
                        return conversationTransformer.single({data, headers})
                    }
                })
            }
        }
    }
}