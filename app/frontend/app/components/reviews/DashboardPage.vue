<template>
    <dashboard-layout
        :active-name="'Reviews'"
        :name="'Reviews'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '../dashboard/Layout'

export default {
    name: 'ReviewsDashboardPage',
    components: {DashboardLayout},
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    }
}
</script>