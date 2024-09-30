<template>
    <div class="RF RF__monilit">
        <div class="unobtrusive-flash-container" />
        <div class="RF__image">
            <review-image />
        </div>
        <div class="RF__form">
            <div class="RF__form__title">
                {{ title }} Feedback
            </div>
            <m-form
                ref="form"
                v-model="disabled"
                @onSubmit="editReview()">
                <div class="RF__section">
                    <div class="RF__categories">
                        <div
                            v-if="creator"
                            class="RF__category RF__cat">
                            <div class="RF__category__title">
                                How was your experience?*
                            </div>
                            <m-rating
                                v-model="editable.immerss_experience"
                                :editable="true" />
                        </div>
                        <div
                            v-else
                            class="RF__category RF__cat">
                            <div class="RF__category__title">
                                Rate the content*
                            </div>
                            <m-rating
                                v-model="editable.quality_of_content"
                                :editable="true" />
                        </div>
                        <div class="RF__smile" style="display:none">
                            <div class="RF__category">
                                <div class="RF__category__title">
                                    Video Quality
                                </div>
                                <m-rating
                                    v-model="editable.video_quality"
                                    :editable="true"
                                    :stars="false" />
                            </div>
                            <div class="RF__category">
                                <div class="RF__category__title">
                                    Sound Quality
                                </div>
                                <m-rating
                                    v-model="editable.sound_quality"
                                    :editable="true"
                                    :stars="false" />
                            </div>
                        </div>
                    </div>
                    <m-input
                        v-if="model.show_reviews"
                        v-model="editable.overall_experience_comment"
                        :errors="false"
                        :maxlength="1600"
                        :pure="true"
                        :rows="2"
                        :textarea="true"
                        placeholder="Tell us more..." />
                </div>
            </m-form>
            <div class="RF__button__wrapper">
                <m-btn
                    class="RF__button"
                    @click="submit()">
                    {{ action }}
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
import Review from '@models/Review'
import ReviewImage from "./ReviewImage.vue"

export default {
    components: {ReviewImage},
    props: {
        model: Object
    },
    data() {
        return {
            disabled: false,
            create: false,
            edit: false,
            editable: {
                id: null,
                quality_of_content: null,
                overall_experience_comment: null,
                reviewable_type: null,
                reviewable_id: null,
                sound_quality: null,
                video_quality: null,
                immerss_experience: null
            },
            review: {}
        }
    },
    computed: {
        title() {
            return this.edit ? 'Edit' : 'Leave'
        },
        action() {
            return this.edit ? 'Done' : 'Send'
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        creator() {
            if (this.review.reviewable) {
                return this.review.reviewable.creator_id == this.currentUser.id
            } else {
                return this.model ? this.model.creator_id == this.currentUser?.id : false
            }
        }
    },
    mounted() {
        if (this.review.review) {
            var commentable_id = this.review.review.commentable_id
            var commentable_type = this.review.review.commentable_type
        } else {
            var commentable_id = this.model.id
            var commentable_type = this.model.type
        }
        Review.api().getReview({reviewable_id: commentable_id, reviewable_type: commentable_type}).then((res) => {
            this.review = res.response.data.response
            if (this.review?.review?.id) {
                this.edit = true
                this.create = false
                this.editable.overall_experience_comment = this.review.review.overall_experience_comment
                this.editable.quality_of_content = this.review.rates.quality_of_content
                this.editable.id = this.review.review.id
                this.editable.reviewable_id = this.review.review.commentable_id
                this.editable.reviewable_type = this.review.review.commentable_type
                this.editable.sound_quality = this.review.rates.sound_quality
                this.editable.video_quality = this.review.rates.video_quality
                this.editable.immerss_experience = this.review.rates.immerss_experience
            } else {
                this.edit = false
                this.create = true
                this.editable.reviewable_id = this.model.id
                this.editable.reviewable_type = this.model.type
                if(this.review.rates.quality_of_content) this.editable.quality_of_content = this.review.rates.quality_of_content
                if(this.review.rates.immerss_experience) this.editable.immerss_experience = this.review.rates.immerss_experience
            }
        }).catch(() => {
            this.edit = false
            this.create = true
            this.editable.reviewable_id = this.model.id
            this.editable.reviewable_type = this.model.type
        })
        this.$eventHub.$on('leave-reviewForm', () => {
            this.edit = false
            this.create = true
            this.openModal()
        })
    },
    methods: {
        submit() {
            this.$refs.form.onSubmit()
        },
        editReview() {
            if (this.currentUser && !this.currentUser.confirmed_at) {
                this.$flash('You have to confirm your email address before continuing')
                return
            }
            if (!this.editable.quality_of_content && !this.editable.immerss_experience) {
                this.$flash('Choose a rating first, then add a review.')
                return
            }
            if (!this.editable.overall_experience_comment || this.editable.overall_experience_comment == '') {
                delete this.editable.overall_experience_comment
            }
            if (this.edit) {
                Review.api().updateReview(this.editable).then((res) => {
                    document.location.reload()
                }).catch(error => {
                    if (error?.response?.data?.message == 'stars value 0 is out of range 1...5' || error?.response?.data?.message == 'stars value  is out of range 1...5') {
                        this.$flash('Choose a rating first, then add a review.')
                    } else if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            } else {
                this.sendReview()
            }

        },
        sendReview() {
            Review.api().createReview(this.editable).then((res) => {
                document.location.reload()
            }).catch(error => {
                if (error?.response?.data?.message == 'stars value 0 is out of range 1...5' || error?.response?.data?.message == 'stars value  is out of range 1...5') {
                    this.$flash('Choose a rating first, then add a review.')
                } else if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        }
    }
}
</script>