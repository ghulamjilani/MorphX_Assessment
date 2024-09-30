<template>
    <div
        v-if="!isPresenter || roomMember.id !== participant.id"
        :class="{ 'mp__participant__notJoined': !onSession }"
        class="mp__participant">
        <div class="mp__participant__avatar">
            <img
                :src="participant && participant.user ? participant.user.avatar_url : $img['hidden_default']"
                class="mp__participant__avatar__image">
        </div>
        <div class="mp__participant__name">
            {{ participant.user ? participant.user.public_display_name : participant.display_name }}
        </div>
        <div class="mp__participant__tools">
            <div
                v-if="!onSession"
                class="mp__participant__tools__offline">
                Offline
            </div>
            <m-icon
                v-if="onSession"
                :class="{
                    'mp__participant__tools__icon__active': !videoMuted,
                    'mp__participant__tools__icon__user': !isPresenter}"
                :name="!videoMuted ? 'GlobalIcon-stream-video':'GlobalIcon-video-off'"
                class="mp__participant__tools__icon"
                size="1.6rem" />
            <m-icon
                v-if="onSession"
                :class="{
                    'mp__participant__tools__icon__active': !audioMuted,
                    'mp__participant__tools__icon__user': !isPresenter}"
                :name="!audioMuted ? 'GlobalIcon-mic':'GlobalIcon-mic-off'"
                class="mp__participant__tools__icon mp__participant__tools__icon__mic"
                size="1.6rem" />
            <m-icon
                v-if="isPresenter && onSession"
                :class="{'mp__participant__tools__icon__active' : dots}"
                class="mp__participant__tools__icon"
                size="1.6rem"
                @click="dots = !dots">
                GlobalIcon-dots-3
            </m-icon>
            <div
                v-show="dots"
                class="channelFilters__icons__options__cover"
                @click="dots = !dots" />
            <div
                v-if="dots"
                class="mp__participant__tools__list">
                <div
                    v-if="!isPresenterPins"
                    class="mp__participant__tools__list__item"
                    @click="togglePin">
                    {{ isPinned ? 'Unpin' : 'Pin' }} user
                </div>
                <div
                    v-if="isPresenterPins"
                    class="mp__participant__tools__list__item">
                    Can't pin now
                </div>
                <div
                    v-if="isPresenter"
                    class="mp__participant__tools__list__item"
                    @click="togglePinForAll">
                    {{ isPresenterPinned ? 'Unpin' : 'Pin' }} user for all
                </div>
                <div
                    v-if="onSession"
                    :class="{'mp__participant__tools__list__item__muted': audioMuted}"
                    class="mp__participant__tools__list__item"
                    @click="mute">
                    Mute user
                </div>
                <div
                    v-if="onSession"
                    :class="{'mp__participant__tools__list__item__muted': !audioMuted}"
                    class="mp__participant__tools__list__item"
                    @click="unmute">
                    Ask to unmute audio
                </div>
                <div
                    v-if="onSession"
                    :class="{'mp__participant__tools__list__item__muted': videoMuted}"
                    class="mp__participant__tools__list__item"
                    @click="stopVideo">
                    Stop video
                </div>
                <div
                    v-if="onSession"
                    :class="{'mp__participant__tools__list__item__muted': !videoMuted}"
                    class="mp__participant__tools__list__item"
                    @click="startVideo">
                    Ask to enable video
                </div>
                <div
                    v-if="onSession"
                    class="mp__participant__tools__list__item"
                    @click="banUser">
                    Block user
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import {mapActions, mapGetters} from 'vuex'
import Room from "@models/Room"

