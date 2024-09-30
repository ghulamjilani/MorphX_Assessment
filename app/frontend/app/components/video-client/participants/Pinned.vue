<template>
    <div
        v-if="roomInfo"
        :class="{
            'cs__participants': layoutPanels.vertical,
            'presenterOnly__participants' : layoutPanels.presenterOnly,
            'grid' : layoutPanels.grid,
            'cm__h__participants' : layoutPanels.horizontal}"
        class="smallScrolls">
        <div
            :class="{
                'grid__users' : layoutPanels.grid,
                'cm__h__users' : layoutPanels.horizontal,
                'presenterOnly__users' : layoutPanels.presenterOnly,
                'cs__participants__users' : layoutPanels.vertical}"
            class="animatedScroll">
            <template v-for="p in pinnedParticipants">
                <participants-tile
                    :key="p.id"
                    :ref="`track-${p.identity.mid}`"
                    :is-presenter="isPresenter"
                    :is-sharing="isSharing"
                    :layout-panels="layoutPanels"
                    :participant="p"
                    :participants-length="0"
                    :pinned="true"
                    :room="room"
                    :room-info="roomInfo" />
            </template>
        </div>
    </div>
</template>

<script>
import {mapActions, mapGetters} from 'vuex'
import ParticipantsTile from './ParticipantsTile.vue'
import Room from "@models/Room"

export default {
    components: {ParticipantsTile},
    props: {
        sidebar: Boolean,
        width: String,
        layoutPanels: Object,
        maxWidthSidebar: String
    },
    data() {
        return {
            trackListen: [],
            participantsListen: [],
            roomSubscribed: false,
            selfSubscribed: false,
            isSidebar: false,
            presenterTileId: -1,
            isSharing: false
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "localPins",
            "presenterPins",
            "isLocalPins",
            "isPresenterPins",
            "room",
            "roomInfo"
        ]),
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        pinnedParticipants() {
            return this.isPresenterPins ? [...this.presenterPins].sort((a, b) => {
                return a.identity.rl === 'P' ? -1 : 1
            }) : [...this.localPins].sort((a, b) => {
                return a.identity.rl === 'P' ? -1 : 1
            })
        }
    },
    watch: {
        room(val) {
            this.checkPinned()
            if (val && !this.roomSubscribed) {
                this.roomSubscribed = true
            }
        },
        localPins: {
            deep: true,
            handler(val, oldVal) {
                this.checkPinned()
                if (val.length === 2 && oldVal.length === 1) {
                    this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
                }
            }
        },
        presenterPins: {
            deep: true,
            handler(val, oldVal) {
                this.checkPinned()
                if (val.length === 2 && oldVal.length === 1) {
                    this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
                }
            }
        }
    },
    methods: {
        ...mapActions("VideoClient", [
            "addLocalPins",
            "removeLocalPins",
            "addPresenterPins",
            "togglePresenterPins"
        ]),
        roomCreated() {
            this.subscribeParticipants()
            this.checkPinned()
        },
        subscribeParticipants() {
            this.room.on("participantConnected", (participant) => {
                this.checkPinned()
            })
            this.room.on("participantDisconnected", (participant) => {
                this.detachParticipantTracks(participant)
                this.checkPinned()
            })
        },
        checkPinned() {
            if (!this.localPins.find(e => e.identity.rl === "P") ||
                !this.presenterPins.find(e => e.identity.rl === "P")) {
                this.room?.participants.forEach(participant => {
                    let identity = JSON.parse(participant.identity)
                    if (identity.rl === "P") {
                        this.addLocalPins({
                            id: identity.mid,
                            identity
                        })
                        this.addPresenterPins({
                            id: identity.mid,
                            identity
                        })
                    }
                })
                if (this.isPresenter) {
                    this.addLocalPins({
                        id: this.roomMember.id,
                        identity: {
                            rl: this.isPresenter ? "P" : "U",
                            id: this.currentUser.id,
                            mid: this.roomMember.id
                        }
                    })
                    this.addPresenterPins({
                        id: this.roomMember.id,
                        identity: {
                            rl: this.isPresenter ? "P" : "U",
                            id: this.currentUser.id,
                            mid: this.roomMember.id
                        }
                    })
                }
            }
            setTimeout(() => {
                this.getParticipants()
            }, 1000)
        },
        tileClass() {
            let e = Math.floor(parseInt(this.width, 10) / 215)
            switch (true) {
                case (e === 2):
                    return 'participantsTile__two'
                case (e === 3):
                    return 'participantsTile__three'
                case (e === 4):
                    return 'participantsTile__four'
                case (e >= 5):
                    return 'participantsTile__five'
            }
        },
        getParticipants(forcedUpdate = false) {
            this.checkParticipantsList(forcedUpdate)
        },
        checkIfPresenter(presenter) {
            return presenter.identity.mid === this.roomInfo?.presenter_user?.id
        },
        checkParticipantsList(forcedUpdate = false) {
        },
        detachParticipantTracks(participant) {
            // pin remove
            let identity = JSON.parse(participant.identity)
            let p = {
                id: identity.mid,
                identity
            }
            this.removeLocalPins(p)
            if (this.isPresenter) {
                if (identity.mid) {
                    Room.api().updateRoomMembers({
                        id: this.roomInfo.id,
                        room_members_attributes: [{
                            id: identity.mid,
                            pinned: false
                        }]
                    })
                        .then(res => {
                            setTimeout(() => {
                                this.$eventHub.$emit("recalculateLayout")
                            }, 500)
                        })
                }
            }

            this.room.participants.forEach(rparticipant => {
                if (rparticipant.identity === participant.identity)
                    rparticipant.tracks.forEach(publication => {
                        if (publication.isSubscribed) {
                            const track = publication.track
                            track.detach().forEach(function (element) {
                                element.srcObject = null
                                element.remove()
                            })
                        }
                    })
            })
        }
    },
    mounted() {
        if (this.room) this.roomCreated()
    },
    created() {
        this.$eventHub.$on("tw-roomCreated", () => {
            this.roomCreated()
            if (this.presenterPins.length > 1) {
                this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
            }
        })

        this.$eventHub.$on("tw-toggleSidebar", (flag) => {
            this.isSidebar = flag
        })

        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.pinnedUsers, data => {
            this.checkPinned()
        })

        this.$eventHub.$on("tw-checkPinned", data => {
            this.checkPinned()
        })

        window.checkPinned = this.checkPinned
    },
    destroyed() {
        this.room.participants.forEach(participant => {
            participant.tracks.forEach(track => {
                track.removeAllListeners()
            })
        })
    }
}
</script>