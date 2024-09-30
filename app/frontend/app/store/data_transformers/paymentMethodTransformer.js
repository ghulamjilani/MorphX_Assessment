export default {
    single({data, headers}) {
        return data?.response || {}
    },

    multiple({data, headers}) {
        return data?.response?.cards || []
    }
}