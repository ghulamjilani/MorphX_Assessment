<template>
    <transition-group
        class="chatGroup__notification__transition"
        name="notificationShow"
        mode="out-in"
        tag="div">
        <div
            v-for="msg in showMessages"
            :key="msg.message.id"
            class="chatGroup__notification__wrapper">
            <div class="chatGroup__notification">
                <div class="chatGroup__notification__title">
                    {{ msg.channel_title }}
                </div>
                <div class="chatGroup__notification__text">
                    {{ msg.message.abstract_user.public_display_name }}: {{ msg.message.body }}
                </div>
                <div class="chatGroup__notification__arrow" />
            </div>
        </div>
    </transition-group>
</template>

<script>

  export default {
    data() {
        return {
           messages: []
        }
    },
    computed: {
        showMessages(){
            return this.messages.filter(e => e.show).slice(-3)
        }
    },
    mounted(){
        this.$eventHub.$on('conversation-flash', (message) => {
            let obj = {...message, show: true}
            this.messages.push(obj)
            setTimeout(() => {
                obj.show = false
            }, 10000)
        })
    }
  }
</script>
<style lang="scss" scoped>
    .notificationShow-enter-active, .notificationShow-leave-active{
        transition: all .2s ease-out;
    }
    .notificationShow-enter, .notificationShow-leave-to {
        transform: scale(0.7) translateX(5rem);
        opacity: 0;
    }
</style>