<template>
    <div class="chatDialog__message">
        <div class="chatDialog__avatar">
            <img
                :src="message.abstract_user.avatar_url"
                class="chatDialog__avatar__image">
        </div>
        <div
            :class="{'chatDialog__text__owner' : isSelf}"
            class="chatDialog__text">
            <span
                :style="'color:' + getNameColor"
                class="chatDialog__text__name">{{
                    message.abstract_user.public_display_name
                }}</span>
            <span class="chatDialog__text__timestamp">
                {{ message.created_at | formattedDate }}
            </span>
            {{ message.body }}
            <m-icon
                v-if="canDestroy"
                class="chatDialog__remove"
                @click="remove">
                GlobalIcon-clear
            </m-icon>
        </div>
    </div>
</template>

<script>
import ImConversationMessages from '@models/ImConversationMessages'
import ImConversations from '@models/ImConversations'

export default {
    props: {
        message: Object
    },
    data() {
        return {
            owner: false,
            colors: {
                'self': '#37A67D',
                'user': 'var(--tp__main)'
            }
        }
    },
    computed: {
        getNameColor() {
            if(this.isSelf){
                return this.colors['self']
            } else {
                return this.colors['user']
            }
        },
        isSelf() {
            return (this.currentUser && this.currentUser?.id == this.message?.abstract_user?.id) ||
               (this.currentGuest && this.currentGuest?.id == this.message?.abstract_user?.id)
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        canDestroy() {
            return this.isSelf || this.currentConversation?.can_moderate_conversation
        },
        currentConversation() {
            return ImConversations.query().whereId(this.message.conversation_id).first()
        }
    },
    methods: {
        remove() {
            if(confirm(this.$t("frontend.app.components.pageparts.im_conversation.conversation_message.are_you_sure"))) {
                ImConversationMessages.api().deleteMessage({
                    id: this.message.id,
                    conversation_id: this.message.conversation_id
                }).then(() => {
                    this.$flash(this.$t("frontend.app.components.pageparts.im_conversation.conversation_message.deleted"), "success")
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash(this.$t("frontend.app.components.pageparts.im_conversation.conversation_message.wrong_error"))
                    }
                })
            }
        }
     }
}
</script>
