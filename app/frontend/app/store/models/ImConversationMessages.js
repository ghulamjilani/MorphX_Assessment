import {Model} from '@vuex-orm/core'
import imСonversationMessagesTransformer from "@data_transformers/imСonversationMessagesTransformer"
import {getCookie} from "@utils/cookies"

export default class ImСonversationMessages extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'im_conversation_messages'

    static fields() {
        return {
            id: this.attr(null),
            body: this.attr(null),
            conversation_id:this.attr(null),
            created_at: this.attr(null),
            deleted_at: this.attr(null),
            conversation_participant_id: this.attr(null),
            conversation_participant: this.attr(null),
            abstract_user: this.attr(null),
            isPoll: this.attr(null),
            poll: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getAllConversationMessages(params = {}) {
                 return this.get(`/api/v1/user/im/conversations/${params.id}/messages`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return imСonversationMessagesTransformer.fetch({data})
                    }
              })
            },
            createMessage(params = {}) {
                let guestJwt = getCookie("_guest_jwt")
                let options = {}
                if(guestJwt) {
                    options["headers"] = {
                        Authorization: `Bearer ${guestJwt}`
                    }
                }

                return this.post(`/api/v1/user/im/conversations/${params.id}/messages`, {
                    message: params.message
                }, options)
            },
            updateMessage(params = {}) {
                return this.put(`/api/v1/user/im/conversations/${params.conversation_id}/messages/${params.id}`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return imСonversationMessagesTransformer.fetch({data})
                    }
                })
            },
            deleteMessage(params = {}) {
                return this.delete(`/api/v1/user/im/conversations/${params.conversation_id}/messages/${params.id}`, {
                    params: params
                })
            }
        }
    }
}