import {getCookie} from "../../utils/cookies"
import {Model} from '@vuex-orm/core'

export default class User extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'user'

    static fields() {
        return {
            id: this.attr(null),
            first_name: this.string(""),
            last_name: this.string(""),
            email: this.string(""),
            slug: this.string(""),
            display_name: this.string(""),
            public_display_name: this.string(""),
            birthdate: this.string(""),
            gender: this.string(""),
            short_url: this.string(""),
            referral_short_url: this.string(""),
            avatar_url: this.string(""),
            created_at: this.string(""),
            relative_path: this.string(""),
            timezone: this.string(""),
            language: this.string(""),
            country: this.attr(null),
            views_count: this.attr(null),
            following: this.attr(null),
            followers: this.attr(null),
            am_format: this.boolean(false),
            type: this.attr(null),
            has_booking_slots: this.boolean(false),
            booking_available: this.boolean(false)
        }
    }

    static apiConfig = {
        actions: {
            currentUser() {
                let token = getCookie('_unite_session_jwt')
                if (token && parseJwt(token).type !== 'room_member') {
                    return this.get(`/api/v1/user/users/${parseJwt(token).id}`, {
                        dataTransformer: ({data}) => {
                            return data.response
                        }
                    })
                } else {
                    setTimeout(() => { // time to page init
                        window.eventHub?.$emit("currentUser:null")
                    }, 1000)
                    return new Promise((res, rej) => {
                        rej(null)
                    })
                }
            },
            signUp(params = {}) {
                return this.post(`/api/v1/auth/registrations`, params, {
                    dataTransformer: ({data}) => {
                        return data.response.user
                    },
                    withCredentials: true
                })
            },
            login(params = {}) {
                return this.post(`/api/v1/auth/users`, params, {
                    dataTransformer: ({data}) => {
                        return data.response.user
                    },
                    withCredentials: true
                })
            },
            logout(params = {}) {
                return this.delete(`/api/v1/auth/users`, params, {
                    dataTransformer: () => {
                        return null
                    },
                    withCredentials: true
                })
            },
            rememberPassword(params = {}) {
                return this.post(`/api/v1/auth/passwords`, params, {})
            },
            userFollows(params = {}) {
                return this.get(`/api/v1/user/follows`, {
                    params: params,
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            updateUser(params = {}) {
                return this.put(`/api/v1/user/users/current`, {
                    reset_password_token: params.reset_password_token,
                    user: {
                        password: params.password,
                        password_confirmation: params.password_confirmation
                    }
                })
            },
            updateCurrentUser(params = {}) {
                return this.put(`/api/v1/user/users/current`, params, {})
            },
            userFollow(params = {}) {
                return this.post(`/api/v1/user/follows/${params.followable_type}/${params.followable_id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            userUnFollow(params = {}) {
                return this.delete(`/api/v1/user/follows/${params.followable_type}/${params.followable_id}`, {
                    dataTransformer: ({data}) => {
                        return data.response
                    }
                })
            },
            getAvatar(params = {}) {
                return this.get(`/api/v1/public/users/fetch_avatar.json?email=` + params.email, {
                    dataTransformer: () => {}
                })
            },
            checkEmail(params = {}) {
                return this.get(`/remote_validations/user_email?user[email]=` + params.email, {})
            },
            getUserPlans() {
                return this.get(`/api/v1/user/channel_subscriptions`, {})
            },
            getCreatorInfo(params = {}) {
                return this.get(`/api/v1/public/users/${params.id}/creator_info`, {
                    params: {...{log_activity: '0'}, ...params}
                })
            },
            getUserChannels(params = {}) {
                return this.get(`/api/v1/public/search/channels`, {params: {user_id: params.id}})
            },
            getUserFullChannels(params = {}) {
                return this.get(`/api/v1/user/channels`, {params})
            },
            getDefaultSessionParams(params = {}) {
                return this.get(`/api/v1/user/sessions/new?feature_parameters=true`, params)
            },
            createSession(params = {}) {
                return this.post(`/api/v1/user/sessions`, params)
            },
            searchApi(params = {limit: 15}) {
                return this.get("/api/v1/public/search/users", {
                    params: {...params}
                })
            },
            mentionSuggestions(params = {limit: 15}) {
                return this.get("/api/v1/user/mentions", {
                    params: {...params}
                })
            },
            getUser(params = {}) {
                return this.get("/api/v1/public/users/" + params.id, {})
            },
            getTokens(params = {}) {
                return this.get("/api/v1/auth/user_tokens", {headers: {'Authorization': `Bearer ${params.refresh}`}})
            },
            accessManagment(params = {}) {
                return this.get("/api/v1/user/access_management/channels", {params})
            },
            getInvitationTokenInfo(params = {}) {
                return this.get(`/users/invitation/accept?invitation_token=${params.token}`, {}, {
                    headers: {
                        'Accept': 'application/json'
                    }
                })
            },
            registrationByInvitationToken(params = {}) {
                return this.put(`/users/invitation?invitation_token=${params.invitation_token}`, params, {
                    headers: {
                        'Accept': 'application/json'
                    }
                })
            },
            checkSignUpToken(params = {}) {
                return this.get(`/api/v1/auth/signup_tokens/${params.signup_token}`)
            },
            useSignUpToken(params = {}) {
                return this.post(`/api/v1/user/signup_tokens`, params)
            },
            createGuestJwt(params = {}) {
                return this.post('/api/v1/auth/guests', params, {headers: {Authorization: getCookie('_guest_jwt')}})
            },
            refreshGuestJwt() {
                return this.put('/api/v1/auth/guests', {} , {headers: {Authorization: getCookie("_guest_jwt_refresh")}})
            }
        }
    }
}