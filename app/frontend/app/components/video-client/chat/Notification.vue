<template>
    <transition-group
        class="tw__notifications"
        name="chatMK2__notification-list"
        tag="div">
        <div
            v-for="message in showMessages"
            v-show="message.show"
            :key="message.id"
            @click="message.show=false">
            <div class="chatMK2__notification">
                <!-- <div class="chatMK2__notification__header">
          <div class="chatMK2__notification__header__avatar">
          <img class="chatMK2__notification__header__avatar__image" :src="getUser(message.message.state) ? getUser(message.message.state).avatar_url : $img['avatar']">
          </div>
          <div class="chatMK2__notification__header__name">
              {{getUser(message.message.state) ? getUser(message.message.state).public_display_name : ''}}
          </div>
          <div class="chatMK2__notification__header__time">
            {{getTime(message)}}
          </div>
        </div> -->
                <div class="chatMK2__notification__body">
                    {{ message.body }}
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
            messages: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        showMessages() {
            let msgs = this.messages.filter(e => e.show)
            return msgs.slice(-4)
        },
        participantsList() {
            return this.$store.getters["VideoClient/participantsList"]
        }
    },
    created() {
        this.$eventHub.$on("tw-notification", message => {
            let msg = {
                id: this.messages.length,
                body: message,
                show: true
            }
            if (!this.messages.find(m => m.show && m.body === message)) {
                this.messages.push(msg)
                setTimeout(() => {
                    msg.show = false
                }, 8000)
            }
        })
        this.$eventHub.$on("tw-notification-user", (participantId, message) => {
            let name = this.getUserName(participantId)
            if (!name) return
            let msg = {
                id: this.messages.length,
                body: name + " " + message,
                show: true
            }
            this.messages.push(msg)
            setTimeout(() => {
                msg.show = false
            }, 8000)
        })
    },
    methods: {
        getUserName(participantId) {
            let id = participantId
            if (id === this.roomInfo.presenter_user.id) return this.roomInfo.presenter_user.public_display_name
            let user = this.participantsList?.find(e => e.id === id)
            if (user) {
                if (user?.user) return user.user.public_display_name
                return user.display_name
            } else return null
        },
        getTime(message) {
            let time = new Date(message.message?.state?.timestamp)
            return (time.getHours() > 9 ? time.getHours() : "0" + time.getHours()) + ":" +
                (time.getMinutes() > 9 ? time.getMinutes() : "0" + time.getMinutes())
        }
    }
}
</script>

