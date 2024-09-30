export default {
    fetch({data, headers}) {
        let formatedSessions = []

        data.response?.sessions?.forEach(item => {
            let session = item.session
            session.creator_avatar_url = item.user.avatar_url
            session.creator_first_name = item.user.first_name
            session.creator_last_name = item.user.last_name
            formatedSessions.push(session)
        });

        return formatedSessions
    }
}