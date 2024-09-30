import eventHub from "@helpers/eventHub.js"

const defaultState = {
    currentUser: null,
    currentGuest: null,
    currentOrganization: null,
    organizations: null,
    pageOrganization: null
}

const getters = {
    currentUser(store) {
        return store.currentUser
    },
    currentGuest(store) {
        return store.currentGuest
    },
    currentOrganization(store) {
        return store.currentOrganization
    },
    organizations(store) {
        return store.organizations
    },
    pageOrganization(store) {
        return store.pageOrganization
    }
}

const actions = {
    setCurrents(context, data) {
        if (data) {
            let subscriptionOption = {
                subscriptionAbility: data.subscription_ability,
                hasSubscription: data.has_subscription,
                has_channel_free_subscriptions: data.has_channel_free_subscriptions,
                has_channel_subscriptions: data.has_channel_subscriptions,
                has_payments: data.has_payments,

            }
            let credentialsOption = {
                credentialsAbility: data.credentials_ability
            }
            let user = {...data.user, ...subscriptionOption, ...credentialsOption}

            context.commit("SET_CURRENT_USER", user)
            context.commit("SET_CURRENT_ORGANIZATION", data.current_organization)
            context.commit("SET_ORGANIZATIONS", data.organizations)
        } else {
            context.commit("SET_CURRENT_USER", null)
            context.commit("SET_CURRENT_ORGANIZATION", null)
            context.commit("SET_ORGANIZATIONS", null)
        }
    },
    setCurrentGuest(context, guest) {
        context.commit("SET_CURRENT_GUEST", guest)
    },
    setPageOrganization(context, data) {
        context.commit("SET_PAGE_ORGANIZATION", data)
    },
    authenticate(context, {data, action}){
        let isSignedIn = context.getters['currentUser']
        if(isSignedIn){
            action()
        }else{
            eventHub.$emit("open-modal:auth", "login", {
                action: "close-and-emit",
                event: "open-doc-afterlogin",
                data: data
            })
        }
    }
}

const mutations = {
    SET_CURRENT_USER(state, payload) {
        state.currentUser = payload
    },
    SET_CURRENT_GUEST(state, payload) {
        state.currentGuest = payload
    },
    SET_CURRENT_ORGANIZATION(state, payload) {
        state.currentOrganization = payload
    },
    UPDATE_NOTIFICATIONS_COUNT(state, newCount) {
        state.currentUser.new_notifications_count = newCount
    },
    SET_ORGANIZATIONS(state, payload) {
        state.organizations = payload
    },
    SET_PAGE_ORGANIZATION(state, payload) {
        state.pageOrganization = payload
    }
}

export default {
    namespaced: true,
    state: defaultState,
    getters: getters,
    actions: actions,
    mutations: mutations
}