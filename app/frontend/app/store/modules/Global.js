const defaultState = {
    routerHistory: [],
    liveSessions: [], // for channels tile
    advertisementBanners: {}
}

const getters = {
    routerHistory(store) {
        return store.routerHistory
    },
    liveSessions(store) {
        return store.liveSessions
    },
    prevRoute(store) {
        if (store.routerHistory.length > 1) {
            return store.routerHistory[store.routerHistory.length - 2]
        } else return null
    },
    advertisementBanners(store) {
        return store.advertisementBanners
    }
}

const actions = {
    setRouterHistory(context, data) {
        if (data) {
            context.commit("ADD_TO_ROUTER_HISTORY", data)
        }
    },
    setLiveSessions(context, data) {
        if (data) {
            context.commit("SET_LIVE_SESSIONS", data)
        }
    },
    setAdvertisementBanners(context, data) {
        if (data) {
            context.commit("SET_ADVERTISEMENT_BANNERS", data)
        }
    }
}

const mutations = {
    ADD_TO_ROUTER_HISTORY(state, payload) {
        state.routerHistory.push(payload)
    },
    SET_LIVE_SESSIONS(state, payload) {
        state.liveSessions = payload
    },
    SET_ADVERTISEMENT_BANNERS(state, payload) {
        state.advertisementBanners = payload.reduce((acc, cur) => {
            acc = {...acc, ...cur}
            return acc
        }, {})
    }
}

export default {
    namespaced: true,
    state: defaultState,
    getters: getters,
    actions: actions,
    mutations: mutations,
}