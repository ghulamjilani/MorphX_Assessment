<template>
    <div
        :id="'participantTile' + (pinned ? 'Pin':'') + participant.id"
        :class="{
            'cm__h__tile': layoutPanels.horizontal,
            'cm__h__tile__presenter' : layoutPanels.horizontal && isPresenterTile,
            'vertical__tile' : layoutPanels.vertical,
            'vertical__tile__presenter' : layoutPanels.vertical && isPresenterTile,
            'grid__tile' : layoutPanels.grid,
            'grid__tile__not_pinned' : !pinned,
            'grid__tile__pinned' : pinned,
            'presenterOnly__tile' : layoutPanels.presenterOnly,
            'participantsTile__invisible' : !isShow || !isEnablegInGrid
        }"
        class="participantsTile">
        <div
            v-if="layoutPanels.horizontal && isPresenterTile"
            class="cm__h__tile__title">
            Presenter
        </div>
        <div
            v-if="layoutPanels.vertical && isPresenterTile"
            :class="{'cs__participants__header' : layoutPanels.vertical}">
            <span>Presenter</span>
            <div class="cs__participants__header__title">
                {{ roomInfo.presenter_user.display_name }}
            </div>
        </div>
        <div
            v-if="layoutPanels.presenterOnly"
            :class="{'presenterOnly__tools__active' : options}"
            class="presenterOnly__tools">
            <div class="presenterOnly__tools__name">
                {{ getUser(participant) ? getUser(participant).display_name : '' }}
            </div>
        </div>
        <div
            v-if="!isPresenterTile"
            :class="{'mp__active' : options && layoutPanels.presenterOnly, 'mp__open' : options}"
            class="mp">
            <m-icon
                ref="optionsSwitch"
                :class="{'mp__participant__tools__icon__active' : options}"
                class="mp__participant__tools__icon"
                size="0"
                @click="optionsToggle()">
                GlobalIcon-dots-3
            </m-icon>
            <div
                v-if="options"
                id="PartToolsList"
                v-click-outside="checkTarget"
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
                    v-if="isPresenter"
                    :class="{'mp__participant__tools__list__item__muted': !active_audio}"
                    class="mp__participant__tools__list__item"
                    @click="mute">
                    Mute user
                </div>
                <div
                    v-if="isPresenter"
                    :class="{'mp__participant__tools__list__item__muted': active_audio}"
                    class="mp__participant__tools__list__item"
                    @click="unmute">
                    Ask to unmute audio
                </div>
                <div
                    v-if="isPresenter"
                    :class="{'mp__participant__tools__list__item__muted': !active_video}"
                    class="mp__participant__tools__list__item"
                    @click="stopVideo">
                    Stop video
                </div>
                <div
                    v-if="isPresenter"
                    :class="{'mp__participant__tools__list__item__muted': active_video}"
                    class="mp__participant__tools__list__item"
                    @click="startVideo">
                    Ask to enable video
                </div>
                <div
                    v-if="isPresenter"
                    class="mp__participant__tools__list__item"
                    @click="opentBanUser()">
                    Block user
                </div>
            </div>
        </div>
        <div
            v-if="!isPresenterTile && (isPinned || isPresenterPinned)"
            class="cm__pinned__pin">
            <m-icon
                class="cm__pinned__pin__icon"
                size="0">
                GlobalIcon-pin
            </m-icon>
        </div>
        <div
            :class="{
                'presenterOnly__tile__wrapper' : layoutPanels.presenterOnly,
                'participantsTile__video__wrapper' : layoutPanels.vertical,
                'cm__h__tile__wrapper': layoutPanels.horizontal,
                'cm__h__tile__wrapper__mobile': $device.mobile() && layoutPanels.horizontal,
                'grid__tile__wrapper' : layoutPanels.grid}">
            <div
                ref="audio"
                class="tile-audio" />
            <div
                v-show="!layoutPanels.presenterOnly && !disconected && active_video && !testTile"
                ref="video"
                :class="{
                    'participantsTile__video' : !layoutPanels.presenterOnly,
                    'participantsTile__video__speakerPresenter' : isPresenterTile,
                    'participantsTile__video__speakerPresenter__layout' : layoutPanels.horizontal || layoutPanels.vertical,
                    'sharing' : isSharing,
                    'participantsTile__video__speaker' : dominantSpeaker,
                    'participantsTile__video__muted': !active_audio}"
                class="tile-video" />
            <div
                v-show="disconected || !active_video || testTile || layoutPanels.presenterOnly"
                :class="classNameSet()">
                <img
                    v-if="!disconected && getUser(participant) && getUser(participant).user && getUser(participant).user.avatar_url"
                    :class="{
                        'participantsTile__video__muted': !active_audio,
                        'presenterOnly__tile__avatar': layoutPanels.presenterOnly,
                        'participantsTile__avatar': !layoutPanels.presenterOnly
                    }"
                    :src="getUser(participant) && getUser(participant).user && getUser(participant).user.avatar_url">
                <svg
                    v-else
                    :class="{'presenterOnly__tile__avatar': layoutPanels.presenterOnly}"
                    fill="none"
                    height="50%"
                    viewBox="0 0 60 60"
                    width="50%"
                    xmlns="http://www.w3.org/2000/svg">
                    <path
                        clip-rule="evenodd"
                        d="M17.5 17.5C17.5 10.5 23 5 30 5C37 5 42.5 10.5 42.5 17.5C42.5 24.5 37 30 30 30C23 30 17.5 24.5 17.5 17.5ZM52.5 47.5V52.5C52.5 54 51.5 55 50 55C48.5 55 47.5 54 47.5 52.5V47.5C47.5 43.25 44.25 40 40 40H20C15.75 40 12.5 43.25 12.5 47.5V52.5C12.5 54 11.5 55 10 55C8.5 55 7.5 54 7.5 52.5V47.5C7.5 40.5 13 35 20 35H40C47 35 52.5 40.5 52.5 47.5ZM30 25C25.75 25 22.5 21.75 22.5 17.5C22.5 13.25 25.75 10 30 10C34.25 10 37.5 13.25 37.5 17.5C37.5 21.75 34.25 25 30 25Z"
                        fill="#6F7073"
                        fill-rule="evenodd" />
                </svg>
                <m-icon
                    v-if="layoutPanels.presenterOnly"
                    :class="active_audio ? 'presenterOnly__tile__micro__active' : 'presenterOnly__tile__micro__inactive'"
                    :name="active_audio ? 'GlobalIcon-mic' : 'GlobalIcon-mic-off'"
                    class="presenterOnly__tile__micro"
                    size="0" />
            </div>
            <div
                v-if="!layoutPanels.presenterOnly"
                :class="{
                    'participantsTile__tools__presenter': isPresenterTile && !layoutPanels.horizontal && !layoutPanels.vertical
                }"
                class="participantsTile__tools">
                <m-icon
                    :class="{'participantsTile__tools__icon__active': active_audio}"
                    :name="active_audio ? 'GlobalIcon-mic' : 'GlobalIcon-mic-off'"
                    class="participantsTile__tools__icon"
                    size="0" />
                <div class="participantsTile__name">
                    {{ getUserName(participant) }}
                </div>
                <div
                    v-if="disconected"
                    class="participantsTile__disconected">
                    disconnected
                </div>
            </div>
            <div
                v-show="loader"
                class="participantsTile__loader">
                <div class="spinnerSlider">
                    <div class="bounceS1" />
                    <div class="bounceS2" />
                    <div class="bounceS3" />
                </div>
            </div>
        </div>
        <!-- <div v-show="layoutPanels.vertical && isPresenterTile"
      :class="{'cs__participants__count' : layoutPanels.vertical}">
      Participants ({{participantsLength}})
    </div> -->
        <m-modal
            ref="banReasonsModal"
            class="banReasonsModal"
            @modalClosed="banModalClosed">
            <template #header>
                <span class="banTitle"> Ban Reason </span>
            </template>
            <m-select
                v-model="banReason"
                :options="banOptions"
                label="Ban Reason" />
            <template #footer>
                <m-btn
                    :disabled="!banReason"
                    @click="ban">
                    Ban
                </m-btn>
            </template>
        </m-modal>
    </div>
