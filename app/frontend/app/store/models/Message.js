import {Model} from '@vuex-orm/core'
import Conversation from "@models/Conversation"

export default class Message extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'message'

    static fields() {
        return {
            id: this.attr(null),
            subject: this.string(''),
            body: this.string(''),

            is_read: this.boolean(false),
            trashed: this.boolean(false),
            deleted: this.boolean(false),
            mailbox_type: this.string(''),

            conversation_id: this.attr(null),
            sender: this.attr({
                // id
                // public_display_name
                // relative_path
                // avatar_url
            }),


            created_at: this.string(''), // 2020-06-30T12:00:00.000Z
            updated_at: this.string(''), // 2020-06-30T12:00:00.000Z

            // relationship
            conversation: this.belongsTo(Conversation, 'conversation_id')
        }
    }
}