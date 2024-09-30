<template>
    <div class="mb-day__inOverlay">
        <div
            ref="root"
            class="c-schedule-track">
            <div
                v-if="trackProcessing"
                class="c-loader" />
            <div
                ref="track"
                :class="{moveWithTransition: moveWithTransition}"
                class="track">
                <div
                    ref="timeline"
                    :style="timelineCSSVars"
                    class="timeline" />
                <div
                    v-for="date in dates"
                    :id="date.format('DD.MM.YYYY')"
                    :key="date.format('DD.MM.YYYY')"
                    :class="{today: date.diff(_today, 'days') == 0, past: (timelineCSSVars['--left'] == '-100px' && date.isBefore(_today))}"
                    class="t-date">
                    <div class="date-sections">
                        <div
                            v-for="dateSection in dateSections"
                            :id="dateSection + date.clone().format('DD.MM.YYYY')"
                            :key="dateSection"
                            :style="sectionStyles"
                            class="date-section">
                            {{ dateSection | formattedTime }}
                        </div>
                    </div>
                    <div class="data-sections">
                        <day-schedule
                            :date="date"
                            :minute-length="minuteLength"
                            :scheduler-for="schedulerFor"
                            :section-length="sectionLength" />
                    </div>
                </div>
            </div>
        </div>
        <div class="size-mode-control-wrap" />
    </div>
</template>

<script>
import DaySchedule from "@components/calendar/DaySchedule"
import Drag from "@mixins/Drag.js"
import LightSession from '@models/LightSession'
import LightVideo from '@models/LightVideo'
import CU from "@mixins/currentUser.js"
import utils from '@helpers/utils'
import eventHub from "@helpers/eventHub.js"
import Vue from 'vue'

