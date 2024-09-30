<template>
    <div
        v-if="conversations.length"
        class="chatGroup">
        <transition
            name="modalUp"
            mode="out-in">
            <div
                v-if="groupOpen || chatOpen"
                class="chatGroup__modal">
                <transition
                    name="groupShow"
                    mode="out-in">
                    <div
                        v-if="groupOpen"
                        class="chatGroup__group">
                        <div class="chatGroup__header">
                            <span>Group Conversations</span>
                            <m-icon
                                size="0"
                                class="chatGroup__header__close"
                                @click="toogleGroup(false)">
                                GlobalIcon-clear
                            </m-icon>
                        </div>
                        <div class="chatGroup__body">
                            <div
                                v-for="conversation in conversations"
                                :key="conversation.id"
                                class="chatGroup__channel"
                                @click="toggleChat(true, conversation.id)">
                                <div class="chatGroup__channel__image">
                                    <img :src="conversation.channel.cover_url">
                                </div>
                                <div class="chatGroup__channel__name">
                                    {{ conversation.channel.title }}
                                </div>
                                <!-- <div class="chatGroup__channel__unread">
                                    <span>1</span>
                                </div> -->
                            </div>
                        </div>
                    </div>
                </transition>
                <transition
                    name="chatShow"
                    mode="out-in">
                    <conversation-chat
                        v-if="chatOpen"
                        :conversation-id="conversation_id"
                        class="chatGroup__chat"
                        @toggleChat="toggleChat"
                        @closeChat="closeChat" />
                </transition>
            </div>
        </transition>
        <transition
            name="iconShow"
            mode="out-in">
            <div
                v-if="!groupOpen && !chatOpen"
                class="chatGroup__wrapper"
                :class="{'up': pageEnding}">
                <div
                    class="chatGroup__icon__wrapper"
                    @click="toogleGroup(true)">
                    <m-icon
                        class="chatGroup__icon"
                        size="0">
                        GlobalIcon-message-square
                    </m-icon>
                </div>
            </div>
        </transition>
        <conversation-flash v-if="!groupOpen && !chatOpen" /><!--dont show flash notification if char modal opened-->
    </div>
</template>

<script>
import ImConversations from '@models/ImConversations'
import ImConversationMessages from '@models/ImConversationMessages'

import ConversationChat from './ConversationChat.vue'
import ConversationFlash from './ConversationFlash.vue'
  export default {
    components: { ConversationChat, ConversationFlash },
    data() {
        return {
            groupOpen: false,
            chatOpen: false,
            newMessages: true,
            conversation_id: false,
            cabelConversations: null,
            pageEnding: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        pageOrganization() {
            return this.$store.getters["Users/pageOrganization"]
        },
        conversations() {
            return ImConversations.query().where("conversationable_type", "Channel").get()
        }
    },
    watch: {
        conversations: {
            handler(val){
                if(val && val.length){
                    this.cabelConversation()
                }
            },
            deep: true
        },
        currentUser(val, old) {
            if(old?.id != val.id) {
                this.cabelConversation()
            }
        }
    },
    mounted(){
        this.getAllChannelConversations()
        setTimeout(() => { this.zIndexDrift() }, 2000)
        setTimeout(() => { this.zIndexDrift() }, 5000)
        setTimeout(() => { this.checkLastOpened() }, 2000)

        document.addEventListener('scroll', () => {
            const scrollableHeight = document.documentElement.scrollHeight - window.innerHeight - 50

            if (window.scrollY >= scrollableHeight) {
                this.pageEnding = true
            }
            else {
                this.pageEnding = false
            }
        })
    },
    methods: {
        cabelConversation(){
            this.conversations.forEach((conversation) => {
                let channel = initImConversationsChannel(conversation.id)
                channel.bind(imConversationsChannelEvents.newMessage, (data) => {
                    let message = { ...data.message }
                    // message.conversation_id = conversation.id
                    message.abstract_user = data.message.conversation_participant.abstract_user
                    ImConversationMessages.insert({ data: message })
                    this.addNewMessage(message, conversation.channel.title)
                    this.$eventHub.$emit("conversation-newMessage", data.message.conversation_id)
                })
                channel.bind(imConversationsChannelEvents.messageDeleted, (data) => {
                    ImConversationMessages.delete(data.message.id.toString())
                })
            })
        },
        addNewMessage(message, channel_title){
            if(!this.groupOpen && !this.chatOpen){
                this.$eventHub.$emit('conversation-flash', { message, channel_title })
            }
        },
        zIndexDrift(){
            if(document.querySelector('.drift-frame-controller')){
                document.querySelectorAll('.drift-frame-controller').forEach(e => {
                    e.style.zIndex = 999
                })
            }
        },
        getAllChannelConversations(){
            ImConversations.api().getAllUserChannelConversations()
        },
        toogleGroup(val){
            this.groupOpen = val
            if(this.groupOpen){
                this.getAllChannelConversations()
            }
        },
        toggleChat(val, id){
            this.chatOpen = val
            this.chatOpen ? this.conversation_id = id : this.conversation_id = null
            this.chatOpen ? this.groupOpen = false : this.groupOpen = true
            localStorage.setItem("last_chat_state", this.chatOpen)
            localStorage.setItem("last_conversation_id", this.conversation_id)
            localStorage.setItem("last_conversation_user_id", this.currentUser.id)
        },
        closeChat(){
            this.chatOpen = false
            this.groupOpen = false
            localStorage.setItem("last_chat_state", this.chatOpen)
        },
        checkLastOpened() {
            if(this.currentUser && localStorage.getItem("last_conversation_user_id")?.toString() != this.currentUser?.id?.toString()) return

            let chatOpen = localStorage.getItem("last_chat_state")
            let conversation_id = localStorage.getItem("last_conversation_id")
            if(chatOpen && chatOpen === "true" && conversation_id && conversation_id !== "null") {
               if(ImConversations.query().whereId(conversation_id).first()) {
                    this.chatOpen = true
                    this.conversation_id = conversation_id
                    this.getAllChannelConversations()
               }
            }
        }
    }
  }
</script>
<style lang="scss" scoped>
    .modalUp-enter-active, .modalUp-leave-active{
        transition: all .3s ease;
    }
    .modalUp-enter, .modalUp-leave-to {
        transform: translateY(50rem);
    }
    .iconShow-enter-active{
        transition: all .4s ease;
    }
    .iconShow-enter, .iconShow-leave-to {
        opacity: 0;
    }
    .groupShow-enter-active, .groupShow-leave-active{
        transition: all .3s ease;
    }
    .groupShow-enter, .groupShow-leave-to {
        transform: translateX(-50rem);
    }
    .chatShow-enter-active, .chatShow-leave-active{
        transition: all .3s ease;
    }
    .chatShow-enter, .chatShow-leave-to {
        transform: translateX(50rem);
    }
</style>