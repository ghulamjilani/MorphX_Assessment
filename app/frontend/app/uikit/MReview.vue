<template>
    <div
        :class="{'MReview__hidden' : !isShown}"
        class="MReview">
        <m-avatar
            class="MReview__left"
            size="l"
            star-size="s"
            :src="review.user.avatar_url"
            :can-book="review.user.has_booking_slots"
            @click="$emit('clickLogo', review)" />
        <div class="MReview__right">
            <div class="MReview__head">
                <div class="MReview__head__line">
                    <div
                        class="MReview__head__name"
                        @click="$emit('clickLogo', review)">
                        {{ userName }}
                    </div>
                    <span class="MReview__head__created"> {{ createdAt }} </span>
                    <span
                        :class="['MReview__head__hidden', {'visible' : !isShown}]">
                        <m-icon :size="'1.6rem'">GlobalIcon-eye-off</m-icon>
                    </span>
                    <div class="MReview__wrap__options">
                        <m-icon
                            v-if="myReview || review.review.can_moderate"
                            ref="dots"
                            class="MReview__options__icon"
                            size="1.8rem"
                            @click="toggleOptions">
                            GlobalIcon-dots-3
                        </m-icon>
                        <div
                            v-show="options"
                            v-click-outside="checkOption"
                            class="MReview__options">
                            <div
                                v-if="myReview"
                                class="MReview__options__button"
                                @click="openEdit()">
                                Edit
                            </div>
                            <div
                                v-if="myReview"
                                class="MReview__options__button"
                                @click="deleteReview()">
                                Delete
                            </div>
                            <div
                                v-if="!myReview && review.review.can_moderate && isShown"
                                class="MReview__options__button"
                                @click="hideReview()">
                                Hide
                            </div>
                            <div
                                v-if="!myReview && review.review.can_moderate && !isShown"
                                class="MReview__options__button"
                                @click="showReview()">
                                Show
                            </div>
                        </div>
                    </div>
                </div>

                <m-rating
                    :value="rating"
                    class="MReview__rating" />
            </div>
            <div class="MReview__right__body">
                <a
                    v-if="type == 'Channel' || type == 'Organization'"
                    :href="reviewableLink"
                    class="MReview__right__reviewable">{{ reviewableTitle }} • </a> {{ croppedDescription }}
            </div>
            <button
                v-if="description && description.length > cropReadMore"
                class="btn__reset ownerModal__readMore"
                @click="toggleReadMore">
                {{ readMore ? ' Read less' : ' Read more' }}
            </button>
        </div>
    </div>
</template>

<script>
import Review from '@models/Review'

import ClickOutside from "vue-click-outside"

export default {
    name: "MReview",
    directives: {
        ClickOutside
    },
    props: {
        review: {
            type: Object,
            default: null
        },
        reviewables: {
            type: String,
            default: null
        },
        type: {
            type: String,
            default: null
        },
        dashboard: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            options: false,
            cropReadMore: 140,
            readMore: false
        }
    },
    computed: {
        croppedDescription() {
            if (this.type == 'Channel' || this.type == 'Organization') {
                this.cropReadMore = 170 - this.reviewableTitle.length
            }
            if (this.description?.length <= this.cropReadMore) this.readMore = true
            return this.readMore ? this.description : this.description?.slice(0, this.cropReadMore) + "..."
        },
        isShown() {
            if (this.review.review.visible != undefined) {
                return this.review.review.visible
            } else {
                return true
            }
        },
        myReview() {
            return this.currentUser?.id == this.review?.user.id
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        createdAt() {
            return moment(this.review.review.created_at).format("DD.MM.YYYY")
        },
        description() {
            return this.review.review.overall_experience_comment
        },
        reviewableLink() {
            return this.review.reviewable.absolute_path
        },
        userLogo() {
            return this.review.user.avatar_url
        },
        userName() {
            return this.review.user.public_display_name
        },
        reviewableTitle() {
            return this.review.reviewable.always_present_title
        },
        rating() {
            if (this.review.rates) {
                if (this.review.rates.immerss_experience) {
                    return this.review.rates.immerss_experience
                } else {
                    return this.review.rates.quality_of_content
                }
            } else {
                return this.review.review.quality_of_content
            }
        }
    },
    methods: {
        toggleReadMore() {
            this.readMore = !this.readMore
        },
        checkOption(event) {
            if (!this.$refs.dots) return
            if (this.$refs.dots.$el == event.target) return
            this.options = false
        },
        toggleOptions() {
            this.options = !this.options
        },
        openEdit() {
            this.options = false
            this.$eventHub.$emit('edit-reviewForm', (this.review))
        },
        deleteReview() {
            this.options = false
            Review.api().destroyReview({
                reviewable_type: this.review.review.commentable_type,
                reviewable_id: this.review.review.commentable_id
            }).then((res) => {
                this.$emit('deleted', this.review)
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        hideReview() {
            this.options = false
            Review.api().updateReview({
                id: this.review.review.id,
                visible: false,
                reviewable_type: this.review.review.commentable_type,
                reviewable_id: this.review.review.commentable_id
            }).then((res) => {
                this.$emit('hiden', this.review)
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        showReview() {
            this.options = false
            Review.api().updateReview({
                id: this.review.review.id,
                visible: true,
                reviewable_type: this.review.review.commentable_type,
                reviewable_id: this.review.review.commentable_id
            }).then((res) => {
                this.$emit('show', this.review)
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        }
    }
}
</script>