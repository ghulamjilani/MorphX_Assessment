<template>
    <dashboard-layout
        :active-name="isContactsAndMailingAvailable ? 'Contacts & Mailing' : 'Contacts'"
        class="CM__dashboard" />
</template>

<script>
import DashboardLayout from '../dashboard/Layout.vue'

export default {
    name: 'ContactsMailingDashboardPage',
    components: {DashboardLayout},
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isContactsAndMailingAvailable() {
            return this.currentUser?.subscriptionAbility?.can_manage_contacts_and_mailing
        }
    }
}
</script>