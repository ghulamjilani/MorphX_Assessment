<template>
    <dashboard-layout
        active-name="Business Subscription"
        name="Business Subscription">
        <template #tabs>
            <div class="dashboardMK2__main__content__tabs">
                <a
                    v-if="currentUser.hasSubscription && !currentOrganization"
                    class="dashboardMK2__main__content__tabs__tab"
                    href="/wizard/business">Company</a>
                <a
                    v-else
                    class="dashboardMK2__main__content__tabs__tab"
                    href="/dashboard/company">Company</a>
                <router-link
                    v-if="enabledBP && (currentUser.hasSubscription || credentialsAbility && credentialsAbility.can_manage_business_plan)"
                    :to="{name: 'business_plan'}"
                    class="dashboardMK2__main__content__tabs__tab dashboardMK2__main__content__tabs__tab__active">
                    Business Plan
                </router-link>
                <div
                    v-else-if="enabledBP"
                    class="dashboardMK2__main__content__tabs__tab dashboardMK2__main__content__tabs__tab__disable">
                    Business Plan
                </div>
            </div>
        </template>
    </dashboard-layout>
</template>

<script>
import DashboardLayout from '../dashboard/Layout.vue'

export default {
    name: 'BusinessDashboardPage',
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
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        credentialsAbility() {
            return this.currentUser?.credentialsAbility
        },
        enabledBP() {
            return this.$railsConfig.global?.service_subscriptions?.enabled
        }
    },
    mounted() {
        this.changeRoute(this.$router.history.current)
    },
    methods: {
        changeRoute() {
            this.pageName = 'business_plan'
            scrollTo(0, 0)
        }
    }
}
</script>