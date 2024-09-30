<template>
    <div class="cm__tools__list">
        <!-- <div class="cm__tools__list__main">Grey filter in muted</div>
    <div
      class="cm__tools__list__available"
      :class="{'cm__tools__list__current': greyFilter}"
      @click="toggleVideoFilter">
      Grey filter
      <m-icon size="16" class="cm__tools__list__current__icon" v-if="greyFilter">GlobalIcon-check</m-icon>
    </div> -->
        <div
            v-show="micSettings || (mobile && !webRTC)"
            class="cm__tools__mobile__list__block customScroll">
            <div class="cm__tools__list__main">
                <m-icon
                    class="cm__tools__list__main__icon"
                    size="0">
                    GlobalIcon-mic
                </m-icon>
                Select a Microphone
            </div>
            <div v-show="audioDeviceOptions.length && (micSettings || mobile)">
                <div
                    v-for="device in audioDeviceOptions"
                    :key="'a-' + device.value"
                    :class="{'cm__tools__list__current': current.audio == device.value}"
                    class="cm__tools__list__available"
                    @click="updateDevice(device.value)">
                    <m-radio
                        :key="device.value"
                        v-model="current.audio"
                        :val="device.value" />
                    <div> {{ device.name }}</div>
                </div>
            </div>
        </div>

        <div
            v-show="vidSettings || (mobile && !webRTC)"
            class="cm__tools__mobile__list__block customScroll">
            <div class="cm__tools__list__main">
                <m-icon
                    class="cm__tools__list__main__icon"
                    size="0">
                    GlobalIcon-stream-video
                </m-icon>
                Select a Camera
            </div>
            <div v-show="videoDeviceOptions.length && (vidSettings || mobile)">
                <div
                    v-for="device in videoDeviceOptions"
                    :key="'v-' + device.value"
                    :class="{'cm__tools__list__current': current.video === device.value}"
                    class="cm__tools__list__available"
                    @click="updateDevice(device.value, true)">
                    <m-radio
                        :key="device.value"
                        v-model="current.video"
                        :val="device.value" />
                    <div> {{ device.name }}</div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import {createLocalAudioTrack, createLocalVideoTrack} from "./../../assets/js/webrtcservice-video"

window.createLocalVideoTrack = createLocalVideoTrack

