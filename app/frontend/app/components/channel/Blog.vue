<template>
    <div>
        <div
            v-show="isCommunityAvailable"
            id="anchorSection__community"
            class="mChannel__blog mChannel__section anchorSection">
            <div class="mChannel__label">
                <div class="mChannel__label__name">
                    {{ $t('frontend.app.components.channel.blog.community') }}
                    <router-link
                        v-show="organization && organization.slug"
                        :to="{name: 'blog', params: {organization: organization.slug }}"
                        class="mChannel__label__link text__uppercase fs__12 color__secondary">
                        View all
                    </router-link>
                </div>
                <div class="mChannel__buttons">
                    <m-btn
                        v-if="posts.length && canCreatePost"
                        class="managePost__header__newPost"
                        @click="createNewPost">
                        <m-icon
                            class="blog__filters__icon"
                            size="normal">
                            GlobalIcon-pencil
                        </m-icon>
                        {{ $t('frontend.app.components.channel.blog.create_new_post') }}
                    </m-btn>
                    <router-link
                        :to="{name: 'blog', params: {organization: organization.slug }}"
                        class="mChannel__buttons__link text__uppercase fs__12 color__secondary">
                        {{ $t('frontend.app.components.channel.blog.view_all') }}
                    </router-link>
                </div>
            </div>
            <div
                v-if="posts.length"
                class="blog__wrapp">
                <div
                    v-for="post in posts"
                    :key="post.post.id"
                    :class="{'postWrapper__draft': post.post.status === 'draft'}"
                    class="postWrapper">
                    <post
                        :access-channel-manage="checkAccessManage(post.post.channel_id)"
                        :access-channel-moderate="checkAccessModerate(post.post.channel_id)"
                        :manage="true"
                        :post="post.post"
                        @removed="removePost(post)"
                        @updated="(updPost) => { updatePost(updPost, post) }" />
                </div>
            </div>
            <div
                v-else-if="loading"
                class="blog__placeholders">
                <post-placeholder class="postPlaceholder" />
                <post-placeholder class="postPlaceholder" />
                <post-placeholder class="postPlaceholder" />
            </div>
            <div
                v-else-if="canCreatePost"
                class="blog__empty__create">
                <div class="blog__empty__text color__h1">
                    {{ $t('frontend.app.components.channel.blog.posts') }}
                </div>
                <no-post-create class="blog__empty__svg" />
                <div class="blog__empty__text">
                    {{ $t('frontend.app.components.channel.blog.start_interacting') }}
                </div>
                <m-btn
                    class="blog__empty__button"
                    size="l"
                    type="bordered"
                    @click="createNewPost">
                    {{ $t('frontend.app.components.channel.blog.create_post') }}
                </m-btn>
            </div>
            <div
                v-else
                class="blog__empty">
                <no-post />
                <div class="blog__empty__text">
                    {{ $t('frontend.app.components.channel.blog.no_posts') }}
                </div>
            </div>
            <m-btn
                v-if="posts.length < count"
                class="blog__showMore"
                type="secondary"
                @click="getPosts(true)">
                {{ $t('frontend.app.components.channel.blog.show_more') }}
            </m-btn>
            <edit-post-modal
                ref="createPostModal"
                :channel-id="channel.id"
                @created="postCreated" />
        </div>
    </div>
</template>

<script>
import Post from "@components/blog/Post"
import EditPostModal from '@components/blog/EditPostModal'
import PostPlaceholder from "@components/PostPlaceholder"
import NoPost from '@components/NoPost.vue'
import NoPostCreate from '@components/NoPostCreate.vue'
import User from "@models/User"
import Blog from "@models/Blog"

