<template>
    <div
        v-if="!ended"
        id="room">
        <video-client
            v-if="type == 'webrtcservice'"
            :can-create-room="canCreateRoom"
            :room-info="roomInfo"
            @changeType="changeType"
            @updateUsersList="updateParticipantslist" />
        <web-rtc-client
            v-if="type == 'webrtc'"
            :room-info="roomInfo" />
        <ip-cam-client
            v-if="type == 'ipcam'"
            :room-info="roomInfo" />
        <obs-client
            v-if="type == 'rtmp'"
            :room-info="roomInfo" />
        <user-already-in-room
            :active="isAlreadyInTheRoom"
            @initThis="initThisUser" />
        <question-to-unmute
            :active="isQuestionToUnmute"
            :type="questionToUnmuteType"
            @close="isQuestionToUnmute = false" />
        <create-poll
            v-if="roomInfo"
            :can-create="isPresenter"
            :model-id="roomInfo && roomInfo.abstract_session_id"
            :model-type="'Session'"
            :current-polls="roomInfo.abstract_session.polls" />
    </div>
</template>

<script>
import {mapActions, mapGetters} from 'vuex'
import {deleteCookie} from "@utils/cookies"

import VideoClient from './video-client/VideoClient.vue'
import UserAlreadyInRoom from "./video-client/UserAlreadyInRoom.vue"
import Room from "@models/Room"
import User from "@models/User"
import WebRTCClient from './web-rtc/WebRTCClient.vue'
import QuestionToUnmute from './video-client/QuestionToUnmute.vue'
import utils from '@helpers/utils'
import IpCamClient from './ipcam/IpCamClient.vue'
import ObsClient from './obs/ObsClient.vue'
import CreatePoll from '@components/polls/CreatePoll.vue'

