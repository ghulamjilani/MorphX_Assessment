<template>
    <dashboard-layout
        :active-name="'Polls'"
        :name="'Polls'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
name: 'PollsDashboardPage',
components: {DashboardLayout},
computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    }
}
}
</script>