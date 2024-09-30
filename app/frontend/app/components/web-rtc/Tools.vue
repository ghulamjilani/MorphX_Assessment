<template>
    <div class="cm__tools__wrapper cm__tools__wrapper__row">
        <div
            :class="{'IpCam__flex' : ip_cam || rtmp}"
            class="display__flex">
            <div
                v-if="!ip_cam && !rtmp"
                v-tooltip="videoMuted ? 'Camera Off': 'Camera On'"
                class="cm__tools">
                <m-icon
                    :class="{'cm__tools__icon__active': !videoMuted}"
                    :name="!videoMuted ? 'GlobalIcon-stream-video':'GlobalIcon-video-off'"
                    class="cm__tools__icon cm__tools__double"
                    size="0"
                    @click="toggleVideoMute" />
                <m-icon
                    ref="videoSelect"
                    :class="{'cm__tools__angle__active' : vidSettings}"
                    class="cm__tools__angle"
                    @click="toggleSettings(false, true)">
                    GlobalIcon-angle-down
                </m-icon>
            </div>
            <div
                v-if="!ip_cam && !rtmp"
                v-tooltip="audioMuted ? 'Mic Off': 'Mic On'"
                class="cm__tools">
                <m-icon
                    :class="{'cm__tools__icon__active': !audioMuted}"
                    :name="!audioMuted ? 'GlobalIcon-mic':'GlobalIcon-mic-off'"
                    class="cm__tools__icon cm__tools__double cm__tools__icon__mic"
                    size="0"
                    @click="toggleAudioMute" />
                <m-icon
                    ref="audioSelect"
                    :class="{'cm__tools__angle__active' : micSettings}"
                    class="cm__tools__angle"
                    @click="toggleSettings(true, false)">
                    GlobalIcon-angle-down
                </m-icon>
            </div>
        </div>
        <select-options
            v-show="settings"
            v-click-outside="micSettings ? checkAudioTarget : checkVideoTarget"
            :mic-settings="micSettings"
            :room-info="roomInfo"
            :settings="settings"
            :vid-settings="vidSettings"
            :web-r-t-c="true"
            @closeSettings="closeSettings" />
        <div class="display__flex">
            <div
                v-tooltip="'Participants'"
                class="cm__tools">
                <m-icon
                    ref="selectParticipants"
                    :class="{'cm__tools__icon__active' : invite}"
                    class="cm__tools__icon"
                    size="0"
                    @click="toggleInvite()">
                    GlobalIcon-users
                </m-icon>
            </div>
            <div
                v-if="!$device.mobile() && !$device.tablet() && !ip_cam && !rtmp"
                v-tooltip="shareScreen ? 'Stop Share' : 'Share Screen'"
                class="cm__tools">
                <m-icon
                    :class="{'cm__tools__icon__active active' : shareScreen}"
                    class="cm__tools__icon"
                    size="0"
                    @click="toggleShare">
                    GlobalIcon-screen-share
                </m-icon>
            </div>
            <div
                v-if="isChatAllowed"
                v-tooltip="'Chat'"
                class="cm__tools">
                <div
                    v-show="newMessages > 0 && !chat"
                    :class="{'webRTC__newMessage' : $device.mobile()}"
                    class="cm__tools__icon__message__new" />
                <m-icon
                    :class="{'cm__tools__icon__active' : chat}"
                    class="cm__tools__icon"
                    size="0"
                    @click="toggleChat">
                    GlobalIcon-message-square
                </m-icon>
            </div>
            <div
                v-tooltip="'Polls'"
                class="cm__tools">
                <m-icon
                    :class="{'active' : more.polls}"
                    class="cm__tools__icon"
                    size="0"
                    @click="openCreatePolls">
                    poll-icon
                </m-icon>
            </div>
            <!-- <div
                class="cm__tools">
                <m-dropdown
                    ref="settingsDropdown"
                    class="cm__tools__icon">
                    <m-option
                        @click="openCreatePolls">
                        {{ $t('frontend.app.components.video_client.tools.tooltips.create_polls') }}
                    </m-option>
                </m-dropdown>
            </div> -->
        </div>
        <div class="display__flex">
            <div class="cm__tools__exit">
                <a
                    class="btn btn btn__bordered"
                    type="bordered"
                    @click="exit">Leave</a>
            </div>
        </div>
    </div>
