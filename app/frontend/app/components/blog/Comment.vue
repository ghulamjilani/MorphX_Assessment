<template>
    <div
        :id="'comm' + comment.id"
        :class="{'comment__hide' : hide || (isVideo && !comment.visible)}"
        class="comment quill-text">
        <div class="comment__left">
            <m-avatar
                size="m"
                star-size="xs"
                :src="comment.user ? comment.user.avatar_url: ''"
                :can-book="comment.user.has_booking_slots"
                @click="creatorModal(comment.user)" />
        </div>
        <div class="comment__right">
            <div class="comment__header">
                <div class="comment__header__data">
                    <div class="comment__header__data__info">
                        <span class="comment__header__data__info__time">
                            <!-- <span>Owner • </span>  -->
                            <timeago
                                :auto-update="30"
                                :datetime="comment.created_at" />
                            <span v-if="comment.edited_at !== undefined && comment.edited_at !== null">
                                (<m-icon :size="'1rem'">GlobalIcon-Pensil2</m-icon> edited)
                            </span>
                            <span v-if="isVideo && !comment.visible">
                                (<m-icon :size="'1rem'">GlobalIcon-eye-off</m-icon> hidden)
                            </span>
                        </span>
                        <div
                            v-if="comment && comment.user"
                            class="comment__header__data__info__name"
                            @click="creatorModal(comment.user)">
                            {{ comment.user.public_display_name }} ({{ comment.user.slug }})
                        </div>
                    </div>
                    <div
                        v-if="canManageComment && currentUser"
                        class="comment__header__data__options">
                        <m-icon
                            class="comment__header__data__options__icon"
                            size="1.8rem"
                            @click="toggleOptions">
                            GlobalIcon-dots-3
                        </m-icon>
                        <div
                            v-show="commentOptions"
                            class="channelFilters__icons__options__cover"
                            @click="toggleOptions" />
                        <div
                            v-show="commentOptions"
                            class="channelFilters__icons__options">
                            <m-btn
                                v-if="currentUser.id !== comment.user.id && isVideo && comment.can_moderate"
                                :reset="true"
                                @click="hideComment">
                                {{ comment.visible ? 'Hide' : 'Show' }} Comment
                            </m-btn>
                            <m-btn
                                v-if="isBlog || (isVideo && comment.can_destroy)"
                                :reset="true"
                                @click="deleteComment">
                                Delete Comment
                            </m-btn>
                            <m-btn
                                v-if="currentUser.id === comment.user.id && canEdit"
                                :reset="true"
                                @click="editComment">
                                Edit Comment
                            </m-btn>
                            <!-- <a @click="hideComment()">{{hide ? 'Show Comment' : 'Hide Comment'}}</a> -->
                            <!-- <a >Block User</a> -->
                        </div>
                    </div>
                </div>
            </div>
            <div
                v-show="!editing"
                class="comment__body"
                v-html="comment.body" />
            <div
                v-show="editing"
                class="comment__body">
                <create-comment
                    ref="edit"
                    :editing="true"
                    :model="model"
                    :type="type"
                    @commented="updateComment" />
            </div>
            <!-- <link-preview
                v-if="comment.link_previews && comment.link_previews.length && getLinkPreview.title && getLinkPreview.url"
                :link="getLinkPreview"
                :manage="manage" /> -->
            <div>
                <div class="comment__buttons">
                    <button
                        v-if="!parentComment && currentUser && canEdit"
                        class="btn__reset cardMK2__post__body__button comment__reply"
                        @click="reply">
                        {{ createCommentOpen ? 'Close' : 'Reply' }}
                    </button>
                    <span v-else />
                    <button
                        v-if="comment.comments_count > 0"
                        class="btn__reset cardMK2__post__body__button comment__reply"
                        @click="loadSubComments(false)">
                        {{ subcommentsOpen ? 'Hide' : 'Show' }} Replies ({{ comment.comments_count }})
                    </button>
                </div>
                <create-comment
                    v-show="createCommentOpen"
                    ref="reply"
                    :model="model"
                    :post="post"
                    :reply-comment="parentComment ? parentComment : comment"
                    :type="type"
                    @commented="commented" />
                <div
                    v-if="subcommentsOpen && comment.comments_count > 0"
                    class="comment__2ndlevel">
                    <!-- <div class="comment__2ndlevel__show">Show comments ({{comment.comments_count}})</div> -->
                    <m-btn
                        v-if="subcomments.length < subcommentsCount"
                        class="comments__showMore"
                        type="secondary"
                        @click="loadSubComments(true)">
                        Show above
                    </m-btn>
                    <comment2nd
                        v-for="cm in subcomments"
                        :key="cm.comment.id"
                        :access-channel-manage="accessChannelManage"
                        :access-channel-moderate="accessChannelModerate"
                        :comment="cm.comment"
                        :manage="manage"
                        :model="model"
                        :parent-comment="comment"
                        :post="post"
                        :type="type"
                        @commented="commented"
                        @removed="subcommentRemoved"
                        @updated="(comm) => { updateSubComment(cm, comm) }" />
                    <!--  -->
                </div>
            </div>
        </div>
        <div
            v-if="dashboard"
            class="preview">
            <a
                :href="comment.commentable.absolute_path"
                target="_blank">
                <img
                    :src="comment.commentable.image_url"
                    alt="">
            </a>
            <a
                :href="comment.commentable.absolute_path"
                class="preview__name"
                target="_blank">
                {{ comment.commentable.always_present_title }}
            </a>
        </div>
    </div>
