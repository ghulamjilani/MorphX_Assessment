<template>
    <div>
        <user-info-modal />
        <booking-payment />
        <share-modal />
        <banner
            :channel="channel"
            :channels="bannerInfo.channels"
            :channels-plans="[]"
            is-blog
            :channel-members="bannerInfo.members"
            :organization="bannerInfo.organization"
            :owner="bannerInfo.owner"
            :token="bannerInfo.token"
            @filterChannel="changeFilterChannel" />
        <div
            id="blog-page"
            class="pageComponent">
            <div v-if="posts.length && !loading">
                <div class="blog__filters">
                    <m-btn
                        v-if="canCreatePost"
                        class="managePost__header__newPost"
                        @click="createNewPost">
                        <m-icon
                            class="blog__filters__icon"
                            size="normal">
                            GlobalIcon-pencil
                        </m-icon>
                        Create New Post
                    </m-btn>
                    <div class="managePost__header__filters">
                        <div class="managePost__header__filters__options">
                            <m-btn
                                class="managePost__header__filters__options__button"
                                type="bordered"
                                @click="toggleFilter">
                                {{ filtersOptions.find(e => e.value === filter).name }}
                                <m-icon
                                    class="managePost__header__filters__icon"
                                    size="1rem">
                                    GlobalIcon-angle-down
                                </m-icon>
                            </m-btn>
                            <div
                                v-show="filterOptions"
                                class="channelFilters__icons__options__cover"
                                @click="toggleFilter" />
                            <div
                                v-show="filterOptions"
                                class="channelFilters__icons__options">
                                <m-btn
                                    v-for="option in filtersOptions"
                                    :key="option.value"
                                    :reset="true"
                                    @click="changeFilter(option.value)">
                                    {{ option.name }}
                                </m-btn>
                            </div>
                        </div>
                        <!-- <m-btn type="bordered" :disabled="true">
              Filters <m-icon class="managePost__header__filters__icon" size="1rem"> GlobalIcon-4cube </m-icon>
            </m-btn> -->
                    </div>
                    <!-- <m-btn type="bordered" :disabled="true">
            Filters <m-icon class="blog__filters__icon" size="1rem"> GlobalIcon-4cube </m-icon>
          </m-btn> -->
                </div>

                <div
                    v-for="post in posts"
                    :key="post.post.id"
                    :class="{'postWrapper__draft': post.post.status === 'draft'}"
                    class="postWrapper">
                    <post
                        :access-channel-manage="checkAccessManage(post.post.channel_id)"
                        :access-channel-moderate="checkAccessModerate(post.post.channel_id)"
                        :manage="false"
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
                class="blog__empty__page blog__empty__create">
                <div class="blog__empty__text">
                    {{ $t('views.dashboard.navigationsidebar.community') }}
                </div>
                <no-post-create class="blog__empty__svg" />
                <div class="blog__empty__text">
                    {{ $t('channel_page.start_interacting') }}
                </div>
                <m-btn
                    class="blog__empty__button"
                    size="l"
                    type="bordered"
                    @click="createNewPost">
                    Create a Post
                </m-btn>
            </div>
            <div
                v-else
                class="blog__empty blog__empty__page">
                <no-post />
                <div class="blog__empty__text">
                    {{ $t('channel_page.no_posts') }}
                </div>
            </div>
            <m-btn
                v-if="posts.length < count"
                class="comments__showMore"
                type="secondary"
                @click="getPosts(null, true)">
                {{ $t('channel_page.show_more') }}
            </m-btn>
        </div>
        <edit-post-modal
            ref="createPostModal"
            @created="postCreated" />
    </div>
</template>

<script>
import Blog from "@models/Blog"
import Channel from "@models/Channel"
import Members from "@models/Members"
import User from "@models/User"

