<template>
    <div class="c-day-schedule">
        <div
            v-for="(row, index) in getDayScheduleItems()"
            :key="index"
            class="c-row">
            <component
                :is="scheduleItem.calendar_component_name"
                v-for="scheduleItem in row"
                :key="scheduleItem.id"
                :calendar-item-data="scheduleItem"
                :hour0="date.startOf('day')"
                :minute-length="minuteLength"
                :scheduler-for="schedulerFor"
                mode="day" />
        </div>
    </div>
</template>

<script>
import mdSchedule from "@mixins/mbSchedule.js"
import MbScheduleItem from "@components/mindbodyonline/schedule/MbScheduleItem.vue"
import SessionCalendarItem from "@components/mindbodyonline/schedule/SessionCalendarItem.vue"
import VideoCalendarItem from "@components/calendar/VideoCalendarItem.vue"
import utils from '@helpers/utils'

export default {
    components: {MbScheduleItem, SessionCalendarItem, VideoCalendarItem},
    mixins: [mdSchedule],
    props: {
        date: {
            default: function () {
                return utils.dateToTimeZone(moment(), true)
            },
            validator: (value) => {
                return value._isAMomentObject === true
            }
        },
        sectionLength: {
            type: Number, // minutes
            default: 30
        },
        schedulerFor: {
            type: String
        },
        // minutes in pixels
        minuteLength: {
            type: Number,
            default: 3
        }
    },
    methods: {
        getDayScheduleItems() {
            let todaysItems = this.getScheduleItems(this.date)
            let rows = [[]]

            for (let i = 0; i < todaysItems.length; i++) {
                let newItem = todaysItems[i]
                let isItemAdded = false

                for (let r = 0; r < rows.length; r++) {
                    isItemAdded = this.addItemToDayScheduleRow(newItem, rows[r])
                    if (isItemAdded) {
                        break
                    }
                }
                if (!isItemAdded) {
                    rows.push([newItem])
                }
            }

            return rows
        },
        addItemToDayScheduleRow(newItem, row) {
            // push newItem to row if row empty
            if (row.length == 0) {
                row.push(newItem)
                return true
            }

            for (let j = 0; j < row.length; j++) {
                let currentItem = row[j]
                let nextItem = row[j + 1]

                // TODO: andrey check this
                // push newItem to current row if newItem fits to time interval ...
                switch (currentItem.calendar_component_name) {
                    case "session-calendar-item":
                        if (
                            (
                                nextItem &&
                                moment(newItem.end_at) < moment(nextItem.start_at) &&
                                moment(newItem.start_at) > moment(currentItem.end_at)
                            )
                            ||
                            (
                                !nextItem &&
                                moment(newItem.start_at) > moment(currentItem.end_at)
                            )
                        ) {
                            row.splice(j + 1, 0, newItem)
                            return true
                        }
                        break
                    case "video-calendar-item":
                        if (
                            (
                                nextItem &&
                                moment(newItem.end_at) < moment(nextItem.start_at) &&
                                moment(newItem.start_at) > moment(currentItem.end_at)
                            )
                            ||
                            (
                                !nextItem &&
                                moment(newItem.start_at) > moment(currentItem.end_at)
                            )
                        ) {
                            row.splice(j + 1, 0, newItem)
                            return true
                        }
                        break
                }
            }

            return false
        }
    }
}
</script>

<style lang="scss">
.c-day-schedule {
    .c-row {
        height: 12rem;
        position: relative;
    }
}
</style>