export default {
    components: {DaySchedule},
    mixins: [Drag, CU],
    props: {
        zeroDate: {
            // moment object
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
            default: 5
        },
        channel_id: {
            type: Number
        },
        isActive: {
            type: Boolean
        }
    },
    data() {
        return {
            totalMinutes: 24 * 60,
            dates: [], // Array of moment dates
            dateSections: [],
            moveWithTransition: false,
            dragInitiated: false,
            lastAddedDay: '',
            isTrackFirstLoad: true,
            isTrackFirstSwiched: true,

            trackProcessing: false,

            timelineCSSVars: {
                '--left': '',
                '--before-length': ''
            },
            loading: 0
        }
    },
    computed: {
        sectionStyles() {
            return {width: this.sectionLength * this.minuteLength + 'px'}
        },
        _today() {
            return utils.dateToTimeZone(moment(), true)
        }
    },
    watch: {
        isActive(val) {
            if (val) {
                this.emitNewDisplayDate()
                if (this.isTrackFirstSwiched) {
                    this.synkTrackPossition()
                    this.synkTimelimePosition()
                    this.isTrackFirstSwiched = false
                }
            }
        }
    },
    methods: {
        prev() {
            this.addLeftDates()

            Vue.nextTick(() => {
                let trackSynkDate = this.dates[1].clone()
                if (trackSynkDate.format("DD.MM.YYYY") != utils.dateToTimeZone(moment(), true).format("DD.MM.YYYY")) {
                    trackSynkDate.set({hour: 0, minute: 0, secconds: 0})
                }

                this.synkTimelimePosition()
                this.synkTrackPossition(trackSynkDate)
            })
        },
        today() {
            this.startUpDates()
            Vue.nextTick(() => {
                this.synkTimelimePosition()
                this.synkTrackPossition()
            })
        },
        next() {
            this.addRightDates()

            Vue.nextTick(() => {
                let trackSynkDate = this.dates[1].clone()
                if (trackSynkDate.format("DD.MM.YYYY") != utils.dateToTimeZone(moment(), true).format("DD.MM.YYYY")) {
                    trackSynkDate.set({hour: 0, minute: 0, secconds: 0})
                }
                this.synkTimelimePosition()
                this.synkTrackPossition(trackSynkDate)
            })
        },
        emitNewDisplayDate(dayIndex = 1) {
            this.$emit('mb-display-date', {mode: 'day', startDay: this.dates[dayIndex]})
        },
        dragCallback(offsetX, offsetY) {
            if (this.trackProcessing) {
                return
            }
            let absOffsetX = Math.abs(offsetX)
            let loadNewDaySectionCount = 3
            let trackRight = offsetX + this.$refs.track.offsetWidth
            let dayViewWidth = this.$refs.root.offsetWidth

            let IsRightScrolled = trackRight <= dayViewWidth + this.sectionLength * this.minuteLength * loadNewDaySectionCount
            let IsLeftScrolled = offsetX >= 0 - this.sectionLength * this.minuteLength * loadNewDaySectionCount

            let emitDate
            let dayLength = this.$refs.track.offsetWidth / 3

            if (absOffsetX >= 0 && absOffsetX <= dayLength - dayViewWidth / 2) {
                emitDate = 0
            } else if (absOffsetX > dayLength - dayViewWidth / 2 && absOffsetX <= (dayLength * 2) - dayViewWidth / 2) {
                emitDate = 1
            } else {
                emitDate = 2
            }

            this.emitNewDisplayDate(emitDate)

            if (IsRightScrolled) {
                this.trackProcessing = true
                this.dragData.active = false
                this.addRightDates()
                Vue.nextTick(() => {
                    this.synkTrackPossition(moment(this.dates[1].format("YYYY-MM-DD") + 'T' + this.dateSections[this.dateSections.length - loadNewDaySectionCount - 1]))
                    this.synkTimelimePosition()
                    this.dragData.active = false
                    setTimeout(() => {
                        this.trackProcessing = false
                    }, 1000)
                })
            } else if (IsLeftScrolled) {
                this.trackProcessing = true
                this.dragData.active = false
                this.addLeftDates()
                Vue.nextTick(() => {
                    this.synkTrackPossition(moment(this.dates[1].format("YYYY-MM-DD") + 'T' + this.dateSections[loadNewDaySectionCount - 1]))
                    this.synkTimelimePosition()
                    this.dragData.active = false
                    setTimeout(() => {
                        this.trackProcessing = false
                    }, 1000)
                })
            }
        },

        //-----------------------------

        startUpDates() {
            this.dates = []
            this.dates.push(this.zeroDate)
            this.addLeftDates()
            this.addRightDates()
        },
        addLeftDates() {
            let dateToAdd

            if (this.dates.length == 0) {
                throw new Error("Add zeroDate to dates")
            } else {
                dateToAdd = this.dates[0].clone().subtract(1, "days")
                this.dates = [dateToAdd, ...this.dates].slice(0, 3)
            }

            this.fetchApiData()

            this.lastAddedDay = 'left'
            this.emitNewDisplayDate()
        },
        addRightDates() {
            let dateToAdd

            if (this.dates.length == 0) {
                throw new Error("Add zeroDate to dates")
            } else {
                dateToAdd = this.dates[this.dates.length - 1].clone().add(1, "days")
                this.dates = window.last([...this.dates, dateToAdd], 3)
            }

            this.fetchApiData()

            this.lastAddedDay = 'right'
            this.emitNewDisplayDate()
        },
        generateDateSections() {
            let tt = 0 // start time
            let currentUser = this.currentUser()

            for (let i = 0; tt < 24 * 60; i++) {
                let hh = Math.floor(tt / 60)
                let mm = (tt % 60)
                this.dateSections[i] = ("0" + (hh % 24)).slice(-2) + ':' + ("0" + mm).slice(-2) // 24 hours format
                tt = tt + this.sectionLength
            }
        },
        getDateTimeOffsetMoment(cd) {
            let d = this.getRoundedDateMoment(this.sectionLength, cd)
            let el = document.getElementById(d.format("HH:mmDD.MM.YYYY"))

            if (el) {
                return {
                    leftOffset: el.offsetLeft,
                    dateСorrection: this.trackProcessing ? 0 : (cd.minutes() - d.minutes()) * this.minuteLength
                }
            } else {
                return {
                    leftOffset: -100,
                    dateСorrection: 0
                }
            }
        },
        getTrackPossition() {
            return this.$refs.track ? this.$refs.track.style.transform.split('(')[1].split('px,')[0] : 0
        },
        getRoundedDateMoment(minutes = 30, d = moment()) {
            let ms = 1000 * 60 * minutes // convert minutes to ms
            let roundedDate = moment(Math.floor(d.valueOf() / ms) * ms)
            return utils.dateToTimeZone(roundedDate, true)
        },
        synkTrackPossition(date = moment()) {
            if (!this.trackProcessing) {
                this.moveWithTransition = true
            }
            date = utils.dateToTimeZone(date, true)

            let to = this.getDateTimeOffsetMoment(date)
            let offsetX
            if (this.trackProcessing) {
                offsetX = this.lastAddedDay == 'right' ? to.leftOffset - this.$refs.root.offsetWidth : to.leftOffset
            } else {
                offsetX = to.leftOffset - (this.$refs.root.offsetWidth / 2) + to.dateСorrection
            }

            this.$refs.track.style.transform = 'translate' + '(-' + offsetX + 'px, 0)'
            if (this.dragInitiated) {
                this.changeDragOffset({left: -offsetX, top: 0})
            } else {
                this.dragInitiated = true
                this.initDrag(this.$refs.track, this.$refs.root, {left: -offsetX, top: 0}, 'x')
            }

            if (!this.trackProcessing) {
                setTimeout(() => {
                    this.moveWithTransition = false
                }, 1000)
            }
        },
        synkTimelimePosition(date = moment()) {
            date = utils.dateToTimeZone(date, true)
            let to = this.getDateTimeOffsetMoment(date)
            let result = to.leftOffset + to.dateСorrection

            this.timelineCSSVars = {
                '--left': result + 'px',
                '--before-length': '-' + result + 'px'
            }
        },
        fetchApiData: utils.debounce(function () {
            if (this.isTrackFirstLoad) {
                return
            }
            this.loading = 0
            eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})

            let today = utils.dateToTimeZone(moment(), true)
            if (
                today.format("DD.MM.YYYY") == this.dates[1].format("DD.MM.YYYY") ||
                today < this.dates[1]
            ) {
                LightSession.api().fetch({
                    channel_id: this.channel_id,
                    limit: 300,
                    end_at_from: today.toISOString(),
                    start_at_to: this.dates[1].clone().startOf('day')
                }).then(() => {
                    this.loading++
                    eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
                })
            } else {
                this.loading++
            }

            LightVideo.api().fetch({
                channel_id: this.channel_id,
                limit: 300,
                end_at_from: this.dates[1].clone().startOf('day'),
                start_at_to: this.dates[1].clone().endOf('day')
            }).then(() => {
                this.loading++
                eventHub.$emit('mb-schedule-fetching-status-changed', {requestsProcessedCount: this.loading})
            })
        }, 500)
    },
    created() {
        this.startUpDates()
        this.generateDateSections()
        this.emitNewDisplayDate()
        this.isTrackFirstLoad = false
    },
    mounted() {
        Vue.nextTick(() => {
            this.synkTrackPossition()
            this.synkTimelimePosition()
            setInterval(() => {
                this.synkTimelimePosition()
            }, 5000)
        })
    }
}
</script>

