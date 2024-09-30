<template xmlns="http://www.w3.org/1999/html">
    <div class="miniCalendar">
        <div class="miniCalendar__header">
            <m-btn
                class="miniCalendar__header__btn"
                :disabled="selectedWeek <= currentWeek && selectedYear <= currentYear"
                @click="changeWeek(-1)">
                <m-icon>GlobalIcon-angle-left</m-icon>
            </m-btn>
            {{ selectedWeekText }}
            <m-btn
                class="miniCalendar__header__btn"
                @click="changeWeek(1)">
                <m-icon>GlobalIcon-angle-right</m-icon>
            </m-btn>
        </div>
        <div class="miniCalendar__days">
            <div
                v-for="day in weekDaysInfo"
                :key="day.date"
                class="miniCalendar__day"
                :class="{'active': day.date == selectedDay, 'disabled': !day.canClick}"
                @click="selectDate(day)">
                <div
                    class="miniCalendar__day__topLine"
                    :class="{'active': day.active}" />
                <div class="miniCalendar__day__dayName">
                    {{ day.dayName }}
                </div>
                <div class="miniCalendar__day__dayNumber">
                    {{ day.dayNumber }}
                </div>
            </div>
        </div>

        <div
            v-if="bookingDayTimes.length == 0 && selectedDay"
            class="miniCalendar__times__empty text__center">
            No available time in this day
            </br>
            Please chose another day
        </div>

        <div class="miniCalendar__times">
            <m-btn
                v-for="time in bookingDayTimes"
                :key="time.time"
                type="bordered"
                class="miniCalendar__time"
                :disabled="!time.active"
                :class="{'active': selectedTime == time.time, 'multiplier': time.multiplier != 0}"
                @click="selectTime(time)">
                {{ time.time }}
                <span
                    v-if="time.multiplier != 0"
                    class="multiplier">{{ time.multiplier > 0 ? '+' : '' }}{{ time.multiplier }}%</span>
            </m-btn>
        </div>
    </div>
</template>

<script>
import Booking from "@models/Booking"