</template>

<script>
import {mapActions, mapGetters} from 'vuex'
import Room from "@models/Room"
import MModal from '../../../uikit/MModal.vue'
import ClickOutside from "vue-click-outside"

export default {
    components: {MModal},
    directives: {
        ClickOutside
    },
    props: {
        enabledParticipantsLength: Number,
        participant: Object,
        layoutPanels: Object,
        testTile: {
            type: Boolean,
            default: false
        },
        pinned: {
            type: Boolean,
            default: false
        },
        isSharing: {
            type: Boolean,
            default: false
        },
        participantsLength: Number,
        enabledParticipantsList: Array
    },
    data() {
        return {
            active_video: false,
            active_audio: false,
            dominantSpeaker: false,
            options: false,
            banReason: null,
            banUser: null,
            disconected: false,
            isParticipantSubscribed: false,
            loading: false,
            audioMuted: false,
            loader: false,
            tryToReinitAudio: 0,
            lastAudioTime: -1,
            reattachTracks: 0
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "localPins",
            "presenterPins",
            "isLocalPins",
            "isPresenterPins",
            "room",
            "roomInfo",
            "participantsList",
            "banList"
            // "mainSectionMode" // don't forget
        ]),
        banOptions() {
            return this.banList.map(e => {
                return {
                    name: e.name,
                    value: e.id
                }
            })
        },
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCurrentUserTile() {
            return this.roomMember.id === this.participant.id
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        isPresenterTile() {
            return this.roomInfo?.presenter_user?.id === this.participant?.identity?.id
        },
        isShow() {
            // if(this.disconected) return false
            if (this.$device.mobile() && this.pinned) return true

            if (this.$device.mobile() && this.layoutPanels.grid && !this.enabledParticipantsList?.includes(this.participant)) return false

            if (this.isPresenterTile && !this.isSharing && !this.layoutPanels.grid) return false
            // show if usual state
            if (this.layoutPanels.grid || this.pinned || this.isSharing) return true
            // if presenter doesn't pin, and not local pins too
            if (!this.isPresenterPins) {
                return !this.isPinned
            } else { // if presenter pin and this user not pinned by presenter
                return !this.isPresenterPinned
            }
        },
        isPinned() {
            return this.localPins.find(f => f.id === this.participant.id)
        },
        isPresenterPinned() {
            return this.presenterPins.find(f => f.id === this.participant.id)
        },
        isEnablegInGrid() {
            if (this.isPresenterPinned || this.isPinned) return true
            if (!this.$device.mobile()) return true
            else if (this.enabledParticipantsList?.includes(this.participant)) return true
            return false
        }
    },
    watch: {
        room(val, oldVal) {
            if (!val) return
            if (!oldVal && val) {
                setTimeout(() => {
                    this.participantLoaded()
                }, 1000) // time to init
            }
            this.checkAndSubscribeToEvents()
        }
    },
    methods: {
        ...mapActions("VideoClient", [
            "addLocalPins",
            "removeLocalPins",
            "addPresenterPins",
            "togglePresenterPins",
            "setBanList"
        ]),
        loadingGrid() {
            this.loader = true
            setTimeout(() => {
                this.loader = false
            }, 2500)
        },

        // Управление юзером
        checkTarget(event) {
            this.checkDropDownPosition()
            if (this.$refs.optionsSwitch.$el == event.target) return
            this.optionsToggle(false)
        },
        optionsToggle(data) {
            this.$eventHub.$emit('tw-options', this.options)
            if (data) {
                this.options = data
                this.$eventHub.$emit('tw-options', this.options)
            } else {
                this.options = !this.options
                this.$eventHub.$emit('tw-options', this.options)
            }
        },
        checkDropDownPosition() {
            let wrapper = document.getElementById('ParticipantsList')
            let elem = document.getElementById('PartToolsList')
            let wrapperrect = wrapper.getBoundingClientRect()
            let Elemrect = elem.getBoundingClientRect()
            if (Elemrect.left < wrapperrect.left) {
                elem.style.right = 0
                if (screen.width >= 1920) {
                    elem.style.right = -30 + 'px'
                    elem.style.top = -20 + 'px'
                }
            }
        },
        openBanReason() {
            // todo: 1 banReasonsModal for all; ban only for presenter
            this.$refs.banReasonsModal.openModal()
            this.banUser = this.participant.id
        },
        banModalClosed() {
            this.banUser = null
            this.banReason = null
        },
        ban() {
            if (!this.banUser) {
                this.$flash("Error, please try again")
            }
            Room.api().banRoomMember({
                room_id: this.roomInfo.id,
                id: this.banUser,
                banned: true,
                ban_reason_id: this.banReason
            }).then(res => {
                this.banUser = null
                this.banReason = null
                this.$eventHub.$emit("tw-updateParticipantslist")
                this.$refs.banReasonsModal.closeModal()
            }).catch(error => {
                this.$flash(error?.response?.data?.message)
            })
        },
        mute() {
            this.optionsToggle(false)
            Room.api().mute({room_id: this.roomInfo.id, id: this.participant.id})
        },
        unmute() {
            this.optionsToggle(false)
            Room.api().unmute({room_id: this.roomInfo.id, id: this.participant.id})
        },
        stopVideo() {
            this.optionsToggle(false)
            Room.api().stop_video({room_id: this.roomInfo.id, id: this.participant.id})
        },
        startVideo() {
            this.optionsToggle(false)
            Room.api().start_video({room_id: this.roomInfo.id, id: this.participant.id})
        },
        opentBanUser() {
            this.optionsToggle(false)
            this.openBanReason()
        },
        togglePin() {
            this.optionsToggle(false)
            if (!this.isPinned) {
                if (this.presenterMode !== 'share') this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
                this.addLocalPins(this.participant)
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
            this.optionsToggle(false)
            // let roomMember = this.roomInfo.room_members.find(e => e.room_member.id === this.participant.identity.mid)
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
        },
        // ----
        classNameSet() {
            let tileClass
            tileClass = this.layoutPanels.presenterOnly ? 'presenterOnly__plug' : 'participantsTile__video'
            tileClass = this.dominantSpeaker && !this.layoutPanels.presenterOnly ? tileClass + ' participantsTile__video__speaker' : tileClass
            tileClass = this.dominantSpeaker && this.layoutPanels.presenterOnly ? tileClass + ' presenterOnly__plug__speaker' : tileClass
            tileClass = this.isPresenterTile ? tileClass + ' participantsTile__video__speakerPresenter' : tileClass
            return tileClass
        },
        findParticipant() {
            let p = null
            if (this.isCurrentUserTile) {
                p = this.room.localParticipant
            } else {
                this.room?.participants.forEach(participant => {
                    let identity = JSON.parse(participant.identity)
                    if (identity.mid === this.participant.id) {
                        p = participant
                    }
                })
            }
            return p
        },
        participantLoaded() {
            setTimeout(() => {
                this.subscribeToParticipant()
                this.initTracks()
            }, 1000) // time to init
        },
        subscribeToParticipant() {
            let participant = this.findParticipant() // !!!

            participant.on('trackPublished', track => {
                this.reattachTracks = 0
                if (track.trackName === "share") return
                if (this.isCurrentUserTile && track.kind === "audio" && track.kind !== "share") {
                    setTimeout(() => {
                        this.initTrack(track, true)
                    }, 1000)
                } else if (track.kind !== "share") {
                    setTimeout(() => {
                        this.initTrack(track)
                    }, 1000)
                }
            })
            participant.on('trackUnpublished', track => {
                if (track.trackName === "share") return
                track.removeAllListeners()
                track?.track?.detach().forEach(function (element) {
                    element.srcObject = null
                    element.remove()
                })

                // remove when webrtcservice stable it
                let vel = document.querySelector(`#participantTile${this.participant.id} ${track.kind}`)
                if (vel) {
                    vel.srcObject = null
                    vel.remove()
                }
            })
        },
        initTracks() {
            if (this.isCurrentUserTile) {
                this.room.localParticipant.videoTracks.forEach(track => {
                    if (track.trackName !== "share") {
                        this.initTrack(track)
                    }
                })
                this.room.localParticipant.audioTracks.forEach(track => {
                    this.initTrack(track, true)
                })
            } else {
                let participant = this.findParticipant()
                participant.tracks.forEach(track => {
                    if (track.trackName !== "share") {
                        this.initTrack(track)
                    }
                })
            }
        },
        /**
         * @argument t Track
         * @argument onlySubscribe Don't init, just subscribe
         */
        initTrack(t, onlySubscribe = false) {
            let track = t.track ? t.track : t

            if (track.name === "share") return
            if (!onlySubscribe) onlySubscribe = this.pinned && track.kind === "audio"

            if (!onlySubscribe) {
                let el = document.querySelector(`#participantTile${this.pinned ? "Pin" : ""}${this.participant.id} ${track.kind}`)

                if (el) { // remove if excists
                    el.srcObject = null
                    el.remove()
                }

                let div = document.querySelector(`#participantTile${this.pinned ? "Pin" : ""}${this.participant.id} .tile-${track.kind}`)
                if (track && track.attach) {
                    div.appendChild(track.attach())
                    this.reattachTracks = 0
                } else {
                    this.reattachTracks++
                    console.log("*** track is empty, trying to reattach #", this.reattachTracks)
                    if (this.reattachTracks <= 5) {
                        setTimeout(() => {
                            this.initTrack(track, onlySubscribe)
                        }, 2000)
                    }
                }
            }

            this['active_' + track.kind] = track.isEnabled

            track.on('disabled', () => { // subscribe to track events
                this['active_' + track.kind] = false
            })
            track.on('enabled', () => {
                this['active_' + track.kind] = true
            })
        },
        stopTrack(track) {
            let t = track.track ? track.track : track
            t?.detach()?.forEach(function (element) {
                element.srcObject = null
                element.remove()
            })
        },
        getUser(participant) {
            if (this.testTile) return {display_name: "Test User" + this.participant.id}
            let user = this.participantsList?.find(e => e.id === participant.identity.mid)
            if (user) return user
            else {
                let user2 = this.roomInfo.room_members.find(e => e.room_member.id === participant.identity.mid)
                if (user2) return user2.room_member
                else return null
            }
        },
        getUserName(participant) {
            if (this.testTile) return "Test User" + this.participant.id
            let user = this.participantsList?.find(e => e.id === participant.identity.mid)
            if (user) {
                if (user.user) return user.user.public_display_name
                if (user.public_display_name) return user.public_display_name
                if (user.display_name) return user.display_name
            }
            let user2 = this.roomInfo.room_members.find(e => e.room_member.id === participant.identity.mid)
            if (user2) {
                if (user2?.room_member?.abstract_user) return user2.room_member.abstract_user.public_display_name
                return user2.room_member.display_name
            }
            return ''
        },
        checkAndSubscribeToEvents() {
            if (!this.room) return

            let founded = false
            this.room.participants.forEach(participant => {
                let identity = JSON.parse(participant.identity)
                if (identity.mid === this.participant.id) {
                    founded = true
                }
            })
            if (JSON.parse(this.room.localParticipant.identity).mid === this.participant.id) {
                founded = true
            }

            this.disconected = !founded
        },
        checkVideoTiles() {
            let participant = this.findParticipant()
            participant.videoTracks.forEach(track => {
                let isEnabled = track.track.isEnabled
                let vel = document.querySelector(`#participantTile${this.participant.id} video`)
                if (isEnabled && !vel) {
                    this.initTrack(track)
                }
            })
        }
    },
    mounted() {
        if (this.room) {
            this.participantLoaded() // !!!
        }

        if (this.layoutPanels.grid && this.$device.mobile()) this.loadingGrid()
        this.checkAndSubscribeToEvents()
        this.$eventHub.$on('tw-loadingGrid', () => {
            this.loadingGrid()
        })
        this.$eventHub.$on("tw-audioMuted", (value) => {
            this.audioMuted = value
        })
    },
    created() {
        if (this.isPresenter && this.banList.length === 0) {
            Room.api().getBanReasons().then(res => {
                this.setBanList(res.response.data.response.ban_reasons)
            })
        }
        if (this.testTile) return
        this.$eventHub.$on("tw-participantTrackControl", data => {
            if (this.participant.id === data.identity.mid) {
                console.log("tw-participantTrackControl", data.identity.mid)
                if (data.type === 'init') {
                    this.initTrack(data.track, data.forcedUpdate)
                }
            }
        })
        this.$eventHub.$on("tw-dominantSpeakerChanged", participant => {
            let identity = participant ? JSON.parse(participant.identity) : null
            if (identity && this.participant.id === identity.mid) {
                this.dominantSpeaker = true
            } else {
                this.dominantSpeaker = false
            }
        })
    },
    beforeDestroy() {
        let vel = document.querySelector(`#participantTile${this.pinned ? "Pin" : ""}${this.participant.id} video`)
        if (vel) {
            vel.srcObject = null
            vel.remove()
        }
        let ael = document.querySelector(`#participantTile${this.pinned ? "Pin" : ""}${this.participant.id} audio`)
        if (ael) {
            ael.srcObject = null
            ael.remove()
        }
    }
}
</script>
