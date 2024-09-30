<template>
    <div>
        <div
            :id="'post' + post.id"
            :class="{'cardMK2__post__body__wrapper': !postPage}">
            <div
                :class="{'cardMK2__post__body__postPage': postPage}"
                class="cardMK2__post__body">
                <div
                    v-if="post.user"
                    v-show="headerShow()"
                    :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}"
                    class="cardMK2__post__body__header">
                    <div
                        v-if="!post.hide_author || managePage"
                        class="cardMK2__post__body__header__avatar">
                        <m-avatar
                            size="m"
                            star-size="s"
                            :src="post.user.avatar_url"
                            :can-book="post.user.has_booking_slots"
                            @click="creatorModal(post.user)" />
                    </div>
                    <div class="cardMK2__post__body__header__info">
                        <div
                            :style="{marginLeft: !post.hide_author || managePage ? '1.2rem' : '0'}"
                            class="cardMK2__post__body__header__info__owner">
                            <span>
                                <span
                                    v-if="post.hide_author && !managePage && !((isHidden && !post.published_at) || isDraft)">Published: </span>
                                <span v-if="(isHidden && !post.published_at) || isDraft">Not publish</span>
                                <timeago
                                    v-else
                                    :auto-update="30"
                                    :datetime="post.published_at ? post.published_at : post.updated_at" />
                            </span>
                            <div
                                v-if="!post.hide_author || managePage"
                                class="cardMK2__post__body__header__title"
                                @click="creatorModal(post.user)">
                                {{ post.user.public_display_name }} ({{ post.user.slug }})
                            </div>
                        </div>
                        <div class="cardMK2__post__body__header__info__options">
                            <m-icon
                                v-if="isArchived"
                                class="cardMK2__post__body__header__info__options__icon"
                                size="1.8rem">
                                GlobalIcon-bag
                            </m-icon>
                            <span
                                v-if="isArchived"
                                v-show="!mobile"
                                class="cardMK2__post__body__header__info__options__hiddenPost">Archived</span>

                            <div
                                v-if="isHidden"
                                :style="{ whiteSpace: 'nowrap' }">
                                <m-icon
                                    class="cardMK2__post__body__header__info__options__icon GlobalIcon-eye-off"
                                    size="1.8rem"
                                    @click="$emit('hide')" />
                                <span
                                    v-show="!mobile"
                                    class="cardMK2__post__body__header__info__options__hiddenPost hiddenPost">Hidden</span>
                            </div>

                            <div
                                v-if="isDraft"
                                :style="{ whiteSpace: 'nowrap' }">
                                <m-icon
                                    class="cardMK2__post__body__header__info__options__icon GlobalIcon-pencil"
                                    size="1.8rem"
                                    @click="editPost()" />
                                <span
                                    v-show="!mobile"
                                    class="cardMK2__post__body__header__info__options__hiddenPost">Draft</span>
                            </div>

                            <div
                                v-if="!isDraft"
                                class="cardMK2__post__body__header__info__options__watchCount">
                                <m-icon
                                    class="GlobalIcon-eye-2"
                                    size="1.8rem" />
                                <span
                                    class="cardMK2__post__body__header__info__options__watchCountText"> {{ post.views_count }} </span>
                            </div>

                            <div
                                v-if="!isDraft"
                                class="cardMK2__post__body__header__info__options__like">
                                <m-icon
                                    :class="{liked: post.liked}"
                                    :name="post.liked ? 'GlobalIcon-heart-full' : 'GlobalIcon-heart'"
                                    class="cardMK2__post__body__header__info__options__heart"
                                    size="1.8rem"
                                    @click="like" />
                                <span class="cardMK2__post__body__header__info__options__likeCount">{{
                                    post.likes_count
                                }}</span>
                            </div>

                            <m-icon
                                v-if="!isDraft && !isArchived"
                                v-show="!isHidden"
                                class="cardMK2__post__body__header__info__options__icon"
                                size="1.8rem"
                                @click="toggleShare">
                                GlobalIcon-share
                            </m-icon>

                            <div
                                v-show="share"
                                class="channelFilters__icons__options__cover"
                                @click="toggleShare" />
                            <div
                                v-show="share"
                                class="cardMK2__post__share">
                                <div class="cardMK2__post__share__title">
                                    Share Post
                                </div>
                                <div class="cardMK2__post__share__body">
                                    <!-- <a v-for="social in social_links" :key="social.id" :href="social.url" class="ownerModal__social"> -->
                                    <a
                                        v-for="social in social_links"
                                        :key="social.provider"
                                        :href="social.url"
                                        class="cardMK2__post__share__icon"
                                        target="_blank">
                                        <m-icon size="1.6rem">
                                            GlobalIcon-{{ social.provider }}
                                        </m-icon>
                                    </a>
                                </div>
                            </div>
                            <m-icon
                                v-if="(accessChannelModerate && isCanModerateBlogPost) || (accessChannelManage && isCanManagePost)"
                                class="cardMK2__post__body__header__info__options__icon"
                                size="1.8rem"
                                @click="toggleOptions">
                                GlobalIcon-dots-3
                            </m-icon>
                        </div>
                    </div>
                </div>
                <div
                    v-show="postOptions"
                    class="channelFilters__icons__options__cover"
                    @click="toggleOptions" />
                <div
                    v-show="postOptions"
                    class="channelFilters__icons__options">
                    <m-btn
                        v-if="!isArchived"
                        :reset="true"
                        @click="editPost()">
                        Edit Post
                    </m-btn>
                    <m-btn
                        v-if="!isDraft && !isArchived"
                        :reset="true"
                        @click="hidePost()">
                        {{ isHidden ? 'Show Post' : 'Hide Post' }}
                    </m-btn>
                    <m-btn
                        v-if="isDraft && !isArchived"
                        :reset="true"
                        @click="publishPost()">
                        Publish Post
                    </m-btn>
                    <m-btn
                        v-if="!isArchived && !isDraft"
                        :reset="true"
                        @click="archivePost">
                        Archive Post
                    </m-btn>
                    <m-btn
                        v-if="isDraft && !isArchived"
                        :reset="true"
                        @click="removePost(true)">
                        Delete Post
                    </m-btn>

                    <m-btn
                        v-if="isArchived"
                        :reset="true"
                        @click="publishPost(true)">
                        Restore as published
                    </m-btn>
                    <m-btn
                        v-if="isArchived"
                        :reset="true"
                        @click="hidePost(true)">
                        Restore as hidden
                    </m-btn>
                    <m-btn
                        v-if="isArchived"
                        :reset="true"
                        @click="removePost">
                        Delete Post
                    </m-btn>
                </div>
                <edit-post-modal
                    ref="editPostModal"
                    :edit-post="post"
                    @updated="update" />
                <div :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}">
                    <div
                        v-if="postPage"
                        class="cardMK2__post__body__title cardMK2__post__body__title__postPage">
                        {{ post.title }}
                    </div>
                    <router-link
                        v-else
                        :to="{ name: 'post-slug', params: { organization, slug: post.slug }}"
                        class="cardMK2__post__body__title text-ellipsis">
                        {{ post.title }}
                    </router-link>
                    <div
                        v-if="post.body_preview && !postPage"
                        id="read_more"
                        :class="{'cardMK2__post__body__description__dashboard': dashboard}"
                        class="cardMK2__post__body__description cardMK2__post__body__description__channel"
                        v-html="purgeBody()" />
                    <div
                        v-if="post.body && postPage"
                        :class="{'cardMK2__post__body__description__dashboard': dashboard, 'cardMK2__post__body__description__postPage': postPage}"
                        class="cardMK2__post__body__description quill-text"
                        v-html="post.body" />
                    <link-preview
                        v-if="post.featured_link_preview && postPage"
                        :link="post.featured_link_preview" />
                    <div
                        v-if="postPage"
                        class="cardMK2__post__body__tags">
                        <m-chips
                            v-for="(tag, index) in post.tag_list"
                            :key="index"
                            class="tagsMK2__tag">
                            {{ tag }}
                        </m-chips>
                    </div>
                </div>
            </div>
            <router-link
                v-if="!postPage && smallText"
                :class="{'cardMK2__post__body__readMore__dashboard': dashboard, 'postWrapper__hide' : (isHidden || isArchived)}"
                :to="{ name: 'post-slug', params: { organization, slug: post.slug }}"
                class="cardMK2__post__body__readMore">
                <button class="btn__reset cardMK2__post__body__button">
                    Read more
                </button>
            </router-link>
            <div
                v-show="mobile && !isDraft"
                :class="{'cardMK2__post__body__options__dashboard': dashboard, 'postWrapper__hide' : isHidden}"
                class="cardMK2__post__body__options cardMK2__post__body__options__likeShare">
                <div class="cardMK2__post__body__header__info__options__like cardMK2__post__body__header__info__bottomStats">
                    <m-icon
                        :name="'GlobalIcon-eye-2'"
                        class="cardMK2__post__body__header__info__options__heart"
                        size="1.8rem"/>
                    <span class="cardMK2__post__body__header__info__options__likeCount">{{ post.views_count }}</span>
                </div>
                <div class="cardMK2__post__body__header__info__options__like cardMK2__post__body__header__info__bottomStats">
                    <m-icon
                        :class="{liked: post.liked}"
                        :name="post.liked ? 'GlobalIcon-heart-full' : 'GlobalIcon-heart'"
                        class="cardMK2__post__body__header__info__options__heart"
                        size="1.8rem"
                        @click="like" />
                    <span class="cardMK2__post__body__header__info__options__likeCount">{{ post.likes_count }}</span>
                </div>
                <div
                    v-show="!isHidden && !isArchived"
                    class="cardMK2__post__body__header__info__bottomStats">
                    <m-icon
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem"
                        @click="toggleShare">
                        GlobalIcon-share
                    </m-icon>
                </div>
                <div
                    v-show="share"
                    class="channelFilters__icons__options__cover"
                    @click="toggleShare" />
                <div
                    v-show="share"
                    class="cardMK2__post__share">
                    <div class="cardMK2__post__share__title">
                        Share Post
                    </div>
                    <div class="cardMK2__post__share__body">
                        <!-- <a v-for="social in social_links" :key="social.id" :href="social.url" class="ownerModal__social"> -->
                        <a
                            v-for="social in social_links"
                            :key="social.provider"
                            :href="social.url"
                            class="cardMK2__post__share__icon"
                            target="_blank">
                            <m-icon size="1.6rem">
                                GlobalIcon-{{ social.provider }}
                            </m-icon>
                        </a>
                    </div>
                </div>
            </div>
            <div
                :class="{'cardMK2__post__body__options__dashboard': dashboard, 'cardMK2__post__body__options__postPage': postPage, 'postWrapper__hide' : isHidden}"
                class="cardMK2__post__body__options">
                <div class="cardMK2__post__body__options__comments">
                    Comments ({{ postCommentsCount === -1 ? post.comments_count : postCommentsCount }})
                </div>
                <div>
                    <button
                        v-if="(postCommentsCount === -1 ? post.comments_count : postCommentsCount) > 0"
                        class="btn__reset cardMK2__post__body__button"
                        @click="toggleComments()">
                        {{ showComments ? 'Hide' : 'Show' }}
                    </button>
                    <button
                        v-else-if="isPublished"
                        class="btn__reset cardMK2__post__body__button"
                        @click="toggleComments()">
                        <m-icon
                            v-if="!showComments"
                            class="cardMK2__post__body__options__comments__createComment">
                            GlobalIcon-message-square
                        </m-icon>
                        {{ showComments ? 'Hide' : 'Comment' }}
                    </button>
                </div>
            </div>
        </div>
        <edit-post-modal
            ref="editPostModal"
            :edit-post="post"
            @updated="update" />
        <div
            v-if="showComments"
            :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}"
            class="cardMK2__post__comments">
            <div class="cardMK2__post__comment">
                <div @click="checkUser($event)">
                    <create-comment
                        v-if="isPublished"
                        :class="{'cardMK2__post__comment__disable' : !currentUser}"
                        :post="post"
                        @commented="commented" />
                </div>
                <comment
                    v-for="comment in comments"
                    :key="comment.comment.id"
                    :access-channel-manage="accessChannelManage"
                    :access-channel-moderate="accessChannelModerate"
                    :comment="comment.comment"
                    :manage="manage"
                    :post="post"
                    :can-edit="isPublished"
                    @removed="commentRemoved"
                    @updated="(comm) => { updateComment(comment, comm) }" />
                <m-btn
                    v-if="commentsOffset < postCommentsCount"
                    class="comments__showMore"
                    type="secondary"
                    @click="getComments(true)">
                    Show more
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
import Comment from '../blog/Comment'
import EditPostModal from '../blog/EditPostModal'
import LinkPreview from '../blog/LinkPreview'
import CreateComment from '../blog/CreateComment'
import User from "@models/User"
import BlogComments from "@models/BlogComments"
import Share from "@models/Share"

