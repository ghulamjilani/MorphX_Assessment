<template>
    <div id="dashboardReviews">
        <div class="dashboardReviews__filters">
            <review-filter @updateSearch="updateSearch" />
        </div>
        <m-loader
            v-if="loading"
            :global="false" />
        <div
            v-if="!loading && (!comments || comments.length == 0)"
            class="videoComments__empty">
            No comments yet...
        </div>
        <comment
            v-for="comment in comments"
            :key="comment.comment.id"
            :comment="comment.comment"
            :dashboard="true"
            :manage="false"
            :model="{commentable_type: comment.comment.commentable_type, commentable_id: comment.comment.commentable_id}"
            :post="{}"
            :type="comment.comment.commentable_type"
            @removed="commentRemoved"
            @updated="(comm) => { updateComment(comment, comm) }" />
        <m-btn
            v-if="commentsOffset < videoCommentsCount"
            class="comments__showMore"
            type="secondary"
            @click="getComments(true)">
            Show more
        </m-btn>
    </div>
</template>

<script>
import ReviewFilter from '../reviews/ReviewFilter.vue'
import Comment from '@components/blog/Comment.vue'
import Comments from "@models/Comments"

export default {
    name: 'CommentsDashboardContent',
    components: {ReviewFilter, Comment},
    data() {
        return {
            loading: false,
            comments: [],
            commentsCount: -1,
            videoCommentsCount: -1,
            commentsLimit: 20,
            commentsOffset: 0,
            reviewableType: "Organization",
            lastSearchParams: null
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
    mounted() {
        if (this.currentUser) {
            this.loading = true
            this.getComments()
        }
    },
    methods: {
        updateSearch(search) {
            this.comments = []
            if (search.reviewable_type) this.reviewableType = search.reviewable_type
            this.lastSearchParams = search
            this.getComments(false, search)
        },
        openFilters() {
            this.$refs.filters.openFilters()
        },
        getComments(isMore = false, search = null) {
            if (!isMore) {
                this.commentsOffset = 0
            }

            let data = {
                commentable_id: this.currentOrganization.id,
                commentable_type: "Organization",
                limit: this.commentsLimit,
                offset: this.commentsOffset,
                order_by: "created_at",
                order: 'desc'
            }
            // if(search) {
            //   data = {...data, ...search};
            //   if(search.reviewable_id) data.commentable_id = search.reviewable_id
            //   if(search.reviewable_type) data.commentable_type = search.reviewable_type
            //   if(search.status) {
            //     data.visible = search.status == 'published'
            //   }
            // }
            if (this.lastSearchParams) {
                data = {...data, ...this.lastSearchParams}
                if (this.lastSearchParams.reviewable_id) data.commentable_id = this.lastSearchParams.reviewable_id
                if (this.lastSearchParams.reviewable_type) data.commentable_type = this.lastSearchParams.reviewable_type
                if (this.lastSearchParams.visible) data.visible = this.lastSearchParams.visible == 'true'
                if (this.lastSearchParams.created_at_from) data.created_after = this.lastSearchParams.created_at_from
                if (this.lastSearchParams.created_at_to) data.created_before = this.lastSearchParams.created_at_to
            }

            Comments.api().getUser(data).then(res => {
                this.loading = false
                if (isMore) {
                    this.comments = this.comments.concat(res.response.data.response.comments)
                    this.commentsOffset += this.commentsLimit
                } else {
                    this.comments = res.response.data.response.comments
                    this.commentsOffset = this.commentsLimit
                    // this.commentsCount = this.post.comments_count
                    this.videoCommentsCount = res.response.data.pagination.count
                }
                this.comments.forEach(com => {
                    com.comment.user = com.user
                    com.comment.commentable = com.commentable
                })
            })
        },
        commentRemoved(comment) {
            this.commentsOffset--
            this.commentsCount--
            this.videoCommentsCount--
            this.comments = this.comments.filter(e => e.comment.id !== comment.id)
        },
        updateComment(comment, newComment) {
            comment.comment.body = newComment.body
            comment.comment.updated_at = newComment.updated_at
        },
        commented(comment) {
            this.comments = [{comment}].concat(this.comments)
            this.commentsOffset += 1
            this.commentsCount += 1
            this.videoCommentsCount += 1
        },
        toggleShowAll() {
            this.offset += this.minReviews
            if (this.comments.length < this.offset) {
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

