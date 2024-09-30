<template>
    <dashboard-layout
        :active-name="'Booking'"
        :name="'Booking'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
name: 'BookingDashboardPage',
components: {DashboardLayout},
computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    }
}
}
</script>