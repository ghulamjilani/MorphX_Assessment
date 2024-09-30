<template>
    <div class="reviewsCommentsSection__wrapper">
        <m-tabs v-if="isTabs">
            <m-tab
                v-if="model.show_comments"
                title="Comments">
                <comments
                    :model="model"
                    :tabs="isTabs" />
            </m-tab>
            <m-tab
                v-if="model.show_reviews"
                title="Reviews">
                <reviews
                    :model="model"
                    :tabs="isTabs" />
            </m-tab>
            <m-tab
				v-if="showPolls"
                title="Polls"
				additionalClass="pollsTitleTab">
                <polls
                    :model="model"
                    :tabs="isTabs" />
            </m-tab>
        </m-tabs>
        <comments
            v-if="!isTabs && model.show_comments"
            :model="model"
            :tabs="isTabs" />
        <reviews
            v-if="!isTabs && model.show_reviews"
            :model="model"
            :tabs="isTabs" />
        <polls
            v-if="!isTabs && showPolls"
            :model="model"
            :tabs="false" />
        <user-info-modal
            :monolit="true"
            :owner="currentUser"
            :token="token" />
        <review-form
            ref="reviewForm"
            :model="model" />
        <create-poll
            :model-id="model.id"
            :model-type="'Session'"
            :can-create="isPresenter && model.type === 'Session'"/>
        <share-modal />
        <booking-payment />
    </div>
</template>

<script>
import UserInfoModal from '../modals/UserInfoModal.vue'
import ReviewForm from "@components/modals/review-form/ReviewForm"
import Comments from './Comments.vue'
import Reviews from './Reviews.vue'
import Polls from './Polls.vue'
import ShareModal from '../modals/ShareModal.vue'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"
import CreatePoll from '@components/polls/CreatePoll.vue'

export default {
    components: {Reviews, Comments, Polls, UserInfoModal, ReviewForm, ShareModal, BookingPayment, CreatePoll},
    props: {
        model: Object
    },
    computed: {
        isTabs() {
            let arr = [this.model.show_comments, this.model.show_reviews, this.showPolls]
            return arr.filter(item => item).length > 1
        },
        token() {
            return getCookie('_unite_session_jwt')
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.currentUser && this.currentUser?.id == Immerss?.session?.organizer_id
        },
        showPolls() {
            return this.model.type !== "Recording"
        }
    }
}
</script>

