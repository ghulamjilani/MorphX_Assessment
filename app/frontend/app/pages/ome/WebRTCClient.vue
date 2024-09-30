<template>
    <div class="ome">
        <div class="ome__settings">
            <m-input
                v-model="webRtcUrlInput"
                :pure="true"
                field-id="webRtcUrlInput"
                name="webRtcUrlInput"
                placeholder="webRtcUrlInput" />
            <div class="ome__state">
                ICE State: {{ ovenState }}
            </div>
            <m-btn @click="toogleStream">
                {{ streamingStarted ? 'Stop' : 'Start' }} Streaming
            </m-btn>
        </div>
        <div class="ome__select">
            <div v-if="videoDeviceOptions && videoDeviceOptions.length">
                <m-select
                    v-model="videoDeviceId"
                    :options="videoDeviceOptions"
                    label="Select a Camera"
                    type="default" />
            </div>
            <div v-if="audioDeviceOptions && audioDeviceOptions.length">
                <m-select
                    v-model="audioDeviceId"
                    :options="audioDeviceOptions"
                    label="Select a Microphone"
                    type="default" />
            </div>
            <div>
                <m-icon
                    class="cm__tools__icon"
                    size="0"
                    @click="userVideo">
                    GlobalIcon-stream-video
                </m-icon>
                <m-icon
                    class="cm__tools__icon"
                    size="0"
                    @click="screenShare">
                    GlobalIcon-screen-share
                </m-icon>
            </div>
        </div>
        <div class="ome__client">
            <div class="ome__main">
                <div class="ome__video__wrapper">
                    <video
                        id="previewPlayer"
                        autoplay
                        class="ome__video"
                        controls
                        playsinline />
                </div>
            </div>
        </div>
    </div>
</template>

<script>

