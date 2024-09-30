<template>
    <div class="mb-week">
        <div class="sc-table">
            <div class="sc-thead">
                <div class="sc-row">
                    <div
                        v-for="day in week"
                        :key="`${day.format('ddd')}-${day.unix()}`"
                        :class="{today: isToday(day)}"
                        class="sc-cell">
                        {{ day.format('ddd') }}
                        <span class="fulldate">, {{ day.format('MMM') }} {{ day.date() }}  </span>
                    </div>
                </div>
            </div>
            <div class="sc-tbody">
                <div class="sc-row">
                    <div
                        v-for="day in week"
                        :key="day.unix()"
                        :class="{today: isToday(day), past: day.isBefore(_today)}"
                        class="sc-cell">
                        <div class="date">
                            <span> {{ day.date() }} </span>
                        </div>
                        <component
                            :is="scheduleItem.calendar_component_name"
                            v-for="scheduleItem in getScheduleItems(day)"
                            :key="scheduleItem.id"
                            :calendar-item-data="scheduleItem"
                            :scheduler-for="schedulerFor"
                            mode="week" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import mdSchedule from "@mixins/mbSchedule.js"
import MbScheduleItem from "@components/mindbodyonline/schedule/MbScheduleItem.vue"
import SessionCalendarItem from "@components/mindbodyonline/schedule/SessionCalendarItem.vue"
import VideoCalendarItem from "@components/calendar/VideoCalendarItem.vue"
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'
import utils from '@helpers/utils'
import eventHub from "@helpers/eventHub.js"

export default {
    components: {MbScheduleItem, SessionCalendarItem, VideoCalendarItem},
    mixins: [mdSchedule],
    props: ['schedulerFor', 'channel_id'],
    data() {
        return {
            startDay: utils.dateToTimeZone(moment(), true).clone().startOf('week'),
            loading: 0
        }
    },
    computed: {
        endDay() {
            return this.startDay.clone().endOf('week')
        },
        week() {
            let calendar = []
            let index = this.startDay.clone()

            while (index.isSameOrBefore(this.endDay, 'day')) {
                let day = index.add(1, 'day')
                calendar.push(day.clone())
            }

            return calendar
        },
        _today() {
            return utils.dateToTimeZone(moment(), true)
        }
    },
    watch: {
        startDay() {
            this.emitNewDisplayDate()
            this.fetchSchedule()
        }
    },
    methods: {
        prev() {
            this.startDay = this.startDay.clone().subtract(1, 'days').startOf('week')
        },
        today() {
            let newStartDay = utils.dateToTimeZone(moment(), true).clone().startOf('week')
            if (this.startDay.format() === newStartDay.format()) {
                return
            }
            this.startDay = utils.dateToTimeZone(moment(), true).clone().startOf('week')
        },
        next() {
            this.startDay = this.endDay.clone().add(1, 'days')
        },
        emitNewDisplayDate() {
            this.$emit('mb-display-date', {mode: 'week', startDay: this.week[0], endDay: this.week[6]})
        },
        fetchSchedule: utils.debounce(function () {
            let today = utils.dateToTimeZone(moment(), true)

            // TODO: andrey mb integration
            // MbClassSchedule.api().fetch({
            //   start_date_after: this.week[0].toISOString(),
            //   start_end_before: this.week[6].toISOString(),
            // })

            this.loading = 0
            eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})

            LightSession.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: today.toISOString(),
                start_at_to: this.endDay > today ? this.endDay.toISOString() : today.toISOString()
            }).then(() => {
                this.loading++
                eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
            })

            LightVideo.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: this.startDay.toISOString(),
                start_at_to: this.endDay.toISOString()
            }).then(() => {
                this.loading++
                eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
            })
        }, 300)
    },
    created() {
        this.emitNewDisplayDate()
    }
}
</script>