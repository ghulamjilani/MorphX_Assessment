<template>
    <div
        v-if="roomInfo"
        :class="{
            'cs__participants': layoutPanels.vertical,
            'sharing': isSharing,
            'presenterOnly__participants' : layoutPanels.presenterOnly,
            'grid' : layoutPanels.grid,
            'cm__h__participants' : layoutPanels.horizontal}"
        :style="{width: width, maxWidth: maxWidthSidebar}"
        class="smallScrolls">
        <div
            v-show="$device.mobile() && layoutPanels.grid && enablePrevGrid"
            class="cm__grid__arrow cm__grid__arrow__prev"
            @click="prevGrid">
            <m-icon size="0">
                GlobalIcon-angle-left
            </m-icon>
        </div>
        <!-- <div v-if="(layoutPanels.vertical && presenterTileId !== -1) || layoutPanels.horizontal"
      :class="{'cs__participants__header' : layoutPanels.vertical, 'cm__h__participants__header' : layoutPanels.horizontal}">
      <span>Presenter</span>
      <div class="cs__participants__header__title">{{roomInfo.presenter_user.public_display_name}}</div>
    </div> -->
        <div
            v-if="(layoutPanels.vertical && mainMode !== 'share') || layoutPanels.presenterOnly"
            :class="{'cs__participants__count' : layoutPanels.vertical, 'presenterOnly__participants__count' : layoutPanels.presenterOnly}">
            <!-- <m-icon v-if="isPresenter && isPresenterPins && !layoutPanels.presenterOnly" class="cs__participants__count__pinIcon"> GlobalIcon-pin </m-icon> -->
            Participants ({{ enabledParticipantsLength }})
            <m-icon
                v-if="isPresenter && isPresenterPins"
                ref="participantsSettings"
                :class="{'presenterOnly__participants__count__icon' : layoutPanels.presenterOnly}"
                class="cm__tools__select__icon"
                @click="togglePartSettings()">
                GlobalIcon-angle-down
            </m-icon>
            <participants-settings
                v-if="partSettings"
                v-click-outside="checkTargetOptions"
                :class="{'presenterOnly__participants__count__select' : layoutPanels.presenterOnly}"
                :room-info="roomInfo"
                @close="partSettings = false" />
        </div>
        <div
            id="dragScroll"
            :class="{
                'grid__users' : layoutPanels.grid,
                'grid__users__mobile' : layoutPanels.grid && $device.mobile(),
                'cm__h__users' : layoutPanels.horizontal,
                'cm__h__users__mobile' : layoutPanels.horizontal && $device.mobile(),
                'sharing' : isSharing,
                'presenterOnly__users' : layoutPanels.presenterOnly,
                'cs__participants__users' : layoutPanels.vertical,
                'cm__h__users__visible' : visible && layoutPanels.horizontal}"
            class="animatedScroll">
            <div
                id="ParticipantsList"
                :class="{
                    'grid__users' : layoutPanels.grid,
                    'grid__users__mobile' : layoutPanels.grid && $device.mobile(),
                    'cm__h__users cm__h__users__container' : layoutPanels.horizontal,
                    'cm__h__users__mobile' : layoutPanels.horizontal && $device.mobile(),
                    'sharing' : isSharing,
                    'presenterOnly__users' : layoutPanels.presenterOnly,
                    'cs__participants__users' : layoutPanels.vertical,
                    'cm__h__users__visible' : visible && layoutPanels.horizontal}"
                class="animatedScroll">
                <div
                    v-if="layoutPanels.horizontal"
                    :class="{'cm__h__tile__count__presenter' : mainMode === 'share'}"
                    class="cm__h__tile__count">
                    Participants ({{ enabledParticipantsLength }})
                    <m-icon
                        v-if="isPresenter && isPresenterPins"
                        ref="participantsSettings"
                        class="cm__h__tile__count__icon"
                        @click="togglePartSettings()">
                        GlobalIcon-angle-down
                    </m-icon>
                    <participants-settings
                        v-if="partSettings"
                        v-click-outside="checkTargetOptions"
                        :room-info="roomInfo"
                        @close="partSettings = false" />
                </div>
                <share-tile
                    v-if="isSelfShare"
                    :is-sharing="isSharing"
                    :layout-panels="layoutPanels" />

                <template v-for="(p, i) in enabledParticipants">
                    <participants-tile
                        :key="p.id"
                        :ref="`track-${p.identity.mid}`"
                        :class="tileClass(p)"
                        :enabled-participants-length="enabledParticipantsLength"
                        :enabled-participants-list="enabledParticipantsList"
                        :is-presenter="isPresenter"
                        :is-sharing="isSharing"
                        :layout-panels="layoutPanels"
                        :participant="p"
                        :participants-length="enabledParticipantsLength" />

                    <div
                        v-if="(layoutPanels.vertical && mainMode === 'share') && i === 0"
                        :key="i"
                        :class="{'cs__participants__count' : layoutPanels.vertical,
                                 'sharing' : layoutPanels.vertical && isSharing}">
                        Participants ({{ enabledParticipantsLength }})
                    </div>
                </template>
            </div>
        </div>
        <div
            v-show="$device.mobile() && layoutPanels.grid && enableNextGrid"
            class="cm__grid__arrow cm__grid__arrow__next"
            @click="nextGrid">
            <m-icon size="0">
                GlobalIcon-angle-right
            </m-icon>
        </div>
    </div>
