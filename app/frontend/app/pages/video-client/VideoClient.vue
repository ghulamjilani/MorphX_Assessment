<template>
    <div class="client video-client">
        <main-section
            v-if="!reconecting"
            :room="room"
            :room-info="roomInfo"
            :self-view="selfView"
            :sidebar="sidebar"
            :tracks="tracks" />
        <self-view
            v-if="selfView"
            :room="room"
            :room-info="roomInfo" />
        <side-bar-section
            v-show="!overlay"
            :room="room"
            :room-info="roomInfo"
            :sidebar="sidebar" />
        <not-supported
            v-show="!overlay"
            ref="notSupported" />
    </div>
</template>

<script>
import Webrtcservice, {isSupported, Logger} from "./../../assets/js/webrtcservice-video"

import {mapActions} from 'vuex'
import MainSection from '@components/video-client/MainSection.vue'
import SideBarSection from '@components/video-client/SideBarSection.vue'
import NotSupported from './NotSupported'
import SelfView from '../../components/video-client/SelfView.vue'

// logger
const logger = Logger.getLogger('webrtcservice-video')
logger.methodFactory = function (methodName, logLevel, loggerName) {
    // const method = originalFactory(methodName, logLevel, loggerName);
    return function (datetime, logLevel, component, message, data) {
        const prefix = '[Webrtcservice Application]'
        //   method(prefix, datetime, logLevel, component, message, data);
        // console.log(prefix, datetime, logLevel, component, message, data);
    }
}
logger.setLevel('debug')

// import ViewNewMessages from '@components/video-client/chat/ViewNewMessages'

