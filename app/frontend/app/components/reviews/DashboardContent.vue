<template>
    <div id="dashboardReviews">
        <review-form ref="reviewForm" />
        <div class="dashboardReviews__filters">
            <review-filter @updateSearch="updateSearch" />
        </div>
        <div
            id="anchorSection__reviews"
            class="mChannel__review mChannel__section anchorSection">
            <div
                v-if="reviewsList.length"
                class="review__wrapp">
                <div
                    v-for="review in reviewsList"
                    :key="review.id"
                    class="review__section">
                    <m-review
                        :dashboard="true"
                        :review="review"
                        :type="reviewableType"
                        @clickLogo="openUser"
                        @deleted="reviewDeleted"
                        @hiden="reviewHiden"
                        @show="reviewShow" />
                </div>
            </div>
            <div
                v-else
                class="review__empty">
                Nobody left a review yet...
            </div>
            <m-btn
                v-if="!loading && reviewsOffset < count"
                class="review__show-more"
                type="secondary"
                @click="fetch(true)">
                {{ showAll ? 'Hide' : 'Show more' }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import ReviewFilter from '../../components/reviews/ReviewFilter.vue'
import ReviewForm from "@components/modals/review-form/ReviewForm"
import Review from "@models/Review"

export default {
    components: {ReviewFilter, ReviewForm},
    data() {
        return {
            reviews: [],
            limitReviews: 20,
            offset: 0,
            count: -1,
            reviewsOffset: -1,
            showAll: false,
            reviewableType: "Organization",
            lastSearchParams: null,
            loading: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        reviewsList() {
            return this.showAll ? this.reviews :
                this.reviews//.length > 0 ? this.reviews.slice(0, this.offset) : [];
        }
    },
    watch: {
        currentUser(val) {
            if (val) {
                this.fetch()
            }
        }
    },
    mounted() {
        if (this.currentUser) {
            this.fetch()
        }
    },
    methods: {
        reviewDeleted(review) {
            this.reviews = this.reviews.filter((r) => r.review.id != review.review.id)
            this.$flash("Review successfully removed", "success")
        },
        reviewUpdated(review) {
            let r = this.reviews.find((r) => r.review.id == review.review.id)
            r.review = review.review
            r.rates = review.rates
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
        updateSearch(search) {
            if (search.reviewable_type) this.reviewableType = search.reviewable_type
            this.lastSearchParams = search
            this.fetch()
        },
        openFilters() {
            this.$refs.filters.openFilters()
        },
        fetch(isMore = false) {
            this.loading = true
            if (!isMore) {
                this.reviewsOffset = 0
            }
            let data = {
                reviewable_id: this.currentOrganization.id,
                reviewable_type: "organization",
                limit: this.limitReviews,
                offset: this.reviewsOffset,
                order_by: "created_at",
                order: 'desc',
                scope: 'participant'
            }
            if (this.lastSearchParams) {
                data = {...data, ...this.lastSearchParams}
            }
            Review.api().getUserParams(data).then((res) => {
                this.loading = false
                if (isMore) {
                    this.reviews = this.reviews.concat(res.response.data.response.reviews)
                    this.reviewsOffset += this.limitReviews
                } else {
                    this.reviews = res.response.data.response.reviews
                    this.reviewsOffset = this.limitReviews
                    // this.commentsCount = this.post.comments_count
                    this.count = res.response.data.pagination.count
                }
            })
        },
        toggleShowAll() {
            this.offset += this.minReviews
            if (this.reviews.length < this.offset) {
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