export default {
  props: {
    bookingSlot: Object,
    bookingSlots: Array,
    duration: Object,
    owner: Object
  },
  data() {
    return {
      weekStr: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      selectedWeek: 0,
      currentWeek: 0,
      currentYear: 2023,
      selectedYear: 0,
      selectedDay: null,
      selectedTime: null,
      dayBookings: [],
      ownerTz: null
    }
  },
  computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    },
    selectedWeekText() {
      let weekStart = window.moment().weeks(this.selectedWeek).weekday(1)
      let weekEnd = window.moment().weeks(this.selectedWeek).weekday(7)
      let str = weekStart.format("MMM") + " " + weekStart.format("DD")

      if(weekStart.format("Y") !== weekEnd.format("Y")) {
        str += ", " + weekStart.format("Y")
      }
      str += " - "
      if(weekStart.format("MMM") !== weekEnd.format("MMM")) {
        str += weekEnd.format("MMM") + " " + weekEnd.format("DD")
      }
      else {
        str += weekEnd.format("DD")
      }
      if(weekStart.format("Y") !== weekEnd.format("Y")) {
        str += ", " + weekEnd.format("YYYY")
      }
      str += ", " + weekEnd.format("Y")
      return str
    },
    weekDaysInfo() {
        let weekStart = window.moment().weeks(this.selectedWeek).weekday(1)
        let days = []
        for(let i = 0; i < 7; i++) {
            let day = {
                dayName: this.weekStr[i],
                dayNumber: weekStart.format("DD"),
                date: weekStart.format("YYYY-MM-DD"),
                active: this.calculatebookingDayTimes(weekStart.format("YYYY-MM-DD")).length > 0,
                canClick: weekStart.format("YYYY-MM-DD") >= window.moment().format("YYYY-MM-DD")
            }
            days.push(day)
            weekStart.add(1, 'days')
        }
        return days
    },
    bookingDayTimes() {
        return this.calculatebookingDayTimes(this.selectedDay)
    },
    canBookToday() {
        return !!this.$railsConfig.global.booking?.can_book_today
    }
  },
  mounted() {
    this.selectedWeek = window.moment().week()
    this.currentWeek = window.moment().week()
    this.selectedYear = window.moment().weeks(this.selectedWeek).weekday(1).format("Y")
    this.currentYear = window.moment().weeks(this.currentWeek).weekday(1).format("Y")

    this.selectedDay = window.moment().add(1, 'days').format("YYYY-MM-DD")
    if(window.moment().add(1, 'days').weeks() != this.selectedWeek) {
        this.selectedWeek++
        this.selectedYear = window.moment().weeks(this.selectedWeek).weekday(1).format("Y")
    }
    this.loadDay(this.selectedDay)
    this.selectedTime = null

    this.$eventHub.$on("booking:created", () => {
        this.loadDay(this.selectedDay)
        this.selectedTime = null
    })
  },
  methods: {
    changeWeek(direction) {
        this.selectedWeek += direction
        this.selectedYear = window.moment().weeks(this.selectedWeek).weekday(1).format("Y")
        this.selectedDay = window.moment(this.selectedDay).add(direction, 'weeks').format("YYYY-MM-DD")
        this.loadDay(this.selectedDay)
        this.selectedTime = null
    },
    selectDate(day) {
        if(this.selectedDay !== day.date && day.canClick) {
            this.selectedDay = day.date
            this.loadDay(day.date)
            this.selectedTime = null
        }
    },
    loadDay(date) {
        let day = window.moment(date)
        let start = day.add(-1, 'days').startOf("day").format()
        let end = day.add(2, 'days').endOf("day").format()
        Promise.all([this.bookingSlots.map(s => Booking.api().getBookingDayInfo({
            id: s.id,
            date_from: start,
            date_to: end
        }))])
        .then(res => {
            this.dayBookings = []
            res[0].forEach(async r => {
                let bs = await r
                this.dayBookings = this.dayBookings.concat(bs.response.data.map(d => {
                    d.start = window.moment(d.start_at).tz(this.currentUser.timezone).format("HH:mm")
                    d.end = window.moment(d.end_at).tz(this.currentUser.timezone).format("HH:mm")
                    d.start_at = window.moment(d.start_at).tz(this.currentUser.timezone)
                    d.end_at = window.moment(d.end_at).tz(this.currentUser.timezone)
                    return d
                }))
                let today = window.moment(date)
                this.dayBookings = this.dayBookings.filter(booking => {
                    return booking.start_at.format("DD") == today.format("DD") // isSame not working
                })
            })
        })
    },
    selectTime(time) {
        this.selectedTime = time.time
        this.$emit('change', {
            date: this.selectedDay,
            time: this.selectedTime
        })
    },
    calculatebookingDayTimes(selectedDay) {
        let times = []
        let slot_rules = JSON.parse(this.bookingSlot.slot_rules)
        let week_rules = JSON.parse(this.bookingSlot.week_rules)

        let daysToCheck = [selectedDay]
        let tommorow = window.moment(selectedDay).add(1, 'days')
        let yesterday = window.moment(selectedDay).add(-1, 'days')
        if(week_rules.includes(tommorow.weeks() + 1)) {
            daysToCheck.push(tommorow.format("YYYY-MM-DD"))
        }
        if(week_rules.includes(yesterday.weeks() + 1)) {
            daysToCheck.push(yesterday.format("YYYY-MM-DD"))
        }

        let scheduler = daysToCheck.map(dtc => {
            let day = window.moment(dtc)
            let dayIndex = day.weekday() - 1
            if(day.weekday() == 0) dayIndex = 6
            let rule = slot_rules[dayIndex]
            if(rule === undefined) return []
            return rule.scheduler.map(sch => {
                this.ownerTz = sch.tz
                let start = window.moment.tz(day.format("YYYY-MM-DD") + " " + sch.start, sch.tz).tz(this.currentUser.timezone)
                let end = window.moment.tz(day.format("YYYY-MM-DD") + " " + sch.end, sch.tz).tz(this.currentUser.timezone)
                return {
                    start_at: start.format(),
                    end_at: end.format(),
                    start: start.format("HH:mm"),
                    end: end.format("HH:mm"),
                    multiplier: sch.multiplier,
                    tz: sch.tz
                }
            }).flat()
        }).flat()

        // check start and end is the same day
        let newToAdd = []
        scheduler.forEach(sch => {
            let start = window.moment.tz(sch.start_at, this.currentUser.timezone).tz(this.currentUser.timezone)
            let end = window.moment.tz(sch.end_at, this.currentUser.timezone).tz(this.currentUser.timezone)
            if(start.format("YYYY-MM-DD") !== end.format("YYYY-MM-DD")) {
                let oldEnd = end.clone()
                sch.end = "23:59"
                sch.end_at = window.moment.tz(sch.start_at, this.currentUser.timezone).endOf('day').toString()
                newToAdd.push({
                    start_at: window.moment.tz(oldEnd, this.currentUser.timezone).startOf('day').toString(),
                    end_at: oldEnd,
                    start: "00:00",
                    end: oldEnd.format("HH:mm"),
                    multiplier: sch.multiplier,
                    tz: sch.tz
                })
            }
        })
        scheduler = scheduler.concat(newToAdd)

        let selectedDayM = window.moment(selectedDay)
        scheduler = scheduler.filter(sch => {
            return window.moment(sch.start_at).format("DD") ==  selectedDayM.format("DD")
        })

        if(scheduler === undefined || scheduler.length == 0 || !week_rules.includes(this.selectedWeek)) return times

        let dayBookingsPeriods = this.dayBookings.map(booking => {
            return {
                start: booking.start,
                end: booking.end
            }
        })
        // check active times
        scheduler?.forEach(sch => {
            let start = window.moment(sch.start, "HH:mm")
            let esch = sch.end.replace("59", "00")
            let end = window.moment(esch, "HH:mm")
            let diff = end.diff(start)/1000/60
            let maxIndex = diff / this.duration.duration
            for(let i = 0; i < Math.floor(maxIndex); i++) {
                let isToday = false
                let checkday = window.moment.tz(selectedDay + " " + start.format("HH:mm"), this.currentUser.timezone).tz(sch.tz)
                if(!this.canBookToday && window.moment().tz(sch.tz).format("YYYY-MM-DD") == checkday.format("YYYY-MM-DD")) {
                    isToday = true
                }

                let time = {
                    time: start.format("HH:mm"),
                    active: !isToday,
                    multiplier: sch.multiplier || false
                }
                times.push(time)

                if(dayBookingsPeriods.some(period => {
                    let periodStart = window.moment(period.start, "HH:mm").add(-this.duration.duration + 1, 'minutes')
                    let periodEnd = window.moment(period.end, "HH:mm")
                    return start.isBetween(periodStart, periodEnd) || start.format("HH:mm") == periodStart.format("HH:mm")
                })) {
                    time.active = false
                }
                if(window.moment(start).add(this.duration.duration, 'minutes').isAfter(end)) {
                    time.active = false
                }

                start.add(this.duration.duration, 'minutes')
            }
        })

        times.sort((a, b) => {
            let aM = window.moment(a.time, "HH:mm")
            let bM = window.moment(b.time, "HH:mm")
            if(aM.isBefore(bM)) return -1
            if(aM.isAfter(bM)) return 1
            return 0
        })

        return times
    }
  }
}
</script>

<style>

</style>