
export default {
    fetch({data}) {
        let formatedMessages = []
        data.response.messages.forEach((item) => {
            formatedMessages.push({
                id: item.message.id,
                body: item.message.body,
                conversation_id: item.message.conversation_id,
                created_at: new Date(item.message.created_at).getTime(),
                deleted_at: item.message.deleted_at,
                conversation_participant_id: item.message.conversation_participant_id,
                conversation_participant: {
                    id: item.message.conversation_participant.id,
                    conversation_id: item.message.conversation_participant.conversation_id,
                    abstract_user_id: item.message.conversation_participant.abstract_user_id,
                    abstract_user_type: item.message.conversation_participant.abstract_user_type,
                    banned: item.message.conversation_participant.banned,
                },
                abstract_user: {
                    id: item.message.conversation_participant.abstract_user.id,
                    type: item.message.conversation_participant.abstract_user.type,
                    display_name: item.message.conversation_participant.abstract_user.display_name,
                    public_display_name: item.message.conversation_participant.abstract_user.public_display_name,
                    avatar_url: item.message.conversation_participant.abstract_user.avatar_url,
                    absolute_url: item.message.conversation_participant.abstract_user.absolute_url,
                    relative_path: item.message.conversation_participant.abstract_user.relative_path,
                    slug: item.message.conversation_participant.abstract_user.slug
                }
            })
        })

        return formatedMessages
    },
    create({data}) {
        let item = data.response
        let message = {
            id: item.message.id,
            body: item.message.body,
            conversation_id: item.message.conversation_id,
            created_at: item.message.created_at,
            deleted_at: item.message.deleted_at,
            conversation_participant_id: item.message.conversation_participant_id,
            conversation_participant: {
                id: item.message.conversation_participant.id,
                conversation_id: item.message.conversation_participant.conversation_id,
                abstract_user_id: item.message.conversation_participant.abstract_user_id,
                abstract_user_type: item.message.conversation_participant.abstract_user_type,
                banned: item.message.conversation_participant.banned,
            },
            abstract_user: {
                id: item.message.conversation_participant.abstract_user.id,
                type: item.message.conversation_participant.abstract_user.type,
                display_name: item.message.conversation_participant.abstract_user.display_name,
                public_display_name: item.message.conversation_participant.abstract_user.public_display_name,
                avatar_url: item.message.conversation_participant.abstract_user.avatar_url,
                absolute_url: item.message.conversation_participant.abstract_user.absolute_url,
                relative_path: item.message.conversation_participant.abstract_user.relative_path,
                slug: item.message.conversation_participant.abstract_user.slug
            }
        }
        return message
    }
}