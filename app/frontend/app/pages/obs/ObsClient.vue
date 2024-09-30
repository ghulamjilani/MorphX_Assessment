<template>
    <div class="webRTC">
        <view-new-messages
            :room-info="roomInfo"
            :style="sideBar ? `right: ${widthSideBar}rem` : ''" />
        <notification :room-info="roomInfo" />
        <header-client
            :info="roomInfo"
            :rtmp="true"
            :web-r-t-c="true"
            :web-r-t-c-live="live" />
        <header-exit-modal
            :exit="exit"
            :room-info="roomInfo"
            @close="exit = false" />
        <div
            v-if="exit"
            class="channelFilters__icons__options__cover client__header__cover"
            @click="exit = false" />
        <div class="webRTC__client IpCam__client">
            <div class="webRTC__main">
                <div
                    v-show="live || ffmpegservice_started && inboundConnection"
                    id="publisher-video"
                    ref="theoplayer"
                    :style="!live && !autostart ? `height: calc(100% - 10rem);` : ''"
                    class="IpCam__video" />
                <div
                    v-show="!ffmpegservice_started || !inboundConnection"
                    :style="!live && !autostart ? `height: calc(100% - 17rem);` : ''"
                    class="IpCam__wait">
                    <div
                        v-if="!ffmpegservice_started && !loading"
                        class="IpCam__wait__title">
                        Streaming server is starting the live stream. This may take a few minutes. Thank you for your
                        patience.
                    </div>
                    <div
                        v-else-if="!inboundConnection && !loading"
                        class="IpCam__wait__title">
                        The streaming server is started. Waiting for inbound connection. You may start streaming now.
                    </div>
                    <div class="IpCam__wait__loader">
                        <m-loader :dark="true" />
                    </div>
                </div>
                <div
                    v-if="!live && !autostart"
                    :style="sideBar && !$device.mobile() ? `width: calc(100% - ${widthSideBar}rem)` : ''"
                    class="IpCam__golive">
                    <div />
                    <m-btn
                        :disabled="!started || !ffmpegservice_started"
                        :loading="loading"
                        class="cm__goLive"
                        size="l"
                        type="save"
                        @click="startRoom()">
                        GO LIVE
                    </m-btn>
                </div>
            </div>
            <side-bar-section
                :ip_cam_or_rtmp="true"
                :room-info="roomInfo"
                :web-r-t-c="true"
                class="IpCam__cs" />
        </div>
        <tools
            :room-info="roomInfo"
            :rtmp="true"
            :style="sideBar && !$device.mobile() ? `width: calc(100% - ${widthSideBar}rem)` : ''"
            class="webRTC__tools IpCam__tools" />
        <webrtc-firefox :active="isFirefox" />
    </div>
</template>

<script>
import FfmpegserviceWebRTCPublish from "../../assets/js/ffmpegservice/FfmpegserviceWebRTCPublish"

import Room from "@models/Room"
import Tools from '@components/web-rtc/Tools.vue'
import SideBarSection from '@components/video-client/SideBarSection.vue'

import HeaderExitModal from '../video-client/HeaderExitModal'
import HeaderClient from '../video-client/HeaderClient.vue'
import ViewNewMessages from '@components/video-client/chat/ViewNewMessages.vue'
import WebrtcFirefox from '@components/modals/WebrtcFirefox.vue'

import Notification from '@components/video-client/chat/Notification.vue'
import MLoader from '../../uikit/MLoader.vue'

import "../../../../assets/javascripts/theoplayer/bind_ui_buttons"
import "../../../../assets/javascripts/theoplayer/event_logs"
import "../../../../assets/javascripts/theoplayer/theoplayer"

window.FfmpegserviceWebRTCPublish = FfmpegserviceWebRTCPublish