</template>

<script>
import ParticipantsTile from './ParticipantsTile.vue'
import ShareTile from './ShareTile.vue'
import ParticipantsSettings from "./ParticipantsSettings"
import ClickOutside from "vue-click-outside"
import {mapGetters} from 'vuex'

export default {
    directives: {
        ClickOutside
    },
    components: {ParticipantsTile, ParticipantsSettings, ShareTile},
    props: {
        sidebar: Boolean,
        width: String,
        // roomInfo: Object,
        // room: Object,
        layoutPanels: Object,
        maxWidthSidebar: String,
        mainMode: String,
        isSelfShare: Boolean
    },
    data() {
        return {
            enabledParticipants: [],
            trackListen: [],
            participantsListen: [],
            roomSubscribed: false,
            selfSubscribed: false,
            isSidebar: false,
            visible: false,
            isScroll: false,
            partSettings: false,
            swipeGrid: {
                min: 0,
                max: 4
            },
            startX: null,
            startY: null,
            dragElement: null
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "isLocalPins",
            "isPresenterPins",
            "room",
            "roomInfo",
            "roomMember"
        ]),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        enabledParticipantsLength() {
            let l = this.enabledParticipants.filter(e => e.identity.rl !== "P").length
            return l < 0 ? 0 : l
        },
        enabledParticipantsList() {
            if (this.layoutPanels.grid && this.$device.mobile()) return this.enabledParticipants.slice(this.swipeGrid.min, this.swipeGrid.max)
            return this.enabledParticipants
        },
        enableNextGrid() {
            return this.layoutPanels.grid && this.$device.mobile() && this.enabledParticipants.length > this.swipeGrid.max
        },
        enablePrevGrid() {
            return this.layoutPanels.grid && this.$device.mobile() && this.swipeGrid.min != 0
        },
        isSharing() {
            return this.mainMode === "share"
        },
        participantsList() {
            return this.$store.getters["VideoClient/participantsList"]
        }
    },
    watch: {
        enabledParticipantsList: {
            handler() {
                this.$nextTick(() => {
                    this.$eventHub.$emit("recalculateLayout")
                })
            },
            deep: true,
            immediate: true
        },
        layoutPanels: {
            handler() {
                if (this.$device.mobile()) {
                    this.swipeGrid.min = 0
                    this.swipeGrid.max = 4
                }
            },
            deep: true
        }
    },
    mounted() {
        // if(this.room) {
        //   this.getParticipants();
        // }
        document.querySelector('#dragScroll').onmousedown = this.mouseDownHandler
        document.onmouseup = this.mouseUpHandler
        document.querySelector('#dragScroll').onmouseleave = this.mouseUpHandler
    },
    created() {
        this.$eventHub.$on("tw-nextGrid", () => {
            this.nextGrid()
        })
        this.$eventHub.$on("tw-prevGrid", () => {
            this.prevGrid()
        })
        this.$eventHub.$on("tw-options", (data) => {
            let s = document.querySelector('.animatedScroll.cm__h__users')
            if (s && s.scrollWidth > s.offsetWidth) {
                this.isScroll = true
            } else {
                this.isScroll = false
            }
            this.visible = data
        })
        this.$eventHub.$on("tw-roomCreated", () => {
            this.roomCreated()
        })

        this.$eventHub.$on("tw-toggleSidebar", (flag) => {
            this.isSidebar = flag
        })
    },
    destroyed() {
        this.room.participants.forEach(participant => {
            participant.tracks.forEach(track => {
                track.removeAllListeners()
            })
        })
    },
    methods: {
        // mouse drag
        mouseDownHandler(e) {
            document.onmousemove = this.mouseMoveHandler
            this.startX = e.clientX
            this.startY = e.clientY
            this.dragElement = document.getElementById('dragScroll')
        },
        mouseMoveHandler(e) {
            if (this.layoutPanels.vertical || this.layoutPanels.presenterOnly) {
                this.dragElement.scrollTop = this.dragElement.scrollTop + ((this.startY - e.clientY) / 15)
            } else if (this.layoutPanels.horizontal) {
                this.dragElement.scrollLeft = this.dragElement.scrollLeft + ((this.startX - e.clientX) / 15)
            }
        },
        mouseUpHandler() {
            document.onmousemove = null
            this.dragElement = null
        },
        togglePartSettings(val) {
            if (val) return this.partSettings = false
            this.partSettings = !this.partSettings
        },
        checkTargetOptions(event) {
            if (this.$refs.participantsSettings.$el == event.target) return
            this.partSettings = false
        },
        nextGrid() {
            if (this.enableNextGrid) {
                this.swipeGrid.max += 4
                this.swipeGrid.min += 4
                this.$eventHub.$emit('tw-loadingGrid')
            }
        },
        prevGrid() {
            if (this.enablePrevGrid) {
                this.swipeGrid.max -= 4
                this.swipeGrid.min -= 4
                this.$eventHub.$emit('tw-loadingGrid')
            }
        },
        tileClass(p) {
            var className = '0'
            if (!this.enabledParticipantsList.includes(p)) {
                className = 'participantsTile__notShow'
            }
            let e = Math.floor(parseInt(this.width, 10) / 215)
            switch (true) {
                case (e >= 2):
                    return className + ' participantsTile__two'
            }
            return className
        },
        // ---
        roomCreated() {
            this.subscribeParticipants()
            this.checkParticipantsList()
        },
        subscribeParticipants() {
            this.room.on("participantConnected", (participant) => {
                this.checkParticipantsList()
                this.$eventHub.$emit("tw-updateParticipantslist")
                this.$eventHub.$once("tw-participantslistUpdated", () => {
                    this.$eventHub.$emit("tw-notification-user", JSON.parse(participant.identity).mid, "connected")
                })
            })
            this.room.on("participantDisconnected", (participant) => {
                this.detachParticipantTracks(participant)
                this.checkParticipantsList()
                this.$eventHub.$emit("tw-notification-user", JSON.parse(participant.identity).mid, "disconnected")
            })
        },
        checkIfPresenter(presenter) {
            return presenter?.identity?.id === this.roomInfo?.presenter_user?.id
        },
        checkParticipantsList(forcedUpdate = false) {
            // if(!this.room) return
            // add all participants to list, without presenter || if not sidebar mode - with presenter
            this.room?.participants.forEach(participant => {
                if (!this.enabledParticipants.find(f => f.identity.mid === JSON.parse(participant.identity).mid) &&
                    (this.roomInfo.presenter_user.id !== JSON.parse(participant.identity).mid || !this.sidebar)) {
                    let identity = JSON.parse(participant.identity)
                    this.enabledParticipants.push({
                        id: identity.mid,
                        identity: identity
                    })
                }
            })
            // Add users current video
            if (!this.enabledParticipants.find(f => f.id === this.roomMember.id) &&
                (!this.isPresenter || !this.sidebar)) {
                let identity = JSON.parse(this.room.localParticipant.identity)
                this.enabledParticipants.unshift({
                    id: identity.mid,
                    identity
                })
            }

            // Presenter first
            this.enabledParticipants.sort((a, b) => {
                return a.identity.rl === 'P' ? -1 : 1
            })
        },
        detachParticipantTracks(participant) {
            this.enabledParticipants = this.enabledParticipants.filter(e => {
                return JSON.stringify(e.identity) !== participant.identity
            })

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
    }
}
</script>