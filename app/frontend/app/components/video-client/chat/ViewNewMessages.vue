<template>
    <transition-group
        v-show="!chatOpened"
        class="chatMK2__notifications"
        name="chatMK2__notification-list"
        tag="div">
        <div
            v-for="message in showMessages"
            v-show="message.show"
            :key="message.message.id"
            @click="openChat">
            <div class="chatMK2__notification">
                <div class="chatMK2__notification__header">
                    <div class="chatMK2__notification__header__avatar">
                        <img
                            :src="getUser(message.message) && getUser(message.message).avatar_url ? getUser(message.message).avatar_url : $img['hidden_default']"
                            class="chatMK2__notification__header__avatar__image">
                    </div>
                    <div
                        v-if="getUser(message.message) && getUser(message.message).display_name"
                        class="chatMK2__notification__header__name">
                        {{ getUser(message.message).display_name }}
                    </div>
                    <div class="chatMK2__notification__header__time">
                        {{ getTime(message.message) }}
                    </div>
                </div>
                <div class="chatMK2__notification__body">
                    {{ message.message.body }}
                </div>
            </div>
        </div>
    </transition-group>
</template>

<script>
export default {
    props: {
        roomInfo: Object
    },
    data() {
        return {
            messages: [],
            chatOpened: false
        }
    },
    computed: {
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        showMessages() {
            let msgs = this.messages.filter(e => e.show && e.message.conversation_participant?.abstract_user?.id !== this.currentUser?.id)
            return msgs.slice(-2)
        }
    },
    created() {
        this.$eventHub.$on("tw-chatNewMessage", message => {
            let msg = {
                message,
                show: !this.chatOpened
            }
            this.messages.push(msg)
            setTimeout(() => {
                msg.show = false
            }, 4000)
        })

        this.$eventHub.$on("tw-toggleChat", flag => {
            this.chatOpened = flag
        })

        this.$eventHub.$on("webRTC-toggleChat", flag => {
            this.chatOpened = flag
        })
    },
    methods: {
        messageJson(message) {
            try {
                return JSON.parse(message.body)
            } catch (error) {
                return undefined
            }
        },
        messageBody(message) {
            return this.messageJson(message) ? this.messageJson(message).messageBody.replace(/<br\s*\/?>/gi, ' ') : message.body.replace(/<br\s*\/?>/gi, ' ')
        },
        getUser(message) {
            if (message?.conversation_participant?.abstract_user) {
                return {
                    avatar_url: message?.conversation_participant?.abstract_user?.avatar_url,
                    display_name: message?.conversation_participant?.abstract_user?.public_display_name
                }
            }
        },
        openChat() {
            this.messages.forEach(e => e.show = false)
            this.$eventHub.$emit("tw-toggleChat", true)
            this.$eventHub.$emit("webRTC-toggleChat", true)
        },
        getTime(message) {
            let time = new Date(message.created_at)
            return (time.getHours() > 9 ? time.getHours() : "0" + time.getHours()) + ":" +
                (time.getMinutes() > 9 ? time.getMinutes() : "0" + time.getMinutes())
        }
    }
}
</script>

