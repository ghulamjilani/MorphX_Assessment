<template>
    <div class="cs__wrapper">
        <div
            v-show="invite || manage"
            :class="{'cs__fullHeight': invite || manage}"
            class="cs">
            <!-- <participants v-show="!invite && !manage" :sidebar="true" :main="false" :width="widthChild" :roomInfo="roomInfo" :room="room" /> -->
            <div
                v-show="invite || manage"
                class="inviteParticipant__wrapper">
                <invite
                    v-show="invite"
                    :ip_cam_or_rtmp="ip_cam_or_rtmp"
                    :room-info="roomInfo"
                    :is-webrtc="webRTC"
                    @close="closeInvite" />
                <manage
                    v-show="manage"
                    @close="closeManage" />
            </div>
        </div>
        <chat
            v-show="chat"
            :room-info="roomInfo"
            :web-r-t-c="webRTC" />
        <video-background
            v-show="virtualBackground"
            :room-info="roomInfo" />
    </div>
</template>

<script>
import Chat from './chat/Chat'
import Invite from './invite/Invite'
import Manage from './manage/Manage.vue'
import VideoBackground from './chat/VideoBackground.vue'

export default {
    components: {Chat, Invite, Manage, VideoBackground},
    props: {
        roomInfo: Object,
        room: Object,
        webRTC: {
            type: Boolean,
            default: false
        },
        ip_cam_or_rtmp: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            fit: true,
            event: "",
            widthChild: 230,
            width: 230,
            leftChild: 0,
            left: 0,
            maxWidth: 0,
            chat: false,
            invite: false,
            manage: false,
            virtualBackground: false
        }
    },
    computed: {
        sideBar() {
            return this.chat || this.invite || this.manage
        }
    },
    created() {
        this.$eventHub.$on("tw-toggleChat", flag => {
            this.chat = flag
        })
        this.$eventHub.$on("tw-toggleInvite", flag => {
            this.invite = flag
        })
        this.$eventHub.$on("webRTC-toggleChat", flag => {
            this.chat = flag
        })
        this.$eventHub.$on("webRTC-toggleInvite", flag => {
            this.invite = flag
        })
        this.$eventHub.$on("tw-toggleManage", flag => {
            this.manage = flag
        })
        this.$eventHub.$on("tw-toggleVirtualBackground", flag => {
            this.virtualBackground = flag
        })
    },
    mounted() {
        if (document.querySelector(".client")) {
            this.maxWidth = document.querySelector(".client").getBoundingClientRect().width * 0.36
            window.addEventListener("resize", function () {
                this.maxWidth = document.querySelector(".client").getBoundingClientRect().width * 0.36
            })
        }
    },
    methods: {
        setDefault(data) {
            this.leftChild = data.left
            this.left = data.left
            this.widthChild = this.width
        },
        eHandler(data) {
            if (this.left != data.left && this.maxWidth >= this.width + (this.leftChild - data.left) && this.width <= this.width + (this.leftChild - data.left)) {
                this.left = data.left
                this.calcWidth(data.left)
            }
        },
        calcWidth(data) {
            return this.widthChild = this.width + (this.leftChild - data)
        },
        closeInvite() {
            this.$eventHub.$emit("tw-toggleInvite", false)
            setTimeout(() => { // animation delay
                this.$eventHub.$emit("recalculateLayout")
            }, 300)
        },
        closeManage() {
            this.$eventHub.$emit("tw-toggleManage", false)
            setTimeout(() => { // animation delay
                this.$eventHub.$emit("recalculateLayout")
            }, 300)
        }
    }
}
</script>

