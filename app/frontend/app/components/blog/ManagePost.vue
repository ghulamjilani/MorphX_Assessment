<template>
    <div class="managePost">
        <div class="managePost__header">
            <div class="managePost__header__result">
                {{ count }} {{ $t('views.dashboard.navigationsidebar.community') }} Posts
            </div>
            <div class="managePost__header__filters">
                <div class="managePost__header__filters__options">
                    <m-btn
                        class="managePost__header__filters__options__button"
                        type="bordered"
                        @click="toggleSort">
                        {{ sortsOptions.find(e => e.value === sort).name }}
                        <m-icon
                            class="managePost__header__filters__icon"
                            size="1rem">
                            GlobalIcon-angle-down
                        </m-icon>
                    </m-btn>
                    <div
                        v-show="sortOptions"
                        class="channelFilters__icons__options__cover"
                        @click="toggleSort" />
                    <div
                        v-show="sortOptions"
                        class="channelFilters__icons__options">
                        <m-btn
                            v-for="option in sortsOptions"
                            :key="option.value"
                            :reset="true"
                            @click="changeFilter(option.value)">
                            {{ option.name }}
                        </m-btn>
                    </div>
                </div>
                <m-btn
                    class="channelFilters__icons__filters"
                    type="bordered"
                    @click="openFilters">
                    Filters
                    <m-icon
                        class="managePost__header__filters__icon"
                        size="1rem">
                        GlobalIcon-filters
                    </m-icon>
                </m-btn>
            </div>
        </div>
        <b-filters
            ref="bfilters"
            :members="[]"
            :model-type="'Post'"
            @updateSearch="updateSearch" />
        <div
            v-if="loading"
            class="managePost__placeholder">
            <post-placeholder />
            <post-placeholder />
            <post-placeholder />
        </div>
        <div
            v-for="post in posts"
            v-else
            :key="post.post.id"
            :class="{'postWrapper__draft': post.post.status === 'draft'}"
            class="postWrapper">
            <post
                :access-channel-manage="checkAccessManage(post.post.channel_id)"
                :access-channel-moderate="checkAccessModerate(post.post.channel_id)"
                :dashboard="true"
                :manage="true"
                :manage-page="true"
                :post="post.post"
                @removed="removePost(post)"
                @updated="(updPost) => { hide(updPost, post) }" />
        </div>
        <m-btn
            v-if="posts.length < count"
            class="comments__showMore"
            type="secondary"
            @click="getPosts(true)">
            Show more
        </m-btn>
    </div>
</template>

<script>
import Post from './Post.vue'
import BFilters from '../common/BFilters.vue'
import PostPlaceholder from "@components/PostPlaceholder"
import User from "@models/User"
import Blog from "@models/Blog"

export default {
    components: {Post, BFilters, PostPlaceholder},
    data() {
        return {
            posts: [],
            limit: 20,
            offset: 0,
            count: 0,
            loading: false,
            // options
            sortOptions: false,
            sortsOptions: [
                {name: "Most Recent", value: "new"},
                {name: "Oldest", value: "old"},
                {name: "Most popular", value: "popularity"}
            ],
            sort: "new",
            search: {},
            postsCount: null,
            accessChannelModerate: [],
            accessChannelManage: []
        }
    },
    computed: {
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        }
    },
    watch: {
        currentOrganization: {
            handler(val) {
                if (val && !this.loading) {
                    this.accessManagmentChannel()
                    this.getPosts()
                }
            },
            immediate: true
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
        getPosts(isMore = false) {
            if (!isMore) {
                this.offset = 0
            }
            this.loading = true
            let data = {
                resource_type: "Organization",
                resource_slug: this.currentOrganization.relative_path.slice(1),
                order_by: "created_at",
                order: "desc",
                limit: this.limit,
                offset: this.offset,
                scope: "edit"
            }

            if (this.search.status) {
                data["status"] = this.search.status
            }

            switch (this.sort) {
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

            Blog.api().search(data).then(res => {
                if (isMore) {
                    this.posts = this.posts.concat(res.response.data.response.posts)
                } else {
                    this.posts = res.response.data.response.posts
                }
                this.count = res.response.data.pagination?.count
                this.offset += this.limit
                this.loading = false
            })
                .catch(error => {
                    this.loading = false
                    this.$flash(error.response.message)
                })
        },
        removePost(post) {
            this.posts = this.posts.filter(e => e.post.id !== post.post.id)
            this.count--
            // this.getPosts()
        },
        hide(updPost, post) {
            post.post = updPost
            // this.getPosts()
        },
        toggleSort() {
            this.sortOptions = !this.sortOptions
        },
        changeFilter(val) {
            this.sort = val
            this.getPosts()
            this.sortOptions = false
        },
        openFilters() {
            this.$refs.bfilters.toggleFilters()
        },
        updateSearch(params) {
            this.search = params
            this.getPosts()
        }
    }
}
</script>