</template>

<script>
import SelectOptions from '../video-client/SelectOptions.vue'
import ClickOutside from "vue-click-outside"

export default {
    components: {SelectOptions},
    directives: {ClickOutside},
    props: {
        roomInfo: Object,
        ip_cam: Boolean,
        rtmp: Boolean
    },
    data() {
        return {
            videoMuted: false,
            audioMuted: false,
            shareScreen: false,
            chat: false,
            invite: false,
            newMessages: 0,
            settings: false,
            sideBar: false,
            micSettings: false,
            vidSettings: false,
            more: {
                polls: false
            }
        }
    },
    computed: {
        isChatAllowed() {
            return this.roomInfo.abstract_session?.allow_chat
        }
    },
    created() {
        this.$eventHub.$on("tw-chatNewMessagesCount", count => {
            this.newMessages = count
        })
    },
    mounted() {
        this.$eventHub.$on("tw-toggleInvite", flag => {
            this.invite = flag
            this.sideBar = this.invite
            this.$eventHub.$emit('webRTC-sideBar', this.sideBar)
        })
        this.$eventHub.$on("webRTC-toggleChat", flag => {
            this.chat = flag
            this.sideBar = this.chat
            this.$eventHub.$emit('webRTC-sideBar', this.sideBar)
        })
        this.$eventHub.$on('webRTC-toggleShareTools', (share) => {
            this.shareScreen = share
        })
        this.$eventHub.$on('webRTC-sideBar', (value) => {
            this.sideBar = value
        })
        this.$eventHub.$on("webRTC-chatNewMessagesCount", count => {
            this.newMessages = count
        })
        this.$eventHub.$on("tw-pollsStatus", (flag) => {
            this.more.polls = flag
        })
    },
    methods: {
        toggleInvite() {
            this.invite = !this.invite
            this.sideBar = this.invite
            this.$eventHub.$emit("webRTC-toggleChat", false)
            this.$eventHub.$emit("tw-toggleInvite", this.invite)
            this.$eventHub.$emit('webRTC-sideBar', this.sideBar)
        },
        checkAudioTarget(event) {
            if (this.$refs.audioSelect && this.$refs.audioSelect.$el == event.target) return
            this.micSettings = false
            this.settings = false
        },
        checkVideoTarget(event) {
            if (this.$refs.videoSelect && this.$refs.videoSelect.$el == event.target) return
            this.vidSettings = false
            this.settings = false
        },
        closeSettings() {
            this.settings = false
            this.micSettings = false
            this.vidSettings = false
        },
        checkTargetOptions(event) {
            if (this.$refs.selectOptions.$el == event.target) return
            this.settings = false
        },
        toggleAudioMute() {
            this.audioMuted = !this.audioMuted
            this.$eventHub.$emit('webRTC-toggleAudioMute')
        },
        toggleVideoMute() {
            this.videoMuted = !this.videoMuted
            this.$eventHub.$emit('webRTC-toggleVideoMute')
        },
        exit() {
            this.$eventHub.$emit('webRTC-exit')
        },
        toggleShare() {
            this.shareScreen = !this.shareScreen
            this.$eventHub.$emit('webRTC-toggleShare', this.shareScreen)
        },
        toggleChat() {
            this.chat = !this.chat
            this.sideBar = this.chat
            this.$eventHub.$emit("tw-toggleInvite", false)
            this.$eventHub.$emit('webRTC-toggleChat', this.chat)
            this.$eventHub.$emit('webRTC-sideBar', this.sideBar)
        },
        toggleSettings(mic = false, vid = false) {
            if (mic) {
                this.micSettings = !this.micSettings
                this.vidSettings = false
            }
            if (vid) {
                this.vidSettings = !this.vidSettings
                this.micSettings = false
            }
            if (!mic && !vid) {
                this.micSettings = false
                this.vidSettings = false
            }
            this.settings = !this.settings
            if (this.micSettings || this.vidSettings) this.settings = true
            this.$eventHub.$emit("webRTC-toggleSettings", this.settings)
        },
        openCreatePolls() {
            this.more.polls = true
            // this.$refs.settingsDropdown.close()
            this.$eventHub.$emit('poll-template:open')
        }
    }
}
</script>

