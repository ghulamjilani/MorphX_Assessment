export default {
    selfFollows({data, headers}) {
        let follows = []

        data?.response?.follows?.forEach(item => {
            let follower = item.follow
            follower.id = item.follow.followable_id
            follower.type = item.follow.followable_type
            follower.avatar_url = item.follow.followable.user?.avatar_url
            follower.public_display_name = item.follow.followable.user?.public_display_name
            follower.relative_path = item.follow.followable.user?.relative_path
            follows.push(follower)
        })
        return follows;
    },
    userFollowers({data, headers}) {
        let followers = []
        data?.response?.followers?.forEach(item => {
            let follower = item
            follower.id = item.id
            follower.type = "User"
            follower.avatar_url = item.avatar_url
            follower.public_display_name = item.public_display_name
            follower.relative_path = item.relative_path
            follower.count = data.pagination?.count
            followers.push(follower)
        })
        return followers;
    },
    companyFollowers({data, headers}) {
        let followers = []
        data?.response?.followers?.forEach(item => {
            let follower = item
            follower.id = item.id
            follower.type = "User"
            follower.avatar_url = item.avatar_url
            follower.public_display_name = item.public_display_name
            follower.relative_path = item.relative_path
            follower.count = data.pagination?.count
            followers.push(follower)
        })
        return followers;
    },
    userFollows({data, headers}) {
        let follows = []
        data?.response?.follows?.forEach(item => {
            if (item.followable.user) {
                var follower = item.followable.user
                follower.id = item.followable.user.id
                follower.avatar_url = item.followable.user.avatar_url
                follower.public_display_name = item.followable.user.public_display_name
                follower.relative_path = item.followable.user.relative_path
                follower.type = "User"
                follower.created_at = item.created_at
                follower.count = data.pagination?.count
            } else if (item.followable.organization) {
                var follower = item.followable.organization
                follower.id = item.followable.organization.id
                follower.avatar_url = item.followable.organization.logo_url
                follower.public_display_name = item.followable.organization.name
                follower.relative_path = item.followable.organization.relative_path
                follower.type = "Organization"
                follower.created_at = item.created_at
                follower.count = data.pagination?.count
            } else {
                var follower = item.followable.channel
                follower.id = item.followable.channel.id
                follower.avatar_url = item.followable.channel.logo_url
                follower.public_display_name = item.followable.channel.title
                follower.relative_path = item.followable.channel.relative_path
                follower.type = "Channel"
                follower.created_at = item.created_at
                follower.count = data.pagination?.count
            }
            follows.push(follower)
        })
        return follows;
    }
}