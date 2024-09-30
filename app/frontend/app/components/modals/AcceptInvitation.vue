<template>
    <m-modal
        ref="acceptInvitation"
        class="acceptInvitation">
        <template #header>
            <div class="acceptInvitation__title">
                Accept Invitation
            </div>
        </template>
        <div class="acceptInvitation__delivery">
            <div class="acceptInvitation__delivery__name">
                As Interactive Delivery Method
            </div>
            <m-btn
                class="acceptInvitation__delivery__button"
                type="save"
                @click="goTo(accept_immersive)">
                {{ textImmersive() }}
            </m-btn>
        </div>
        <div class="acceptInvitation__delivery acceptInvitation__delivery__livestream">
            <div class="acceptInvitation__delivery__name">
                As Livestream Delivery Method
            </div>
            <m-btn
                class="acceptInvitation__delivery__button acceptInvitation__delivery__livestream__button"
                type="save"
                @click="goTo(accept_livestream)">
                {{ textLivestream() }}
            </m-btn>
        </div>
    </m-modal>
</template>

<script>
import axios from "@plugins/axios.js"

export default {
    props: {
        currentBlockingMessage: Object
    },
    data() {
        return {
            accept_livestream: "",
            accept_immersive: ""
        }
    },
    methods: {
        textLivestream() {
            if (this.currentBlockingMessage.livestream_purchase_price && this.currentBlockingMessage.livestream_purchase_price != "$0.00") {
                return "Buy for " + this.currentBlockingMessage.livestream_purchase_price
            } else {
                return "Subscribe"
            }
        },
        textImmersive() {
            if (this.currentBlockingMessage.immersive_purchase_price && this.currentBlockingMessage.immersive_purchase_price != "$0.00") {
                return "Buy for " + this.currentBlockingMessage.immersive_purchase_price
            } else {
                return "Subscribe"
            }
        },
        open(id) {
            this.$refs.acceptInvitation.openModal()
            axios.get(`/sessions/${id}/preview_accept_invitation.json`).then((response) => {
                this.accept_livestream = response.data.accept_livestream[0].split('href="')[1].split('"')[0]
                this.accept_immersive = response.data.accept_immersive[0].split('href="')[1].split('"')[0]
            })
        },
        close() {
            this.$refs.acceptInvitation.closeModal()
        }
    }
}
</script>