<template>
    <div class="mb-day">
        <div class="sc-table">
            <div class="sc-thead">
                <div class="sc-row">
                    <div
                        v-for="hour in hours"
                        :key="hour.unix()"
                        class="sc-cell">
                        {{ hour.format("HH:mm") }}
                    </div>
                </div>
            </div>
            <div
                ref="tBody"
                class="sc-tbody">
                <div
                    :style="{ left: leftDistance / 10 + 'rem' }"
                    class="timeline" />
                <div
                    v-for="(row, index) in daySchedule"
                    :key="index"
                    class="sc-row">
                    <template v-for="scheduleItem in row">
                        <component
                            :is="scheduleItem.calendar_component_name"
                            :key="scheduleItem.id"
                            :calendar-item-data="scheduleItem"
                            :hour0="hours[0]"
                            :minute-length="minuteLength"
                            :minutes-count="minutesCount"
                            :scheduler-for="schedulerFor"
                            mode="day" />
                    </template>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import mdSchedule from "@mixins/mbSchedule.js"
import MbScheduleItem from "@components/mindbodyonline/schedule/MbScheduleItem.vue"
import SessionCalendarItem from "@components/mindbodyonline/schedule/SessionCalendarItem.vue"

export default {
    components: {MbScheduleItem, SessionCalendarItem},
    mixins: [mdSchedule],
    props: {
        sectionCount: {
            type: Number,
            default: 7
        },
        sectionLength: {
            type: Number, // minutes
            default: 30
        },
        startSection: {
            type: Number,
            default: 3
        },
        schedulerFor: {
            type: String
        }
    },
    data() {
        return {
            width: 0,
            minutesIndex: 0,

            // TODO: Andrey refactor, refresh leftDistance computed property
            refreshLeftDistanceTrigger: 0
        }
    },
    computed: {
        hours() {
            let hours = []
            let now = moment().add(this.minutesIndex * this.sectionCount * this.sectionLength, "minutes")

            if (now.minutes() < 30) {
                now.startOf("hour")
            } else {
                now.startOf("hour").add(30, "minutes")
            }

            // generate hours before start section
            for (let i = this.startSection - 1; i > 0; i--) {
                hours.push(now.clone().subtract(this.sectionLength * i, "minutes"))
            }

            // generate start and after start sections
            for (let i = 0; i <= this.sectionCount - this.startSection; i++) {
                hours.push(now.clone().add(this.sectionLength * i, "minutes"))
            }

            return hours
        },
        minutesCount() {
            return this.sectionCount * this.sectionLength
        },
        minuteLength() {
            return this.width / this.minutesCount
        },
        leftDistance() {
            // TODO: Andrey refactor, refresh leftDistance computed property
            this.refreshLeftDistanceTrigger
            // -------------------------------------------------------------
            return this.minuteLength * moment().diff(this.hours[0], "minutes")
        },
        daySchedule() {
            // let todaysItems = this.getClasses(moment().startOf("day"));
            let todaysItems = this.getUniteSesions(moment().startOf("day"))
            let rows = [todaysItems]

            // let todaysItems = this.seedClasses(10)
            // let todaysItems = [
            //   {
            //     start_time: "2020-10-17T08:00:00+03:00",
            //       end_time: "2020-10-17T23:30:00+03:00",
            //   },
            //   {
            //     start_time: "2020-10-17T08:00:00+03:00",
            //       end_time: "2020-10-17T23:30:00+03:00",
            //   },
            //   {
            //     start_time: "2020-10-17T08:00:00+03:00",
            //       end_time: "2020-10-17T23:30:00+03:00",
            //   },
            // ]

            // for (let i = 0; i < todaysItems.length; i++) {
            //   let newItem = todaysItems[i];
            //   let isItemAdded = false;

            //   for (let r = 0; r < rows.length; r++) {
            //     isItemAdded = this.addItemToDayScheduleRow(newItem, rows[r])
            //     if(isItemAdded){break}
            //   }
            //   if(!isItemAdded){
            //     rows.push([newItem])
            //   }
            // }
            return rows
        }
    },
    mounted() {
        this.refreshLeftDistance()
        setInterval(() => {
            this.refreshLeftDistance()
        }, 500)

        window.addEventListener("resize", () => {
            this.refreshLeftDistance()
        })
    },
    destroyed() {
        window.removeEventListener("resize", () => {
            this.refreshLeftDistance()
        })
    },
    methods: {
        prev() {
            // если предыдущая дата -> получить рассписание по редыдущей дате
            this.minutesIndex--
        },
        today() {
            this.minutesIndex = 0
        },
        next() {
            // если следущая дата -> получить рассписание по следующей дате
            this.minutesIndex++
        },
        refreshLeftDistance() {
            this.refreshLeftDistanceTrigger++
            this.width = this.$refs.tBody.offsetWidth
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

                // push newItem to current row if newItem fits to time interval ...
                if (
                    (
                        nextItem &&
                        moment(newItem.end_time) < moment(nextItem.start_time) &&
                        moment(newItem.start_time) > moment(currentItem.end_time)
                    )
                    ||
                    (
                        !nextItem &&
                        moment(newItem.start_time) > moment(currentItem.end_time)
                    )
                ) {
                    row.splice(j + 1, 0, newItem)
                    return true
                }
            }

            return false
        },
        emitNewDisplayDate() {
            this.$emit('mb-display-date', {mode: 'day', startDay: this.startDay, endDay: this.endDay})
        }
    }
}
</script>
