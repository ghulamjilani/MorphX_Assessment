<template>
    <div class="videoComments">
        <div
            v-if="!tabs"
            class="review__label">
            Comments
        </div>
        <create-comment
            v-show="currentUser"
            :class="{'cardMK2__post__comment__disable' : !currentUser}"
            :model="model"
            :post="{}"
            :type="model.type"
            @commented="commented" />
        <!-- :accessChannelManage="accessChannelManage" :accessChannelModerate="accessChannelModerate" -->
        <div
            v-if="!currentUser"
            class="videoComments__notAuthorized">
            We'd love your feedback! <span @click="openAuth">Sign Up</span> here to comment!
        </div>
        <!-- <div class="videoComments__notAuthorized" v-if="currentUser && !currentUser.confirmed_at">
      Please confirm your email address!
    </div> -->
        <div
            v-if="!comments || comments.length == 0"
            class="videoComments__empty">
            No comments yet... Be first to comment!
        </div>
        <comment
            v-for="comment in comments"
            :key="comment.comment.id"
            :comment="comment.comment"
            :manage="false"
            :model="model"
            :post="{}"
            :type="model.type"
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
import Comments from "@models/Comments"
import Comment from '../blog/Comment.vue'
import CreateComment from '../blog/CreateComment.vue'

export default {
    components: {Comment, CreateComment},
    props: {
        model: Object,
        tabs: Boolean
    },
    data() {
        return {
            comments: [],
            commentsCount: -1,
            videoCommentsCount: -1,
            commentsLimit: 5,
            commentsOffset: 0
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.getComments()
    },
    methods: {
        getComments(isMore = false) {
            if (!isMore) {
                this.commentsOffset = 0
            }

            Comments.api().getPublic({
                commentable_type: this.model.type,
                commentable_id: this.model.id,
                limit: this.commentsLimit,
                offset: this.commentsOffset,
                order_by: "created_at",
                order: 'desc'
            }).then(res => {
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
        openAuth() {
            if ($('#signupPopup')) {
                window.eventHub.$emit("open-modal:auth", "sign-up")
                // $('#signupPopup').modal('show');
            }
        }
    }
}
</script>

