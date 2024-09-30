<template>
    <div
        class="homePage"
        :class="{'isPlatformOwner': isPlatformOwner}">
        <!-- <banner-wrapper /> -->
        <div id="sessions">
            <anchors group="homepage" />
            <!-- <AdButler ad-key="748912" /> -->
            <!-- <AdButler ad-key="749353" /> -->

            <components-manager group="homepage" />

            <!-- <live-sessions />
            <replays-uploads-without-scroll
                :title="'popular'"
                :order-by="'views_count'" />
            <creators-list />
            <h-p-channels />
            <organization-tiles />
            <footer-banner
                v-if="!currentUser && $t('views.home.footer_banner.title') != 'views.home.footer_banner.title'" />
            <replays-uploads-without-scroll
                :title="'discover'"
                :order-by="'listed_at'"
                :show-more="true" /> -->
            <share-modal />
            <user-info-modal />
            <booking-payment />
            <moderate-promo-weight />
        </div>
    </div>
</template>

<script>

import ShareModal from '@components/modals/ShareModal'
import UserInfoModal from '../../components/modals/UserInfoModal.vue'
import Anchors from "@components/main-page/Anchors.vue"
import ModeratePromoWeight from '@components/common/ModeratePromoWeight.vue'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    components: {
        ShareModal,
        UserInfoModal,
        Anchors,
        ModeratePromoWeight, BookingPayment
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPlatformOwner() {
            return this.currentUser?.platform_role == 'platform_owner'
        },
    },
    mounted() {
        this.$store.dispatch("Users/setPageOrganization", null)
    }
}
</script>