export default {
    components: {Comment, EditPostModal, LinkPreview, CreateComment},
    props: {
        post: Object,
        orientation: String,
        mobile: Boolean,
        dashboard: Boolean,
        hide: Boolean,
        postPage: Boolean,
        manage: Boolean,
        managePage: Boolean,
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
            postOptions: false,
            share: false,
            commentPost: '',
            readMore: false,
            showPreview: true,
            showComments: false,
            smallText: true,
            comments: [],
            commentsCount: -1,
            postCommentsCount: -1,
            commentsLimit: 3,
            commentsOffset: 0,
            social_links: [
                {id: 1, url: `https://www.facebook.com/sharer.php?u=`, provider: 'facebook'},
                {id: 2, url: 'https://twitter.com/intent/tweet', provider: 'twitter'},
                {id: 3, url: 'https://www.linkedin.com/shareArticle', provider: 'linkedin'},
                {id: 4, url: 'https://www.tumblr.com/widgets/share/tool', provider: 'tumblr'},
                {id: 5, url: 'http://pinterest.com/pin/create/button/', provider: 'pinterest'},
                {id: 6, url: 'https://ssl.reddit.com/submit', provider: 'reddit'}
            ]
        }
    },
    computed: {
        organization() {
            if (this.$route.params.organization) {
                return this.$route.params.organization
            } else if (this.currentOrganization && this.currentOrganization.relative_path) {
                return this.currentOrganization.relative_path.slice(1)
            } else {
                return this.$route.params.id
            }
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCanManagePost() {
            return this.currentUser?.credentialsAbility?.can_manage_blog_post && this.currentUser.id === this.post.user.id
        },
        isCanModerateBlogPost() {
            return this.currentUser?.credentialsAbility?.can_moderate_blog_post
        },
        isPublished() {
            return this.post.status === 'published'
        },
        isDraft() {
            return this.post.status === 'draft'
        },
        isHidden() {
            return this.post.status === 'hidden'
        },
        isArchived() {
            return this.post.status === 'archived'
        }
    },
// facebook_url: "https://www.facebook.com/sharer.php?u=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10"
// linkedin_url: "https://www.linkedin.com/shareArticle?mini=true&url=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10&title=Benjamin Ramos on Guitar channel: synthetic-title-10&summary=synthetic-title-10 - https://https://my.unite.live/s/sVjaeX↵Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin risus. Praesent lectus.↵↵Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis.↵Streamed on 12 Jan 05:25 PM EET&source=localhost"
// pinterest_url: "http://pinterest.com/pin/create/button/?url=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10&description=Benjamin Ramos on Guitar channel: synthetic-title-10&media=/stub/jpgs/0.jpg"
// reddit_url: "https://ssl.reddit.com/submit?url=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10&title=Benjamin Ramos on Guitar channel: synthetic-title-10"
// tumblr_url: "https://www.tumblr.com/widgets/share/tool?canonicalUrl=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10"
// twitter_url: "https://twitter.com/intent/tweet?url=https://localhost/flipopia-livefish/guitar/22-jan-15-00-synthetic-title-10?video_id=10&text=Benjamin Ramos on Guitar channel: synthetic-title-10"

    watch: {
        post(val) {
            if (val && this.postPage) {
                this.getComments()
            }
        }
    },
    mounted() {
        if (this.postPage) {
            this.showComments = true
            this.commentsLimit = 4
            // if(this.post) this.getComments()
        }
        this.checkTextLength()
        setTimeout(() => {
            document.querySelectorAll(`#post${this.post.id} .mention`).forEach(el => {
                el.addEventListener("click", (e) => {
                    let id = e.target.parentNode.dataset.id
                    if (!id) {
                        id = e.target.dataset.id
                    }
                    User.api().getUser({id}).then(res => {
                        this.$eventHub.$emit("open-modal:userinfo", {
                            notFull: true,
                            model: res.response.data.response.user
                        })
                    })
                })
            })
        }, 1000)
    },
    methods: {
        checkTextLength() {
            if (this.post?.body?.length < 60) this.smallText = false
        },
        purgeBody() {
            if (this.post.body_preview) {
                return this.post.body_preview.replace(/<img.*?>/g, '').replace(/h[\d]/g, 'span')
                    .replace(/class=.*?"/g, '').replace(/<li>/g, " ")
                    .replace(/<ul>/g, " ").replace("<ol>", " ")
                    .replace(/<blockquote>/g, " ")
            }
        },
        checkUser() {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth")
            }
        },
        removePreview() {
            this.showPreview = false
        },
        headerShow() {
            if (this.orientation === "horizontal") return true
        },
        toggleOptions() {
            this.postOptions = !this.postOptions
        },
        toggleShare() {
            this.share = !this.share
            if (this.share) {
                this.getShare()
            }
        },
        toggleComments() {
            this.showComments = !this.showComments
            if (this.showComments) {
                this.getComments()
            }
        },
        getComments(isMore = false) {
            if (!isMore) {
                this.commentsOffset = 0
            }

            BlogComments.api().getComments({
                // post_id: this.post.id,
                limit: this.commentsLimit,
                offset: this.commentsOffset,
                commentable_type: "Blog::Post",
                commentable_id: this.post.id,
                order_by: "created_at"
            }).then(res => {
                if (isMore) {
                    this.comments = this.comments.concat(res.response.data.response.comments)
                    this.commentsOffset += this.commentsLimit
                } else {
                    this.commentsOffset = this.commentsLimit
                    this.comments = res.response.data.response.comments
                    this.commentsCount = this.post.comments_count
                    this.postCommentsCount = res.response.data.pagination.count
                }
            })
        },
        hidePost(isFromArchive = false) {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("hide", isFromArchive)
                this.postOptions = false
            }
        },
        editPost() {
            if ((this.accessChannelModerate && this.isCanModerateBlogPost) || (this.accessChannelManage && this.isCanManagePost)) {
                this.$refs.editPostModal.open()
                this.postOptions = false
            }
        },
        removePost(draft = false) {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("remove", draft)
                this.postOptions = false
            }
        },
        update(post) {
            this.$emit("update", post)
        },
        commented(comment) {
            this.comments = [{comment}].concat(this.comments)
            this.commentsOffset += 1
            this.commentsCount += 1
            this.postCommentsCount += 1
        },
        getShare() {
            Share.api().fetch({
                model_type: "Blog::Post",
                model_id: this.post.id
            }).then(res => {
                this.social_links.forEach(e => {
                    e.url = res.response.data.response.model[e.provider + "_url"]
                })
            })
        },
        creatorModal(creator) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: creator
            })
        },
        commentRemoved(comment) {
            this.commentsOffset--
            this.commentsCount--
            this.postCommentsCount--
            this.comments = this.comments.filter(e => e.comment.id !== comment.id)
            if(this.postCommentsCount == 0) this.showComments = false
        },
        updateComment(comment, newComment) {
            comment.comment.body = newComment.body
            comment.comment.updated_at = newComment.updated_at
        },
        like() {
            this.$emit("like")
        },
        publishPost(isFromArchive = false) {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("publish", isFromArchive)
                this.toggleOptions()
            }
        },
        archivePost() {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("archive", this.post)
                this.toggleOptions()
            }
        }
    }
}
</script>