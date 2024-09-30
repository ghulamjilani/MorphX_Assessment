<template>
    <dashboard-layout
        :active-name="'Components Builder'"
        :name="'Components Builder'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '@components/dashboard/Layout.vue'

export default {
  name: 'ComponentsBuilderDashboardPage',
  components: {DashboardLayout},
  computed: {
      currentUser() {
          return this.$store.getters["Users/currentUser"]
      }
  }
}
</script>