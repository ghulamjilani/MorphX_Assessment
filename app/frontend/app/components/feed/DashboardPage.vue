<template>
    <dashboard-layout
        :active-name="'My Library'"
        :name="'My Library'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
    name: 'MyFeedDashboardPage',
    components: {DashboardLayout},
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    }
}
</script>