<style lang="scss">
.c-schedule-track {
    overflow: hidden;
    position: relative;
    background: var(--bg__content);
    background-blend-mode: soft-light, normal;
    border: 0.2rem solid #FFFFFF;
    box-sizing: border-box;
    box-shadow: inset -5px -5px 10px var(--sh__main), inset 5px 5px 10px var(--sh__main);
    border-radius: 2rem;

    .c-loader,
    .c-loader:before,
    .c-loader:after {
        border-radius: 50%;
        width: 2.5em;
        height: 2.5em;
        -webkit-animation-fill-mode: both;
        animation-fill-mode: both;
        -webkit-animation: load7 1.8s infinite ease-in-out;
        animation: load7 1.8s infinite ease-in-out;
    }

    .c-loader {
        position: absolute;
        top: 0;
        left: 0;
        bottom: 0;
        right: 0;
        z-index: 9;

        color: var(--tp__h1);
        font-size: 0.7rem;
        margin: 5rem auto;
        text-indent: -9999em;
        -webkit-transform: translateZ(0);
        -ms-transform: translateZ(0);
        transform: translateZ(0);
        -webkit-animation-delay: -0.16s;
        animation-delay: -0.16s;
    }

    .c-loader:before,
    .c-loader:after {
        content: '';
        position: absolute;
        top: 0;
    }

    .c-loader:before {
        left: -3.5em;
        -webkit-animation-delay: -0.32s;
        animation-delay: -0.32s;
    }

    .c-loader:after {
        left: 3.5em;
    }

    @-webkit-keyframes load7 {
        0%,
        80%,
        100% {
            box-shadow: 0 2.5em 0 -1.3em;
        }
        40% {
            box-shadow: 0 2.5em 0 0;
        }
    }
    @keyframes load7 {
        0%,
        80%,
        100% {
            box-shadow: 0 2.5em 0 -1.3em;
        }
        40% {
            box-shadow: 0 2.5em 0 0;
        }
    }

    .track {
        display: flex;
        width: fit-content;
        background-color: transparent;

        &.moveWithTransition {
            transition: transform 1s ease;
        }

        .timeline {
            position: absolute;
            top: 0;
            bottom: 0;
            left: var(--left);
            border-right: 1px solid var(--tp__active);
            z-index: 1;

            transition: left 1s;

            &:before {
                content: '';
                top: 2.7rem;
                bottom: 0;
                right: 0;
                left: var(--before-length);
                position: absolute;
                background-color: #00000008;
            }

            &:after {
                content: "";
                position: absolute;
                width: 0.7rem;
                height: 0.7rem;
                top: -0.4rem;
                left: -0.3rem;
                border-radius: 100%;
                background-color: var(--tp__active);
            }
        }

        .t-date {
            display: flex;
            flex-wrap: wrap;
            flex-direction: row;
            height: 20.8rem;

            &:not(.today).past {
                background-color: rgba(168, 168, 168, 0.11);
            }

            .date-sections {
                display: flex;
                max-height: 2.8rem;
                font-weight: bold;
                background-color: var(--bg__label);
                color: rgba(255, 255, 255, 0.7);

                .date-section {
                    line-height: 2em;
                    border-right: 1px solid var(--border__separator);
                    text-align: left;
                    padding-left: 0.8rem;
                    position: relative;

                    &:before {
                        content: '';
                        height: 100vh;
                        width: 0.1rem;
                        position: absolute;
                        left: -0.1rem;
                        top: 2.8rem;
                        background: rgba(168, 168, 168, 0.11);
                    }

                    &.past:after {
                        content: '';
                        height: 100vh;
                        left: 0;
                        right: 0;
                        top: 2.8rem;
                        position: absolute;
                        background: rgba(168, 168, 168, 0.11);
                    }

                    &.today {
                        color: var(--tp__main);
                    }
                }
            }

            .data-sections {
                height: 100%;
                width: 100%;
            }
        }
    }
}
</style>