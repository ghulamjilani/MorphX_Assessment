<template>
    <div class="chatDialog__message">
        <div class="chatDialog__avatar">
            <img
                :src="message.abstract_user.avatar_url"
                class="chatDialog__avatar__image">
        </div>
        <div
            :class="{'chatDialog__text__owner' : self}"
            class="chatDialog__text">
            <span
                :style="'color:' + getNameColor()"
                class="chatDialog__text__name">{{
                    message.abstract_user.public_display_name
                }}</span>
            <span class="chatDialog__text__timestamp">{{getTime}}</span>
            {{ message.body }}
        </div>
    </div>
</template>

<script>
import {mapGetters} from 'vuex'
import { getCookie } from '../../../utils/cookies'

export default {
    props: {
        message: Object
    },
    data() {
        return {
            owner: false,
            self: false,
            colors: {
                'self': '#37A67D',
                'user': 'var(--tp__main)',
                'presenter': '#F23535'
            }
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "roomInfo",
            "roomMember"
        ]),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentGuest() {
            return this.$store.getters["Users/currentGuest"]
        },
        isPresenterMessage() {
            return this.roomInfo && this.message?.abstract_user?.id === this.roomInfo?.presenter_user?.id
        },
        getTime() {
            let date = new Date(this.message.created_at)
            let h = date.getHours(), m = date.getMinutes()
            return (h > 9 ? h : "0" + h ) + ":" + (m > 9 ? m : "0" + m )
        }
    },
    methods: {
        getNameColor() {
            if((this.currentUser?.id == this.message?.abstract_user?.id) ||
               (getCookie("current_guest_id") == this.message?.abstract_user?.id) ||
               (this.currentGuest?.id == this.message?.abstract_user?.id) ){
                this.self = true
                return this.colors['self']
            } else if(this.isPresenterMessage) {
                return this.colors['presenter']
            } else{
                return this.colors['user']
            }
        }
     }
}
</script>
