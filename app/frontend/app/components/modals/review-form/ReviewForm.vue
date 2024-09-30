<template>
    <m-modal
        ref="reviewForm"
        class="RF__wrapper"
        @modalClosed="closeModal(true)">
        <div class="unobtrusive-flash-container" />
        <div class="RF">
            <div class="RF__image">
                <review-image />
            </div>
            <div class="RF__form">
                <div class="RF__form__title">
                    {{ title }} {{ $t('frontend.app.components.modals.review-form.review_form.feedback') }}
                </div>
                <m-form
                    ref="form"
                    v-model="disabled"
                    @onSubmit="editReview()">
                    <div class="RF__section__title">
                        {{ $t('frontend.app.components.modals.review-form.review_form.pls_rate_session') }}:
                    </div>
                    <div class="RF__section">
                        <div class="RF__categories">
                            <div
                                v-if="creator"
                                class="RF__category">
                                <div class="RF__category__title">
                                    {{ $t('frontend.app.components.modals.review-form.review_form.your_experience') }}
                                </div>
                                <div class="RF__category__subTitle">
                                    {{ $t('frontend.app.components.modals.review-form.review_form.review_does_not_affect_session_statistics') }}
                                </div>
                                <m-rating
                                    v-model="editable.immerss_experience"
                                    :editable="true" />
                            </div>
                            <div
                                v-else
                                class="RF__category">
                                <div class="RF__category__title">
                                    {{ $t('frontend.app.components.modals.review-form.review_form.rate_the_content') }}
                                </div>
                                <m-rating
                                    v-model="editable.quality_of_content"
                                    :editable="true" />
                            </div>
                            <div class="RF__smile" style="display:none">
                                <div class="RF__category">
                                    <div class="RF__category__title">
                                        {{ $t('frontend.app.components.modals.review-form.review_form.video_quality') }}
                                    </div>
                                    <m-rating
                                        v-model="editable.video_quality"
                                        :editable="true"
                                        :stars="false" />
                                </div>
                                <div class="RF__category">
                                    <div class="RF__category__title">
                                        {{ $t('frontend.app.components.modals.review-form.review_form.sound_quality') }}
                                    </div>
                                    <m-rating
                                        v-model="editable.sound_quality"
                                        :editable="true"
                                        :stars="false" />
                                </div>
                            </div>
                        </div>
                        <m-input
                            v-if="model && model.show_reviews"
                            v-model="editable.overall_experience_comment"
                            :errors="false"
                            :maxlength="1600"
                            :pure="true"
                            :rows="3"
                            :textarea="true"
                            placeholder="Tell us more..." />
                    </div>
                </m-form>
            </div>
        </div>
        <template #black_footer>
            <div class="RF__button__wrapper">
                <m-btn
                    class="RF__button"
                    @click="submit()">
                    {{ action }}
                </m-btn>
            </div>
        </template>
    </m-modal>
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
            return this.edit ? this.$t('frontend.app.components.modals.review-form.review_form.edit') : this.$t('frontend.app.components.modals.review-form.review_form.leave')
        },
        action() {
            return this.edit ? this.$t('frontend.app.components.modals.review-form.review_form.done') : this.$t('frontend.app.components.modals.review-form.review_form.send')
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
        this.$eventHub.$on('edit-reviewForm', (review) => {
            if (review) {
                var commentable_id = review.review.commentable_id
                var commentable_type = review.review.commentable_type
            } else {
                var commentable_id = this.model.id
                var commentable_type = this.model.type
            }
            Review.api().getReview({reviewable_id: commentable_id, reviewable_type: commentable_type}).then((res) => {
                this.review = res.response.data.response
                if (this.review) {
                    if (this.review.review?.id) {
                        this.edit = true
                        this.create = false
                        this.editable.overall_experience_comment = this.review.review.overall_experience_comment
                        this.editable.id = this.review.review.id
                        this.editable.reviewable_id = this.review.review.commentable_id
                        this.editable.reviewable_type = this.review.review.commentable_type
                    } else {
                        this.edit = false
                        this.create = true
                        this.editable.reviewable_id = this.model.id
                        this.editable.reviewable_type = this.model.type
                    }
                    this.editable.quality_of_content = this.review.rates.quality_of_content
                    this.editable.sound_quality = this.review.rates.sound_quality
                    this.editable.video_quality = this.review.rates.video_quality
                    this.editable.immerss_experience = this.review.rates.immerss_experience
                }
            }).catch(() => {
                this.edit = false
                this.create = true
                this.editable.reviewable_id = this.model.id
                this.editable.reviewable_type = this.model.type
            })
            this.openModal()
        })
        this.$eventHub.$on('leave-reviewForm', () => {
            this.edit = false
            this.create = true
            this.openModal()
        }),
        this.$eventHub.$on('leave-review-not-available', () => {
            if (this.$device.tablet() || this.$device.mobile()) {
                this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.rating_reviews_not_available'))
            }
        }),
        this.$eventHub.$on('try-leave-reviewForm', () => {
            if (this.currentUser && !this.currentUser.confirmed_at) {
                this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.have_confirm_email'))
            }
        })
    },
    methods: {
        submit() {
            this.$refs.form.onSubmit()
        },
        openModal() {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login", {
                    action: "close-and-emit",
                    event: 'closeAndReview',
                    data: {}
                })
                return
            }
            this.$refs.reviewForm.openModal()
        },
        closeModal(val = false) {
            this.edit = false
            this.create = false
            if (val) {
                this.editable = {}
            } else {
                this.$refs.reviewForm.closeModal()
            }
        },
        editReview() {
            if (this.currentUser && !this.currentUser.confirmed_at) {
                this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.have_confirm_email'))
                return
            }
            if (!this.editable.quality_of_content && !this.editable.immerss_experience) {
                this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.rating_first_then_review'))
                return
            }
            if (!this.editable.overall_experience_comment || this.editable.overall_experience_comment == '') {
                delete this.editable.overall_experience_comment
            }
            if (this.edit) {
                Review.api().updateReview(this.editable).then((res) => {
                    if (!this.creator && this.editable.overall_experience_comment && res.response.data.response.review.visible) {
                        this.$eventHub.$emit("review-updated", res.response.data.response)
                    }
                    this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.review_successfully_updated'), "success")
                    if (window.spaMode == "monolith") {
                        setTimeout(() => {
                            this.closeModal()
                        }, 800)
                    } else {
                        this.closeModal()
                    }
                }).catch(error => {
                    if (error?.response?.data?.message == 'stars value 0 is out of range 1...5' || error?.response?.data?.message == 'stars value  is out of range 1...5') {
                        this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.rating_first_then_review'))
                    } else if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.something_wrong_try_later'))
                    }
                })
            } else {
                this.sendReview()
            }
        },
        sendReview() {
            Review.api().createReview(this.editable).then((res) => {
                if (!this.creator && this.editable.overall_experience_comment) {
                    this.$eventHub.$emit("review-created", res.response.data.response)
                }
                this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.review_successfully_created'), "success")
                if (window.spaMode == "monolith") {
                    setTimeout(() => {
                        this.closeModal()
                    }, 800)
                } else {
                    this.closeModal()
                }
            }).catch(error => {
                if (error?.response?.data?.message == 'stars value 0 is out of range 1...5' || error?.response?.data?.message == 'stars value  is out of range 1...5') {
                    this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.rating_first_then_review'))
                } else if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash(this.$t('frontend.app.components.modals.review-form.review_form.something_wrong_try_later'))
                }
            })
        }
    }
}
</script>