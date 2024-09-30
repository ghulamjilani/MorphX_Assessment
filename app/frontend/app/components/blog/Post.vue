<template>
    <div class="post">
        <m-card
            v-if="post"
            :orientation="orientation"
            class="card-post-old"
            size="full">
            <template #top>
                <post-top
                    :access-channel-manage="accessChannelManage"
                    :access-channel-moderate="accessChannelModerate"
                    :dashboard="dashboard"
                    :hide="post.status === 'hidden' || post.status === 'archived'"
                    :manage="manage"
                    :manage-page="managePage"
                    :mobile="mobile"
                    :orientation="orientation"
                    :post="post"
                    :post-page="postPage"
                    @archive="archivePost"
                    @hide="hide"
                    @like="like"
                    @publish="publish"
                    @remove="removePost"
                    @update="update" />
            </template>
            <template #bottom>
                <post-bottom
                    :access-channel-manage="accessChannelManage"
                    :access-channel-moderate="accessChannelModerate"
                    :dashboard="dashboard"
                    :hide="post.status === 'hidden' || post.status === 'archived'"
                    :manage="manage"
                    :manage-page="managePage"
                    :mobile="mobile"
                    :orientation="orientation"
                    :post="post"
                    :post-page="postPage"
                    @archive="archivePost"
                    @hide="hide"
                    @like="like"
                    @publish="publish"
                    @remove="removePost"
                    @update="update" />
            </template>
        </m-card>
    </div>
</template>

<script>
import PostBottom from '@components/card-templates/PostBottom.vue'
import PostTop from '@components/card-templates/PostTop.vue'
import Blog from "@models/Blog"
import utils from '@helpers/utils'

export default {
    components: {PostTop, PostBottom},
    props: {
        post: Object,
        postPage: {
            type: Boolean,
            default: false
        },
        dashboard: {
            type: Boolean,
            default: false
        },
        manage: {
            type: Boolean,
            default: false
        },
        managePage: {
            type: Boolean,
            default: false
        },
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
            mobile: false,
            orientation: 'horizontal'
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCanManagePost() {
            return this.currentUser?.credentialsAbility?.can_manage_blog_post && this.currentUser.id === this.post.user.id
        },
        isCanModerateBlogPost() {
            return this.currentUser?.credentialsAbility?.can_moderate_blog_post
        }
    },
    mounted() {
        this.resizeWindow()
        this.$eventHub.$on(organizationBlogChannelEvents.postLikesCountUpdated, data => {
            if (data && data.id === this.post.id) {
                let post = this.post
                post.likes_count = data.likes_count
                this.$emit("updated", post)
            }
        })
    },
    methods: {
        removePost(draft) {
            var con = false
            if (draft) {
                if (confirm("This action is irrecoverable. Are you sure?")) {
                    con = true
                }
            } else {
                if (confirm("You are about to delete this post. All its social media shares are also to be removed and become unavailable anymore. Are you sure?")) {
                    con = true
                }
            }
            if (con) {
                Blog.api().remove({id: this.post.id}).then(() => {
                    this.$flash("Post successfully removed", "success")
                    this.$emit("removed")
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
        },
        hide(isFromArchive) {
            let status = ""
            if (!this.isCanModerateBlogPost && !this.isCanManagePost) return false
            if (this.post.status !== "hidden") {
                status = "hidden"
            } else {
                status = "published"
            }

            Blog.api().changeStatus({
                id: this.post.id,
                status,
                published_at: !this.post.published_at ? utils.dateToTimeZone(moment(), true).format() : this.post.published_at
            }).then(res => {
                let post = this.post
                post.status = status
                if (!isFromArchive) this.$emit("updated", post)
                else this.$emit("removed")
                if (status === "hidden") {
                    this.$flash("Post successfully hidden", "success")
                } else {
                    this.$flash("Post successfully shown", "success")
                }
            })
        },
        resizeWindow() {
            if (this.postPage) {
                this.orientation = "vertical"
            }
            if (this.dashboard) {
                this.orientation = "horizontal"
            }
            if (window.innerWidth < 892) {
                this.mobile = true
                this.orientation = "vertical"
            }
            window.addEventListener('resize', (e) => {
                if (window.innerWidth < 892) {
                    this.mobile = true
                    this.orientation = "vertical"
                } else {
                    this.mobile = false
                    if (!this.postPage) this.orientation = "horizontal"
                }
            })
        },
        update(post) {
            this.$emit("updated", post)
        },
        like() {
            if (this.currentUser) {
                Blog.api().like({id: this.post.id})
                    .then(res => {
                        this.$emit("updated", res.response.data.response.post)
                    })
            } else {
                this.$eventHub.$emit("open-modal:auth", "login")
            }
        },
        publish(isFromArchive) {
            Blog.api().changeStatus({
                id: this.post.id,
                status: "published",
                published_at: !this.post.published_at ? utils.dateToTimeZone(moment(), true).format() : this.post.published_at
            }).then(res => {
                let post = this.post
                post.status = "published"
                if (!isFromArchive) this.$emit("updated", post)
                else this.$emit("removed")
                this.$flash("Post successfully published", "success")
            })
        },
        archivePost() {
            Blog.api().changeStatus({
                id: this.post.id,
                status: "archived"
            }).then(res => {
                let post = this.post
                post.status = "archived"
                this.$emit("removed", post)
                this.$flash("Post successfully archived", "success")
            })
        }
    }
}
</script>