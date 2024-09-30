<template>
    <m-btn
        class="bookingSlotList__addBtn"
        :square="false"
        :full="false"
        size="s"
        type="main"
        :disabled="!credentialsAbility.can_manage_booking"
        @click="addNewSlot">
        + New Booking
    </m-btn>
</template>

<script>

export default {
	name: 'bookingSlot__addNewSlotBtn',
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        credentialsAbility() {
            return this.currentUser.credentialsAbility
        },
    },
	methods: {
		addNewSlot() {
            if(this.currentUser.confirmed_at) {
                this.$eventHub.$emit('open-modal:BookingSlotModal', 'create')
            }
            else {
                this.$flash('Please confirm your email address to create a new slot', 'error')
            }
		}
	}
}
</script>