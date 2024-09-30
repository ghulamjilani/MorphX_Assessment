<template>
    <dashboard-layout
        :active-name="'Optin Manager'"
        :name="'Optin Manager'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
name: 'MopsDashboardPage',
components: {DashboardLayout},
computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    }
}
}
</script>