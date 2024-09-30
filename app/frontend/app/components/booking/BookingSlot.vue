<template>
    <div class="bookingSlot">
        <div class="bookingSlot__left">
            <div class="bookingSlot__info">
                <div><span>Name:</span></div>
                {{ bookingSlot.name }}
            </div>
            <div
                v-if="bookingSlot.channel"
                class="bookingSlot__info">
                <div><span>Channel:</span></div>
                {{ bookingSlot.channel.title }}
            </div>
            <!-- <div class="bookingSlot__info">
                Sessions: {{ bookingSlot.sessionCount }}
            </div> -->
        </div>
        <div class="bookingSlot__right">
            <m-icon
                v-tooltip="'Clone this Slot'"
                size="1.5rem"
                @click="clone">
                GlobalIcon-copy2
            </m-icon>

            <m-icon
                size="1.5rem"
                v-tooltip="'Edit this Slot'"
                @click="edit">
                GlobalIcon-edit
            </m-icon>

            <m-icon
                size="1.5rem"
                v-tooltip="'Delete this Slot'"
                @click="remove">
                GlobalIcon-trash
            </m-icon>
        </div>
    </div>
</template>

<script>
import Booking from "@models/Booking"

export default {
    props: {
        bookingSlot: {
            type: Object,
            required: true
        }
    },
    data() {
        return {

        }
    },
    methods: {
        edit() {
            this.$eventHub.$emit('open-modal:BookingSlotModal', 'edit', this.bookingSlot)
        },
        clone() {
            this.$eventHub.$emit('open-modal:BookingSlotModal', 'clone', this.bookingSlot)
        },
        remove() {
            if(confirm("Are you sure you want to delete this booking slot?")) {
                Booking.api().removeBookingSlot({id: this.bookingSlot.id}).then((res) => {
                    this.$flash("Deleted", "success")
                    this.$eventHub.$emit('update:BookingSlotList')
                })
            }
        }
    }
}
</script>

<style>

</style>