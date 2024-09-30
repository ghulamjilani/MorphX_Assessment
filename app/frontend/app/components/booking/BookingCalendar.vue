<template>
    <div class="bookingCalendar">
        <vue-cal
            ref="fullCalendar"
            :disable-views="['years', 'year']"
            class="fullCalendar vuecal--blue-theme"
            today-button
            :events="events"
            :focus-on-click="false"
            selectable="false"
			:time-cell-height="60"
            :min-cell-width="checkMobile ? 150 : 50"
			:active-view="checkMobile ? 'day' : 'week'"
            @ready="ready($event)">
            <template #today-button>
                Today
            </template>
            <template #arrow-prev>
                <i class="GlobalIcon-angle-left" />
            </template>
            <template #arrow-next>
                <i class="GlobalIcon-angle-right" />
            </template>
            <template #event="{ event, view }">
                <div class="vuecal__event">
                    <v-popover
                        v-if="event.booking"
                        :popover-class="(checkMobile && view == 'week' ? 'session__event__popoverMobile' : 'session__event__popover') + ' ' + (event.dayNumber == 0 && view == 'week' ? 'sunday' : '')">
                        <div class="session__event__popover__trigger">
                            Session
                            <i
                                v-close-popover
                                class="GlobalIcon-info-square" />
                        </div>

                        <!-- This will be the content of the popover -->
                        <template slot="popover">
                            <div class="session__event__content">
                                <div class="session__event__content__title">
                                    Session Details
                                    <i
                                        v-close-popover
                                        class="GlobalIcon-clear" />
                                </div>
                                <div
                                    v-if="event.booking && event.booking.session"
                                    class="session__event__content__list">
                                    <div>
                                        <span>Name: </span>
										<a
                                            :href="event.booking.session.url"
                                            target="_blank">{{ event.booking.session.title }};</a>
                                        <!--session name is link to session page-->
                                    </div>
									<div>
										<span>Session type:</span> Booked session;
										<!--при возможности указать какой тип сессии, обычная, стрим, интерактив, буккед и тд-->
									</div>
                                    <div>
                                        <span>Cost:</span> {{ (event.booking.session.price_cents / 100).toFixed(2) }}$;
                                    </div>
                                    <div>
                                        <span>Duration:</span> {{ event.booking.duration }} min;
                                    </div>
                                    <div>
                                        <span>Session Start:</span>{{ event.start.formatTime('HH:mm') }}
									</div>
									<div>
										<span>Session End:</span>{{ event.end.formatTime('HH:mm') }}
                                    </div>
                                    <div>
                                        <span>Replay:</span> {{ event.booking.session.replay ? 'included' : 'not included' }};
                                    </div>
                                </div>
                                <div
                                    v-if="event.booking && event.booking.user"
                                    class="session__event__buyerDetails">
                                    <div class="session__event__buyerDetails__title">
                                        Buyer Details
                                    </div>
                                    <div class="session__event__buyerDetails__list">
                                        <div class="session__event__buyerDetails__list__left">
											<a
												:href="event.booking.user.absolute_url"
												class="UserTile__img"
												target="_blank">
												<m-avatar
													:src="event.booking.user.avatar_url"
													:alt="event.booking.user.public_display_name"
													size="s"/>
											</a>
                                        </div>
                                        <div class="session__event__buyerDetails__list__right">
                                            <div>
                                                <span>Name:</span>
												<a
                                                    :href="event.booking.user.absolute_url"
                                                    target="_blank">
                                                    {{ event.booking.user.public_display_name }}
                                                </a>
                                                <!--name is link to user page in new window-->
                                            </div>
                                        </div>
                                    </div>
									<div
                                        v-if="event.booking.comment"
                                        class="session__event__buyerDetails__list__additionalInfo">
										<span>Additional info:</span>
										{{ event.booking.comment }}
									</div>
                                </div>
                            </div>
                        </template>
                    </v-popover>
                    <div
                        v-if="!event.booking"
                        class="vuecal__event-time">
                        <span>Booking hours:</span>
                        <span>{{ event.start.formatTime("HH:mm") }}</span> -
                        <span>{{ event.end.formatTime("HH:mm") }}</span>
                        <br>
                        <span v-if="+event.schedule.multiplier != 0">Multiplier: {{ event.schedule.multiplier > 0 ? '+' : '' }}{{ event.schedule.multiplier }}%</span>
                    </div>
                </div>
            </template>
            <template #events-count="{ events, view }">
                <div
                    v-if="events.filter(e => !e.booking).length > 0"
                    class="vuecal__events-count">
                    {{ events.filter(e => !e.booking).length }}
                </div>
                <div
                    v-if="events.filter(e => e.booking).length > 0"
                    class="vuecal__events-count vuecal__events-count__sessions">
                    {{ events.filter(e => e.booking).length }}
                </div>
            </template>
        </vue-cal>
    </div>