export default {
    components: {
        Tools,
        HeaderClient,
        SideBarSection,
        ViewNewMessages,
        HeaderExitModal,
        WebrtcFirefox,
        Notification,
        MLoader
    },
    props: {
        roomInfo: Object
    },
    data() {
        return {
            roomStatus: "not started",
            loading: false,
            exit: false,
            started: false,
            share: false,
            sideBar: false,
            widthSideBar: 40,
            isFirefox: false,
            ffmpegservice_started: false,
            loading: true,
            flash: false
        }
    },
    computed: {
        inboundConnection() {
            return this.roomInfo.ffmpegservice_account.stream_status == 'up'
        },
        live() {
            return this.roomInfo.ffmpegservice_account.stream_status == 'up' && this.status
        },
        roomStarted() {
            return this.roomStatus == 'started'
        },
        autostart() {
            return this.roomInfo.abstract_session.autostart
        },
        status() {
            return this.roomInfo.status == 'active'
        }
    },
    watch: {
        started: {
            handler(val) {
                if (val && this.roomInfo.abstract_session.autostart) {
                    this.startRoom()
                }
            },
            deep: true
        },
        roomInfo: {
            handler(val) {
                if (val) {
                    if (this.roomInfo.ffmpegservice_account.stream_status == "up") {
                        this.ffmpegservice_started = true
                    }
                    this.$nextTick(() => {
                        if (!this.started && !this.flash) {
                            this.flash = true
                            let diff = moment(this.roomInfo.abstract_session.start_at).tz("Europe/London").subtract(2, 'minutes').valueOf() - moment().tz("Europe/London").valueOf()
                            setTimeout(() => {
                                this.$flash('Attention! Viewers will be able to see your camera stream 2 minutes before your session going live.', 'warning', 2000 * 60)
                            }, diff)
                        }
                    })
                }
            },
            deep: true
        }
    },
    mounted() {
        this.checkStarted()
        if (this.live) {
            this.ffmpegservice_started = true
            this.loading = false
            if (!document.querySelector('.video-js')) {
                this.$nextTick(() => {
                    initTheOplayer(this.roomInfo.ffmpegservice_account.hls_url, '#publisher-video', {})
                    this.customPowered()
                })
            }
        }
        this.$eventHub.$on(sessionsChannelEvents.livestreamUp, () => {
            this.loading = false
            this.roomInfo.ffmpegservice_account.stream_status = 'up'
            this.ffmpegservice_started = true
            if (!this.live && this.autostart && !document.querySelector('.video-js')) this.startRoom()
        })
        this.$eventHub.$on(sessionsChannelEvents.livestreamDown, (data) => {
            this.loading = false
            if (data.transcoder_status == "started") {
                this.ffmpegservice_started = true
                if (!document.querySelector('.video-js')) {
                    this.$nextTick(() => {
                        initTheOplayer(this.roomInfo.ffmpegservice_account.hls_url, '#publisher-video', {})
                        this.customPowered()
                    })
                }
            } else {
                this.roomInfo.ffmpegservice_account.stream_status = 'off'
            }
        })
        this.$eventHub.$on('webRTC-exit', () => {
            this.exit = true
        })
        this.$eventHub.$on('webRTC-sideBar', (flag) => {
            this.sideBar = flag
        })
    },
    methods: {
        customPowered() {
            let contextMenuLink = document.querySelector('.theo-context-menu-a')
            if (!contextMenuLink) return
            contextMenuLink.style.backgroundImage = 'url(' + this.$img['favicon_morphx'] + ')'
            contextMenuLink.href = this.$railsConfig?.global?.host
            contextMenuLink.innerHTML = this.$t('assets.javascripts.powered')
        },
        checkStarted() {
            let diff = moment(this.roomInfo.abstract_session.start_at).tz("Europe/London").valueOf() - moment().tz("Europe/London").valueOf()
            if (diff <= 0) {
                this.started = true
            } else {
                setTimeout(() => {
                    this.started = true
                }, diff)
            }
        },
        startRoom() {
            this.loading = true
            Room.api().activateRoom({id: this.roomInfo.id}).then((res) => {
                this.roomStatus = "started"
                this.$store.dispatch("VideoClient/setRoomInfo", res.response.data.response.room)
                this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                if (!document.querySelector('.video-js')) {
                    initTheOplayer(this.roomInfo.ffmpegservice_account.hls_url, '#publisher-video', {})
                    this.$nextTick(() => {
                        this.customPowered()
                    })
                }
                this.loading = false
            }).catch((error) => {
                if (error.response?.data.message == "Validation failed: Session has already started") this.roomStatus = "started"
                Room.api().getRoom({id: this.roomInfo.id}).then((res) => {
                    this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                    this.$eventHub.$emit("tw-roomInfoLoaded", res.response.data.response.room)
                    if (!document.querySelector('.video-js')) {
                        initTheOplayer(this.roomInfo.ffmpegservice_account.hls_url, '#publisher-video', {})
                        this.$nextTick(() => {
                            this.customPowered()
                        })
                    }
                    this.loading = false
                })
            })
        },
        stopRoom() {
            Room.api().closeRoom({id: this.roomInfo.id}).then(res => {
                this.roomStatus = "stopped"
                // this.close()
            }).catch(error => {
                // this.$flash(error.response)
            })
        }
    }
}
</script>