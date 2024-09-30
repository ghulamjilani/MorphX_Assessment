import {Model} from '@vuex-orm/core'
import {getCookie} from "@utils/cookies"

export default class Room extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'room'

    static fields() {
        return {
            id: this.attr(null),
            abstract_session_id: this.attr(null),
            abstract_session_type: this.attr(null),
            abstract_session: this.morphTo('abstract_session_id', 'abstract_session_type')
        }
    }

    static mutators() {
        return {
            abstract_session_type(value) {
                return value ? value.toLowerCase() : ''
            }
        }
    }

    static apiConfig = {
        actions: {
            joinByToken(params) {
                if (params.isGuest) {
                    return this.post(`/api/v1/guest/rooms/join_interactive_by_token`, params, {headers: {Authorization: getCookie('_guest_jwt')}})
                } else {
                    return this.post(`/api/v1/user/rooms/join_interactive_by_token`, params)
                }
            },
            getRoom(params) {
                if (params.token) {
                    return this.joinByToken(params)
                } else if (params.isGuest) {
                    options = {headers: { Authorization: "Bearer " + getCookie('_guest_jwt') }}
                    return this.get(`/api/v1/guest/rooms/${params.id}`, params, options)
                } else {
                    return this.get(`/api/v1/user/rooms/${params.id}`)
                }
            },
            activateRoom(params = {}) {
                return this.put(`/api/v1/user/rooms/${params.id}`, {room: {action: "start"}})
            },
            closeRoom(params = {}) {
                return this.put(`/api/v1/user/rooms/${params.id}`, {room: {action: "stop"}})
            },
            updateRoom(params = {}) {
                return this.put(`/api/v1/user/rooms/${params.id}`, {room: params})
            },
            banRoomMember(params = {}) {
                return this.put(`/api/v1/user/rooms/${params.room_id}`, {
                    room: {
                        room_members_attributes: [{
                            id: params.id,
                            banned: params.banned,
                            ban_reason_id: params.ban_reason_id
                        }]
                    }
                })
            },
            unpinAll(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/unpin_all`, {room: params})
            },
            updateRoomMembers(params = {}) {
                return this.put(`/api/v1/user/rooms/${params.id}`, {room: params})
            },
            getWebrtcserviceTokens(params = {}) {
                return this.post('/api/v1/user/webrtcservice/chat/access_tokens', params, {})
            },
            getInvitedImmersiveParticipant(params = {}) {
                return this.get('/api/v1/user/session_invited_immersive_participantships', {params: params})
            },
            getInvitedLivestreamParticipant(params = {}) {
                return this.get('/api/v1/user/session_invited_livestream_participantships', {params: params})
            },
            inviteParticipant(params = {}, service_type = "webrtcservice") {
                if(service_type === "webrtcservice") {
                    return this.post('/api/v1/user/session_invited_immersive_participantships', params, {})
                }
                else {
                    return this.post('/api/v1/user/session_invited_livestream_participantships', params, {})
                }
            },
            controlParticipants(params = {}) {
                return this.post(`api/v1/user/room_members`, params, {})
            },
            mute(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/${params.id}/mute`, params)
            },
            unmute(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/${params.id}/unmute`, params)
            },
            stop_video(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/${params.id}/stop_video`, params)
            },
            start_video(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/${params.id}/start_video`, params)
            },
            banUser(params = {}) {
                return this.post(`/api/v1/user/rooms/${params.room_id}/room_members/${params.id}/ban_kick`, params)
            },
            getBanReasons() {
                return this.get("/api/v1/public/ban_reasons")
            },
            checkGuestEnabled(params = {}) {
                return this.get(`/api/v1/public/interactive_access_tokens/${params.token}`, {})
            },
            getDurations(params = {}){
                return this.get(`/api/v1/user/sessions/${params.session_id}/durations`)
            },
            addDurations(params = {}){
                return this.post(`/api/v1/user/sessions/${params.session_id}/durations`)
            },
            getFfmpegserviceStatus(params = {}){
                return this.get(`/api/v1/user/ffmpegservice_accounts/${params.id}/get_status`)
            }
        }
    }
}
