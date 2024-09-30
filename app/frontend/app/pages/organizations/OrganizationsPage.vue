<template>
    <div class="homePage">
        <div id="sessions">
            <components-manager group="organizationsage" />
            <share-modal />
            <booking-payment />
            <user-info-modal
                :token="token" />
        </div>
    </div>
</template>

<script>

import ShareModal from '@components/modals/ShareModal'
import UserInfoModal from '../../components/modals/UserInfoModal.vue'
import {getCookie} from "@utils/cookies"
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    components: {
        ShareModal,
        UserInfoModal, BookingPayment
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        token() {
            return getCookie('_unite_session_jwt')
        }
    },
    mounted() {
        this.$store.dispatch("Users/setPageOrganization", null)
    }
}
</script>