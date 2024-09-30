import axios from "@plugins/axios.js"

const defaultState = {
    organization: {
        id: null,
        name: "",
        logo_url: "",
        rating: "",
        voted: ""
    },
    current_plan: {
        name: "",
        streaming_time: null,
        transcoding_time: null,
        storage: null,
        max_channels_count: null
    },
    channels: [],
    statistics: {
        channels_count: null,
        past_sessions_count: null,
        sessions_minutes: null,
        replays_count: null,
        replays_storage: null,
        recording_count: null,
        recordings_storage: null,
        creators_count: null,
        used_storage: null,
        used_streaming_seconds: null,
        used_transcoding_seconds: null
    }
}

const getters = {}

const actions = {
    getStatistics(context) {
        return new Promise((resolve, reject) => {
            axios.get('/api/v1/user/statistics')
                .then(res => {
                    context.commit('GET_STATISTICS', res.data.response)
                    return resolve(res)
                }).catch((errors) => {
                return reject(errors)
            })
        })
    }
}

const mutations = {
    GET_STATISTICS(state, payload) {
        state.organization = payload.organization
        state.current_plan = payload.current_plan
        state.channels = payload.channels
        state.statistics = payload.statistics
    }
}

export default {
    namespaced: true,
    state: defaultState,
    getters: getters,
    actions: actions,
    mutations: mutations,
}