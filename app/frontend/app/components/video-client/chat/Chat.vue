<template>
    <div class="chatMK2">
        <div
            :class="{'chatMK2__header__keyboard' : keyboard && $device.orientation == 'landscape'}"
            class="chatMK2__header">
            <div
                v-show="loading"
                class="cm__loader">
                <div class="spinnerSlider">
                    <div class="bounceS1" />
                    <div class="bounceS2" />
                    <div class="bounceS3" />
                </div>
            </div>
            <div class="chatMK2__header__title">
                Chat
            </div>
            <div
                class="chatMK2__header__close"
                @click="closeChat()">
                <m-icon size="1.8rem">
                    GlobalIcon-clear
                </m-icon>
            </div>
        </div>

        <chat-wrapper
            :session-id="roomInfo.abstract_session_id"
            :web-r-t-c="webRTC"
            :room-info="roomInfo" />
    </div>
</template>

<script>
import ClickOutside from "vue-click-outside"

import ChatWrapper from '@components/pageparts/chat/ChatWrapper'

export default {
    directives: {
        ClickOutside
    },
    components: {ChatWrapper},
    props: {
        roomInfo: Object,
        webRTC: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            loading: false,
            isChatOpened: false,
            newMessages: 0,
            firstEnter: true,
            keyboard: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        }
    },
    created() {
        this.$eventHub.$on("tw-toggleChat", flag => {
            this.isChatOpened = flag
            this.newMessages = 0
            this.$eventHub.$emit("tw-chatNewMessagesCount", this.newMessages)
        })
        this.$eventHub.$on("webRTC-toggleChat", flag => {
            this.isChatOpened = flag
            this.newMessages = 0
            this.$eventHub.$emit("webRTC-chatNewMessagesCount", this.newMessages)
        })
    },
    methods: {
        checkMobile() {
            return this.$device.mobile()
        },
        keyboardCheck(open) {
            if (this.$device.mobile()) {
                this.keyboard = open
            }
        },
        bindEvents() {
        //     this.currentChannel.on('messageAdded', (message => {
        //         this.messages.push(message)
        //         if (this.checkBottom()) this.scrollToBottom()
        //         this.loading = false
        //         if (!this.isChatOpened) {
        //             this.newMessages += 1
        //             this.$eventHub.$emit("tw-chatNewMessagesCount", this.newMessages)
        //             this.$eventHub.$emit("tw-chatNewMessage", message)
        //             this.$eventHub.$emit("webRTC-chatNewMessage", message)
        //         }
        //     }))
        },
        scrollToBottom() {
            setTimeout(() => {
                this.calculateToBottom()
            }, 500)
            this.calculateToBottom()
        },
        checkBottom() {
            const scrollHeight = this.$refs.messages.scrollHeight
            const height = this.$refs.messages.clientHeight
            const maxScrollTop = scrollHeight - height
            console.log(scrollHeight, height, maxScrollTop, this.$refs.messages.scrollTop - maxScrollTop)
            return this.$refs.messages.scrollTop - maxScrollTop > -10
        },
        calculateToBottom() {
            const scrollHeight = this.$refs.messages.scrollHeight
            const height = this.$refs.messages.clientHeight
            const maxScrollTop = scrollHeight - height + 50
            this.$refs.messages.scrollTop = maxScrollTop > 0 ? maxScrollTop : 0
        },
        closeChat() {
            this.$eventHub.$emit("tw-toggleChat", false)
            this.$eventHub.$emit("webRTC-toggleChat", false)
            this.$eventHub.$emit('webRTC-sideBar', (false))
        },
        setCaretPosition(elem, caretPos) {
            if (elem != null) {
                if (elem.createTextRange) {
                    var range = elem.createTextRange()
                    range.move('character', caretPos)
                    range.select()
                } else {
                    if (elem.selectionStart) {
                        elem.focus()
                        elem.setSelectionRange(caretPos, caretPos)
                    } else
                        elem.focus()
                }
            }
        }
    }
}
</script>
