<template>
    <m-modal
        ref="selfView"
        :backdrop="false"
        :class="{'selfView__smallHeight' : smallHeight && $device.desktop(),
                 'selfView__phone' : smallHeight && $device.mobile()}"
        class="selfView">
        <div class="selfView__wrapper">
            <div class="selfView__header">
                <div class="selfView__header__title">
                    Welcome to {{ service_name }}!
                </div>
                <div class="selfView__header__text">
                    You are to join the room with the following configuration:
                    <span>{{ alertText }}</span>
                </div>
            </div>
            <div class="selfView__video__wrapper">
                <div class="selfView__loader">
                    <m-loader :white="true" />
                </div>
                <div
                    v-if="videoTrack"
                    id="selfViewVideo"
                    class="selfView__video" />
                <div
                    v-else
                    class="selfView__video__default__wrapper">
                    <div class="selfView__video__default">
                        Please allow your browser to access your camera and microphone.
                    </div>
                </div>
                <div class="selfView__video__tools">
                    <div class="cm__tools">
                        <m-icon
                            :class="{'cm__tools__icon__active': !videoMuted && videoTrack}"
                            :name="!videoMuted && videoTrack ? 'GlobalIcon-stream-video':'GlobalIcon-video-off'"
                            class="cm__tools__icon"
                            size="0"
                            @click="toggleVideoMute" />
                    </div>
                    <div class="cm__tools">
                        <m-icon
                            :class="{'cm__tools__icon__active': !audioMuted}"
                            :name="!audioMuted && audioTrack ? 'GlobalIcon-mic':'GlobalIcon-mic-off'"
                            class="cm__tools__icon"
                            size="0"
                            @click="toggleAudioMute" />
                    </div>
                </div>
            </div>
            <div class="selfView__settings">
                <m-select
                    v-model="current.video"
                    :options="videoDeviceOptions"
                    :without-error="true"
                    class="selfView__settings__select"
                    label="Camera"
                    type="default"
                    @input="(val) => { updateDevice(val, true)}" />
                <m-select
                    v-model="current.audio"
                    :options="audioDeviceOptions"
                    :without-error="true"
                    class="selfView__settings__select"
                    label="Microphone"
                    type="default"
                    @input="(val) => { updateDevice(val, false)}" />
                <div id="selfViewAudio" />
                <div class="selfView__mic">
                    <div class="selfView__mic__header">
                        <div class="selfView__mic__title">
                            Microphone Test
                        </div>
                        <div>
                            <m-icon
                                v-show="!audioTrack"
                                class="selfView__mic__warn"
                                size="0">
                                GlobalIcon-Warning
                            </m-icon>
                            <m-icon
                                v-show="audioTrack"
                                class="selfView__mic__check"
                                size="0">
                                GlobalIcon-check-circle
                            </m-icon>
                        </div>
                    </div>
                    <div class="selfView__mic__level__wrapper">
                        <div
                            :style="{width: ((200 - level) / 2) + '%'}"
                            class="selfView__mic__level" />
                    </div>
                </div>
            </div>
        </div>
        <div class="selfView__footer">
            <!-- <m-btn v-if="videoTrack && audioTrack" @click="joinRoom()" class="selfView__footer__button">JOIN</m-btn> -->
            <m-btn
                :disabled="loading"
                class="selfView__footer__button"
                @click="joinRoom()">
                JOIN
            </m-btn>
            <!-- <m-btn v-else type="secondary" @click="allowDevices()" class="selfView__footer__button">Allow</m-btn> -->
        </div>
    </m-modal>
</template>

<script>
import {createLocalAudioTrack, createLocalVideoTrack} from "./../../assets/js/webrtcservice-video"

