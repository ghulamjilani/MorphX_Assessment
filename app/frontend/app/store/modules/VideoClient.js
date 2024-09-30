const defaultState = {
    room: null,
    roomInfo: null,
    localAudioMuted: false,
    localVideoMuted: false,
    localPins: [],
    presenterPins: [],
    roomMember: null,
    participantsList: [],
    banList: []
}

const getters = {
    room(state) {
        return state.room
    },
    roomMember(state) {
        return state.roomMember
    },
    roomInfo(state) {
        return state.roomInfo
    },
    localAudioMuted(state) {
        return state.localAudioMuted
    },
    localVideoMuted(state) {
        return state.localVideoMuted
    },
    localPins(state) {
        return state.localPins
    },
    presenterPins(state) {
        return state.presenterPins
    },
    participantsList(state) {
        return state.participantsList
    },
    isLocalPins(state) {
        if (state.localPins.length > 1) {
            return true
        } else return state.localPins.length === 1 && !state.localPins.find(e => e.identity.rl === "P")
    },
    isPresenterPins(state) {
        if (state.presenterPins.length > 1) {
            return true
        } else return state.presenterPins.length === 1 && !state.presenterPins.find(e => e.identity.rl === "P")
    },
    banList(state) {
        return state.banList;
    }
}

const actions = {
    setRoom({state, commit}, data) {
        commit("SET_ROOM", data)
    },
    setRoomMember({state, commit}, data) {
        commit("SET_ROOM_MEMBER", data)
    },
    setRoomInfo({state, commit}, data) {
        commit("SET_ROOM_INFO", data)
    },
    setLocalAudioMuted({state, commit}, data) {
        commit("SET_LOCAL_AUDIO_MUTED", data)
    },
    setLocalVideoMuted({state, commit}, data) {
        commit("SET_LOCAL_VIDEO_MUTED", data)
    },
    setLocalPins({state, commit}, data) {
        commit("SET_LOCAL_PINS", data)
    },
    addLocalPins({state, commit}, data) {
        commit("ADD_LOCAL_PINS", data)
    },
    removeLocalPins({state, commit}, data) {
        commit("REMOVE_LOCAL_PINS", data)
    },
    setPresenterPins({state, commit}, data) {
        commit("SET_PRESENTER_PINS", data)
    },
    addPresenterPins({state, commit}, data) {
        commit("ADD_PRESENTER_PINS", data)
    },
    togglePresenterPins({state, commit}, data) {
        if (state.presenterPins.find(e => e.id === data.id)) {
            commit("REMOVE_PRESENTER_PINS", data)
        } else {
            commit("ADD_PRESENTER_PINS", data)
        }
    },
    updatePresenterPins({state, commit}, data) {
        let arr = []
        data.forEach(d => {
            // if(!state.presenterPins.find(e => e.id === d))
            let rm = state.roomInfo.room_members.find(e => e.room_member.id === d)
            let isPresenter = state.roomInfo?.presenter_user?.id === d
            let mid = rm?.room_member?.id
            let participant = {
                id: d,
                identity: {
                    id: d,
                    rl: isPresenter ? "P" : "U",
                    mid
                }
            }
            if (isPresenter) arr.unshift(participant)
            else arr.push(participant)
        })

        commit("SET_PRESENTER_PINS", arr)
    },
    removePresenterPins({state, commit}, data) {
        commit("REMOVE_PRESENTER_PINS", data)
    },
    addToParticipantsList({state, commit}, data) {
        let add = data.filter(d => !state.participantsList.find(p => p.id === d.room_member.id))
        add = add.map(d => d.room_member)
        commit("ADD_PARTICIPANTS_LIST", add)
    },
    setBanList({state, commit}, data) {
        commit("SET_BAN_LIST", data)
    }
}

const mutations = {
    SET_ROOM(state, data) {
        state.room = data
    },
    SET_ROOM_MEMBER(state, data) {
        state.roomMember = data
    },
    SET_ROOM_INFO(state, data) {
        state.roomInfo = data
    },
    SET_LOCAL_AUDIO_MUTED(state, data) {
        state.localAudioMuted = data
    },
    SET_LOCAL_VIDEO_MUTED(state, data) {
        state.localVideoMuted = data
    },
    SET_LOCAL_PINS(state, data) {
        state.localPins = data
    },
    ADD_LOCAL_PINS(state, data) {
        if (!state.localPins.find(e => e.id === data.id))
            state.localPins.push(data)
    },
    REMOVE_LOCAL_PINS(state, data) {
        state.localPins = state.localPins.filter(f => f.id !== data.id)
    },
    SET_PRESENTER_PINS(state, data) {
        state.presenterPins = data
    },
    ADD_PRESENTER_PINS(state, data) {
        let isPresenter = state.roomInfo?.presenter_user?.id == data.id
        if (!state.presenterPins.find(e => e.id === data.id)) {
            if (isPresenter) state.presenterPins.unshift(data)
            else state.presenterPins.push(data)
        }

    },
    REMOVE_PRESENTER_PINS(state, data) {
        state.presenterPins = state.presenterPins.filter(f => f.id !== data.id)
    },
    ADD_PARTICIPANTS_LIST(state, data) {
        state.participantsList = state.participantsList.concat(data)
    },
    SET_BAN_LIST(state, data) {
        state.banList = data;
    }
}

export default {
    namespaced: true,
    state: defaultState,
    getters: getters,
    actions: actions,
    mutations: mutations,
}