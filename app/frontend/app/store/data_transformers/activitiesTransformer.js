export default {
    multiple({data, headers}) {
        let activities = []

        data?.response?.activities?.forEach(item => {
            let activity = item.activity
            activity.id = item.activity.id.$oid
            activity.trackable.price = +item.activity.trackable.price

            activity.created_at = moment.tz(item.activity.created_at, "Europe/London").format()
            activity.updated_at = moment.tz(item.activity.updated_at, "Europe/London").format()
            activities.push(activity)
        })

        return activities;
    },
    single({data, headers}) {
        return data.response
    },
}