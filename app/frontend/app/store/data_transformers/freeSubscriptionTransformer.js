export default {
    selfFreeSubscriptions({data, headers}) {
        let subs = []

        data?.response?.forEach(item => {
            let sub = item
            sub.channel_id = item.channel.id

            subs.push(sub)
        })
        return subs;
    }
}