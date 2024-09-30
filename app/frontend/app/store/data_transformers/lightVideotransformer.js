export default {
    fetch({data, headers}) {
        let formatedVideos = []

        data.response?.videos?.forEach(item => {
            let video = item.video
            video.start_at = item.session.start_at
            video.end_at = item.session.end_at
            video.title = item.session.title
            video.description = item.session.description
            video.creator_avatar_url = item.user.avatar_url
            video.creator_first_name = item.user.first_name
            video.creator_last_name = item.user.last_name
            formatedVideos.push(video)
        });

        return formatedVideos
    }
}