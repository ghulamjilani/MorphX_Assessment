import User from "@models/User";
import {getCookie} from "@utils/cookies"
import store from '@store/store'

export default {
    methods: {
        isCurrentUser() {
            return getCookie('_unite_session_jwt')
        },
        currentUser() {
            if(store.getters["Users/currentUser"]) return store.getters["Users/currentUser"]

            let token = getCookie('_unite_session_jwt')
            return token ? User.find(parseJwt(token).id) : undefined
        }
    }
}