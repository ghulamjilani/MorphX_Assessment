<template>
    <div class="history">
        <div class="history__wrapper">
            <div class="history__header">
                <div class="history__filter">
                    <m-date-filter
                        v-model="dateFilter"
                        placeholder="Filter by date"
                        @change="dateChanged" />
                </div>
                <m-btn
                    class="history__button"
                    rounded
                    type="secondary"
                    @click="deleteAll">
                    Clear History
                </m-btn>
            </div>
            <div class="history__body">
                <div
                    v-for="(activity, index) in activities"
                    :key="activity.id"
                    class="history__section__wrapper">
                    <div
                        v-if="index == 0 || (activities[index - 1] && !isSameDate(activities[index - 1].updated_at, activity.updated_at))"
                        class="history__section__header">
                        <div>
                            {{ dateParse(activity.updated_at) }}
                        </div>
                        <div
                            class="history__delete"
                            @click="deleteDay(activity.updated_at)">
                            <i class="VideoClientIcon-trash-emptyF" /> Delete
                        </div>
                    </div>
                    <div class="history__tile">
                        <m-tile
                            :action="activity.key"
                            :chips="chipsShow(activity.trackable.type)"
                            :following="activity.trackable.following"
                            :logo-url="activity.trackable.logo_url"
                            :name="activity.trackable.name"
                            :poster-url="activity.trackable.poster_url"
                            :price="activity.trackable.price"
                            :purchased="activity.trackable.purchased"
                            :short-url="activity.trackable.short_url"
                            :time="timeParse(activity.updated_at)"
                            :type="activity.trackable.type"
                            :private="activity.trackable.private"
                            kind="history"
                            list-mode />
                    </div>
                </div>

                <infinite-loading
                    ref="InfiniteLoading"
                    spinner="waveDots"
                    @infinite="infiniteHandler">
                    <div slot="no-more" />
                    <div
                        slot="no-results"
                        class="history__body__no-results">
                        There are no more Activities
                    </div>
                </infinite-loading>
            </div>
        </div>
    </div>
</template>

<script>
import Activities from "@models/Activities"
import InfiniteLoading from "vue-infinite-loading"

export default {
    components: {InfiniteLoading},
    data() {
        return {
            indexParams: {
                limit: 30,
                offset: 0,
                date_from: null,
                date_to: null
            },
            dateFilter: {
                date: null,
                dateValue: null
            }
        }
    },
    computed: {
        activities() {
            return Activities.query().orderBy('updated_at', 'desc').get()
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    created() {
        // Activities.api().fetch(this.indexParams)
    },
    methods: {
        dateChanged() {
            Activities.create({data: []})
            this.indexParams = {
                limit: 30,
                offset: 0,
                date_from: null,
                date_to: null
            }
            this.$refs.InfiniteLoading.stateChanger.reset()
            if (this.dateFilter.dateValue !== 'all') {
                this.indexParams.date_from = this.dateFilter.date.start.toISOString()
                this.indexParams.date_to = this.dateFilter.date.end.toISOString()
            }
        },
        timeParse(time) {
            return new Date(Date.parse(time)).toLocaleString("en-US", {
                hour: "numeric",
                minute: "numeric",
                hour12: this.currentUser?.am_format
            })
        },
        isSameDate(dateA, dateB) {
            return dateA.split("T")[0] === dateB.split("T")[0]
        },
        dateParse(date) {
            let mDate = moment(date).tz("Europe/London")
            let today = moment().tz("Europe/London")
            let dateName
            let dayDiff = today.dayOfYear() - mDate.dayOfYear()

            if (dayDiff === 0) {
                dateName = 'Today'
            } else if (dayDiff === 1) {
                dateName = 'Yesterday'
            } else {
                dateName = mDate.format('MMMM, DD')
            }

            return dateName
        },
        chipsShow(type) {
            return type === "Video" || type === "Session" || type === "Recording" || type === 'Channel'
        },
        deleteAll() {
            Activities.api()
                .deleteAll()
                .then((response) => {
                    Activities.create({data: []})
                    this.$refs.InfiniteLoading.stateChanger.reset()
                })
        },
        deleteDay(day) {
            let date_from = moment.tz(day, "Europe/London").startOf('day').toISOString()
            let date_to = moment.tz(day, "Europe/London").endOf('day').toISOString()
            Activities.api().deleteByDateRange({date_from: date_from, date_to: date_to}).then(data => {
                if (data?.response?.data?.message) {
                    Activities.delete((activity) => {
                        return data?.response?.data?.message.includes(activity.id)
                    })
                }
                this.indexParams.offset = this.activities.length
                this.$refs.InfiniteLoading.stateChanger.reset()
            })
        },
        infiniteHandler($state) {
            Activities.api()
                .fetch(this.indexParams)
                .then((response) => {
                    if (this.indexParams.offset >= response.response.data.pagination?.count) {
                        $state.complete()
                    } else {
                        this.indexParams.offset = this.indexParams.offset + this.indexParams.limit
                        $state.loaded()
                    }
                })
        }
    }
}
</script>