export default {
    components: {
        VideoClient,
        "web-rtc-client": WebRTCClient,
        UserAlreadyInRoom,
        QuestionToUnmute,
        IpCamClient,
        ObsClient,
        CreatePoll
    },
    data() {
        return {
            roomInfo: null,
            ended: false,
            type: "",
            // events
            sessionsChannel: null,
            presenceImmersiveRoomsChannel: null,
            //
            loading: false,
            isAlreadyInTheRoom: false,
            isQuestionToUnmute: false,
            questionToUnmuteType: "",
            closeOld: false,
            canCreateRoom: false,
            RoomMembersChannel: false
        }
    },
    watch: {
        currentUser: {
            deep: true,
            handler(val) {
                if (val) {
                    this.$eventHub.$emit("close-modal:auth")
                }
                if (val && !this.loading && !this.roomInfo) {
                    this.fetch()
                }
            }
        },
        'RoomMembersChannel.is_connected': {
            deep: true,
            immediate: true,
            handler(val, oldVal) {
                if (val && oldVal == false) {
                    this.fetch(this.currentUser == null)
                }
            }
        }
    },
    mounted() {
        this.$eventHub.$on("tw-subscribeForImmersiveRoomsChannelEvents", flag => {
            this.subscribeForImmersiveRoomsChannelEvents()
        })
        this.$eventHub.$on("tw-canCreateRoom", flag => {
            this.canCreateRoom = flag
        })
        this.$eventHub.$on("tw-loginToRoom", (user) => {
            if (user.guest) {
                this.fetch(true)
            }
        })

        window.twver = "webrtcservice-video 2.14.0"

        if (this.currentUser) this.fetch()

        this.$eventHub.$on("tw-updateParticipantslist", () => {
            this.updateParticipantslist()
        })

        this.$eventHub.$on("roomUpdated", (room) => {
            this.roomInfo.abstract_session = room.abstract_session
            this.roomInfo.status = room.status
            this.roomInfo.service_token = room.service_token
            this.roomInfo.room_members = room.room_members
            this.roomInfo.is_screen_share_available = room.is_screen_share_available
            if (this.roomInfo.ffmpegservice_account) this.roomInfo.ffmpegservice_account = room.ffmpegservice_account
        })

        this.$eventHub.$on("tw-updateRoomInfo", () => {
            // this.fetch()
        })

        window.onbeforeunload = function () {
            return true
        }


        User.api().currentUser()
            .catch(err => {
                deleteCookie("_unite_session_jwt")
                deleteCookie("_cable_jwt")
                deleteCookie('_unite_session_jwt_refresh')
                this.$eventHub.$emit("updateJwt")
                this.$eventHub.$emit("open-modal:auth", "guest", {
                    action: "close-and-emit-res",
                    event: 'tw-loginToRoom',
                    data: {}
                }, {
                    backdrop: false,
                    close: false,
                    guest: true
                })
            })
    },
    computed: {
        ...mapGetters("VideoClient", ["localPins", "presenterPins", "isLocalPins", "isPresenterPins"]),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        participantsList() {
            return this.$store.getters["VideoClient/participantsList"]
        },
        isPresenter() {
            return this.currentUser && this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
    },
    methods: {
        ...mapActions("VideoClient", [
            "setRoomInfo",
            "addPresenterPins",
            "updatePresenterPins",
            "setPresenterPins",
            "addToParticipantsList"
        ]),
        initThisUser() {
            this.closeOld = true
            this.isAlreadyInTheRoom = false
            this.canCreateRoom = true
            this.fetch()
        },
        fetch(isGuest = false) {
            let id = this.$route.params.id
            let token = this.$route.params.token
            this.loading = true
            Room.api().getRoom({id, token, isGuest}).then(res => {
                this.roomInfo = res.response.data.response.room
                this.loading = false

                setTimeout(() => {
                    this.$eventHub.$emit("conversation-polls", this.roomInfo.abstract_session.polls)
                }, 1000)


                if (location.href.includes("join") && this.roomInfo?.id && !this.roomInfo?.current_room_member?.guest) {
                    history.pushState(null, null, `/rooms/${this.roomInfo.id}`)
                }

                this.type = this.roomInfo.abstract_session.service_type
                if (this.type === "webrtcservice") {
                    if (!isGuest && !this.closeOld && this.roomInfo?.room_members.find(e =>
                        this.currentUser?.id === e.room_member?.abstract_user?.id && e.room_member?.abstract_user_type === 'User' && e.room_member?.joined)) {
                        this.isAlreadyInTheRoom = true
                        return
                    }
                    this.canCreateRoom = true
                    // this.$eventHub.$emit("tw-participantslist", res.response.data.response.room.room_members)
                    this.addToParticipantsList(res.response.data.response.room.room_members)
                    this.$eventHub.$emit("tw-roomInfoLoaded", this.roomInfo)
                    this.subscribeForEvents()

                    this.checkIfBanned()

                    this.$store.dispatch("VideoClient/setRoomMember", res.response.data.response.room.current_room_member)

                    this.RoomMembersChannel = initRoomMembersChannel(res.response.data.response.room.current_room_member.id)

                    let roomInfoDC = JSON.parse(JSON.stringify(this.roomInfo))
                    this.setRoomInfo(roomInfoDC)

                    let pinned = []
                    this.roomInfo.room_members.forEach(e => {
                        if (e.room_member.pinned) {
                            let user_id = e.room_member.abstract_user_type === 'User' ? e.room_member.abstract_user_id : null
                            let isPresenter = this.roomInfo.presenter_user.id === user_id
                            pinned.push({
                                id: e.room_member.id,
                                identity: {
                                    rl: isPresenter ? "P" : "U",
                                    id: user_id,
                                    mid: e.room_member.id
                                }
                            })
                        }
                    })
                    this.setPresenterPins(pinned)
                    if (pinned.length > 0) {
                        this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
                    }
                } else {
                    this.sessionsChannel = initSessionsChannel()

                    this.sessionsChannel.bind(sessionsChannelEvents.livestreamUp, (data) => {
                        if (data.session_id === this.roomInfo?.abstract_session?.id) {
                            this.$eventHub.$emit(sessionsChannelEvents.livestreamUp, data)
                        }
                    })
                    this.sessionsChannel.bind(sessionsChannelEvents.livestreamDown, (data) => {
                        if (data.session_id === this.roomInfo?.abstract_session?.id) {
                            this.$eventHub.$emit(sessionsChannelEvents.livestreamDown, data)
                        }
                    })
                    this.sessionsChannel.bind(sessionsChannelEvents.sessionStopped, (data) => {
                        if (data.session_id === this.roomInfo?.abstract_session?.id) {
                            this.$eventHub.$emit(sessionsChannelEvents.sessionStopped, data)
                            if (!this.ended)
                                this.$eventHub.$emit("flash-client","Session ended")
                            this.ended = true
                            setTimeout(() => {
                                this.closePage()
                            }, 5000)
                        }
                    })
                }
            }).catch(error => {
                this.loading = false
                if (error?.response?.data?.message?.error) this.$eventHub.$emit("flash-client",error?.response?.data?.message?.error)
                else if (error?.response?.data?.message) this.$eventHub.$emit("flash-client",error?.response?.data?.message)
                setTimeout(() => {
                    this.closePage(true)
                }, 2000)
            })
        },
        updateParticipantslist: utils.debounce(function () {
            if (!this.roomMember) return
            let id = this.$route.params.id
            if (!id) id = this.roomInfo.id
            let token = this.$route.params.token
            let isGuest = this.roomMember.guest
            Room.api().getRoom({id, token, isGuest}).then(res => {
                // this.$eventHub.$emit("tw-participantslist", res.response.data.response.room.room_members)
                this.addToParticipantsList(res.response.data.response.room.room_members)
                let roomInfoDC = JSON.parse(JSON.stringify(res.response.data.response.room))
                this.setRoomInfo(roomInfoDC)
                this.$eventHub.$emit("tw-participantslistUpdated")
            })
        }, 1000),
        closePage(redirect = false) {
            window.onbeforeunload = null

            window.opener = self
            if (!redirect) window.close()
            location.href = location.origin
        },
        subscribeForEvents() {
            //  SessionsChannel
            this.sessionsChannel = initSessionsChannel()

            this.sessionsChannel.bind(sessionsChannelEvents.sessionStarted, (data) => {
                if (data.session_id === this.roomInfo?.abstract_session?.id) {
                    this.$eventHub.$emit(sessionsChannelEvents.sessionStarted, data)
                    this.$eventHub.$emit("tw-goLive-new")
                    this.$eventHub.$emit("tw-goLive-event")
                }
            })
            this.sessionsChannel.bind(sessionsChannelEvents.sessionStopped, (data) => {
                if (data.session_id === this.roomInfo?.abstract_session?.id) {
                    this.$eventHub.$emit(sessionsChannelEvents.sessionStopped, data)
                    this.closePage()
                    if (!this.ended)
                        this.$flash("Session ended")
                    this.ended = true
                }
            })

            this.subscribeForImmersiveRoomsChannelEvents()
        },
        subscribeForImmersiveRoomsChannelEvents() {
            this.presenceImmersiveRoomsChannel = initPresenceImmersiveRoomsChannel(this.roomInfo.id)

            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.micChanged, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.micChanged, data)
                if (data.room_members.includes(this.roomMember.id)) {
                    if (data.status === 'disabled') {
                        this.$eventHub.$emit("tw-muteAudio")
                    }
                    if (data.status === 'enabled') {
                        this.$eventHub.$once("tw-answerSourcesStatus", answ => {
                            if (!answ.audio) {
                                this.isQuestionToUnmute = true
                                this.questionToUnmuteType = "audio"
                            }
                        })
                        this.$eventHub.$emit("tw-askSourcesStatus")
                    }
                }
            })

            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.videoChanged, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.videoChanged, data)
                if (data.room_members.includes(this.roomMember.id)) {
                    if (data.status === 'disabled') {
                        this.$eventHub.$emit("tw-muteVideo")
                    }
                    if (data.status === 'enabled') {
                        this.$eventHub.$once("tw-answerSourcesStatus", answ => {
                            if (!answ.video) {
                                this.isQuestionToUnmute = true
                                this.questionToUnmuteType = "video"
                            }
                        })
                        this.$eventHub.$emit("tw-askSourcesStatus")
                    }
                }
            })

            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.screenShareAbilityChanged, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.screenShareAbilityChanged, data)
                this.roomInfo.is_screen_share_available = data.is_screen_share_available
                let roomInfoDC = JSON.parse(JSON.stringify(this.roomInfo))
                this.setRoomInfo(roomInfoDC)
            })
            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.pinnedUsers, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.pinnedUsers, data)
                if (!this.isPresenterPins && data?.pinned_members?.length > 0) {
                    this.$eventHub.$emit("tw-notification", `Presenter pins some users`)
                }
                this.updatePresenterPins(data.pinned_members)

                setTimeout(() => {
                    this.$eventHub.$emit("recalculateLayout")
                }, 500)
            })
            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.banKick, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.banKick, data)
                if (data.room_member_id === this.roomMember.id) {
                    this.$flash("You have been banned")
                    localStorage.setItem("banned", this.roomInfo.id)
                    this.$eventHub.$emit("tw-muteAudio")
                    this.$eventHub.$emit("tw-muteVideo")
                    setTimeout(() => {
                        window.onbeforeunload = null
                        window.opener = self
                        location.href = location.origin
                    }, 1000)
                }
            })

            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.noPresenterStopScheduled, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.noPresenterStopScheduled, data)
            })
            this.presenceImmersiveRoomsChannel.bind(presenceImmersiveRoomsChannelEvents.presenterJoined, (data) => {
                this.$eventHub.$emit(presenceImmersiveRoomsChannelEvents.presenterJoined, data)
            })
        },
        checkIfBanned() {
            let isBanned = localStorage.getItem("banned")
            if (isBanned && +isBanned === this.roomInfo.id) {
                this.$flash("You have been banned")
                setTimeout(() => {
                    window.onbeforeunload = null
                    window.opener = self
                    location.href = location.origin
                }, 1000)
            }
        },
        changeType(type) {
            this.type = type
            if (type === "close") {
                setTimeout(() => {
                    // window.onbeforeunload = null
                    // window.opener = self;
                    // window.close()
                    // location.href = location.origin
                }, 5000)
            }
        }
    }
}
</script>
