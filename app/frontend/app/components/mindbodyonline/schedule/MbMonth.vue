<template>
    <div class="mb-month">
        <div
            v-if="loading < 2"
            class="loading">
            <div class="spinnerSlider">
                <div class="bounceS1" />
                <div class="bounceS2" />
                <div class="bounceS3" />
            </div>
        </div>
        <div class="sc-table">
            <div
                v-if="displayNoItems"
                class="displayNoItemsWrap">
                <div class="displayNoItems">
                    {{ $t('channel_page.no_sessions_for_month') }}
                </div>
            </div>
            <div
                :class="{'tbody-has-scrool-bar': isScTbodyHasScrollBar}"
                class="sc-thead">
                <div class="sc-row">
                    <div
                        v-for="day in weekDays"
                        :key="day"
                        class="sc-cell">
                        {{ day }}
                    </div>
                </div>
            </div>

            <div
                ref="tBody"
                class="sc-tbody">
                <div
                    v-for="(week, index) in month"
                    :key="index"
                    class="sc-row">
                    <div
                        v-for="day in week"
                        :key="day.unix()"
                        :class="{today: isToday(day), past: day.isBefore(_today)}"
                        class="sc-cell">
                        <div class="date">
                            <span>
                                {{ day.date() }}
                            </span>
                        </div>

                        <template v-if="sheduleItems[day.format('YYYY-MM-DD')].length <= 2">
                            <component
                                :is="scheduleItem.calendar_component_name"
                                v-for="scheduleItem in sheduleItems[day.format('YYYY-MM-DD')].slice(0, 2)"
                                :key="scheduleItem.id"
                                :calendar-item-data="scheduleItem"
                                :scheduler-for="schedulerFor"
                                mode="month" />
                        </template>

                        <template v-else>
                            <component
                                :is="scheduleItem.calendar_component_name"
                                v-for="scheduleItem in sheduleItems[day.format('YYYY-MM-DD')].slice(0, 1)"
                                :key="scheduleItem.id"
                                :calendar-item-data="scheduleItem"
                                :scheduler-for="schedulerFor"
                                mode="month" />

                            <v-popover
                                :popper-options="{ modifiers: { preventOverflow: { boundariesElement: 'window' } } }"
                                popover-class="common-pop-up v-tooltip">
                                <div
                                    v-if="sheduleItems[day.format('YYYY-MM-DD')].length > 2"
                                    class="more-btn">
                                    +{{ sheduleItems[day.format('YYYY-MM-DD')].length - 1 }}
                                </div>

                                <template slot="popover">
                                    <calendar-day-pop-up
                                        :schedule-items="sheduleItems[day.format('YYYY-MM-DD')].slice(1)"
                                        :scheduler-for="schedulerFor" />
                                </template>
                            </v-popover>
                        </template>
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
import CalendarDayPopUp from "@components/mindbodyonline/schedule/CalendarDayPopUp.vue"
import eventHub from "@helpers/eventHub.js"
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'
import utils from '@helpers/utils'
import Vue from "vue"

export default {
    components: {MbScheduleItem, CalendarDayPopUp, SessionCalendarItem, VideoCalendarItem},
    mixins: [mdSchedule],
    props: ['schedulerFor', 'channel_id'],
    data() {
        return {
            loading: 2,
            monthIndex: 0,
            isScTbodyHasScrollBar: false,
            displayNoItems: false,
            shouldcheckIsItemsPresent: false,
            weekDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            sheduleItems: {}
        }
    },
    computed: {
        startDay() {
            return utils.dateToTimeZone(moment(), true).clone().add(this.monthIndex, 'months').startOf('month').startOf('week')
        },
        endDay() {
            return utils.dateToTimeZone(moment(), true).clone().add(this.monthIndex, 'months').endOf('month').endOf('week')
        },
        month() {
            let calendar = []
            let index = this.startDay.clone()

            while (index.isBefore(this.endDay, 'day')) {
                calendar.push(
                    new Array(7).fill(0).map(
                        (n, i) => {
                            let day = index.add(1, 'day')
                            this.sheduleItems[day.format('YYYY-MM-DD')] = this.getScheduleItems(day)
                            return day.clone()
                        }
                    )
                )
            }
            if (this.shouldcheckIsItemsPresent) {
                Vue.nextTick(() => {
                    this.checkIsItemsPresent()
                })
            }

            return calendar
        },
        _today() {
            return utils.dateToTimeZone(moment(), true)
        }
    },
    watch: {
        monthIndex() {
            this.emitNewDisplayDate()
            this.fetchSchedule()
        }
    },
    methods: {
        prev() {
            this.monthIndex--
        },
        today() {
            this.monthIndex = 0
        },
        next() {
            this.monthIndex++
        },
        emitNewDisplayDate() {
            this.$emit('mb-display-date', {mode: 'month', midDay: this.month[2][0]})
        },
        handleTbodyScroll() {
            document.querySelector("body").trigger("click")
            this.checkTbodyScroll()
        },
        checkTbodyScroll() {
            if (this.$refs.tBody && this.$refs.tBody.scrollHeight > this.$refs.tBody.clientHeight) {
                this.isScTbodyHasScrollBar = true
            } else {
                this.isScTbodyHasScrollBar = false
            }
        },
        checkIsItemsPresent() {
            if (document.querySelector('.mb-month .mb-schedule-item')) {
                this.displayNoItems = false
            } else {
                this.displayNoItems = true
            }
        },
        fetchSchedule: utils.debounce(function () {
            let today = moment()

            // TODO: andrey mb integration
            // MbClassSchedule.api().fetch({
            //   start_date_before: this.month[this.month.length - 1][6].toISOString(),
            //   end_date_after: this.month[0][0].toISOString(),
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
                this.checkTbodyScroll()
                eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
            })

            LightVideo.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: this.startDay.toISOString(),
                start_at_to: this.endDay.toISOString()
            }).then(() => {
                this.loading++
                this.checkTbodyScroll()
                eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
            })
        }, 300)
    },
    created() {
        this.emitNewDisplayDate()
    },
    mounted() {
        this.checkTbodyScroll()
        this.$refs.tBody.addEventListener('scroll', this.handleTbodyScroll)
        window.addEventListener('resize', () => {
            this.checkTbodyScroll()
        })
        eventHub.$on("mb-schedule-size-changed", () => {
            Vue.nextTick(() => {
                this.checkTbodyScroll()
            })
        })
        setTimeout(() => {
            this.checkIsItemsPresent()
            this.shouldcheckIsItemsPresent = true
        }, 1000)
    },
    destroyed() {
        if (this.$refs.tBody)
            this.$refs.tBody.removeEventListener('scroll', this.handleTbodyScroll)
        window.removeEventListener('resize', () => {
            this.checkTbodyScroll()
        })
    }
}
</script>