<template>
    <div class="bookUser">
        <div class="bookUser__title">
            Booking
        </div>
        <div
            v-if="successMessage"
            class="bookUser__successMessage scrollOffset">
            Private booked session successfully purchased. You can find it in your dashboard. We have included a direct link for easy access:
            <a href="/dashboard/sessions_participates"> Go to Dashboard </a>
            <br>
            <m-btn @click="newAfterSuccess" class="bookUser__successMessage__button" type="main" size="m">Book another session</m-btn>
        </div>
        <div
            v-if="!successMessage"
            class="bookUser__slots scrollOffset">
            <h3>Select Slot</h3>

            <div class="bookUser__slots__list">
                <template v-for="slot in slots">
                    <div
                        v-if="!selected || (selected && selected.id == slot.id)"
                        :key="slot.id"
                        class="bookUser__slots__list__item"
                        :class="{'selected': selected && selected.id == slot.id}"
                        @click="selectSlot(slot)">
                        <BookingSlot
                            :booking-slot="slot"
                            :duration="duration"
                            :class="{'selected': selected && selected.id == slot.id}" />
                    </div>
                </template>
            </div>
        </div>
        <div
            v-if="!successMessage && selected"
            class="bookUser__duration__select">
            <div class="bookUser__duration__select__title scrollOffset">
                Select Duration
            </div>
            <div class="bookUser__duration__select__wrapper">
                <template
                    v-for="slotDurationPrice in slotDurationPrices">
                    <div
                        :class="{'active': selectedDuration && selectedDuration == slotDurationPrice.value}"
                        class="bookUser__duration__select__item"
                        @click="selectDuration(slotDurationPrice)">
                        <i
                            v-if="selectedDuration && selectedDuration == slotDurationPrice.value"
                            class="GlobalIcon-check-circle" />
                        <div>
                            <span>Duration</span>
                            <div>{{ slotDurationPrice.duration }}</div>
                        </div>
                        <div>
                            <span>Price</span>
                            <div>{{ slotDurationPrice.price }}</div>
                        </div>
                    </div>
                </template>
            </div>
        </div>

        <div
            v-if="!successMessage && selected && selectedDuration"
            class="bookUser__miniCalendar__wrapper">
            <div class="bookUser__miniCalendar__title">
                Select Day and Time
            </div>
            <div class="bookUser__miniCalendar">
                <BookingMiniCalendar
                    :booking-slots="slots"
                    :booking-slot="selected"
                    :duration="duration"
                    :owner="owner"
                    @change="changeDateTime" />
            </div>
        </div>
        <div
            v-if="!successMessage && selected && selectedDuration && date"
            class="bookUser__comment scrollOffset">
            <m-input
                v-model="comment"
                type="text"
                :textarea="true"
                label="comment to creator (optional)"
                :max-counter="1200"
                :max-length="1200"
                rules="max-length:1200" />
        </div>
        <div
            v-if="!successMessage && selected && selectedDuration && date"
            class="bookUser__btn text__center">
            <m-btn
                type="main"
                size="m"
                :disabled="finalPriceCents == null || comment.length >= 1201 || loading"
                @click="book">
                Book Session {{ selected.replay ? 'with Replay ' : '' }} for {{ (finalPriceCents/100).toFixed(2) }}$
            </m-btn>
        </div>
    </div>
</template>

<script>
import Booking from "@models/Booking"
import BookingSlot from "@components/booking/bookModal/BookingSlot.vue"
import BookingMiniCalendar from "@components/booking/bookModal/BookingMiniCalendar.vue"
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    components: {BookingSlot, BookingMiniCalendar, BookingPayment},
    props: {
        owner: Object
    },
    data() {
        return {
            loading: false,
            slots: [],
            selected: null,
            selectedDuration: null,
            date: null,
            finalPrice: '..$',
            finalPriceCents: 0,
            comment: "",
            successMessage: null
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        slotDurationPrices() {
            if(this.selected) {
                return this.selected.booking_prices.map(item => {
                    return {
						duration: item.duration + ' min',
						price: '$' + item.price_cents/100,
                        name: item.duration + 'min for ' + item.price_cents/100 + '$',
                        value: item.id
						// TODO: Andrey prosti menya, ya ne znayu kak eto sdelat normalno :( nyshen refaktor :)
                    }
                })
            }
            return []
        },
        duration() {
            return this.selected?.booking_prices.find(item => item.id == this.selectedDuration)
        }
    },
    watch: {
        selected(val) {
            this.$nextTick(() => {
                if(val) {
                    document.querySelector(".bookUser__duration__select__title").scrollIntoView({block: "start", behavior: "smooth" })
                }
                else {
                    document.querySelector(".bookUser__slots").scrollIntoView({block: "start", behavior: "smooth" })
                }
            })
        }
    },
    mounted() {
        this.fetchSlots()
        this.$eventHub.$on("booking:created", (successMessage) => {
            this.finalPriceCents = null
            this.successMessage = successMessage
            this.$nextTick(() => {
                document.querySelector(".bookUser__successMessage").scrollIntoView({block: "start", behavior: "smooth" })
            })
        })
    },
    methods: {
        fetchSlots() {
            Booking.api().getBookingSlots({
                user_id: this.owner.id
            }).then(res => {
                this.slots = res.response.data
            })
        },
        selectSlot(slot) {
            if(this.selected?.id == slot.id && !this.selectedDuration) {
                this.selected = null
            } else {
                this.selected = slot
            }
        },
        changeDateTime(data) {
            this.date = data
            this.calculatePrice()
            this.$nextTick(() => {
                document.querySelector(".bookUser__comment").scrollIntoView({block: "start", behavior: "smooth" })
            })
        },
        book() {
            let data = {
                bookingSlot: this.selected,
                owner: this.owner,
                date: this.date,
                duration: this.duration,
                comment: this.comment,
                price_cents: this.finalPriceCents
            }
            this.$eventHub.$emit("open-modal:bookingPayment", data)
        },
        calculatePrice() {
            this.loading = true
            let start = window.moment.tz(this.date.date + " " + this.date.time, this.currentUser.timezone)
            let end = window.moment.tz(this.date.date + " " + this.date.time, this.currentUser.timezone)
            end.add(this.duration.duration, "minutes")
            let start_at = start.format()
            let end_at = end.format()

            Booking.api().calculatePrice({
                id: this.selected.id,
                price_id: this.duration.id,
                start_at: start_at,
                end_at: end_at
            }).then(res => {
                this.loading = false
                this.finalPriceCents = +res.response.data
            }).catch((error) => {
                this.finalPriceCents = null
                    this.loading = false
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
        },
		selectDuration(slotDurationPrice) {
			this.selectedDuration = slotDurationPrice.value
		},
        newAfterSuccess() {
            this.selected = null
            this.selectedDuration = null
            this.date = null
            this.finalPrice = '..$'
            this.finalPriceCents = 0
            this.comment = ""
            this.successMessage = null
        }
    }

}
</script>

<style>

</style>