<template>
    <div class="bookingDashboard">
        <div class="bookingDashboard__content">
            <div class="bookingDashboard__title">
                <h2>Booking</h2>
                <div class="bookingDashboard__title__withBtn">
                    <span>
                        Сalendar with the schedule of slots and purchased sessions
                    </span>
                    <div>
                        <bookingSlot__addNewSlotBtn />
                    </div>

                </div>
            </div>
            <div class="separateLine" />

            <booking-calendar />
        </div>
        <div>
            <div class="bookingDashboard__content">
                <div class="bookingDashboard__title">
                    <h2>My Bookings</h2>
                    <span>Creating and editing slot schedules</span>
                </div>
                <booking-slot-list />
            </div>
            <div class="text__right">
                <bookingSlot__addNewSlotBtn />
            </div>
        </div>
    </div>
</template>

<script>
import BookingCalendar from './BookingCalendar.vue'
import BookingSlotList from './BookingSlotList.vue'
import BookingSlot__addNewSlotBtn from "./BookingSlot__addNewSlotBtn.vue"

export default {
    name: 'BookingDashboard',
    components: {
		BookingSlot__addNewSlotBtn,
        BookingCalendar,
        BookingSlotList
    }
}
</script>