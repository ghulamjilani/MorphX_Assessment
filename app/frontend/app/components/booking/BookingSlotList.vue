<template>
    <div class="bookingSlotList">
        <booking-slot
            v-for="slot in slots"
            v-show="!slot.deleted"
            :key="slot.id"
            :booking-slot="slot" />
        <create-edit-booking-slot />
    </div>
</template>

<script>
import BookingSlot from './BookingSlot.vue'
import CreateEditBookingSlot from './CreateEditBookingSlot.vue'
import Booking from '@models/Booking'
import BookingSlot__addNewSlotBtn from "./BookingSlot__addNewSlotBtn.vue"

export default {
    name: 'BookingSlotList',
    components: {
		BookingSlot__addNewSlotBtn,
        BookingSlot,
        CreateEditBookingSlot
    },
    data() {
        return {
            slots: []
        }
    },
    mounted() {
        this.fetchSlots()
        this.$eventHub.$on('update:BookingSlotList', () => {
            this.fetchSlots()
        })
    },
    methods: {
        fetchSlots() {
            Booking.api().getBookingSlots().then((res) => {
                this.slots = res.response.data
                this.$eventHub.$emit("booking:slots-loaded", this.slots)
            })
        }
    }
}
</script>

<style>

</style>