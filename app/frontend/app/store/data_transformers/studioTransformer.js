export default {
    multiple({data, headers}) {
        return data.response?.studios.map((item) => {
            return item.studio
        })
    },
    single({data, headers}) {
        return data.response?.studio
    },
}