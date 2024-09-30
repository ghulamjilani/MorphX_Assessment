export default {
    multiple({data, headers}) {
        return data.response?.studio_rooms.map((item) => {
            return item.studio_room
        })
    },
    single({data, headers}) {
        return data.response?.studio_room
    },
}