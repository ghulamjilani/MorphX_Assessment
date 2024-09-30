<template>
    <div
        v-if="post"
        class="cardMK2__post__imgWrapper">
        <div
            v-if="post.user"
            v-show="headerShow()"
            class="cardMK2__post__body__header">
            <div
                v-if="!post.hide_author || managePage"
                :class="{'postWrapper__hide' : isHidden && !postPage}"
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
                    :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}"
                    :style="{marginLeft: !post.hide_author || managePage ? '1.2rem' : '0'}"
                    class="cardMK2__post__body__header__info__owner">
                    <span>
                        <span v-if="post.hide_author && !managePage && !((isHidden && !post.published_at) || isDraft)">Published: </span>
                        <span v-if="(isHidden && !post.published_at) || isDraft">Not publish</span>
                        <timeago
                            v-else
                            :auto-update="30"
                            :datetime="post.published_at ? post.published_at : post.updated_at" />
                    </span>
                    <div
                        v-if="!post.hide_author || managePage"
                        class="cardMK2__post__body__title"
                        @click="creatorModal(post.user)">
                        {{ post.user.public_display_name }} ({{ post.user.slug }})
                    </div>
                </div>
                <div
                    :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}"
                    class="cardMK2__post__body__header__info__options">
                    <m-icon
                        v-if="isArchived"
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem">
                        GlobalIcon-bag
                    </m-icon>
                    <span
                        v-if="isArchived && postPage"
                        v-show="!mobile"
                        class="cardMK2__post__body__header__info__options__hiddenPost">Archived</span>

                    <m-icon
                        v-if="isHidden && postPage"
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem"
                        @click="$emit('hide')">
                        GlobalIcon-eye-off
                    </m-icon>
                    <span
                        v-if="isHidden && postPage"
                        v-show="!mobile"
                        class="cardMK2__post__body__header__info__options__hiddenPost hiddenPost white-space__nowrap">Hidden</span>

                    <m-icon
                        v-if="isDraft"
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem"
                        @click="editPost()">
                        GlobalIcon-pencil
                    </m-icon>
                    <span
                        v-if="isDraft"
                        v-show="!mobile"
                        class="cardMK2__post__body__header__info__options__hiddenPost">Draft</span>

                    <div
                        v-if="!isDraft"
                        v-show="!mobile"
                        class="cardMK2__post__body__header__info__options__watchCount">
                        <m-icon
                            class="GlobalIcon-eye-2"
                            size="1.8rem" />
                        <span
                            class="cardMK2__post__body__header__info__options__watchCountText"> {{ post.views_count }} </span>
                    </div>

                    <div
                        v-if="!isDraft"
                        v-show="!mobile"
                        class="cardMK2__post__body__header__info__options__like">
                        <m-icon
                            :class="{liked: post.liked}"
                            :name="post.liked ? 'GlobalIcon-heart-full' : 'GlobalIcon-heart'"
                            class="cardMK2__post__body__header__info__options__heart"
                            size="1.8rem"
                            @click="like" />
                        <span
                            class="cardMK2__post__body__header__info__options__likeCount">{{ post.likes_count }}</span>
                    </div>

                    <m-icon
                        v-if="!isDraft && !isArchived"
                        v-show="!mobile && !isHidden"
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
                        v-show="isHidden && mobile && !postPage"
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem"
                        @click="$emit('hide')">
                        GlobalIcon-eye-off
                    </m-icon>
                    <m-icon
                        v-if="(accessChannelModerate && isCanModerateBlogPost) || (accessChannelManage && isCanManagePost)"
                        class="cardMK2__post__body__header__info__options__icon"
                        size="1.8rem"
                        @click="toggleOptions">
                        GlobalIcon-dots-3
                    </m-icon>
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
                        {{ hide ? 'Show Post' : 'Hide Post' }}
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
            </div>
        </div>
        <router-link :to="{ name: 'post-slug', params: { organization, slug: post.slug }}">
            <div
                :class="{'postWrapper__hide' : (isHidden || isArchived) && !postPage}"
                :style="(post && post.cover_url) ? `background-image: url('${post.cover_url}')` : ''"
                class="cardMK2__post__imgWrapper__image" />
        </router-link>
    </div>
</template>

<script>
import EditPostModal from '../blog/EditPostModal'
import Share from "@models/Share"

export default {
    components: {EditPostModal},
    props: {
        post: Object,
        orientation: String,
        mobile: Boolean,
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
        isDraft() {
            return this.post.status === 'draft'
        },
        isHidden() {
            return this.post.status === 'hidden'
        },
        isArchived() {
            return this.post.status === 'archived'
        },
        isCanManagePost() {
            return this.currentUser?.credentialsAbility?.can_manage_blog_post && this.currentUser.id === this.post.user.id
        },
        isCanModerateBlogPost() {
            return this.currentUser?.credentialsAbility?.can_moderate_blog_post
        }
    },
    methods: {
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
        headerShow() {
            if (this.orientation === "vertical") return true
        },
        toggleShare() {
            this.share = !this.share
            if (this.share) {
                this.getShare()
            }
        },
        toggleOptions() {
            this.postOptions = !this.postOptions
        },
        hidePost(isFromArchive = false) {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("hide", isFromArchive)
                this.postOptions = false
            }
        },
        removePost(draft = false) {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("remove", draft)
                this.postOptions = false
            }
        },
        editPost() {
            if ((this.accessChannelModerate && this.isCanModerateBlogPost) || (this.accessChannelManage && this.isCanManagePost)) {
                this.$refs.editPostModal.open()
                this.postOptions = false
            }
        },
        removePost() {
            if (this.isCanModerateBlogPost || this.isCanManagePost) {
                this.$emit("remove")
                this.postOptions = false
            }
        },
        update(post) {
            this.$emit("update", post)
        },
        creatorModal(creator) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: creator
            })
        },
        like() {
            this.$emit("like", this.post)
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