import User from "@models/User"

export default {
    multiple({data, headers}) {
        return data.response.conversations.map(item => {
            let sender = item.conversation.participants.find((participant) => {
                return participant.id === item.conversation.last_receipt.message.sender_id
            })

            return {
                id: item.conversation.id,
                created_at: item.conversation.created_at,
                updated_at: item.conversation.updated_at,
                originator_id: item.conversation.originator_id,
                is_read: item.conversation.last_receipt.is_read,

                messages: [{
                    id: item.conversation.last_receipt.message.id,
                    subject: item.conversation.last_receipt.message.subject,
                    body: item.conversation.last_receipt.message.body,
                    is_read: item.conversation.last_receipt.is_read,
                    trashed: item.conversation.last_receipt.trashed,
                    deleted: item.conversation.last_receipt.deleted,
                    mailbox_type: item.conversation.last_receipt.mailbox_type,
                    conversation_id: item.conversation.id,
                    sender: sender,
                    created_at: item.conversation.last_receipt.message.created_at,
                    updated_at: item.conversation.last_receipt.message.updated_at,
                }]
            }
        })
    },
    single({data, headers}) {
        return {
            id: data.response.conversation.id,
            created_at: data.response.conversation.created_at,
            updated_at: data.response.conversation.updated_at,
            originator_id: data.response.conversation.originator_id,
            is_read: data.response.conversation.receipts.sort((a, b) => {
                a.receipt.created_at > b.receipt.created_at
            }).find((item) => {
                return item.receipt.mailbox_type == 'inbox'
            })?.receipt?.is_read,

            messages: data.response.conversation.receipts.map((item) => {
                return {
                    id: item.receipt.message.id,
                    subject: item.receipt.message.subject,
                    body: item.receipt.message.body,
                    is_read: item.receipt.is_read,
                    trashed: item.receipt.trashed,
                    deleted: item.receipt.deleted,
                    mailbox_type: item.receipt.mailbox_type,
                    conversation_id: data.response.conversation.id,
                    sender: data.response.conversation.participants.find((participant) => {
                        return participant.id === item.receipt.message.sender_id
                    }),
                    created_at: item.receipt.message.created_at,
                    updated_at: item.receipt.message.updated_at,
                }
            })
        }
    },
}