export default {
    props: {
        settings: Boolean,
        room: Object,
        roomInfo: Object,
        webRTC: {
            type: Boolean,
            default: false
        },
        mobile: {
            type: Boolean,
            default: false
        },
        micSettings: false,
        vidSettings: false
    },
    data() {
        return {
            selectMic: false,
            selectSpeaker: false,
            selectCamera: false,
            devices: [],
            current: {
                audio: "default",
                video: "default"
            },
            greyFilter: true
        }
    },
    computed: {
        audioDeviceOptions() {
            let arr = this.devices.filter(e => e.kind === 'audioinput' && e.deviceId !== "").map(e => {
                return {
                    value: e.deviceId,
                    name: e.deviceId === "default" ? "Same as System" : e.label
                }
            })

            if (this.room?.localParticipant?.audioTracks?.values()?.next()?.value) {
                let name = this.room.localParticipant.audioTracks.values().next().value.track.mediaStreamTrack.label
                let device = arr.find(e => e.name === name)
                if (device) {
                    this.current.audio = device.value
                }
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
            if (this.room?.localParticipant?.videoTracks?.values()?.next()?.value) {
                let name = this.room.localParticipant.videoTracks.values().next().value.track.mediaStreamTrack.label
                let device = arr.find(e => e.name === name)
                if (device) {
                    this.current.video = device.value
                }
            }
            return arr
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        }
    },
    watch: {
        settings(val) {
            this.getDevices()
        }
    },
    created() {
        this.getDevices()

        navigator.mediaDevices.ondevicechange = (event) => {
            this.checkNewDevices()
        }
    },
    mounted() {
        if (this.$device.mobile()) this.$eventHub.$emit('tw-mobileSelectOption')
        this.$eventHub.$on('webRTC-setCamera', (id) => {
            this.current.video = id
        })
        this.$eventHub.$on('webRTC-setMicrophone', (id) => {
            this.current.audio = id
        })
    },
    methods: {
        getDevices() {
            navigator.mediaDevices.enumerateDevices().then((e) => {
                this.devices = e
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
        toggleSelectMic() {
            this.selectMic = !this.selectMic
        },
        checkShared() {
            let flag = false
            this.room.participants.forEach(participant => {
                participant.videoTracks.forEach(track => {
                    if (track.trackName === "share") {
                        flag = true
                    }
                })
            })
            this.room.localParticipant.videoTracks.forEach(track => {
                if (track.trackName === "share") {
                    flag = true
                }
            })
            return flag
        },
        toggleSelectSpeaker() {
            this.selectSpeaker = !this.selectSpeaker
        },
        toggleSelectCamera() {
            this.selectCamera = !this.selectCamera
        },
        updateDevice(deviceId, isVideo = false) {
            // don't forget
            if (this.webRTC) {
                if (isVideo && deviceId !== '') {
                    this.$eventHub.$emit("webRTC-CameraChanged", deviceId)
                    this.$emit('closeSettings')
                }
                if (!isVideo && deviceId !== '') {
                    this.$eventHub.$emit("webRTC-MicrophoneChanged", deviceId)
                    this.$emit('closeSettings')
                }
            } else {
                if (isVideo) {
                    const localParticipant = this.room.localParticipant
                    let isMuted = false
                    if (deviceId !== '') {
                        createLocalVideoTrack({deviceId: {exact: deviceId}, width: this.isPresenter ? 1920 : 720})
                            .then((localVideoTrack) => {
                                this.current.video = deviceId
                                localParticipant.videoTracks.forEach(e => {
                                    if (e.trackName !== 'share') {
                                        isMuted = !e.track.isEnabled
                                        console.log(isMuted)
                                        e.track.stop()
                                        e.unpublish()
                                        e.track.detach().forEach(function (element) {
                                            element.srcObject = null
                                            element.remove()
                                        })
                                    }
                                })
                                this.room.localParticipant.publishTrack(localVideoTrack)
                                    .then(publication => {
                                        this.$emit("deviceUpdated")
                                        setTimeout(() => {
                                            // this.$eventHub.$emit("tw-roomCreated");
                                            this.$eventHub.$emit("tw-updateLocalDevice")

                                            if (isMuted) {
                                                publication.track.disable()
                                                setTimeout(() => {
                                                    publication.track.disable()
                                                    // publication.track.stop();
                                                }, 500)
                                            }

                                        }, 500)
                                        if (this.isPresenter && !this.checkShared())
                                            this.$eventHub.$emit("tw-attachMainTrack", localVideoTrack)
                                        this.$emit('closeSettings')
                                    }).catch(error => {
                                    this.$flash("Something wrong with your device")
                                })
                            }).catch(error => {
                            this.$flash("Something wrong with your device")
                        })
                    }
                } else {
                    const localParticipant = this.room.localParticipant
                    let isMuted = false
                    if (deviceId !== '') {
                        createLocalAudioTrack({deviceId: {exact: deviceId}})
                            .then((localTrack) => {
                                this.current.audio = deviceId
                                localParticipant.audioTracks.forEach(e => {
                                    isMuted = !e.track.isEnabled
                                    e.track.stop()
                                    e.unpublish()
                                    e.track.detach().forEach(function (element) {
                                        element.srcObject = null
                                        element.remove()
                                    })
                                })
                                this.room.localParticipant.publishTrack(localTrack).then(publication => {
                                    this.$emit('closeSettings')
                                    setTimeout(() => {
                                        if (isMuted) {
                                            publication.track.disable()
                                        }
                                    }, 500)
                                })
                            })
                    }
                }
            }
        },
        toggleVideoFilter() {
            this.greyFilter = !this.greyFilter
            this.$eventHub.$emit("tw-toggleVideoFilter", this.greyFilter)
        }
    }
}
</script>

