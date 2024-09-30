<template>
    <div>
        <m-flash-message
            ref="flash"
            :block-message="true" />
        <div
            v-show="roomInfo || room"
            :class="{'client__header__selfView' : selfView}"
            class="client__header">
            <div class="client__header__status">
                <div class="client__header__status__label">
                    <m-btn
                        v-if="checkLive"
                        class="client__header__status__label__live"
                        square>
                        LIVE
                    </m-btn>
                    <m-btn
                        v-else
                        class="client__header__status__label__offline"
                        square>
                        OFFLINE
                    </m-btn>
                </div>
                <div class="client__header__recording">
                    <m-icon
                        v-if="roomInfo && roomInfo.status === 'active' && roomInfo.abstract_session.record"
                        v-tooltip="recording ? 'Recording' : 'Not recording'"
                        :class="{'client__header__recording__icon__active': recording}"
                        class="client__header__recording__icon"
                        size="0">
                        GlobalIcon-recording
                    </m-icon>
                </div>
                <div
                    v-if="roomInfo"
                    :class="{
                        'client__header__status__time__10': minutes10,
                        'client__header__status__time__1': minutes1,
                    }"
                    class="client__header__status__time">
                    {{ greenRoom ? "-" : '' }}{{ millsFromStart | dateTimeWithZeros(false) }} / {{
                        (roomInfo.abstract_session.duration * 60 * 1000) + 1 | dateTimeWithZeros(false)
                    }}
                </div>
                <div
                    v-if="isPresenter"
                    class="client__header__status__addTime_tooltip"
                    v-tooltip="
                        canIncreaseDuration ?
                            'Extend session time by '+ sessionDuration.change_by +' minutes' :
                            'Time extension not available for this session'">
                    <m-btn
                        class="client__header__status__addTime"
                        :disabled="!canIncreaseDuration"
                        @click="addDuration">
                        +{{ sessionDuration.change_by }}min
                    </m-btn>
                </div>
            </div>
            <div
                v-if="roomInfo && roomInfo.abstract_session"
                class="client__header__info">
                <div
                    v-if="roomInfo"
                    class="client__header__info__title">
                    {{ roomInfo.abstract_session.always_present_title }}
                </div>
            </div>
            <div
                v-if="!webRTC"
                v-click-outside="closeInfoPanel"
                @mouseleave="closeInfoPanel">
                <settings
                    v-if="RTMPSettings"
                    :ffmpegservice_account="info.ffmpegservice_account" />
                <div
                    v-if="roomInfo && roomInfo.abstract_session"
                    v-show="infoPanel"
                    class="client__header__info__panel">
                    <m-icon
                        class="client__header__info__panel__icon"
                        @click="closeInfoPanel">
                        GlobalIcon-clear
                    </m-icon>
                    <div class="client__header__info__panel__info">
                        Session info
                    </div>
                    <div
                        v-if="joinLink"
                        class="client__header__info__panel__title">
                        {{ $t("frontend.app.pages.video_client.header_client.join_link") }}
                    </div>
                    <div
                        v-if="joinLink"
                        class="client__header__info__panel__block">
                        <div class="client__header__info__panel__link">
                            {{ joinLink.absolute_url }}
                        </div>
                        <m-btn
                            :type="'tetriary'"
                            class="client__header__info__panel__button"
                            @click="copy(joinLink.absolute_url)">
                            Copy
                        </m-btn>
                    </div>
                    <div
                        v-if="guestLink"
                        class="client__header__info__panel__title">
                        {{ $t("frontend.app.pages.video_client.header_client.guest_link") }}
                    </div>
                    <div
                        v-if="guestLink"
                        class="client__header__info__panel__block">
                        <div class="client__header__info__panel__link">
                            {{ guestLink.absolute_url }}
                        </div>
                        <m-btn
                            :type="'tetriary'"
                            class="client__header__info__panel__button"
                            @click="copy(guestLink.absolute_url)">
                            Copy
                        </m-btn>
                    </div>
                    <div class="client__header__info__panel__title">
                        Session page
                    </div>
                    <div class="client__header__info__panel__block">
                        <div class="client__header__info__panel__link">
                            {{ relativePath() }}
                        </div>
                        <div class="webRTC__header__buttons">
                            <m-btn
                                :type="'tetriary'"
                                class="client__header__info__panel__button"
                                @click="goTo(relativePath(), true)">
                                Go to
                            </m-btn>
                            <m-btn
                                :type="'tetriary'"
                                class="client__header__info__panel__button"
                                @click="copy(relativePath())">
                                Copy
                            </m-btn>
                        </div>
                    </div>
                </div>
                <div class="client__header__info__wrapper">
                    <div
                        v-if="room"
                        :class="'internet__count__' + room.localParticipant.networkQualityLevel"
                        class="internet__count ">
                        <div />
                        <div />
                        <div />
                        <div />
                        <div />
                    </div>
                    <m-icon
                        v-if="rtmp"
                        :class="{'RTMP__settings__icon__active': RTMPSettings}"
                        :name="'GlobalIcon-settings'"
                        class="RTMP__settings__icon"
                        size="0"
                        @click="toggleRTMPSettings" />
                    <m-icon
                        v-if="$device.mobile()"
                        class="client__header__info__icon"
                        size="0"
                        @click="toggleInfoPanel">
                        GlobalIcon-info
                    </m-icon>
                    <m-icon
                        v-else
                        class="client__header__info__icon"
                        size="0"
                        @mouseover="infoPanel = true">
                        GlobalIcon-info
                    </m-icon>
                </div>
            </div>
            <div
                v-else
                v-click-outside="closeInfoPanel"
                @mouseleave="closeInfoPanel">
                <settings
                    v-if="RTMPSettings"
                    :ffmpegservice_account="info.ffmpegservice_account" />
                <div
                    v-if="roomInfo && roomInfo.abstract_session"
                    v-show="infoPanel"
                    class="client__header__info__panel">
                    <m-icon
                        class="client__header__info__panel__icon"
                        @click="closeInfoPanel">
                        GlobalIcon-clear
                    </m-icon>
                    <div class="client__header__info__panel__info">
                        Session info
                    </div>
                    <div class="client__header__info__panel__title">
                        Session page
                    </div>
                    <div class="client__header__info__panel__block">
                        <div class="client__header__info__panel__link">
                            {{ relativePath() }}
                        </div>
                        <div class="webRTC__header__buttons">
                            <m-btn
                                :type="'tetriary'"
                                class="client__header__info__panel__button"
                                @click="goTo(relativePath(), true)">
                                Go to
                            </m-btn>
                            <m-btn
                                :type="'tetriary'"
                                class="client__header__info__panel__button"
                                @click="copy(relativePath())">
                                Copy
                            </m-btn>
                        </div>
                    </div>
                </div>
                <div class="client__header__info__wrapper">
                    <m-icon
                        v-if="rtmp"
                        :class="{'RTMP__settings__icon__active': RTMPSettings}"
                        :name="'GlobalIcon-settings'"
                        class="RTMP__settings__icon"
                        size="0"
                        @click="toggleRTMPSettings" />
                    <m-icon
                        v-if="$device.mobile()"
                        class="client__header__info__icon"
                        size="0"
                        @click="toggleInfoPanel">
                        GlobalIcon-info
                    </m-icon>
                    <m-icon
                        v-else
                        class="client__header__info__icon"
                        size="0"
                        @mouseover="infoPanel = true">
                        GlobalIcon-info
                    </m-icon>
                </div>
            </div>
        </div>
        <header-exit-modal
            :exit="exit"
            :room-info="roomInfo"
            @close="exit = false" />
        <div
            v-if="exit"
            class="channelFilters__icons__options__cover client__header__cover"
            @click="exit = false" />
    </div>
