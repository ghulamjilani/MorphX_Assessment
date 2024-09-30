<template>
    <div class="messageMK2">
        <div class="messageMK2__avatar">
            <img
                :src="getAvatar"
                class="messageMK2__avatar__image">
        </div>
        <div
            :class="{'messageMK2__text__owner' : self}"
            class="messageMK2__text">
            <span class="messageMK2__text__timestamp">{{ getTime() }}</span>
            <span
                :style="'color:' + getNameColor"
                class="messageMK2__text__name">{{
                    getUser && getUser.display_name || getUser && getUser.public_display_name
                }}</span>
            {{ messageBody }}
        </div>
    </div>
</template>

<script>
export default {
    props: {
        message: Object,
        roomInfo: Object
    },
    data() {
        return {
            owner: false,
            self: false,
            colors: {
                'owner': '#F23535',
                'self': '#37A67D',
                'user': '#FFFFFF'
            }
        }
    },
    computed: {
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        participantsList() {
            return this.$store.getters["VideoClient/participantsList"]
        },
        getUser() {
            if (this.messageJson) {
                let id = +this.message.author
                if (this.roomInfo && id === this.roomInfo.presenter_user.id) {
                    this.owner = true
                }
                return {
                    avatar_url: this.messageJson.authorAvatarUrl,
                    display_name: this.messageJson.authorName
                }
            } else {
                return null
            }
        },
        getAvatar() {
            if (this.getUser?.avatar_url) return this.getUser.avatar_url
            if (this.getUser?.user?.avatar_url) return this.getUser.user.avatar_url
            return this.$img['hidden_default']
        },
        getNameColor() {
            if (this.owner) return this.colors['owner']
            else if (this.roomMember?.user?.id === +this.message.author || this.roomMember?.id === +this.message.author) {
                this.self = true
                return this.colors['self']
            } else return this.colors['user']
        },
        messageJson() {
            try {
                return JSON.parse(this.message.body)
            } catch (error) {
                return undefined
            }
        },
        messageBody() {
            return this.messageJson ? this.messageJson.messageBody.replace(/<br\s*\/?>/gi, ' ') : this.message.body.replace(/<br\s*\/?>/gi, ' ')
        }
    },
    methods: {
        getTime() {
            let time = new Date(this.message.state?.timestamp)
            return (time.getHours() > 9 ? time.getHours() : "0" + time.getHours()) + ":" +
                (time.getMinutes() > 9 ? time.getMinutes() : "0" + time.getMinutes())
        }
    }
}
</script>
