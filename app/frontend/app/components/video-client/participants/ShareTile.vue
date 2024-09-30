<template>
    <div
        :id="'shareTile'"
        :class="{
            'cm__h__tile': layoutPanels.horizontal,
            'cm__h__tile__presenter' : layoutPanels.horizontal && isPresenterTile,
            'vertical__tile' : layoutPanels.vertical,
            'vertical__tile__presenter' : layoutPanels.vertical && isPresenterTile,
            'grid__tile' : layoutPanels.grid,
            'presenterOnly__tile' : layoutPanels.presenterOnly,
            'participantsTile__invisible' : !isShow || !isEnablegInGrid
        }"
        class="participantsTile grid__tile__not_pinned">
        <div class="cm__h__tile__title">
            {{ $t('components.video_client.tiles.your_screenshare') }}
        </div>
        <div
            :class="{
                'presenterOnly__tile__wrapper' : layoutPanels.presenterOnly,
                'participantsTile__video__wrapper' : layoutPanels.vertical,
                'cm__h__tile__wrapper': layoutPanels.horizontal,
                'cm__h__tile__wrapper__mobile': $device.mobile() && layoutPanels.horizontal,
                'grid__tile__wrapper' : layoutPanels.grid}">
            <div
                v-show="!layoutPanels.presenterOnly"
                ref="video"
                :class="{
                    'participantsTile__video' : !layoutPanels.presenterOnly,
                    'participantsTile__video__speakerPresenter' : isPresenterTile,
                    'participantsTile__video__speakerPresenter__layout' : layoutPanels.horizontal || layoutPanels.vertical,
                    'sharing' : isSharing}"
                class="tile-video" />
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
    </div>
</template>

<script>
import {mapActions, mapGetters} from 'vuex'
import Room from "@models/Room"
import ClickOutside from "vue-click-outside"

export default {
    directives: {
        ClickOutside
    },
    props: {
        layoutPanels: Object,
        isSharing: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            active_video: false,
            options: false,
            disconected: false,
            isParticipantSubscribed: false,
            loading: false,
            loader: false,
            reattachTracks: 0,
            participant: null
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
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCurrentUserTile() {
            return this.roomMember.id === this.participant?.identity?.mid
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        isPresenterTile() {
            return this.roomInfo?.presenter_user?.id === this.participant?.identity?.mid
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
        },
        participant(val) {
          if(val) {
            this.participantLoaded()
          }
        }
    },
    mounted() {
        this.$nextTick(() => {
          this.initTracks()
        })
        if (this.layoutPanels.grid && this.$device.mobile()) this.loadingGrid()
        this.checkAndSubscribeToEvents()
        this.$eventHub.$on('tw-loadingGrid', () => {
            this.loadingGrid()
        })

        this.$eventHub.$on("tw-selfShare:disable", (track) => {
          console.log("tw-selfShare:disable")
          this.stopTrack(track)
        })
    },
    beforeDestroy() {
        let vel = document.querySelector(`#shareTile video`)
        if (vel) {
            vel.srcObject = null
            vel.remove()
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
        // ----
        classNameSet() {
            let tileClass
            tileClass = this.layoutPanels.presenterOnly ? 'presenterOnly__plug' : 'participantsTile__video'
            tileClass = this.isPresenterTile ? tileClass + ' participantsTile__video__speakerPresenter' : tileClass
            return tileClass
        },
        findParticipant() {
            if(!this.participant) return null
            let p = null
            if (this.isCurrentUserTile) {
                p = this.room.localParticipant
            } else {
                this.room?.participants.forEach(participant => {
                    let identity = JSON.parse(participant.identity)
                    if (identity.mid === this.participant?.id) {
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
            if(!participant) return

            participant.on('trackPublished', track => {
                this.reattachTracks = 0
                if (track.trackName !== "share") return
                if (this.isCurrentUserTile && track.trackName === "share") {
                    setTimeout(() => {
                        this.initTrack(track, true)
                    }, 1000)
                } else if (track.trackName === "share") {
                    setTimeout(() => {
                        this.initTrack(track)
                    }, 1000)
                }
            })
            participant.on('trackUnpublished', track => {
                if (track.trackName !== "share") return
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
            this.room.localParticipant.videoTracks.forEach(track => {
                if (track.trackName === "share") {
                    this.initTrack(track)
                }
            })
        },
        /**
         * @argument t Track
         * @argument onlySubscribe Don't init, just subscribe
         */
        initTrack(t, onlySubscribe = false) {
            let track = t.track ? t.track : t

            if (track.name !== "share") return
            if (!onlySubscribe) onlySubscribe = this.pinned && track.kind === "audio"

            if (!onlySubscribe) {
                let el = document.querySelector(`#shareTile ${track.kind}`)

                if (el) { // remove if excists
                    el.srcObject = null
                    el.remove()
                }

                let div = document.querySelector(`#shareTile .tile-${track.kind}`)
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
                if (identity.mid === this.participant?.id) {
                    founded = true
                }
            })
            if (JSON.parse(this.room.localParticipant.identity).mid === this.participant?.id) {
                founded = true
            }

            this.disconected = !founded
        },
        checkVideoTiles() {
            let participant = this.findParticipant()
            participant.videoTracks.forEach(track => {
                let isEnabled = track.track.isEnabled
                let vel = document.querySelector(`#shareTile video`)
                if (isEnabled && !vel) {
                    this.initTrack(track)
                }
            })
        }
    },
}
</script>