import ShareModal from '@components/modals/ShareModal'
import Post from '@components/blog/Post.vue'
import Banner from '@components/channel/Banner'
import UserInfoModal from '@components/modals/UserInfoModal.vue'
import EditPostModal from '@components/blog/EditPostModal'
import PostPlaceholder from "@components/PostPlaceholder"
import NoPost from '@components/NoPost.vue'
import NoPostCreate from '@components/NoPostCreate.vue'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    components: {Post, Banner, UserInfoModal, EditPostModal, PostPlaceholder, NoPost, NoPostCreate, ShareModal, BookingPayment},
    data() {
        return {
            posts: [],
            limit: 20,
            offset: 0,
            organization_id: -1,
            count: 0,
            channel: {},
            bannerInfo: {
                channel: {},
                token: '',
                channels: [],
                organization: {},
                members: [],
                owner: {}
            },
            // filter
            filterOptions: false,
            filterChannel: null,
            filtersOptions: [
                {name: "Most Recent", value: "new"},
                {name: "Oldest", value: "old"},
                {name: "Most popular", value: "popularity"}
            ],
            filter: "new",
            loading: false,
            accessChannelModerate: [],
            accessChannelManage: []
        }
    },
    computed: {
        prevRoute() {
            let prevRoute = this.$store.getters["Global/prevRoute"]
            if (prevRoute) return prevRoute
            else return null
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        members() {
            return Members.query().get()
        },
        canCreatePost() {
            if(!this.currentUser?.subscriptionAbility?.can_manage_blog ||
                !this.currentUser?.credentialsAbility?.can_manage_blog_post) return false

            if (this.currentOrganization?.id !== this.bannerInfo?.organization?.id) return false

            return this.currentUser?.id === this.bannerInfo?.organization?.user?.id ||
                    this.currentUser?.credentialsAbility?.can_manage_blog_post &&
                    (this.posts.find((p) => p.post.channel.can_create_post === true) ||
                    (this.posts.length === 0 && this.channel.can_create_post))
        }
    },
    watch: {
        currentUser: {
            handler(val) {
                if (val) {
                    this.accessManagmentChannel()
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        if (this.prevRoute && this.prevRoute.name === "channel-slug") {
            let arr = this.prevRoute.path.split("/")
            let slug = arr[arr.length - 2] + "/" + arr[arr.length - 1]
            this.getPosts(slug)
            this.getChannel('/' + slug, true)
        } else {
            this.getPosts()
        }
    },
    methods: {
        accessManagmentChannel() {
            User.api().accessManagment({permission_code: 'moderate_blog_post'}).then(res => {
                this.accessChannelModerate = res.response.data.response.map((c) => {
                    return c.id
                })
                User.api().accessManagment({permission_code: 'manage_blog_post'}).then(res => {
                    this.accessChannelManage = res.response.data.response.map((c) => {
                        return c.id
                    })
                })
                    .catch(error => {
                        this.$flash(error.response.message)
                    })
            })
                .catch(error => {
                    this.$flash(error.response.message)
                })
        },
        checkAccessModerate(id) {
            if (!this.accessChannelModerate.length) return false
            return this.accessChannelModerate.includes(id)
        },
        checkAccessManage(id) {
            if (!this.accessChannelManage.length) return false
            return this.accessChannelManage.includes(id)
        },
        getPosts(channelSlug = null, isMore = false) {
            if (!isMore) {
                this.offset = 0
            }
            this.loading = true
            let data = {
                resource_type: "Organization",
                resource_slug: this.$route.params.organization,
                status: "published",
                limit: this.limit,
                offset: this.offset
            }

            switch (this.filter) {
                case "new":
                    data["order_by"] = "created_at"
                    data["order"] = "desc"
                    break
                case "old":
                    data["order_by"] = "created_at"
                    data["order"] = "asc"
                    break
                case "popularity":
                    data["order_by"] = "likes_count"
                    data["order"] = "desc"
                    break
            }

            if (this.filterChannel && !channelSlug) {
                data["resource_type"] = "Channel"
                data["resource_slug"] = null
                data["resource_id"] = this.filterChannel
            }

            if (channelSlug) {
                data["resource_type"] = "Channel"
                data["resource_slug"] = channelSlug
            }

            Blog.api().search(data).then(res => {
                if (isMore) {
                    this.posts = this.posts.concat(res.response.data.response.posts)
                } else {
                    this.posts = res.response.data.response.posts
                }
                this.count = res.response.data.pagination?.count
                this.offset += this.limit
                if (this.posts.length) {
                    this.organization_id = this.posts[0].post.organization_id

                }
                this.getInfo()
                this.$eventHub.$emit('blog-changeChannel')
                this.loading = false
            })
        },
        removePost(post) {
            this.posts = this.posts.filter(e => e.post.id !== post.post.id)
            // this.getPosts()
        },
        updatePost(updPost, post) {
            post.post = updPost
        },
        getInfo() {
            Channel.api().getPublicOrganization({id: this.$route.params.organization}).then((res) => {
                this.bannerInfo.organization = res.response.data.response.organization
                this.$store.dispatch("Users/setPageOrganization", res.response.data.response.organization)
                this.bannerInfo.channels = res.response.data.response.organization.channels.map(ch => {
                    ch.organization = JSON.parse(JSON.stringify(res.response.data.response.organization))
                    return ch
                })
                this.bannerInfo.owner = res.response.data.response.organization.user || {}
            })
        },
        changeFilterChannel(channel) {
            this.filterChannel = channel
            if (channel === "all") {
                this.channel = null
                this.filterChannel = null
            } else {
                this.getChannel(channel)
            }
            this.getPosts()
        },
        toggleFilter() {
            this.filterOptions = !this.filterOptions
        },
        changeFilter(val) {
            this.filter = val
            this.getPosts()
            this.filterOptions = false
        },
        createNewPost() {
            this.$refs.createPostModal.open()
        },
        postCreated(post) {
            this.$refs.createPostModal.close(true)
            if (post.status === "published" && post.channel_id == this.channel?.id) {
                this.posts.unshift({post})
            }
        },
        getChannel(slug, isSlug = false) {
            let param = {}
            if (isSlug) param['slug'] = slug
            else param['id'] = slug
            Channel.api().getPublicChannel(param).then((res) => {
                this.channel = res.response.data.response.channel
            })
        }
    }
}
</script>

