<template>
    <div
        :class="[{low: isLow, tall: isTall, overlay: isOverlay, hidden: isHidden}, schedulerFor]"
        class="mb-schedule">
        <div class="top-info-wrap">
            <div class="top-info">
                <div class="mode-switch">
                    <ul>
                        <li
                            v-if="sizeMode == 'low' || isSpa"
                            :class="{active: isDay}"
                            @click="switchMode('day')">
                            {{ $t('channel_page.day') }}
                        </li>
                        <li
                            :class="{active: isWeek}"
                            @click="switchMode('week')">
                            {{ $t('channel_page.week') }}
                        </li>
                        <li
                            :class="{active: isMonth}"
                            @click="switchMode('month')">
                            {{ $t('channel_page.month') }}
                        </li>
                    </ul>
                </div>
                <div class="displayDate">
                    {{ displayDate }}
                </div>
                <div class="navigation">
                    <ul>
                        <li
                            :class="{disabled: fetching}"
                            :title="fetching ? 'Schedule is loading' : ''"
                            class="arrow"
                            @click="prev()">
                            <i class="GlobalIcon-angle-left" />
                        </li>
                        <li
                            :class="{disabled: fetching}"
                            :title="fetching ? 'Schedule is loading' : ''"
                            class="today"
                            @click="today()">
                            Today
                        </li>
                        <li
                            :class="{disabled: fetching}"
                            :title="fetching ? 'Schedule is loading' : ''"
                            class="arrow"
                            @click="next()">
                            <i class="GlobalIcon-angle-right" />
                        </li>
                    </ul>
                </div>
            </div>
            <div
                v-show="isOverlay"
                class="minimize-wrap">
                <div
                    class="size-mode-btn btn btn__main btn-m"
                    @click="switchSizeMode(sm || 'low')">
                    <span> {{ $t('channel_page.close') }}</span>
                    <i class="GlobalIcon-Plus" />
                </div>
            </div>
        </div>

        <schedule-track
            v-if="open"
            v-show="isDay"
            ref="day"
            :channel_id="channel_id"
            :is-active="isDay"
            :scheduler-for="schedulerFor"
            :size-mode="sizeMode"
            :zero-date="zeroDate"
            @mb-display-date="updateDisplayDate" />

        <mb-week
            v-if="open"
            v-show="isWeek"
            ref="week"
            :channel_id="channel_id"
            :is-active="isWeek"
            :scheduler-for="schedulerFor"
            :size-mode="sizeMode"
            @mb-display-date="updateDisplayDate" />

        <mb-month
            v-if="open"
            v-show="isMonth"
            ref="month"
            :channel_id="channel_id"
            :is-active="isMonth"
            :scheduler-for="schedulerFor"
            :size-mode="sizeMode"
            @mb-display-date="updateDisplayDate" />

        <div
            v-if="mode != 'day'"
            class="size-mode-control-wrap">
            <div
                class="size-mode-btn btn btn__main btn-m"
                @click="switchSizeMode('overlay')">
                Show full calendar
            </div>
        </div>
    </div>
</template>

<script>
import eventHub from "@helpers/eventHub.js"
import MbWeek from "@components/mindbodyonline/schedule/MbWeek"
import MbMonth from "@components/mindbodyonline/schedule/MbMonth"
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'
import ScheduleTrack from "@components/calendar/ScheduleTrack"
import utils from '@helpers/utils'

export default {
    components: {MbWeek, MbMonth, ScheduleTrack},
    props: {
        schedulerFor: {
            type: String
        }, // mbs-organization, mbs-user
        channel_id: {
            type: Number
        },
        sm: {
            type: String
        },
        mbScheduleUid: {
            type: String
        },
        placement: {
            type: String,
            default: 'monolith'
        }
    },
    data() {
        return {
            displayDate: '',
            mode: 'month', // day, week, month
            sizeMode: 'low', // low, tall, overlay,
            zeroDate: utils.dateToTimeZone(moment(), true),
            fetching: false,
            open: false
        }
    },
    computed: {
        isDay() {
            return this.mode == 'day'
        },
        isWeek() {
            return this.mode == 'week'
        },
        isMonth() {
            return this.mode == 'month'
        },
        sizeModeBtnText() {
            return this.sizeMode == 'low' ? 'Expand' : 'Collapse'
        },
        isLow() {
            return this.sizeMode == 'low'
        },
        isTall() {
            return this.sizeMode == 'tall'
        },
        isOverlay() {
            return this.sizeMode == 'overlay'
        },
        isHidden() {
            return this.sizeMode == 'hidden'
        },
        isMonolith() {
            return this.placement == 'monolith'
        },
        isSpa() {
            return this.placement == 'spa'
        }
    },
    watch: {
        sizeMode(value) {
            if (value === 'overlay') {
                document.querySelector("body").classList.add("mb-schedule-overlay")
            } else {
                document.querySelector("body").classList.remove("mb-schedule-overlay")
            }
        }
    },
    created() {
        // TODO: andrey mb integration
        // MbClassSchedule.api().fetch({
        //   start_date_before: today.endOf('month').endOf('week').toISOString(),
        //   end_date_after: today.startOf('month').startOf('week').toISOString(),
        // })

        this.sizeMode = this.sm || 'low'

        eventHub.$on('mb-schedule-set-up-new-size-mode', (data) => {
            if (data.mbScheduleUid === this.mbScheduleUid) {
                this.open = true
                this.sizeMode = data.sizeMode
                this.fetch()
            }
        })

        eventHub.$on('mb-schedule-fetching-status-changed', (data) => {
            if (data.requestsProcessedCount == 2) { // request for Sessions, request for Replays == 2
                this.fetching = false
            } else if (data.requestsProcessedCount == 0) {
                this.fetching = true
            }
        })
    },
    methods: {
        fetch() {
            let today = moment()
            LightSession.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: today.toISOString(),
                start_at_to: today.clone().endOf('month').endOf('week').toISOString()
            })
            LightVideo.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: today.clone().startOf('month').startOf('week').toISOString(),
                start_at_to: today.clone().endOf('month').endOf('week').toISOString()
            })
        },
        switchMode(mode) {
            this.mode = mode
        },
        switchSizeMode(newMode) {
            this.sizeMode = newMode
            eventHub.$emit("mb-schedule-size-changed", {mode: newMode})
        },
        prev() {
            if (!this.fetching) {
                this.$refs[this.mode].prev()
            }
        },
        today() {
            if (!this.fetching) {
                this.$refs[this.mode].today()
            }
        },
        next() {
            if (!this.fetching) {
                this.$refs[this.mode].next()
            }
        },
        updateDisplayDate({mode, startDay, endDay, midDay}) {
            if (this.mode == mode) {
                switch (mode) {
                    case 'day':
                        this.displayDate = startDay.format('MMM, D YYYY')
                        break
                    case 'week':
                        let displayDate = ''
                        if (startDay.month() == endDay.month()) {
                            displayDate = startDay.format('MMM') + ' ' + startDay.date() + ' - ' + endDay.date() + ', ' + startDay.year()
                        } else {
                            displayDate = startDay.format('MMM') + ' ' + startDay.date() + ' - ' + endDay.format('MMM') + endDay.date() + ', ' + startDay.year()
                        }
                        this.displayDate = displayDate
                        break
                    case 'month':
                        this.displayDate = midDay.format('MMM') + ', ' + midDay.year()
                        break
                }
            }
        }
    }
}
</script>