export default {
    props: {
        participant: Object
    },
    data() {
        return {
            audioMuted: true,
            videoMuted: true,
            dots: false,
            onSession: true
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "localPins",
            "presenterPins",
            "isPresenterPins",
            "roomMember",
            "roomInfo",
            "room"
        ]),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        isPinned() {
            return this.localPins.find(f => f.id === this.participant.id)
        },
        isPresenterPinned() {
            return this.presenterPins.find(f => f.id === this.participant.id)
        }
    },
    created() {
        this.$eventHub.$on("tw-toggleTrack", data => {
            if (data.user_id === this.participant.id) {
                if (data.audio) {
                    this.audioMuted = !data.active
                } else {
                    this.videoMuted = !data.active
                }
            }
        })

        this.$eventHub.$on("tw-toggleManage", data => {
            this.checkTracks()
        })

        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.micChanged, data => {
            console.log("-----------2", data)
            if (data.room_members.includes(this.participant.id)) {
                if (data.status === 'disabled') {
                    // this.$eventHub.$emit("tw-muteAudio")
                }
            }
        })

        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.videoChanged, data => {
            if (data.room_members.includes(+this.participant.id)) {
                if (data.status === 'disabled') {
                    // this.$eventHub.$emit("tw-muteVideo")
                }
            }
        })

        setInterval(() => {
            this.checkTracks()
        }, 1000)

    },
    methods: {
        ...mapActions("VideoClient", [
            "addLocalPins",
            "removeLocalPins"
        ]),
        mute() {
            this.dots = false
            Room.api().mute({room_id: this.roomInfo.id, id: this.participant.id})
        },
        unmute() {
            this.dots = false
            Room.api().unmute({room_id: this.roomInfo.id, id: this.participant.id})
        },
        stopVideo() {
            this.dots = false
            Room.api().stop_video({room_id: this.roomInfo.id, id: this.participant.id})
        },
        startVideo() {
            this.dots = false
            Room.api().start_video({room_id: this.roomInfo.id, id: this.participant.id})
        },
        banUser() {
            this.dots = false
            this.$emit("banUser", this.participant)
        },
        checkTracks() {
            let founded = false
            this.room?.participants.forEach(participant => {
                if (JSON.parse(participant.identity).mid === this.participant.id) {
                    founded = true
                    participant.tracks.forEach(publication => {
                        if (publication.kind === 'audio') {
                            this.audioMuted = !publication.isTrackEnabled
                        } else if (publication.trackName !== 'share') {
                            this.videoMuted = !publication.isTrackEnabled
                        }
                    })
                }
            })
            if (this.roomMember.id === this.participant.id) {
                founded = true
                this.room?.localParticipant.tracks.forEach(publication => {
                    if (publication.kind === 'audio') {
                        this.audioMuted = !publication.isTrackEnabled
                    } else if (publication.trackName !== 'share') {
                        this.videoMuted = !publication.isTrackEnabled
                    }
                })
            }

            if (!founded) {
                this.audioMuted = true
                this.videoMuted = true
            }

            this.onSession = founded
        },
        togglePin() {
            this.dots = false
            if (!this.isPinned) {
                if (this.presenterMode !== 'share') this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
                this.room?.participants.forEach(participant => {
                    if (JSON.parse(participant.identity).mid === this.participant.id) {
                        let identity = JSON.parse(participant.identity)
                        let LocalPin = {...this.participant, identity: identity}
                        this.addLocalPins(LocalPin)
                    }
                })
                setTimeout(() => {
                    this.$eventHub.$emit("recalculateLayout")
                }, 500)
            } else {
                this.removeLocalPins(this.participant)
                this.room?.participants.forEach(participant => {
                    participant.tracks.forEach(track => {
                        let identity = JSON.parse(participant.identity)
                        if (this.participant.id === identity.mid &&
                            !this.presenterPins.find(e => e.id === identity.mid)) {
                            track.track?.setPriority("low")
                        }
                    })
                })
                setTimeout(() => {
                    this.$eventHub.$emit("recalculateLayout")
                }, 500)
            }
        },
        togglePinForAll() {
            this.dots = false
            let pinned = this.presenterPins.find(f => f.id === this.participant.id)
            let mid = this.participant.id
            if (mid) {
                Room.api().updateRoomMembers({
                    id: this.roomInfo.id,
                    room_members_attributes: [{
                        id: mid,
                        pinned: !pinned
                    }]
                })
                    .then(res => {
                        setTimeout(() => {
                            this.$eventHub.$emit("recalculateLayout")
                        }, 500)
                    })
            } else {
                console.log("CANT FOUND ROOM MEMBER ID!")
            }
        }
    }
}
</script>