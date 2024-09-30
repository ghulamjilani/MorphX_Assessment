<template>
    <div class="webRTC">
        <view-new-messages
            :room-info="roomInfo"
            :style="sideBar ? `right: ${widthSideBar}rem` : ''" />
        <notification :room-info="roomInfo" />
        <header-client
            :info="roomInfo"
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
        <div class="webRTC__client">
            <div class="webRTC__main">
                <div class="webRTC__video__wrapper">
                    <video
                        id="publisher-video"
                        autoplay
                        class="webRTC__video"
                        muted
                        playsinline />
                </div>
                <div
                    v-if="!live && started"
                    :style="sideBar && !$device.mobile() ? `width: calc(100% - ${widthSideBar}rem)` : ''"
                    class="cm__goLive__wrapper webRTC__goLive">
                    <div class="webRTC__goLive__left" />
                    <div class="webRTC__goLive__center">
                        <m-btn
                            :disabled="connectingToFfmpegservice"
                            :loading="connectingToFfmpegservice"
                            class="cm__goLive"
                            size="l"
                            type="save"
                            @click="startAll">
                            GO LIVE
                        </m-btn>
                        <div class="webRTC__goLive__text">
                            {{ !connectingToFfmpegservice ? `You can click the start button to begin your session. After the preparation is finished.` : `The session is being prepared, and it will start as soon as we are ready.` }}
                        </div>
                    </div>
                    <div class="webRTC__goLive__right" />
                </div>
            </div>
            <side-bar-section
                :room-info="roomInfo"
                :web-r-t-c="true"
                class="webRTC__cs" />
        </div>
        <tools
            :room-info="roomInfo"
            :style="sideBar && !$device.mobile() ? `width: calc(100% - ${widthSideBar}rem)` : ''"
            class="webRTC__tools" />
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

window.FfmpegserviceWebRTCPublish = FfmpegserviceWebRTCPublish