export default {
    components: {MainSection, SideBarSection, NotSupported, SelfView},
    props: {
        roomInfo: Object,
        canCreateRoom: Boolean
    },
    data() {
        return {
            room: null,
            sidebar: false,
            loading: false,
            tryToCreateRoom: 0,
            startCreating: false,
            overlay: false,
            tracks: [], // selfview tracks
            selfView: true,
            createdTime: -1,
            lastBytesSent: 0,
            reconecting: false
        }
    },
    computed: {
        // roomInfo() {
        //   return this.$store.getters["VideoClient/roomInfo"]
        // },
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.currentUser?.id === this.roomInfo?.presenter_user?.id
        }
    },
    watch: {
        room: {
            handler(val) {
                if (val && this.$device.mobile()) {
                    this.setSidebar()
                }
            }
        },
        roomInfo: {
            deep: true,
            immediate: true,
            handler(val, oldVal) {
                if (val.status === 'active' && (!oldVal || oldVal.status !== 'active')) {
                    this.selfView = true
                }
            }
        }
    },
    methods: {
        ...mapActions("VideoClient", ["setRoom"]),
        setSidebar() {
            if (this.$device.mobile()) {
                this.sidebar = true
                this.$eventHub.$emit('tw-changeSidebar', true)
                this.$eventHub.$emit('tw-hideSidebar', true)
            } else {
                this.sidebar = false
                this.$eventHub.$emit('tw-changeSidebar', false)
                this.$eventHub.$emit('tw-hideSidebar', false)
            }
        },
        leaveRoomIfJoined() {
            if (this.room) {
                this.room.disconnect()
            }
        },
        createRoom(tracks = []) {
            if (this.startCreating) return
            if (!this.canCreateRoom) return

            this.startCreating = true
            this.loading = true
            document.querySelector('.cm__loader').style.display = "block"
            let connectOptions = {
                name: "room-" + this.roomInfo.id,
                // logLevel: 'debug',
                audio: true,
                video: {
                    width: 720,
                    frameRate: 24,
                    name: 'camera',
                    facingMode: "user"
                },
                tracks: tracks,
                bandwidthProfile: {
                    video: {
                        mode: 'collaboration' // presentation collaboration
                    }
                },
                renderDimensions: {
                    high: {height: 720, width: 1280},
                    standard: {height: 300, width: 533},
                    low: this.$device.mobile() ? {height: 144, width: 120} : {height: 176, width: 144}
                    // high: {height:1080, width:1920},
                    // standard: {height:720, width:1280},
                    // low: {height:176, width:144}
                },
                networkQuality: {local: 1, remote: 2},
                maxSubscriptionBitrate: this.$device.mobile() ? 1000000 : 1500000,
                preferredVideoCodecs: [{codec: 'VP8', simulcast: true}],
                dominantSpeaker: true
            }

            if (this.isPresenter) {
                connectOptions.video = {height: 720, name: 'camera'}
                connectOptions.networkQuality = {local: 2, remote: 1}
            }

            if (this.tryToCreateRoom > 3) {
                connectOptions.video = true
            }
            if (this.tryToCreateRoom > 4) {
                connectOptions.audio = false
            }
            if (this.tryToCreateRoom > 6) {
                connectOptions.video = false
            }
            if (this.tryToCreateRoom > 7) {
                connectOptions.audio = true
                connectOptions.video = true
            }

            console.log("tryToCreateRoom", this.tryToCreateRoom, connectOptions)

            this.leaveRoomIfJoined()

            Webrtcservice.connect(this.roomInfo.service_token, connectOptions).then((room) => {
                this.room = room
                this.loading = false
                window.room = room
                this.startCreating = false
                this.setRoom(room)

                setTimeout(() => {
                    this.$eventHub.$emit("tw-roomCreated")
                    this.$emit("updateUsersList")
                    this.$eventHub.$emit("recalculateLayout")
                    if (this.isPresenter) {
                        this.room.localParticipant.videoTracks.forEach(track => {
                            track.setPriority("high")
                        })
                    } else {
                        this.room.localParticipant.videoTracks.forEach(track => {
                            track.setPriority("low")
                        })
                    }
                }, 600) // time to init
                setTimeout(() => {
                    document.querySelector('.cm__loader').style.display = "none"
                }, 600)
                setTimeout(() => {
                    this.$eventHub.$emit("tw-createChat")
                }, 1000)

                this.initUsageEvents()

                this.room.on('dominantSpeakerChanged', participant => {
                    this.$eventHub.$emit("tw-dominantSpeakerChanged", participant)
                })

                this.room.on('disconnected', (room, error) => {
                    if (error?.code === 20104) {
                        this.$flash('Signaling reconnection failed due to expired AccessToken!')
                    } else if (error?.code === 53000) {
                        this.$flash('Signaling reconnection attempts exhausted!')
                    } else if (error?.code === 53204) {
                        this.$flash('Signaling reconnection took too long!')
                    } else if (error?.code === 53205) {
                        this.$flash("You can open only one client from one account", "warning", 60 * 1000)
                        setTimeout(() => {
                            // webrtcservice-video.js:22957 2021-06-11T10:30:13.947Z warn [WebrtcserviceConnection #1: wss://global.vss.webrtcservice.com/signaling] Unexpected state "closed" for handling a "heartbeat" message from the TCMP server.
                            window.onbeforeunload = null
                            this.$emit("changeType", "close")
                        }, 1000)
                    }
                })

                this.room.on('reconnecting', error => {
                    this.$flash('Poor Internet connection. Connection may be broken.')
                })

                this.room.on('disconnected', error => {
                    console.log("!!! room disconnected", error.message, error.code)
                    setTimeout(() => {
                        if (this.room?.state === "disconnected") {
                            this.$flash('Connection is lost. Check your Internet connection.')
                        }
                    }, 5000)
                    let interval = setInterval(() => {
                        console.log("!!! tw-reconect", this.room?.state)
                        if (this.room?.state === "disconnected") {
                            this.reconnect()
                            this.$eventHub.$emit("tw-reconect")
                        } else {
                            clearInterval(interval)
                        }
                    }, 5000)
                })
            })
            .catch(error => {
                console.log("!!! catch createWebrtcservice", error)
                // if(error == "DOMException: Permission denied") {
                this.tryToCreateRoom += 1
                this.startCreating = false
                if (this.tryToCreateRoom < 10) {
                    // this.checkDevices()
                    this.createRoom(tracks)
                }
                // }
            })
        },
        initUsageEvents() {
            // interactive bandwidth
            setInterval(() => {
                this.room._signaling.getStats().then(res => {
                    let bytesSent = res.values()?.next()?.value?.activeIceCandidatePair?.bytesSent / 1024

                    window.sendWebrtcUsage({
                        model_id: this.roomInfo?.abstract_session?.id,
                        model_type: "Session",
                        channel_id: this.roomInfo?.channel?.id,
                        organization_id: this.roomInfo?.channel?.organization_id,
                        event_type: "INTERACTIVE_BANDWIDTH",
                        event_value: +bytesSent - this.lastBytesSent,
                        host_id: this.roomInfo?.abstract_session?.presenter_id
                    })

                    this.lastBytesSent = +bytesSent
                })
            }, 10000)
        },
        reconnect() {
            window.authenticateCableConnection()
            setTimeout(() => {
                this.room?.disconnect()
                this.startCreating = false
                this.reconecting = true
                this.$nextTick(() => {
                    this.reconecting = false
                    this.createRoom(this.tracks)
                    // this.$eventHub.$emit("tw-subscribeForImmersiveRoomsChannelEvents") // guests
                })
            }, 200)
        }
    },
    created() {
        window.addEventListener("unload", this.leaveRoomIfJoined)
    },
    mounted() {
        window.reconnect = this.reconnect
        this.$eventHub.$on("tw-closeSelfView", () => {
            this.selfView = false
        })
        this.$eventHub.$on("tw-openSelfView", () => {
            // this.selfView = true
        })
        this.$eventHub.$on("tw-selfView-goLive", (tracks) => {
            this.tracks = tracks
            if (this.roomInfo.status === 'active') this.createRoom(tracks)
        })

        this.$eventHub.$on("tw-goLive-new", () => {
            this.createRoom(this.tracks)
        })

        window.addEventListener("resize", this.setSidebar)
        this.$eventHub.$on("mobileOverlay", (data) => {
            this.overlay = data
        })

        this.$eventHub.$on("tw-reconect", (tracks) => {
            // this.createRoom(tracks)
        })
        this.$eventHub.$on("tw-toggleSidebar", flag => {
            this.sidebar = flag
        })

        if (!isSupported) this.$refs.notSupported.open()

        this.$eventHub.$emit("showHeaderClient")
    }
}
</script>

