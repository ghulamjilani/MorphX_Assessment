<template>
    <div
        id="anchorSection__reviews"
        :class="!isVideo ? 'mChannel__review mChannel__section anchorSection' : 'review__sessionPage'">
        <review-form
            v-if="!isVideo"
            ref="reviewForm"
            :model="model" />
        <div
            v-if="!isVideo"
            class="mChannel__label">
            {{ $t('channel_page.reviews') }}
        </div>
        <div
            v-else-if="!tabs"
            class="review__label">
            {{ $t('channel_page.reviews') }}
        </div>
        <div
            v-if="currentUser && (model.can_rate || session_review) && canCurrentUserReview"
            class="review__header">
            <div class="review__header__title">
                {{ $t('channel_page.leave_revieww') }}
            </div>
            <m-btn
                class="review__header__button"
                type="bordered"
                @click="leaveReview()">
                {{ $t('channel_page.leave_review') }}
            </m-btn>
        </div>
        <div
            v-if="reviewsList.length"
            class="review__wrapp">
            <div
                v-for="review in reviewsList"
                :key="review.review.id"
                class="review__section">
                <m-review
                    :monilit="monilit"
                    :review="review"
                    :type="model.type"
                    @clickLogo="openUser"
                    @deleted="reviewDeleted"
                    @hiden="reviewHiden"
                    @show="reviewShow" />
            </div>
        </div>
        <div
            v-else
            class="review__empty">
            {{ $t('channel_page.no_reviews') }} {{ isVideo && model.can_rate && canCurrentUserReview  ? $t('channel_page.first_review') : '' }}
        </div>
        <m-btn
            v-if="reviews.length > offset || showAll"
            class="review__show-more"
            type="secondary"
            @click="toggleShowAll">
            {{ showAll ? $t('channel_page.hide') : $t('channel_page.show_more') }}
        </m-btn>
    </div>
</template>

<script>
import Review from '@models/Review'
import ReviewForm from "@components/modals/review-form/ReviewForm"
export default {
    components: {ReviewForm},
    props: {
        model: Object,
        monilit: Boolean,
        tabs: Boolean
    },
    data() {
        return {
            session_review: false,
            minReviews: 6,
            offset: 6,
            showAll: false,
            reviews: [],
            loading: false,
            canCurrentUserReview: false
        }
    },
    computed: {
        token() {
            return getCookie('_unite_session_jwt')
        },
        reviewsList() {
            return this.showAll ? this.reviews :
                this.reviews.length > 0 ? this.reviews.slice(0, this.offset) : []
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isVideo() {
            let arr = ['Recording', 'Video', 'Session']
            return arr.includes(this.model.type)
        }
    },
    watch: {
        model: {
            handler() {
                this.$nextTick(() => {
                    if (this.model && this.model.id && this.model.type && !this.reviews.length && !this.loading) {
                        setTimeout(() => {
                            this.fetch()
                        }, 1500)
                    }
                })
            },
            deep: true,
            immediate: true
        },
        reviews: {
            handler(val) {
                if (!val.some((r) => r.review.user_id === this.currentUser?.id) && this.currentUser?.confirmed_at != null) {
                    this.canCurrentUserReview = true
                } else {
                    this.canCurrentUserReview = false
                }
            }
        }
    },
    mounted() {
        this.$eventHub.$on('session-review', () => {
            this.session_review = true
        })
        this.$eventHub.$on("review-updated", (val) => {
            this.reviewUpdated(val)
        })
        this.$eventHub.$on("review-created", (val) => {
            this.reviewCreated(val)
        })
        this.$eventHub.$on('fetch-reviews', () => {
            this.fetch()
        })
    },
    methods: {
        leaveReview() {
            this.$eventHub.$emit('edit-reviewForm')
        },
        reviewDeleted(review) {
            this.reviews = this.reviews.filter((r) => r.review.id != review.review.id)
        },
        reviewUpdated(review) {
            let r = this.reviews.find((rev) => rev.review.id == review.review.id)
            if (!r) {
                this.reviews.unshift(review)
            } else {
                r.review = review.review
                r.rates = review.rates
            }
        },
        reviewCreated(review) {
            this.reviews.unshift(review)
        },
        reviewHiden(review) {
            let r = this.reviews.find((r) => r.review.id == review.review.id)
            r.review.visible = false
            this.$flash("Review successfully hidden", "success")
        },
        reviewShow(review) {
            let r = this.reviews.find((r) => r.review.id == review.review.id)
            r.review.visible = true
            this.$flash("Review successfully shown", "success")
        },
        fetch() {
            if (this.loading) return
            this.loading = true
            if (this.currentUser) {
                Review.api().getUserParams({
                    scope: 'participant',
                    reviewable_type: this.model.type,
                    reviewable_id: this.model.id,
                    order: 'desc'
                }).then((res) => {
                    this.reviews = res.response.data.response.reviews
                    this.loading = false
                    if (this.model.type == 'Channel') this.$eventHub.$emit('channel-review', this.reviews)
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            } else {
                Review.api().getPublic({
                    reviewable_type: this.model.type,
                    reviewable_id: this.model.id,
                    order: 'desc'
                }).then((res) => {
                    this.reviews = res.response.data.response.reviews
                    this.loading = false
                    if (this.model.type == 'Channel') this.$eventHub.$emit('channel-review', this.reviews)
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
        },
        toggleShowAll() {
            if (this.showAll) {
                this.offset -= this.minReviews
                this.showAll = false
            } else {
                this.offset += this.minReviews
                this.showAll = true
            }
        },
        openUser(review) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: review.user
            })
        }
    }
}
</script>