export default {
    components: {
        Tools,
        HeaderClient,
        SideBarSection,
        ViewNewMessages,
        HeaderExitModal,
        WebrtcFirefox,
        Notification
    },
    props: {
        roomInfo: Object
    },
    data() {
        return {
            // roomInfo: null,
            roomStatus: "not started",
            // ffmpegservice
            privateRoomChannel: null,
            publishing: false,
            pendingPublish: false,
            pendingPublishTimeout: undefined,
            muted: false,
            video: true,
            selectedCam: 'default',
            selectedMic: 'default',
            settings: {
                sdpURL: null,
                applicationName: null,
                streamName: null,
                audioBitrate: "64",
                audioCodec: "opus",
                videoBitrate: "3500",
                videoCodec: "42e01f",
                videoFrameRate: "30",
                frameSize: "default"
            },
            ffmpegserviceState: {},
            connectingToFfmpegservice: false,
            exit: false,
            started: false,
            share: false,
            sideBar: false,
            widthSideBar: 40,
            isFirefox: false,
            lastDeviceId: null,
            usageInterval: null,
            ffmpegserviceId: null,
            ffmpegserviceCanStart: null,
            intervalCheckingStatus: null,
            firstStart: true
        }
    },
    computed: {
        live() {
            return this.ffmpegserviceState.connectionState == 'connected' && this.roomStatus == 'started'
        },
        roomStarted() {
            return this.roomStatus == 'started'
        },
        ffmpegserviceConnected() {
            return this.ffmpegserviceState.connectionState == 'connected'
        },
        audioId() {
            return this.ffmpegserviceState.constraints?.audio?.deviceId
        },
        videoId() {
            return this.ffmpegserviceState.constraints?.video?.deviceId
        }
    },
    watch: {
        roomInfo: {
            handler(val) {
                if (val) {
                    this.$nextTick(() => {
                        if (this.roomInfo.abstract_session.autostart && !this.started) {
                            let diff = moment(this.roomInfo.abstract_session.start_at).tz("Europe/London").subtract(2, 'minutes').valueOf() - moment().tz("Europe/London").valueOf()
                            setTimeout(() => {
                                this.$eventHub.$emit('flash-client', 'Attention! Viewers will be able to see your camera stream 2 minutes before your session going live.', 'warning', 2000 * 60)
                            }, diff)
                        }
                    })
                }
            },
            immediate: true
        },
        audioId: {
            handler(val) {
                if (val) {
                    this.$eventHub.$emit("webRTC-setMicrophone", val)
                }
            },
            deep: true
        },
        videoId: {
            handler(val) {
                if (val) {
                    this.$eventHub.$emit("webRTC-setCamera", val)
                }
            },
            deep: true
        },
        started: {
            handler(val) {
                if (val && this.roomInfo.abstract_session.autostart) {
                    // this.startAll()
                }
            },
            deep: true
        }
    },
    mounted() {

        if (navigator.userAgent.includes("Firefox")) {
            this.isFirefox = true
        }

        this.checkStarted()
        this.privateRoomChannel = initPrivateLivestreamRoomsChannel(this.roomInfo.id)

        this.initFormAndSettings()
        this.init()
        this.setSessionInfo()

        // if (this.started && this.roomInfo.abstract_session.autostart) {
        //     this.startAll()
        // }
        this.privateRoomChannel.bind(privateLivestreamRoomsChannelEvents.livestreamDown, (data) => {
            if (data.transcoder_status == 'started' && this.started && this.roomInfo.abstract_session.autostart) {
                this.startAll()
            }
        })
        this.$eventHub.$on('webRTC-exit', () => {
            this.exit = true
        })
        this.$eventHub.$on('webRTC-toggleShare', (share) => {
            this.share = share
            this.toggleShare()
        })
        this.$eventHub.$on('webRTC-toggleVideoMute', () => {
            this.toggleVideoMute()
        })
        this.$eventHub.$on('webRTC-toggleAudioMute', () => {
            this.toggleAudioMute()
        })
        this.$eventHub.$on('webRTC-CameraChanged', (id) => {
            this.onAvMenuCameraChanged(id)
        })
        this.$eventHub.$on('webRTC-MicrophoneChanged', (id) => {
            this.onAvMenuMicrophoneChanged(id)
        })
        this.$eventHub.$on('webRTC-cancelShare', () => {
            this.$eventHub.$emit('webRTC-toggleShareTools', false)
        })
        this.$eventHub.$on('webRTC-sideBar', (value) => {
            this.sideBar = value
        })
        this.$eventHub.$on("webRTC-toggleChat", (flag) => {
            this.sideBar = flag
        })
        setTimeout(() => {
            this.$eventHub.$emit("tw-createChat")
        }, 1000)

        setTimeout(() => {
            console.log("*** select correct microphone")
            navigator.mediaDevices.enumerateDevices().then((e) => {
                let dId = e.filter(e => e.kind === 'audioinput' && e.deviceId !== "" && e.deviceId !== "default")[0]?.deviceId
                if (dId) this.$eventHub.$emit("webRTC-MicrophoneChanged", dId)
            })
        }, 5000)
    },
    methods: {
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
        // bug with websocket connection error
        checkConnectingToFfmpegserviceWebsocket() {
            if(!this.intervalCheckingStatus) {
                this.intervalCheckingStatus = setInterval(() => {
                    if (FfmpegserviceWebRTCPublish.getState().connectionState == 'stopped') {
                        console.log("try ConnectingToFfmpegserviceWebsocket")
                        // this.stop()
                        setTimeout(() => {
                            this.start()
                        }, 1000)
                    }
                }, 4000)
            }
        },
        startAll() {
            this.connectingToFfmpegservice = true
            if (!this.ffmpegserviceConnected) this.start()
            if (!this.roomStarted) this.startRoom()
            this.checkConnectingToFfmpegserviceWebsocket()
            // setTimeout(() => {
            //     if (!this.ffmpegserviceConnected) {
            //         console.log("*** try to reconnect device")
            //         navigator.mediaDevices.enumerateDevices().then((e) => {
            //             let dId = e.filter(e => e.kind === 'videoinput' && e.deviceId !== "" && e.deviceId !== "default")[0]?.deviceId
            //             if (dId) this.$eventHub.$emit("webRTC-CameraChanged", dId)
            //             // this.stop()
            //             setTimeout(() => {
            //                 this.start()
            //             }, 500)
            //         })
            //     }
            // }, 5000)
        },
        toggleVideoMute() {
            if (FfmpegserviceWebRTCPublish.getState().videoEnabled) {
                this.videoOff()
            } else {
                this.videoOn()
            }
        },
        toggleAudioMute() {
            if (FfmpegserviceWebRTCPublish.getState().audioEnabled) {
                this.audioOff()
            } else {
                this.audioOn()
            }
        },
        toggleShare() {
            if (this.share) {
                this.lastDeviceId = this.videoId
                FfmpegserviceWebRTCPublish.setCamera('screen')
            } else {
                FfmpegserviceWebRTCPublish.setCamera(this.lastDeviceId ? this.lastDeviceId : this.videoId)
            }
        },
        startRoom() {
            Room.api().activateRoom({id: this.roomInfo.id}).then((res) => {
                this.roomStatus = "started"
                this.$store.dispatch("VideoClient/setRoomInfo", res.response.data.response.room)
                this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                this.$eventHub.$emit("tw-roomInfoLoaded", res.response.data.response.room)
            }).catch((error) => {
                if (error.response.data.message == "Validation failed: Session has already started") this.roomStatus = "started"
                Room.api().getRoom({id: this.roomInfo.id}).then((res) => {
                    this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                    this.$eventHub.$emit("tw-roomInfoLoaded", res.response.data.response.room)
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
        },
        init() {
            FfmpegserviceWebRTCPublish.on({
                onStateChanged: (newState) => {
                    console.log("FfmpegserviceWebRTCPublish.onStateChanged")
                    console.log(JSON.stringify(newState), newState)
                    this.ffmpegserviceState = newState
                    // LIVE / ERROR Indicator
                    if (newState.connectionState === 'connected') {
                        this.onPublishPeerConnected()
                        this.connectingToFfmpegservice = false
                        console.log("ffmpegservice onStateChanged", "+ onPublishPeerConnected");
                    } else if (newState.connectionState === 'failed') {
                        this.onPublishPeerConnectionFailed()
                        this.connectingToFfmpegservice = false
                        console.log("ffmpegservice onStateChanged", "- onPublishPeerConnectionFailed");
                    } else {
                        this.onPublishPeerConnectionStopped()
                        // this.connectingToFfmpegservice = false
                        // console.log("ffmpegservice onStateChanged", "-- onPublishPeerConnectionStopped");
                    }
                },
                onCameraChanged: (cameraId) => {
                    if (cameraId !== this.selectedCam) {
                        this.selectedCam = cameraId
                        let camSelectValue = 'CameraMobile_' + cameraId
                        if (cameraId === 'screen') camSelectValue = 'screen_screen'
                        // $('#camera-list-select').val(camSelectValue);
                    }
                },
                onMicrophoneChanged: (microphoneId) => {
                    if (microphoneId !== this.selectedMic) {
                        this.selectedMic = microphoneId
                        // $('#mic-list-select').val('MicrophoneMobile_'+microphoneId);
                    }
                }
                // onError: errorHandler,
                // onSoundMeter: soundMeter
            })
            FfmpegserviceWebRTCPublish.set({
                videoElementPublish: document.getElementById('publisher-video')
                // useSoundMeter:true
            })
                .then((result) => {
                    // AvMenu.init(result.cameras,result.microphones, onAvMenuCameraChanged, onAvMenuMicrophoneChanged);
                })
        },
        okToStart() {
            if (this.settings.sdpURL === "") {
                throw "No stream configured."
            } else if (this.settings.applicationName === "") {
                throw "Missing application name."
            } else if (this.settings.streamName === "") {
                throw "Missing stream name."
            }

            if(this.firstStart) return true
            if(!this.ffmpegserviceCanStart) return false

            return true
        },
        updateFrameSize(frameSize) {
            let constraints = JSON.parse(JSON.stringify(FfmpegserviceWebRTCPublish.getState().constraints))
            if (frameSize === 'default') {
                constraints.video["width"] = {min: "640", ideal: "1280", max: "1920"}
                constraints.video["height"] = {min: "360", ideal: "720", max: "1080"}
            } else {
                constraints.video["width"] = {exact: frameSize[0]}
                constraints.video["height"] = {exact: frameSize[1]}
            }
            FfmpegserviceWebRTCPublish.set({constraints: constraints})
        },
        update(settings) {
            this.settings = settings
            return FfmpegserviceWebRTCPublish.set(settings)
        },
        start() {
            this.checkFfmpegserviceStatus().then(() => {
                if (this.okToStart()) {
                    FfmpegserviceWebRTCPublish.start()
                    this.firstStart = false
                }
            })
        },
        stop() {
            FfmpegserviceWebRTCPublish.stop()
        },
        videoOn() {
            FfmpegserviceWebRTCPublish.setVideoEnabled(true)
        },
        videoOff() {
            FfmpegserviceWebRTCPublish.setVideoEnabled(false)
        },
        audioOn() {
            FfmpegserviceWebRTCPublish.setAudioEnabled(true)
        },
        audioOff() {
            FfmpegserviceWebRTCPublish.setAudioEnabled(false)
        },

        // Helpers

        setPendingPublish(pending) {
            if (pending) {
                this.pendingPublish = true
                this.pendingPublishTimeout = setTimeout(() => {
                    this.stop()
                    console.log({message: "Publish failed. Unable to connect."})
                    this.setPendingPublish(false)
                }, 10000)
            } else {
                this.pendingPublish = false
                if (this.pendingPublishTimeout != null) {
                    clearTimeout(this.pendingPublishTimeout)
                    this.pendingPublishTimeout = undefined
                }
            }
        },
        // updatePublisher() {
        //     // let publishSettings = Settings.mapFromForm(Settings.serializeArrayFormValues($( "#publish-settings-form" )));
        //     Settings.saveToCookie(publishSettings)
        //     return update(publishSettings)
        // },
        usageInit() {
            this.createdTime = new Date().getTime();
            // this.usageInterval = setInterval(() => {
            //     window.sendWebrtcUsage({
            //         model_id: this.roomInfo?.abstract_session?.id,
            //         channel_id: this.roomInfo?.channel?.id,
            //         organization_id: this.roomInfo?.channel?.organization_id,
            //         event_type: "LIVESTREAM_TIME",
            //         event_value: (new Date().getTime() - this.createdTime) / 1000
            //     })
            // }, 20*1000)
        },
        usageStop() {
            clearInterval(this.usageInterval);
            this.usageInterval = null;
        },
        // updatePublisher() {
        //     // let publishSettings = Settings.mapFromForm(Settings.serializeArrayFormValues($( "#publish-settings-form" )));
        //     Settings.saveToCookie(publishSettings);
        //     return update(publishSettings);
        // },

        // Updaters
        onAvMenuCameraChanged(cameraId) {
            if (this.selectedCam !== cameraId) {
                this.selectedCam = cameraId
                FfmpegserviceWebRTCPublish.setCamera(cameraId)
            }
        },
        onAvMenuMicrophoneChanged(microphoneId) {
            if (this.selectedMic !== microphoneId) {
                this.selectedMic = microphoneId
                FfmpegserviceWebRTCPublish.setMicrophone(microphoneId)
            }
        },
        onPublishPeerConnected() {
            this.publishing = true
            this.setPendingPublish(false)
        },
        onPublishPeerConnectionFailed() {
            this.setPendingPublish(false)
            this.onPublishPeerConnected()
        },
        onPublishPeerConnectionStopped() {
            if (!this.pendingPublish) {
                this.publishing = false
            }
        },

        // Init settings
        initFormAndSettings() {
            // let pageParams = Settings.mapFromCookie(this.settings);
            // pageParams = Settings.mapFromQueryParams(pageParams);
            // Settings.updateForm(pageParams);
            // if (pageParams.frameSize != null && pageParams.frameSize !== '' && pageParams.frameSize !== 'default')
            // {
            //   this.updateFrameSize(pageParams.frameSize.split('x'));
            // }
            // if (browserDetails.browser === 'safari')
            // {
            //   // $("#videoCodec option[value='VP9']").remove();
            // }
        },
        setSessionInfo() {
            this.settings.applicationName = this.roomInfo.ffmpegservice_account.application_name
            this.settings.sdpUrl = this.roomInfo.ffmpegservice_account.sdp_url
            this.settings.streamName = this.roomInfo.ffmpegservice_account.stream_name
            this.ffmpegserviceId = this.roomInfo.ffmpegservice_account.id
            FfmpegserviceWebRTCPublish.getState().streamInfo.applicationName = this.settings.applicationName
            FfmpegserviceWebRTCPublish.getState().sdpURL = this.settings.sdpUrl
            FfmpegserviceWebRTCPublish.getState().streamInfo.streamName = this.settings.streamName
        },
        checkFfmpegserviceStatus() {
            return new Promise((resolve) => {
                if(this.ffmpegserviceCanStart || this.firstStart) {
                    resolve()
                    return
                }
                Room.api().getFfmpegserviceStatus({id: this.ffmpegserviceId}).then(res => {
                    this.ffmpegserviceCanStart = res.response.data.message == "started"
                    resolve()
                })
            })
        }
    }
}
</script>