export default {
    components: {Post, EditPostModal, PostPlaceholder, NoPost, NoPostCreate},
    props: {
        channel: {},
        organization: {},
        canCreate: [Object, Boolean],
        priority: {
            type: Array,
            default: null
        }
    },
    data() {
        return {
            limit: 3,
            offset: 0,
            count: -1,
            posts: [],
            loading: true,
            accessChannelModerate: [],
            accessChannelManage: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        canCreatePost() {
            return this.canCreate && this.accessChannelManage.length && this.accessChannelManage.includes(this.channel.id)
        },
        isCommunityAvailable() {
            return this.posts.length > 0 || this.channel?.can_create_post || this.channel?.display_empty_blog || this.channel?.posts?.count > 0
            // return this.organization?.subscription_features?.can_manage_blog
        }
    },
    watch: {
        channel: {
            handler(val) {
                if (val?.id) {
                    this.posts = []
                }
            },
            immediate: true
        },
        posts(val) {
            this.$emit("postsCount", val?.length)
        }
    },
    mounted() {
        this.$eventHub.$on('priority', (val) => {
            if (this.priority[0] == val) {
                this.accessManagmentChannel()
            }

            if (this.priority[1] == val) {
                this.searchBlog()
            }

        })
    },
    methods: {
        accessModerate() {
            return new Promise((resolve, reject) => {
                User.api().accessManagment({permission_code: 'moderate_blog_post'}).then(res => {
                    this.accessChannelModerate = res.response.data.response.map((c) => {
                        return c.id
                    })
                    resolve()
                })
            })
        },
        accessManage() {
            return new Promise((resolve, reject) => {
                User.api().accessManagment({permission_code: 'manage_blog_post'}).then(res => {
                    this.accessChannelManage = res.response.data.response.map((c) => {
                        return c.id
                    })
                    resolve()
                })
            })
        },
        searchBlog() {
            return new Promise((resolve, reject) => {
                this.loading = true
                this.offset = 0
                Blog.api().search({
                    resource_type: "Channel",
                    resource_id: this.channel.id,
                    status: "published",
                    limit: this.limit,
                    offset: this.offset
                }).then(res => {
                    this.offset += this.limit
                    this.count = res.response.data.pagination?.count
                    this.posts = res.response.data.response.posts
                    this.loading = false
                    resolve()
                    this.$eventHub.$emit('check-priority', 1)
                    this.$eventHub.$emit('loaded-by-priority')
                })
            })
        },
        accessManagmentChannel() {
            if (this.currentUser) {
                this.accessModerate().then(() => {
                    this.accessManage().then(() => {
                        this.$eventHub.$emit('check-priority', 2)
                    }).catch(error => {
                        this.$flash(error.response.message)
                    })
                }).catch(error => {
                    this.$flash(error.response.message)
                })
            } else {
                this.$eventHub.$emit('check-priority', 0)
            }
        },
        checkAccessModerate(id) {
            if (!this.accessChannelModerate.length) return false
            return this.accessChannelModerate.includes(id)
        },
        checkAccessManage(id) {
            if (!this.accessChannelManage.length) return false
            return this.accessChannelManage.includes(id)
        },
        getPosts(more = false) {
            this.loading = true
            if (!more) {
                this.offset = 0
            }
            Blog.api().search({
                resource_type: "Channel",
                resource_id: this.channel.id,
                status: "published",
                limit: this.limit,
                offset: this.offset
            }).then(res => {
                if (more) {
                    this.offset += this.limit
                    this.posts = this.posts.concat(res.response.data.response.posts)
                    this.count = res.response.data.pagination?.count
                } else {
                    this.offset += this.limit
                    this.count = res.response.data.pagination?.count
                    this.posts = res.response.data.response.posts
                }
                this.loading = false
            })
        },
        removePost(post) {
            this.posts = this.posts.filter(e => e.post.id !== post.post.id)
            this.offset--
        },
        updatePost(updPost, post) {
            post.post = updPost
        },
        createNewPost() {
            this.$refs.createPostModal.open()
        },
        postCreated(post) {
            this.$refs.createPostModal.close(true)
            if (post.status === "published" && post.channel_id === this.channel.id) {
                this.posts.unshift({post})
            }
        }
    }
}
</script>