export default {
    data() {
        return {
            lastResult: null,
            newConstraint: {},
            videoElement: null,
            webRtcUrlInput: null,
            streamingStarted: false,
            ovenState: null,
            allDevices: null,
            input: null,
            audioDeviceId: null,
            videoDeviceId: null,
            settings: {
                sdpURL: null,
                applicationName: null,
                streamName: null,
                audioBitrate: "64",
                audioCodec: "opus",
                videoBitrate: "3500",
                videoCodec: "42e01f",
                videoFrameRate: "30",
                frameSize: "default",
                videoResolution: "hd"
            }
        }
    },
    computed: {
        audioDeviceOptions() {
            if (!this.allDevices) return
            let arr = this.allDevices.audioinput.filter(e => e.deviceId !== "").map(e => {
                return {
                    value: e.deviceId,
                    name: e.deviceId === "default" ? "Same as System" : e.label
                }
            })
            let device = arr[0]
            if (device) {
                this.audioDeviceId = device.value
            }
            return arr
        },
        videoDeviceOptions() {
            if (!this.allDevices) return
            let arr = this.allDevices.videoinput.filter(e => e.deviceId !== "").map(e => {
                return {
                    value: e.deviceId,
                    name: e.label
                }
            })
            let device = arr[0]
            if (device) {
                this.videoDeviceId = device.value
            }
            return arr
        }
    },
    watch: {
        videoDeviceId: {
            handler(val) {
                if (val) {
                    this.userVideo()
                }
            },
            deep: true,
            immediate: true
        },
        audioDeviceId: {
            handler(val) {
                if (val) {
                    this.userVideo()
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.getDevices()
        this.initOven()
        this.videoElement = document.getElementById('previewPlayer')
    },
    methods: {
        userVideo() {
            this.input.getUserMedia(this.getUserConstraints())
        },
        screenShare() {
            this.input.getDisplayMedia(this.getDisplayConstraints())
        },
        getUserConstraints() {
            if (this.videoDeviceId) {
                this.newConstraint.video = {
                    deviceId: {
                        exact: this.videoDeviceId
                    }
                }
            }
            if (this.audioDeviceId) {
                this.newConstraint.audio = {
                    deviceId: {
                        exact: this.audioDeviceId
                    }
                }
            }
            if (this.settings.videoResolution) {
                this.newConstraint.video.width = this.settings.videoResolution.width
                this.newConstraint.video.height = this.settings.videoResolution.height
            }
            if (this.settings.videoFrameRate) {
                this.newConstraint.video.frameRate = {exact: parseInt(this.settings.videoFrameRate)}
            }
            return this.newConstraint
        },
        getDisplayConstraints() {
            this.newConstraint.video = {}
            if (this.settings.videoResolution) {
                this.newConstraint.video.width = this.settings.videoResolution.width
                this.newConstraint.video.height = this.settings.videoResolution.height
            } else {
                this.newConstraint.video = true
            }
            if (this.settings.videoFrameRate) {
                if (!this.newConstraint.video) {
                    this.newConstraint.video = {}
                }
                this.newConstraint.video.frameRate = parseInt(this.settings.videoFrameRate)
            }
            this.newConstraint.audio = true
            return this.newConstraint
        },
        checkDevice(devices, deviceId) {
            if (deviceId === 'displayCapture') {
                return true
            }
            let filtered = _.filter(devices, (device) => {
                return device.deviceId === deviceId
            })
            return filtered.length > 0
        },
        createInput() {
            this.input = window.OvenWebRTCInput.create({
                callbacks: {
                    error: (error) => {
                        let errorMessage = ''
                        if (error.message) {
                            errorMessage = error.message
                        } else if (error.name) {
                            errorMessage = error.name
                        } else {
                            errorMessage = error.toString()
                        }
                        if (errorMessage === 'OverconstrainedError') {
                            errorMessage = 'The input device does not support the specified resolution or frame rate.'
                        }
                        this.$flash(errorMessage)
                    },
                    connectionClosed: (type, event) => {
                        if (type === 'websocket') {
                            let reason
                            // See http://tools.ietf.org/html/rfc6455#section-7.4.1
                            if (event.code === 1000)
                                reason = "Normal closure, meaning that the purpose for which the connection was established has been fulfilled."
                            else if (event.code === 1001)
                                reason = "An endpoint is \"going away\", such as a server going down or a browser having navigated away from a page."
                            else if (event.code === 1002)
                                reason = "An endpoint is terminating the connection due to a protocol error"
                            else if (event.code === 1003)
                                reason = "An endpoint is terminating the connection because it has received a type of data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it receives a binary message)."
                            else if (event.code === 1004)
                                reason = "Reserved. The specific meaning might be defined in the future."
                            else if (event.code === 1005)
                                reason = "No status code was actually present."
                            else if (event.code === 1006)
                                reason = "The connection was closed abnormally, e.g., without sending or receiving a Close control frame"
                            else if (event.code === 1007)
                                reason = "An endpoint is terminating the connection because it has received data within a message that was not consistent with the type of the message (e.g., non-UTF-8 [http://tools.ietf.org/html/rfc3629] data within a text message)."
                            else if (event.code === 1008)
                                reason = "An endpoint is terminating the connection because it has received a message that \"violates its policy\". This reason is given either if there is no other sutible reason, or if there is a need to hide specific details about the policy."
                            else if (event.code === 1009)
                                reason = "An endpoint is terminating the connection because it has received a message that is too big for it to process."
                            else if (event.code === 1010) // Note that this status code is not used by the server, because it can fail the WebSocket handshake instead.
                                reason = "An endpoint (client) is terminating the connection because it has expected the server to negotiate one or more extension, but the server didn't return them in the response message of the WebSocket handshake. <br /> Specifically, the extensions that are needed are: " + event.reason
                            else if (event.code === 1011)
                                reason = "A server is terminating the connection because it encountered an unexpected condition that prevented it from fulfilling the request."
                            else if (event.code === 1015)
                                reason = "The connection was closed due to a failure to perform a TLS handshake (e.g., the server certificate can't be verified)."
                            else
                                reason = "Unknown reason"
                            this.$flash('Web Socket is closed. ' + reason)
                        }
                        if (type === 'ice') {
                            this.$flash('Peer Connection is closed. State: ' + this.input.peerConnection.iceConnectionState)
                        }
                    },
                    iceStateChange: (state) => {
                        this.ovenState = state
                    }
                }
            })
            this.input.attachMedia(this.videoElement)
            window.input = this.input
        },
        startStreaming() {
            this.streamingStarted = true
            if (this.input) {
                this.input.startStreaming(this.webRtcUrlInput)
            }
        },
        stopStreaming() {
            this.streamingStarted = false
            if (this.input) {
                this.input.remove()
                this.createInput()
            }
        },
        toogleStream() {
            if (!this.streamingStarted) {
                this.startStreaming()
            } else {
                this.stopStreaming()
            }
        },
        initOven() {
            setInterval(() => {
                if (!this.input || !this.input.peerConnection) {
                    // bitrateSpan.text('-');
                    return
                }
                let sender = null
                this.input.peerConnection.getSenders().forEach((s) => {
                    if (s.track && s.track.kind === 'video') {
                        sender = s
                    }
                })
                if (!sender) {
                    // bitrateSpan.text('-');
                    return
                }
                sender.getStats().then(res => {
                    res.forEach(report => {
                        let bytes
                        let headerBytes
                        let packets
                        if (report.type === 'outbound-rtp') {
                            if (report.isRemote) {
                                return
                            }
                            const now = report.timestamp
                            bytes = report.bytesSent
                            headerBytes = report.headerBytesSent
                            packets = report.packetsSent
                            if (this.lastResult && this.lastResult.has(report.id)) {
                                // calculate bitrate
                                const bitrate = 8 * (bytes - this.lastResult.get(report.id).bytesSent) /
                                    (now - this.lastResult.get(report.id).timestamp)
                                const headerrate = 8 * (headerBytes - this.lastResult.get(report.id).headerBytesSent) /
                                    (now - this.lastResult.get(report.id).timestamp)
                                const packetsSent = packets - this.lastResult.get(report.id).packetsSent
                                // bitrateSpan.innerHTML = (bitrate.toFixed(2) + 'kbps');
                            }
                            // console.log('framesEncoded', report.framesEncoded, 'keyFramesEncoded', report.keyFramesEncoded, report.framesEncoded / report.keyFramesEncoded + '(' + report.framesPerSecond + 'fps)')
                        }
                        if (report.type === 'track') {
                            // console.log(report)
                        }
                    })
                    this.lastResult = res
                })
            }, 2000)
        },
        // get all devices at the first time
        getDevices() {
            window.OvenWebRTCInput.getDevices().then((devices) => {
                this.allDevices = devices
                this.createInput()
            }).catch((error) => {
                let errorMessage = ''
                if (error.message) {
                    errorMessage = error.message
                } else if (error.name) {
                    errorMessage = error.name
                } else {
                    errorMessage = error.toString()
                }
                this.$flash(errorMessage)
            })
        }
    }
}
</script>