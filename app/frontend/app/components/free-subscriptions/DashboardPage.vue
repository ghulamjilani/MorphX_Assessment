<template>
    <dashboard-layout
        :active-name="'Free Subscriptions'"
        class="FS__dashboard" />
</template>

<script>
import DashboardLayout from "@components/dashboard/Layout.vue"

export default {
    name: "FreeSubscriptionsVueDashboardPage",
    components: { DashboardLayout }
}
</script>
