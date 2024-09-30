export default {
    fetch({data, headers}) {
        let mbMbClassSchedule = []

        data.response?.forEach(item => {
            mbMbClassSchedule.push(item)
        })

        return mbMbClassSchedule
    }
}