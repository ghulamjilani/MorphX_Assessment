export default {
    selfSubscriptions({data, headers}) {
        let subs = []

        data?.response?.forEach(item => {
            let sub = item
            sub.channel_id = item.channel.id
            sub.plan_id = item.plan.id

            subs.push(sub)
        })
        return subs;
    }
}