</template>

<script>
import VueCal from 'vue-cal'
import Booking from "@models/Booking"

export default {
    name: 'BookingCalendar',
    components: {
        VueCal
    },
    data() {
        return {
            events: [],
            bookings: [],
            slots: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        checkMobile() {
			return this.$device.mobile()
		},
    },
    mounted() {
        this.$eventHub.$on("booking:slots-loaded", (bookingSlots) => {
            this.slots = bookingSlots
            this.getAllBookings()
        })
    },
    methods: {
        ready() {
            // this.monthChange()
            console.log("ready")
            this.$nextTick(() => {
                document.querySelector(".vuecal__arrow.vuecal__arrow--prev").addEventListener("click", () => {
                    this.monthChange()
                })
                document.querySelector(".vuecal__arrow.vuecal__arrow--next").addEventListener("click", () => {
                    this.monthChange()
                })
                document.querySelector(".vuecal__today-btn").addEventListener("click", () => {
                    this.monthChange()
                })
                document.querySelector(".vuecal__bg").scroll({
                    top: 500,
                    behavior: "smooth"
                })
            })
        },
        addNewEvent(dayName, weekNumber, schedule) {
            let days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            let daytoset = days.indexOf(dayName) + 1
            let date = new Date()
            let currentWeek = this.getWeekNumber(date)
            let distance = (daytoset - date.getDay()) + ((weekNumber - currentWeek) * 7)
            date.setDate(date.getDate() + distance)

            let sh = +schedule.start.split(':')[0]
            let sm = +schedule.start.split(':')[1]
            let eh = +schedule.end.split(':')[0]
            let em = +schedule.end.split(':')[1]

            let event = {
                title: "",
                content: "",
                start: new Date(date.setHours(sh, sm, 0, 0)),
                end: new Date(date.setHours(eh, em, 0, 0)),
                startTimeMinutes: sh * 60 + sm,
                endTimeMinutes: eh * 60 + em,
                schedule
            }

            this.events.push(event)
        },
        getWeekNumber(date){
            var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
            var dayNum = d.getUTCDay() || 7
            d.setUTCDate(d.getUTCDate() + 4 - dayNum)
            var yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1))
            return Math.ceil((((d - yearStart) / 86400000) + 1)/7)
        },
        getAllBookings() {
            this.events = []
            this.getBookingDaysInfo()
            this.slots.forEach(bs => {
                let weeks = JSON.parse(bs.week_rules)
                let slot_rules = JSON.parse(bs.slot_rules)
                weeks.forEach(week => {
                    slot_rules.forEach(sr => {
                        sr.scheduler.forEach(schedule => {
                            this.addNewEvent(sr.name, week, schedule)
                        })
                    })
                })
            })
        },
        getBookingDaysInfo() {
            let currentStartDate = this.$refs.fullCalendar.view.startDate
            let start = window.moment(currentStartDate).startOf('month').add(-1, "days").add(-1, "months").format()
            let end = window.moment(currentStartDate).endOf('month').add(1, "days").add(1, "months").format()
            Booking.api().getAllBookingsDayInfo({
                date_from: start,
                date_to: end,
                requested_bookings: true
            }).then(res => {
                let bookings = res.response.data || []
                bookings.forEach(booking => {
                    let event = {
                        title: "Session",
                        content: '',
                        start: new Date(booking.start_at).toLocaleString("en-US", {timeZone: this.currentUser.timezone}),
                        end: new Date(booking.end_at).toLocaleString("en-US", {timeZone: this.currentUser.timezone}),
                        class: 'session__event__tile',
                        background: true,
                        booking,
                        dayNumber: new Date(booking.start_at).getDay()
                    }
                    this.events.push(event)
                })
            })
        },
        monthChange() {
            this.getAllBookings()
        },
		logEvents(message, events) {
			console.log(message, events)
		}
    }
}
</script>

<style>

</style>