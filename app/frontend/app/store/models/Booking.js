import {Model} from '@vuex-orm/core'

export default class Booking extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'Booking'

    static apiConfig = {
        actions: {
            getBookingSlots(params = {}) {
                return this.get(`/api/v1/user/booking/booking_slots`, {params})
            },
            createBookingSlot(params = {}) {
                return this.post(`/api/v1/user/booking/booking_slots`, params)
            },
            updateBookingSlot(params = {}) {
                return this.put(`/api/v1/user/booking/booking_slots/${params.id}`, params)
            },
            removeBookingSlot(params = {}) {
                return this.delete(`/api/v1/user/booking/booking_slots/${params.id}`, params)
            },
            getBookingCategories(params = {}) {
                return this.get(`/api/v1/user/booking/booking_categories`, {params})
            },
            getBookingDayInfo(params = {}) {
                return this.get(`/api/v1/user/booking/booking_slots/${params.id}/bookings`, {params})
            },
            getAllBookingsDayInfo(params = {}) {
                return this.get(`/api/v1/user/booking/bookings`, {params})
            },
            createBook(params = {}) {
                return this.post(`/api/v1/user/booking/bookings`, params)
            },
            calculatePrice(params = {}) {
                return this.get(`/api/v1/user/booking/booking_slots/${params.id}/calculate_price`, {params})
            },
            getBookingCreateInfo(params = {}) {
                return this.get(`/api/v1/user/booking/booking_slots/new`, {params})
            }
        }
    }
}