</template>

<script>
import HeaderExitModal from './HeaderExitModal'
import ClickOutside from "vue-click-outside"
import Settings from '../../pages/obs/Settings.vue'
import MFlashMessage from '@uikit/MFlashMessage.vue'

import Room from '@models/Room'
import Vue from 'vue/dist/vue.esm'

export default {
    components: {HeaderExitModal, Settings, MFlashMessage},
    directives: {
        ClickOutside
    },
    props: {
        webRTC: {
            type: Boolean,
            default: false
        },
        webRTCLive: {
            type: Boolean,
            default: false
        },
        rtmp: {
            type: Boolean,
            default: false
        },
        info: Object
    },
    data() {
        return {
            roomInfo: null,
            exit: false,
            recording: true,
            millsFromStart: 0,
            infoPanel: false,
            greenRoom: false,
            minutes10: false,
            minutes1: false,
            selfView: false,
            RTMPSettings: false,
            sessionDuration: {
                change_by: 10,
                duration_change_times_left: 3,
                duration_available_max: 180
            }
        }
    },
    computed: {
        room() {
            return this.$store.getters["VideoClient/room"]
        },
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        joinLink() {
            return this.roomInfo?.interactive_access_tokens?.find(e => !e.guests)
        },
        guestLink() {
            return this.roomInfo?.interactive_access_tokens?.find(e => e.guests)
        },
        checkLive() {
            if (this.webRTC) {
                return this.webRTCLive
            } else {
                return this.roomInfo && this.roomInfo.status === 'active'
            }
        },
        canIncreaseDuration() {
            if (this.sessionDuration.duration_change_times_left == 0) {
                return false
            }

            return this.roomInfo?.abstract_session?.duration && ((this.sessionDuration.duration_available_max - this.roomInfo.abstract_session.duration) >= this.sessionDuration.change_by)
        }
    },
    watch: {
        roomInfo(val){
            if(val) {
                this.checkDurations()
            }
        }
    },
    mounted() {
        let flash = this.$refs["flash"].flash

        window.hcflash = this.$refs["flash"].flash
        Vue.prototype.$hcflash = this.$refs["flash"].flash

        this.$eventHub.$on('flash-client', (text, type, time) => {
            flash(text, type, time)
        })

        this.$eventHub.$on('rtmp-closeSetting', () => {
            this.toggleRTMPSettings()
        })
        this.$eventHub.$on("tw-openSelfView", () => {
            this.selfView = true
        })
        this.$eventHub.$on("tw-closeSelfView", () => {
            this.selfView = false
        })
        if (this.webRTC && this.info) this.roomInfo = this.info
        this.$eventHub.$on('exit', () => {
            this.exit = true
        })
        this.$eventHub.$on('tw-roomInfoLoaded', (roomInfo) => {
            this.roomInfo = roomInfo
        })
        setInterval(() => {
            if (this.roomInfo) {
                if (new Date().getTime() > new Date(this.roomInfo.abstract_session.start_at).getTime()) {
                    this.greenRoom = false
                    this.millsFromStart = new Date().getTime() - new Date(this.roomInfo.abstract_session.start_at).getTime()
                    let left = this.roomInfo.abstract_session.duration - this.millsFromStart / 1000 / 60
                    if (left < 10 && left > 1 && !this.minutes10) {
                        this.minutes10 = true
                        this.$eventHub.$emit("tw-notification", `Warning! ${Math.ceil(left)} minutes left!`)
                    }
                    if (left < 1 && !this.minutes1) {
                        this.minutes1 = true
                        this.$eventHub.$emit("tw-notification", `Warning! ${Math.ceil(left)} minute left!`)
                    }
                    if(left > 10 && (this.minutes10 || this.minutes1)){
                        this.minutes10 = false
                        this.minutes1 = false
                    }
                } else {
                    this.greenRoom = true
                    setTimeout(() => {
                        this.$eventHub.$emit("chat:update-conversations")
                    }, 1000)
                    this.millsFromStart = new Date(this.roomInfo.abstract_session.start_at).getTime() - new Date().getTime()
                }
            }
        }, 500)
    },
    methods: {
        toggleRTMPSettings() {
            this.infoPanel = false
            this.RTMPSettings = !this.RTMPSettings
        },
        relativePath() {
            return location.origin + this.roomInfo.abstract_session.relative_path
        },
        copy(value) {
            this.$clipboard(value)
            this.closeInfoPanel()
            this.$hcflash("Сopied!", "success")
        },
        closeInfoPanel() {
            this.infoPanel = false
        },
        toggleInfoPanel() {
            this.RTMPSettings = false
            if (!this.isPresenter) this.infoPanel = false
            this.infoPanel = !this.infoPanel
        },
        checkDurations() {
            if (!this.isPresenter) return

            Room.api().getDurations({session_id: this.roomInfo.abstract_session.id}).then(res => {
                this.sessionDuration = res.response.data.response.session.session_duration
            })
        },
        addDuration(){
            this.sessionDuration.duration_change_times_left--

            Room.api().addDurations({session_id: this.roomInfo.abstract_session.id}).then(res => {
                if(res.response.data?.errors?.duration) {
                    this.$hcflash(res.response.data?.errors?.duration)
                }
                else {
                    this.sessionDuration = res.response.data.response.session.session_duration
                    this.roomInfo.abstract_session.duration = res.response.data.response.session.duration
                    this.$hcflash(`Session has been extended by ${this.sessionDuration.change_by} minutes. `, "success")
                }
            }).catch(error =>{
                console.log(error.response)
            })
        }
    }
}
</script>