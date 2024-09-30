<template>
    <dashboard-layout
        class="CM__dashboard"
        :name="'Documents'"
        :active-name="$t('frontend.app.components.documents.dashboard_page.documents')"/>
</template>

<script>
import DashboardLayout from '../dashboard/Layout.vue'

export default {
    name: 'DocumentsDashboardPage',
    components: {DashboardLayout}
}
</script>