</template>

<script>
import LinkPreview from '../blog/LinkPreview'
import BlogComments from "@models/BlogComments"
import CreateComment from './CreateComment.vue'
import User from "@models/User"
import Comments from "@models/Comments"

export default {
    name: 'BlogComment',
    components: {LinkPreview, CreateComment, 'comment2nd': () => import('./Comment.vue')},
    props: {
        type: {
            type: String,
            default: 'blog'
        },
        dashboard: {
            type: Boolean,
            default: false
        },
        model: Object,
        post: Object,
        canEdit: {
            type: Boolean,
            default: true
        },
        manage: Boolean,
        comment: Object,
        parentComment: Object,
        accessChannelModerate: {
            type: Boolean,
            default: false
        },
        accessChannelManage: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            commentOptions: false,
            hide: false,
            showPreview: true,
            editing: false,
            createCommentOpen: false,
            subcomments: [],
            subcommentsOpen: false,
            subcommentsLimit: 5,
            subcommentsOffset: 0,
            subcommentsCount: 0
        }
    },
    computed: {
        canManageComment() {
            if (this.isBlog) {
                return (this.currentUser?.credentialsAbility?.can_moderate_blog_post && this.accessChannelModerate) || this.currentUser?.id === this.comment.user.id
            } else if (this.isVideo) {
                return this.currentUser?.id === this.comment.user.id || this.comment.can_destroy || this.comment.can_moderate
            }
        },
        getLinkPreview() {
            return this.comment.link_previews[0].link_preview
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isBlog() {
            return this.type == "blog"
        },
        isVideo() {
            let arr = ['Recording', 'Video', 'Session']
            return arr.includes(this.type)
        }
    },
    mounted() {
        this.subscribeToMentions()
    },
    methods: {
        toggleOptions() {
            this.commentOptions = !this.commentOptions
        },
        removePreview() {
            this.showPreview = false
        },
        reply() {
            this.createCommentOpen = !this.createCommentOpen
            this.$refs.reply.insertMention()
            // this.$flash("Wait for phase 2") // TODO: remove
        },
        creatorModal(creator) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: creator
            })
        },
        deleteComment() {
            if (this.isBlog) {
                BlogComments.api().deleteComment({id: this.comment.id}).then(res => {
                    this.$flash("Comment successfully removed", "success")
                    this.$emit("removed", this.comment)
                })
                    .catch(error => {
                        this.$flash(error.response.message)
                    })
            } else if (this.isVideo) {
                Comments.api().deleteComment({id: this.comment.id}).then(res => {
                    this.$emit("removed", this.comment)
                    this.$flash("Comment successfully removed", "success")
                })
                    .catch(error => {
                        this.$flash(error.response.message)
                    })
            }
        },
        hideComment() {
            let flag = !this.comment.visible
            this.commentOptions = false
            // this.editing = true
            this.comment.visible = flag
            Comments.api().updateComment({
                id: this.comment.id,
                visible: flag,
                commentable_type: this.comment.commentable_type,
                commentable_id: this.comment.commentable_id
            }).then(res => {
                this.$emit("updated", this.comment)
                this.$flash(flag ? "Comment successfully shown" : "Comment successfully hidden", "success")
            })
                .catch(error => {
                    this.$flash(error.response.message)
                })
            // this.$emit("updated", this.comment.comment)
        },
        editComment() {
            this.commentOptions = false
            this.editing = true
            this.$refs.edit.editComment(this.comment)
            setTimeout(() => {
                this.subscribeToMentions()
            }, 1000)
        },
        updateComment(comment) {
            this.$emit("updated", comment)
            this.editing = false
            setTimeout(() => {
                this.subscribeToMentions()
            }, 1000)
        },
        commented(comment) {
            this.createCommentOpen = false
            if (this.parentComment) {
                this.$emit("commented", comment)
            } else {
                this.createCommentOpen = false

                // if(this.isBlog) {
                //   this.subcomments.unshift({comment})
                // }
                // if(this.isVideo) {
                this.subcomments.push({comment})
                // }
                let cm = this.comment
                cm.comments_count += 1
                this.subcommentsOpen = true
                this.subcommentsOffset++
                this.subcommentsCount++
            }
            // [{comment}].concat(this.subcomments)
            // this.subcomments.push(comment)
        },
        loadSubComments(isMore = false) {
            if (!isMore) {
                this.subcommentsOffset = 0
            }
            if (this.subcommentsOpen && !isMore) {
                this.subcommentsOpen = false
            } else {
                if (this.isBlog) {
                    BlogComments.api().getComments({
                        // post_id: this.post.id,
                        limit: this.subcommentsLimit,
                        offset: this.subcommentsOffset,
                        commentable_type: "Blog::Comment",
                        commentable_id: this.comment.id,
                        order_by: "created_at"
                    }).then(res => {
                        if (isMore) {
                            this.subcomments = res.response.data.response.comments.reverse().concat(this.subcomments)
                            // this.subcomments = this.subcomments.concat(res.response.data.response.comments)
                            this.subcommentsOffset += this.subcommentsLimit
                        } else {
                            this.subcommentsOpen = true
                            this.subcomments = res.response.data.response.comments.reverse()
                            this.subcommentsOffset = this.subcommentsLimit
                            this.subcommentsCount = res.response.data?.count ? res.response.data?.count : res.response.data.pagination.count
                        }
                    })
                } else if (this.isVideo) {
                    Comments.api().getPublic({
                        commentable_type: "Comment",
                        commentable_id: this.comment.id,
                        limit: this.subcommentsLimit,
                        offset: this.subcommentsOffset,
                        order_by: "created_at",
                        order: 'desc'
                    }).then(res => {
                        if (isMore) {
                            this.subcomments = res.response.data.response.comments.reverse().concat(this.subcomments)
                            // this.subcomments = this.subcomments.concat(res.response.data.response.comments)
                            this.subcommentsOffset += this.subcommentsLimit
                        } else {
                            this.subcommentsOpen = true
                            this.subcomments = res.response.data.response.comments.reverse()
                            this.subcommentsOffset = this.subcommentsLimit
                            this.subcommentsCount = res.response.data?.count ? res.response.data?.count : res.response.data.pagination.count
                        }
                        this.subcomments.forEach(com => {
                            com.comment.user = com.user
                        })
                    })
                }
            }
        },
        subcommentRemoved(comment) {
            this.subcommentsOffset--
            this.subcommentsCount--
            this.subcomments = this.subcomments.filter(e => e.comment.id !== comment.id)
            let cm = this.comment
            cm.comments_count -= 1
        },
        updateSubComment(comment, newComment) {
            console.log(comment, newComment)
            comment.comment.body = newComment.body
            comment.comment.edited_at = newComment.edited_at
        },
        subscribeToMentions() {
            setTimeout(() => {
                document.querySelectorAll(`#comm${this.comment.id} .mention`).forEach(el => {
                    el.addEventListener("click", (e) => {
                        let id = e.target.parentNode?.dataset.id
                        if (!id) {
                            id = e.target?.dataset?.id
                        }
                        if (!id) {
                            id = e.path.find(elP => elP.className == "mention").dataset?.id
                        }
                        User.api().getUser({id}).then(res => {
                            this.$eventHub.$emit("open-modal:userinfo", {
                                notFull: true,
                                model: res.response.data.response.user
                            })
                        })
                    })
                })
            }, 500)
        }
    }
}
</script>