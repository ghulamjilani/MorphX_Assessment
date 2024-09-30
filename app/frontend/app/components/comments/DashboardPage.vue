<template>
    <dashboard-layout
        :active-name="'Comments'"
        :name="'Comments'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
    name: 'CommentsDashboardPage',
    components: {DashboardLayout},
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    }
}
</script>