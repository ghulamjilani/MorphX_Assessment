<template>
    <transition-group
        class="flash__container flash__container__show"
        name="flash-list"
        tag="div">
        <m-blocking-message
            v-if="blockMessage"
            key="blocking-message" />
        <div
            v-for="message in messages"
            v-show="message.show"
            :key="message.id">
            <div
                :class="'flash__' + message.type"
                class="flash__container__alert">
                <button
                    class="flash__container__close"
                    type="button"
                    @click="message.show = false">
                    <i class="GlobalIcon-clear" />
                </button>
                <span
                    class="notificationText"
                    v-html="message.text" />
            </div>
        </div>
    </transition-group>
</template>

<script>
import MBlockingMessage from "./MBlockingMessage"

export default {
    components: {
        MBlockingMessage
    },
    props: {
        blockMessage: Boolean
    },
    data() {
        return {
            id: 0,
            messages: []
        }
    },
    created() {
        let flashCookie = this.$cookies?.get('flash')
        let flashMessageArray = []
        let timeout = 500
        let hostname = window.location.hostname

        if (flashCookie) {
            if(typeof flashCookie == 'string') {
                flashMessageArray = JSON.parse(
                    decodeURIComponent(flashCookie.replace(/\+/g, '%20'))
                )
            }
            else {
                flashMessageArray = flashCookie.map(message => {
                    message[1] = message[1].replace(/\+/g, ' ')
                    return message
                })
            }

            flashMessageArray.forEach((message) => {
                setTimeout(() => {
                    this.flash(message[1], message[0])
                }, timeout)
                timeout += 300
                this.$cookies.remove('flash', '/', hostname)
                this.$cookies.remove('flash', '/', hostname.substring(hostname.indexOf('.')))
            })
        }
    },
    methods: {
        flash(message, type = "warning", time = 6000) {
            let msg = {
                id: this.id++,
                text: message,
                type: type,
                show: true,
                delay: time
            }
            this.messages.push(msg)
            setTimeout(() => {
                msg.show = false
            }, time)
        }
    }
}
</script>