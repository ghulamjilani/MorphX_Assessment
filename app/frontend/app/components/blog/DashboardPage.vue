<template>
    <dashboard-layout
        :name="$t('views.dashboard.navigationsidebar.community')"
        :active-name="$t('views.dashboard.navigationsidebar.community')">
        <template #tabs>
            <div class="dashboardMK2__main__content__tabs">
                <router-link
                    :class="{'dashboardMK2__main__content__tabs__tab__active': pageName === 'new_post', 'dashboardMK2__main__content__tabs__tab__disable': !can_manage_blog_post}"
                    :to="{name: 'create-post'}"
                    class="dashboardMK2__main__content__tabs__tab">
                    New Post
                </router-link>
                <router-link
                    :class="{'dashboardMK2__main__content__tabs__tab__active': pageName === 'manage'}"
                    :to="{name: 'manage-blog'}"
                    class="dashboardMK2__main__content__tabs__tab">
                    Manage
                </router-link>
            </div>
        </template>
    </dashboard-layout>
</template>

<script>
import DashboardLayout from '../dashboard/Layout.vue'

export default {
    name: 'BlogDashboardPage',
    components: {DashboardLayout},
    beforeRouteEnter(to, from, next) {
        if (this) this.changeRoute(to)
        next()
    },
    beforeRouteUpdate(to, from, next) {
        if (this) this.changeRoute(to)
        next()
    },
    data() {
        return {
            pageName: ''
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        can_manage_blog_post() {
            return this.currentUser?.credentialsAbility?.can_manage_blog_post
        },
        can_moderate_blog_post() {
            return this.currentUser?.credentialsAbility?.can_moderate_blog_post
        }
    },
    mounted() {
        this.changeRoute(this.$router.history.current)
    },
    methods: {
        changeRoute(route) {
            if (route.name === 'manage-blog') {
                this.pageName = 'manage'
            } else {
                this.pageName = 'new_post'
            }
            scrollTo(0, 0)
        }
    }
}
</script>