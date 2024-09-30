export default {
    multiple({data, headers}) {
        return data?.response?.notifications?.map((item) => {
            return item.notification
        })
    },
    single({data, headers}) {
        return data.response
    }
}