export default {
    props: {
        room: Object,
        roomInfo: Object
    },
    data() {
        return {
            service_name: "Morphx",
            videoMuted: false,
            audioMuted: false,
            devices: [],
            current: {
                audio: "default",
                video: "default"
            },
            videoTrack: null,
            audioTrack: null,
            level: 0,
            isClose: false,
            smallHeight: false,
            loading: true
        }
    },
    computed: {
        isPresenter() {
            return this.currentUser?.id === this.roomInfo?.presenter_user?.id
        },
        audioDeviceOptions() {
            let arr = this.devices.filter(e => e.kind === 'audioinput' && e.deviceId !== "").map(e => {
                return {
                    value: e.deviceId,
                    name: e.deviceId === "default" ? "Same as System" : e.label
                }
            })
            if (arr[0]) {
                this.current.audio = arr[0].value
            }
            return arr
        },
        videoDeviceOptions() {
            let arr = this.devices.filter(e => e.kind === 'videoinput' && e.deviceId !== "").map(e => {
                return {
                    value: e.deviceId,
                    name: e.label
                }
            })
            if (arr[0]) {
                this.current.video = arr[0].value
            }
            return arr
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        alertText() {
            if (!this.videoMuted && !this.audioMuted) {
                return ' camera and microphone turned on.'
            } else if (!this.videoMuted && this.audioMuted) {
                return ' camera turned on.'
            } else if (this.videoMuted && !this.audioMuted) {
                return ' microphone turned on.'
            } else {
                return 'camera and microphone turned off.'
            }
        }
    },
    watch: {
        roomInfo: {
            handler(val) {
                if (val && !this.isClose && !this.videoTrack & !this.audioTrack) {
                    this.createFirst()
                }
            },
            deep: true,
            immediate: true
        }
    },
    created() {
        navigator.mediaDevices.ondevicechange = (event) => {
            this.checkNewDevices()
        }
        this.$eventHub.$emit("tw-openSelfView")

        setTimeout(() => {
            this.loading = false
        }, 5000) // try to find camera/audio
    },
    mounted() {
        this.getDevices()
        this.$eventHub.$emit("tw-canCreateRoom", false)
        this.service_name = this.$railsConfig.global.service_name
        this.open()
        this.checkBrowser()
        window.addEventListener("resize", () => {
            this.checkBrowser()
        })
    },
    methods: {
        checkBrowser() {
            let windowH = document.documentElement.clientHeight
            if (windowH < 767) {
                this.smallHeight = true
            }
        },
        audioAttach(track) {
            var el = document.querySelector('#selfViewAudio')
            if (el) {
                el.innerHTML = ""
                el.appendChild(track.attach())
                this.loading = false
            } else {
                setTimeout(() => {
                    el = document.querySelector('#selfViewAudio')
                    el.innerHTML = ""
                    el.appendChild(track.attach())
                    this.loading = false
                }, 2000)
            }
        },
        videoAttach(track) {
            var el = document.querySelector('#selfViewVideo')
            if (el) {
                el.innerHTML = ""
                el.appendChild(track.attach())
                this.loading = false
            } else {
                setTimeout(() => {
                    el = document.querySelector('#selfViewVideo')
                    el.innerHTML = ""
                    el.appendChild(track.attach())
                    this.loading = false
                }, 2000)
            }
        },
        createFirst() {
            this.live = !this.isAwaiting
            createLocalVideoTrack().then((track) => {
                this.videoTrack = track
                this.getDevices()
                setTimeout(() => {
                    this.videoAttach(track)
                }, 1000)
            })
            createLocalAudioTrack().then((track) => {
                this.audioTrack = track
                setTimeout(() => {
                    this.audioAttach(track)
                }, 1000)
                this.gotStream(new MediaStream([track.mediaStreamTrack]))
            })
        },
        joinRoom() {
            this.$eventHub.$emit("tw-canCreateRoom", true)
            this.$nextTick(() => {
                let tracks = [this.audioTrack, this.videoTrack].filter(function (el) {
                    return el != null
                })
                this.$eventHub.$emit("tw-selfView-goLive", tracks)
                this.close()
            })
        },
        gotStream(stream) {
            window.AudioContext = window.AudioContext || window.webkitAudioContext
            var audioContext = new AudioContext()
            var analyser = audioContext.createAnalyser()
            var microphone = audioContext.createMediaStreamSource(stream)
            var javascriptNode = audioContext.createScriptProcessor(2048, 1, 1)

            analyser.smoothingTimeConstant = 0.3
            analyser.fftSize = 1024

            microphone.connect(analyser)
            analyser.connect(javascriptNode)
            javascriptNode.connect(audioContext.destination)
            javascriptNode.addEventListener('audioprocess', (audioEvent) => {
                var array = new Uint8Array(analyser.frequencyBinCount)
                analyser.getByteFrequencyData(array)
                var values = 0

                var length = array.length
                for (var i = 0; i < length; i++) {
                    values += array[i]
                }
                if (!this.audioMuted) {
                    this.level = values / length
                } else {
                    this.level = 0
                }
            })
        },
        toggleVideoMute() {
            if (!this.videoTrack) return
            this.videoMuted = !this.videoMuted
            if (!this.videoMuted) {
                this.videoTrack.enable()
            } else {
                this.videoTrack.disable()
            }
        },
        toggleAudioMute() {
            if (!this.audioTrack) return
            this.audioMuted = !this.audioMuted
            if (!this.audioMuted) {
                this.audioTrack.enable()
            } else {
                this.audioTrack.disable()
            }
        },
        open() {
            this.$refs.selfView.openModal()
        },
        close() {
            this.$refs.selfView.closeModal()
            this.$eventHub.$emit("tw-closeSelfView")
            this.isClose = true
        },
        allowDevices() {
            return new Promise((resolve, reject) => {
                navigator.mediaDevices.getUserMedia({video: true, audio: true})
                    .then((stream) => {
                        this.createFirst()
                        this.checkNewDevices()
                        resolve()
                    })
                    .catch((err) => {
                        console.log('No mic or video!')
                        resolve()
                    })
            })
        },
        getDevices() {
            navigator.mediaDevices.enumerateDevices().then((e) => {
                if (!e.find((d) => d.label != '')) {
                    setTimeout(() => {
                        this.getDevices()
                    }, 500)
                } else {
                    this.devices = e
                }
            })
        },
        checkNewDevices() {
            navigator.mediaDevices.enumerateDevices().then((e) => {
                // device on
                let newDevices = e.filter(d => !this.devices.find(od => od.deviceId === d.deviceId))
                this.devices = e
                newDevices.forEach(nd => {
                    this.updateDevice(nd.deviceId, nd.kind === 'videoinput')
                })
                // device off
                if (!this.devices.find(d => d.deviceId === this.current.audio)) {
                    this.updateDevice("default", false)
                }
                if (!this.devices.find(d => d.deviceId === this.current.video)) {
                    let videodevice = this.devices.find(d => d.kind === 'videoinput')
                    this.updateDevice(videodevice.deviceId, true)
                }
            })
        },
        updateDevice(deviceId, isVideo = false) {
            if (isVideo) {
                createLocalVideoTrack({deviceId: {exact: deviceId}}).then((track) => {
                    this.current.video = deviceId
                    this.videoTrack = track
                    setTimeout(() => {
                        this.videoAttach(track)
                    }, 1000)
                })
            } else {
                if (this.audioTrack) {
                    this.audioTrack.disable()
                    this.audioTrack.stop()
                }
                setTimeout(() => { // delay for unpublish audio (Firefox)
                    createLocalAudioTrack({deviceId: {exact: deviceId}}).then((track) => {
                        this.current.audio = deviceId
                        this.audioTrack = track
                        setTimeout(() => {
                            this.audioAttach(track)
                        }, 1000)
                        this.gotStream(new MediaStream([track.mediaStreamTrack]))
                    })
                }, 1000)
            }
        }
    }
}
</script>