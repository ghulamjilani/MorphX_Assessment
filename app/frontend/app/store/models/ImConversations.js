import {Model} from '@vuex-orm/core'
import imСonversationsTransformer from "@data_transformers/imСonversationsTransformer"
import {getCookie} from "@utils/cookies"

export default class ImСonversation extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'im_conversation'

    static fields() {
        return {
            id: this.attr(null),
            last_message: this.attr(null),
            channel: this.attr(null),
            conversationable_id: this.attr(null),
            conversationable_type: this.attr(null),
            can_create_message:  this.attr(null),
            can_moderate_conversation:  this.attr(null),
            closed: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            getAllUserChannelConversations(params = {}) {
                return this.get(`/api/v1/user/im/channel_conversations`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response.conversations.map(conversation => {
                            return imСonversationsTransformer.fetch(conversation)
                        })

                    }
                })
            },
            getSessionConversations(params = {}) {
                let guestJwt = getCookie("_guest_jwt")
                let options = {
                    params: params,
                    dataTransformer: ({data}) => {
                        return imСonversationsTransformer.fetch(data.response)
                    }
                }
                if(guestJwt) {
                    options["headers"] = {
                        Authorization: `Bearer ${guestJwt}`
                    }
                }

                return this.get(`/api/v1/user/im/sessions/${params.session_id}/conversation`, options)
            }
        }
    }
}