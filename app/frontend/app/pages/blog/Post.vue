<template>
    <div
        id="post-page"
        class="postPage__wrapper">
        <div class="postPage__navigation">
            <m-btn
                v-if="humanityPrevRoute"
                :disabled="disabled"
                class="avatarBlock__item__content__following"
                type="bordered"
                @click="back">
                Back to {{ prevName }}
            </m-btn>
            <div v-else />
            <div class="postPage__navigation__left">
                <router-link
                    v-if="nextPost"
                    :to="{name: 'post-slug', params: { organization: organizationSlug, slug: nextPost.slug }}">
                    <m-btn
                        class="postPage__navigation__next"
                        type="bordered">
                        Next Post
                    </m-btn>
                </router-link>
                <m-btn
                    v-if="canCreate"
                    class="managePost__header__newPost"
                    @click="createNewPost">
                    <m-icon
                        class="blog__filters__icon"
                        size="normal">
                        GlobalIcon-pencil
                    </m-icon>
                    Create New Post
                </m-btn>
            </div>
        </div>
        <div class="postPage__post">
            <post
                :access-channel-manage="checkAccessManage(post.channel_id)"
                :access-channel-moderate="checkAccessModerate(post.channel_id)"
                :post="post"
                :post-page="true"
                @removed="removePost"
                @updated="update" />
        </div>
        <user-info-modal />
        <booking-payment />
        <edit-post-modal
            ref="createPostModal"
            @created="postCreated" />
    </div>
</template>

<script>
import Post from '@components/blog/Post.vue'
import UserInfoModal from '@components/modals/UserInfoModal.vue'
import EditPostModal from '@components/blog/EditPostModal'

import Blog from "@models/Blog"
import User from "@models/User"
import Channel from "@models/Channel"
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    components: {Post, UserInfoModal, EditPostModal, BookingPayment},
    beforeRouteUpdate(to, from, next) {
        this.getPost(to.params.slug)
        scrollTo(0, 0)
        next()
    },
    data() {
        return {
            post: {},
            mobile: false,
            nextPost: null,
            accessChannelModerate: [],
            accessChannelManage: [],
            disabled: true
        }
    },
    computed: {
        humanityPrevRoute() {
            let prevRoute = this.$store.getters["Global/prevRoute"]
            if (prevRoute) return prevRoute
            else return null
        },
        prevName() {
            if (this.humanityPrevRoute.humanityName == 'Community') {
                return this.$t('views.dashboard.navigationsidebar.community')
            } else {
                return this.humanityPrevRoute.humanityName
            }
        },
        organizationSlug() {
            return this.$route.params.organization
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        canCreate() {
            if(!this.currentUser?.subscriptionAbility?.can_manage_blog ||
                !this.currentUser?.credentialsAbility?.can_manage_blog_post) return false

            if (this.currentOrganization?.id !== this.post?.organization_id) return false
            return this.currentUser?.credentialsAbility?.can_manage_blog_post && this.post.channel.can_create_post
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
        setTimeout(() => {
            this.disabled = false
        }, 3000)
        scrollTo(0, 0)
        this.getPost()
        this.resizeWindow()
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
        getPost(slug = null) {
            Blog.api().getPost({slug: slug ? slug : this.$route.params.slug}).then(res => {
                this.post = res.response.data.response.post
                this.getNextPost()
                this.getOrganization()
            })
        },
        getOrganization() {
            Channel.api().getPublicOrganization({id: this.organizationSlug}).then((res) => {
                this.$store.dispatch("Users/setPageOrganization", res.response.data.response.organization)
            })
        },
        getNextPost() {
            Blog.api().search({
                resource_type: "Organization",
                resource_slug: this.organizationSlug,
                status: "published",
                limit: 2,
                offset: 0,
                order: 'asc',
                date_from: this.post.created_at
            }).then(res => {
                let data = res.response.data.response.posts
                let posts = data.filter(e => e.post.id !== this.post.id)
                if (posts && posts.length) this.nextPost = posts[0].post
                else this.nextPost = null
            })
        },
        returnBack() {
            this.$router.push({name: 'manage-blog'})
            // this.$router.push({name: 'blog', params: {organization: this.organizationSlug}})
            // this.$router.push({ name: 'blog', params: { organization: this.$route.params.organization } })
        },
        removePost() {
            this.returnBack()
        },
        update(post) {
            this.post = post
        },
        back() {
            if (this.humanityPrevRoute.humanityName == 'Post') {
                let arr = this.humanityPrevRoute.path.split('/')
                let slug = arr[arr.length - 1]
                this.$router.push({name: 'post-slug', params: {organization: this.organizationSlug, slug: slug}})
            } else {
                this.$router.back()
            }
        },
        resizeWindow() {
            if (window.innerWidth < 640) this.mobile = true
            window.addEventListener('resize', (e) => {
                if (window.innerWidth < 640) {
                    this.mobile = true
                } else {
                    this.mobile = false
                }
            })
        },
        createNewPost() {
            this.$refs.createPostModal.open()
        },
        postCreated() {
            this.$router.push({name: 'manage-blog'})
        }
    }
}
</script>

