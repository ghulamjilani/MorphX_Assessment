<template>
    <m-modal
        ref="bookingSlotModal"
        :backdrop="false"
        :confirm="true"
        class="createEditBookingSlot bookingSlotModal">
        <template slot="header">
            <div class="bookingSlotModal__section">
                <h3 v-if="mode === 'create'">
                    New booking slot
                </h3>
                <h3 v-else>
                    Edit booking slot: {{ bookingSlot.name }}
                </h3>
            </div>
        </template>
        <!--DETAILS FORM-->
        <m-form
            v-if="bookingSlot"
            ref="bookingSlotForm"
            v-model="disabled">
            <div class="bookingSlotModal__section">
                <m-input
                    v-model="bookingSlot.name"
                    label="Slot Name *"
                    type="text"
                    :max-counter="64"
                    :required="true"
                    rules="required|min-length:6|max-length:64" />

                <m-input
                    v-model="bookingSlot.description"
                    label="Description *"
                    type="text"
                    :textarea="true"
                    :max-counter="1200"
                    rules="required|max-length:1200" />
                <div class="display__flex gap__2">
                    <m-select
                        v-model="bookingSlot.channel_id"
                        label="Channel *"
                        :options="channels"
                        :required="true"
                        class="full__width"
                        rules="required" />

                    <m-select
                        v-model="bookingSlot.booking_category_id"
                        label="Category *"
                        :options="booking_categories"
                        :required="true"
                        class="full__width"
                        rules="required" />
                </div>

                <tags
                    v-model="bookingSlot.tags"
                    :min-tags="3"
                    :max-tags="12"
                    description="Please add minimum 3 tags" />
            </div>
        </m-form>
        <!--DETAILS FORM END-->

        <!--PRICING-->
        <div
            v-if="bookingSlot"
            class="createEditBookingSlot__price">
            <div class="bookingSlotModal__section">
                <div class="display__flex flex__justify__space-between align__items__center createEditBookingSlot__price__title">
                    <h3>
                        Pricing *
                        <i
                            v-tooltip="{
                                content: priceTooltipContent,
                                trigger: 'hover click'
                            }"
                            class="GlobalIcon-info-square" />
                    </h3>
                    <m-btn
                        v-tooltip="'Add new pricing line'"
                        :square="false"
                        size="s"
                        type="bordered"
                        class="createEditBookingSlot__price__addBtn"
                        @click="addNewRule">
                        Add pricing line +
                    </m-btn>
                </div>
                <div class="createEditBookingSlot__price__rule__wrapp">
                    <div class="createEditBookingSlot__price__rule__anotate" />
                    <div
                        v-for="(rule, index) in bookingSlot.booking_prices_attributes"
                        v-show="!rule.deleted"
                        :key="index"
                        class="createEditBookingSlot__price__rule">
                        <div class="createEditBookingSlot__price__rule__top">
                            <div>
                                <div class="createEditBookingSlot__price__rule__top__title">
                                    Duration
                                </div>
                                <span class="createEditBookingSlot__price__rule__top__value">{{ rule.duration }} min</span>
                            </div>
                            <div>
                                <div class="createEditBookingSlot__price__rule__top__title">
                                    Price
                                </div>
                                <span class="createEditBookingSlot__price__rule__top__value">$ {{ rule.price_cents }}</span>
                            </div>
                            <div>
                                <m-icon
                                    v-if="!rule.editTime"
                                    v-tooltip="'Edit'"
                                    size="1.6rem"
                                    :name="'GlobalIcon-edit'"
                                    @click="rule.editTime = !rule.editTime" />
                                <m-icon
                                    v-tooltip="'Delete'"
                                    name="GlobalIcon-trash"
                                    @click="removeRule(rule)" />
                            </div>
                        </div>

                        <div
                            v-if="rule.editTime"
                            class="createEditBookingSlot__price__rule__settings">
                            <div class="createEditBookingSlot__price__rule__settings__title">
                                Edit duration and price form:
                            </div>
                            <div class="createEditBookingSlot__price__rule__slider">
                                <label>Choose duration:</label>
                                <vue-slider
                                    v-model="rule.duration"
                                    :interval="5"
                                    :max="maxBookingDuration"
                                    :min="15"
                                    :tooltip="'none'"
                                    style="width: calc(100% - 30rem);height: .5rem;margin: auto;padding: 0"
                                    class="rangeSlider">
                                    <template #process="{style}">
                                        <div
                                            :style="style"
                                            class="rangeSlider__process" />
                                    </template>
                                    <template #dot>
                                        <m-btn
                                            class="rangeSlider__dot"
                                            tag-type="button">
                                            {{ rule.duration }} {{ $t('components.modals.cis.modal_form.min') }}
                                        </m-btn>
                                    </template>
                                </vue-slider>
                            </div>
                            <div class="createEditBookingSlot__price__rule__price">
                                <label>
                                    Choose Price:
                                </label>
                                <div class="createEditBookingSlot__price__setPrice">
                                    <m-price-input
                                        v-model="rule.price_cents"
                                        custom-style="padding: 0; width:15rem;"
                                        type="text"
                                        label=""
                                        :min="0.99"
                                        :errors="false" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>


                <div
                    v-if="false"
                    class="createEditBookingSlot__price__replay">
                    <div class="createEditBookingSlot__price__replay__top">
                        <div class="createEditBookingSlot__price__replay__top__title">
                            <div>Replay Recording</div>
                            <span>Allow user to access the recording after the session.</span>
                        </div>

                        <m-toggle v-model="bookingSlot.replay" />
                    </div>

                    <div
                        v-if="bookingSlot.replay"
                        class="createEditBookingSlot__price__replay__bottom">
                        <div class="createEditBookingSlot__price__replay__bottom__title">
                            <span>Please annotate that if you set price to 0, the Replay recording will be free</span>
                        </div>
                        <div class="display__flex flex__justify__space-between align__items__center">
                            <label>Price</label>
                            <m-price-input
                                v-model="bookingSlot.replay_price_cents"
                                custom-style="padding: 0;width:15rem;"
                                type="text"
                                label=""
                                :free-button="true"
                                :min="0.99"
                                :errors="false" />
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div
            v-if="bookingSlot"
            class="bookingSlotModal__section createEditBookingSlot__timing">
            <div class="createEditBookingSlot__timing__title createEditBookingSlot__daily">
                <h3>
                    Availability *
                    <i
                        v-if="calendarMode"
                        v-tooltip="{
                            content: dailyAvailabilityTooltipContent,
                            trigger: 'hover click'
                        }"
                        class="GlobalIcon-info-square" />
                </h3>
                <div class="createEditBookingSlot__timing__title__toggle">
                    <span
                        v-if="!checkMobile">Simple view</span>
                    <m-toggle
                        v-if="!checkMobile"
                        v-model="calendarMode" />
                    <span
                        v-if="!checkMobile">Calendar view</span>
                </div>
            </div>
            <template
                v-if="!calendarMode">
                <div
                    v-for="day in timing"
                    :key="day.name"
                    class="createEditBookingSlot__timing__day">
                    <span class="createEditBookingSlot__timing__day__controls">{{ day.name }}</span>
                    <div
                        class="createEditBookingSlot__timing__day__controls">
                        <m-btn
                            v-for="schedule in day.scheduler"
                            :key="day.name + schedule.start"
                            :type="schedule.edit ? 'main' : 'bordered'"
                            :square="true"
                            @click="openSimpleEdit(schedule, day)">
                            {{ schedule.start }} - {{ schedule.end }}
                            <span
                                v-if="schedule.multiplierValue != 0"
                                class="multiplier">{{ schedule.multiplierValue > 0 ? '+' : '' }}{{ schedule.multiplierValue }}%</span>
                        </m-btn>
                        <m-btn
                            type="reset"
                            :square="true"
                            @click="addNewSchedule(day, $event)">
                            +
                        </m-btn>
                    </div>
                </div>
                <div
                    v-if="changeTiming"
                    class="createEditBookingSlot__timing__day__timepicker">
                    <div class="createEditBookingSlot__timing__day__timepicker__wrapper">
                        <div>
                            <span>Chose time interval</span>
                        </div>
                        <div class="createEditBookingSlot__timing__day__timepicker__time__form">
                            <span>from:</span>
                            <vue-timepicker
                                v-model="changeTiming.schedule.editStart"
                                format="HH:mm"
                                auto-scroll
                                manual-input
                                :minute-interval="5" />
                            <span>to:</span>
                            <vue-timepicker
                                v-model="changeTiming.schedule.editEnd"
                                format="HH:mm"
                                auto-scroll
                                manual-input
                                :minute-interval="5" />
                        </div>

                        <div class="createEditBookingSlot__timing__day__timepicker__multiplier">
                            <div class="createEditBookingSlot__timing__day__timepicker__multiplier__select">
                                <div class="display__flex flex__justify__space-between align__items__center">
                                    <span>Add Multiplier</span>
                                    <m-toggle v-model="changeTiming.schedule.multiplier" />
                                </div>
                                <div
                                    v-if="changeTiming.schedule.multiplier"
                                    class="display__flex flex__justify__space-between align__items__center padding-t__20 padding-b__10">
                                    <div>Chose %</div>
                                    <m-input
                                        v-model="changeTiming.schedule.multiplierValue"
                                        :pure="true"
                                        :errors="false"
                                        placeholder="%"
                                        type="number" />
                                </div>
                            </div>
                            <div>
                                <span>Multiplier allows you to apply a surcharge in the specified % (for example, you can make a surcharge for prime time, weekends, etc.)</span>
                            </div>
                        </div>
                        <div class="text__right">
                            <m-btn
                                type="bordered"
                                @click="removeTime(changeTiming.schedule, changeTiming.day)">
                                Remove
                            </m-btn>

                            <m-btn
                                :disabled="
                                    changeTiming.schedule.editStart == '' || changeTiming.schedule.editEnd == ''
                                        || changeTiming.schedule.editStart.includes('m') || changeTiming.schedule.editEnd.includes('m')
                                        || changeTiming.schedule.editStart.includes('H') || changeTiming.schedule.editEnd.includes('H')"
                                @click="saveSimple(changeTiming.day, changeTiming.schedule, $event)">
                                Save
                            </m-btn>
                        </div>
                        <div class="createEditBookingSlot__timing__day__timepicker__close">
                            <m-icon
                                name="GlobalIcon-clear"
                                @click="closeSimple" />
                        </div>
                    </div>
                </div>
            </template>
            <div
                v-if="calendarMode"
                class="createEditBookingSlot__timing__calendar">
                <vue-cal
                    ref="calendar"
                    hide-view-selector
                    hide-title-bar
                    :disable-views="['years', 'year', 'month', 'day']"
                    :editable-events="{ title: false, drag: true, resize: true, delete: true, create: true }"
                    :drag-to-create-threshold="0"
                    :snap-to-time="5"
                    :events="scheduler"
                    :on-event-create="onEventCreate"
                    @ready="listenAllMultipliers(null)"
                    @event-title-change="logEvents('event-title-change', $event)"
                    @event-content-change="logEvents('event-content-change', $event)"
                    @event-duration-change="logEvents('event-duration-change', $event)"
                    @event-drop="logEvents('event-drop', $event)"
                    @event-create="logEvents('event-create', $event)"
                    @event-drag-create="logEvents('event-drag-create', $event)"
                    @event-delete="logEvents('event-delete', $event)" />
            </div>
        </div>
        <div
            v-if="bookingSlot"
            class="createEditBookingSlot__week bookingSlotModal__section">
            <div>
                <h3>
                    Weekly Schedule *
                    <i
                        v-if="calendarMode"
                        v-tooltip="{
                            content: weekAvailabilityTooltipContent,
                            trigger: 'hover click'
                        }"
                        class="GlobalIcon-info-square" />
                </h3>
                <vue-cal
                    class="weekCalendar"
                    :time="false"
                    show-week-numbers
                    active-view="month"
                    hide-view-selector
                    :disable-views="['years', 'year', 'week', 'day']">
                    <template #title="{ title, view }">
                        <m-btn
                            type="secondary"
                            @click="selectAllMonth(view)">
                            All weeks
                        </m-btn>
                        <span>{{ title }}</span>
                    </template>
                    <template #arrow-prev>
                        <i class="GlobalIcon-angle-left" />
                    </template>
                    <template #arrow-next>
                        <i class="GlobalIcon-angle-right" />
                    </template>
                    <template #week-number-cell="{week}">
                        <div
                            :class="{'active': weekSelected.includes(week)}"
                            class="vuecal__cell-week-number">
                            <m-checkbox
                                v-model="weekSelected"
                                :disabled="currentWeek > week"
                                :val="week">
                                {{ week }}
                            </m-checkbox>
                        </div>
                    </template>
                    <template #cell-content="{ cell }">
                        <div
                            class="vuecal__cell-date"
                            :class="{'active': weekSelected.includes(cell.startDate.getWeek())}">
                            {{ cell.content }}
                        </div>
                    </template>
                </vue-cal>
            </div>
        </div>
        <div class="createEditBookingSlot__buttons bookingSlotModal__section">
            <m-btn
                :disabled="loading"
                type="secondary"
                @click="cancel">
                Cancel
            </m-btn>
            <m-btn
                :disabled="disabledForm"
                type="save"
                :loading="loading"
                @click="save">
                {{ mode == 'create' ? 'CREATE' : 'UPDATE' }} BOOKING SLOT
            </m-btn>
        </div>
    </m-modal>
</template>

<script>
import Tags from '@components/blog/Tags.vue'
import VueSlider from 'vue-slider-component'
import VueCal from 'vue-cal'
import VueTimepicker from 'vue2-timepicker'
import 'vue2-timepicker/dist/VueTimepicker.css'

import User from "@models/User"
import Booking from "@models/Booking"

import ClickOutside from "vue-click-outside"

export default {
    name: 'CreateEditBookingSlot',
    directives: {
        ClickOutside
    },
    components: {
        Tags,
        VueSlider,
        VueCal,
        VueTimepicker
    },
    data() {
        return {
            disabled: false,
            loading: false,
            mode: 'create',
            bookingSlot: null,
            channels: [],
            booking_categories: [],
            minMinutes: 15,
            maxBookingDuration: 15,
            newBookingSlot: {
                name: '',
                description: '',
                channel_id: '',
                booking_category_id: '',
                tags: [],
                replay: false,
                replay_price_cents: 0,
                currency: "USD",
                slot_rules: "",
                week_rules: "",
                booking_prices_attributes: []
            },
            scheduler: [],
            calendarMode: true,
            timing: [],
            changeTiming: null,
            weekSelected: [],
            currentWeek: 0,
            currentYear: 0,
			weekAvailabilityTooltipContent:'<p>Choose the week or weeks when the daily availability pattern will be used.</p>',
			dailyAvailabilityTooltipContent:'<p>In calendar mode, it is possible to create daily availability by clicking on the selected day (and moving the mouse cursor in the direction of the timeline). Dragging and dropping selected tiles is also possible.</p>',
			priceTooltipContent:`
                        <p>Setting Prices for Booking Slots and Duration Options:</p>
                        <p>Creators have the flexibility to set prices for bookinga based on different time intervals.</p>
                        <p>To provide customers with a seamless experience, creators need to create separate entries for each duration option and assign the appropriate prices accordingly.</p>
						<p>Here's a step-by-step example of how it works:</p>
                        <ol>
                            <li>Creators define various duration options for the booking, in 5 minutes increaments</li>
                            <li>For each duration option, creators set a specific price that aligns with the value they offer.</li>
                            <li>Customers can then view the available duration options and select the desired one from the list of options.</li>
                            <li>Once the customer makes a selection, they can proceed to purchase the chosen duration at the specified price.</li>
                        </ol>`
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        disabledForm() {
            return this.disabled || !this.bookingSlot ||
                !this.bookingSlot.channel_id ||
                !this.bookingSlot.booking_category_id ||
                this.bookingSlot.tags.length < 3 ||
                this.bookingSlot.booking_prices_attributes.filter(e => !e.deleted).length <= 0 ||
                this.scheduler.length <= 0 ||
                this.weekSelected.length <= 0
        },
        checkMobile() {
			return this.$device.mobile()
		},
    },
    mounted() {
        this.currentWeek = new Date().getWeek()

        this.fetchInfo()

        this.$eventHub.$on('open-modal:BookingSlotModal', (mode, bookingSlot = null) => {
            this.mode = mode
            if(mode === 'create') {
                this.bookingSlot = JSON.parse(JSON.stringify(this.newBookingSlot))
                this.weekSelected = []
                this.timing = []
                this.scheduler = []
                this.addNewRule()
                this.simpleCalendarCalculate()
            }
            else if (mode === 'edit') {
                this.fromApiToForm(bookingSlot)
                this.$nextTick(() => {
                    setTimeout(() => {
                        this.$refs.bookingSlotForm?.checkObserver()
                    }, 1000)
                })
            }
            else if (mode === 'clone') {
                this.fromApiToForm(bookingSlot)
                this.bookingSlot.id = null
                this.bookingSlot.name = this.bookingSlot.name + ' (clone)'
                // this.save()
                this.mode = 'create'
                this.$nextTick(() => {
                    setTimeout(() => {
                        this.$refs.bookingSlotForm?.checkObserver()
                    }, 1000)
                })
            }
            this.openModal()
        })

        this.simpleCalendarCalculate()
    },
    methods: {
        fromApiToForm(bookingSlot) {
            this.weekSelected = []
                this.timing = []
                this.scheduler = []
                let bookingSlotRaw = JSON.parse(JSON.stringify(bookingSlot))

                this.weekSelected = JSON.parse(bookingSlotRaw.week_rules)
                let tt = JSON.parse(bookingSlotRaw.slot_rules)
                tt.forEach(t => {t.scheduler.forEach(s => {
                    s.edit = false
                    s.multiplierValue = s.multiplier || 0
                    s.multiplier = +s.multiplier != 0 ? true : false
                })})
                this.timing = tt
                bookingSlotRaw.tags = JSON.parse(bookingSlotRaw.tags)
                bookingSlotRaw.booking_prices_attributes = bookingSlotRaw.booking_prices.map(p => {
                    return {
                        id: p.id,
                        duration: p.duration,
                        editTime: false,
                        price_cents: p.price_cents/100,
                        currency: p.currency,
                        deleted: false
                    }
                })
                if(this.mode == 'clone') {
                    bookingSlotRaw.booking_prices_attributes.forEach(p => {
                        delete p.id
                    })
                }
                bookingSlotRaw.replay_price_cents = bookingSlotRaw.replay_price_cents/100

                this.timing.forEach(t => {
                    if(t.day) t.name = t.day
                    t.scheduler.sort((a, b) => {
                        return (a.start.split(':')[0] * 60 + a.start.split(':')[1])
                            - (b.start.split(':')[0] * 60 + b.start.split(':')[1])
                    })
                })

                this.timing.forEach(t => {
                    t.scheduler.forEach(s => {
                        this.addNewEvent(t.name, s)
                    })
                })

                this.bookingSlot = JSON.parse(JSON.stringify(bookingSlotRaw))
        },
        openModal() {
            if(this.checkMobile) {
                this.calendarMode = false
            }
            else {
                this.calendarMode = true
            }
            this.$refs.bookingSlotModal.openModal()
        },
        closeModal() {
            this.$refs.bookingSlotModal.closeModal()
        },
        fetchInfo() {
            User.api().getDefaultSessionParams().then((res) => {
                this.maxBookingDuration = res.response.data.response.feature_parameters.find(fp => fp.code == 'max_session_duration')?.value
            })

            Booking.api().getBookingCreateInfo().then((res) => {
                this.channels = res.response.data.response.channels.map(ch => {
                    return {
                        name: ch.title,
                        value: ch.id
                    }
                })
            })

            Booking.api().getBookingCategories().then(res => {
                this.booking_categories = res.response.data.map(ch => {
                    return {
                        name: ch.name,
                        value: ch.id
                    }
                })
            })
        },
        cancel() {
            this.closeModal()
        },
        save() {
            this.loading = true

            let data = this.bookingSlot
            data.week_rules = JSON.stringify(this.weekSelected)
            data.slot_rules = JSON.stringify(this.timing.map(t => {
                return {
                    name: t.name,
                    scheduler: t.scheduler.map(s => {
                        return {
                            start: s.start,
                            end: s.end,
                            tz: this.currentUser.timezone,
                            multiplier: +s.multiplierValue || 0
                        }
                    })
                }
            }))

            data.tags = JSON.stringify(data.tags)

            data.booking_prices_attributes = data.booking_prices_attributes.map(p => {
                return {
                    id: p.id,
                    duration: p.duration,
                    price_cents: p.price_cents*100,
                    currency: p.currency,
                    deleted: p.deleted
                }
            })

            delete data.booking_prices

            data.replay_price_cents = data.replay_price_cents*100

            if(parseFloat(data.replay_price_cents) == 0) {
                data.replay_price_cents = null
            }

            if(this.mode == 'create' || this.mode == 'clone') {
                Booking.api().createBookingSlot(data).then(res => {
                    this.loading = false
                    if(this.mode == 'clone') {
                        this.mode = 'edit'
                        this.fromApiToForm(res.response.data)
                    }
                    else{
                        this.closeModal()
                        this.$flash('Booking slot was created successfully', 'success')
                    }
                    this.$eventHub.$emit('update:BookingSlotList')
                })
            }
            else {
                Booking.api().updateBookingSlot(data).then(res => {
                    this.loading = false
                    this.closeModal()
                    this.$eventHub.$emit('update:BookingSlotList')
                    this.$flash('Booking slot was updated successfully', 'success')
                })
            }
        },
        addNewRule() {
            this.bookingSlot.booking_prices_attributes.push({
                duration: 15,
                editTime: true,
                price_cents: 1,
                currency: "USD",
                deleted: false
            })
        },
        removeRule(rule) {
            rule.deleted = true
            // this.bookingSlot.booking_prices_attributes.splice(index, 1)
        },
        onEventCreate(event) {
            event.id = Math.random().toString(36).substring(7)
            event.content = this.getContentHTML(event)
            event.multiplier = false
            event.multiplierValue = 0
            return event
        },
        logEvents(eventName, event) {
            if(event.event) {
                event = event.event
            }
            if(event.endTimeMinutes - event.startTimeMinutes < this.minMinutes) {
                event.end = new Date(new Date(event.start).setHours(event.start.getHours(), event.start.getMinutes() + this.minMinutes))
                event.endTimeMinutes = event.start.getHours() * 60 + event.start.getMinutes() + this.minMinutes
                let ev = this.$refs.calendar.view.events.find(e => e.id == event.id)
                ev.end = event.end
                ev.endTimeMinutes = event.endTimeMinutes
            }

            this.scheduler = this.$refs.calendar.view.events
            console.log(eventName, event)
            this.simpleCalendarCalculate()

            if(eventName == 'event-delete') {
                this.scheduler = this.scheduler.filter(e => e.id != event.id)
                this.timing.forEach(t => {
                    t.scheduler = t.scheduler.filter(s => s.event.id != event.id)
                })
            }

            if(eventName == 'event-drag-create' || eventName == 'event-drop') {
                this.$nextTick(() => {
                    this.listenAllMultipliers()
                })
            }
        },
        simpleCalendarCalculate() {
            console.log('simpleCalendarCalculate')
            let days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
            let viewDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            let timing = viewDays.map(d => {
                return {
                    name: d,
                    scheduler: []
                }
            })

            this.scheduler.forEach(s => {
                let day = timing.find(d => d.name === days[new Date(s.start).getDay()])
                day.scheduler.push({
                    start: s.start.format('HH:mm'),
                    end: s.end.format('HH:mm'),
                    edit: false,
                    event: s,
                    multiplier: s.multiplier,
                    multiplierValue: s.multiplierValue
                })
            })

            timing.forEach(t => {
                t.scheduler.sort((a, b) => {
                    return (a.start.split(':')[0] * 60 + a.start.split(':')[1])
                        - (b.start.split(':')[0] * 60 + b.start.split(':')[1])
                })
            })

            this.timing = timing
        },
        openSimpleEdit(schedule, day) {
            this.changeTiming = {
                day,
                schedule
            }
            this.timing.forEach(t => {
                t.scheduler.forEach(s => {
                    s.edit = false
                })
            })

            schedule.editStart = schedule.start
            schedule.editEnd = schedule.end
            schedule.edit = true
        },
        saveSimple(day, schedule, event) {
            this.changeTiming = null
            console.log('saveSimple')
            event.stopPropagation()
            schedule.edit = false
            if(window.moment(schedule.editEnd, "HH:mm").diff(window.moment(schedule.editStart, "HH:mm")) / 1000 / 60 < this.minMinutes) {
                schedule.editEnd = window.moment(schedule.editStart, "HH:mm").add(this.minMinutes, 'minutes').format('HH:mm')
            }
            schedule.start = schedule.editStart
            schedule.end = schedule.editEnd
            schedule.event.multiplier = schedule.multiplier
            schedule.event.multiplierValue = schedule.multiplierValue
            schedule.event.startTimeMinutes = +schedule.start.split(':')[0] * 60 + +schedule.start.split(':')[1]
            schedule.event.endTimeMinutes = +schedule.end.split(':')[0] * 60 + +schedule.end.split(':')[1]
            schedule.event.start = new Date(new Date(schedule.event.start).setHours(+schedule.start.split(':')[0], +schedule.start.split(':')[1]))
            schedule.event.end = new Date(new Date(schedule.event.end).setHours(+schedule.end.split(':')[0], +schedule.end.split(':')[1]))

            this.timing.forEach(t => {
                t.scheduler.sort((a, b) => {
                    return (a.start.split(':')[0] * 60 + a.start.split(':')[1])
                        - (b.start.split(':')[0] * 60 + b.start.split(':')[1])
                })
            })
        },
        closeSimple() {
            this.changeTiming = null
            this.timing.forEach(t => {
                t.scheduler.forEach(s => {
                    s.edit = false
                })
            })
        },
        removeTime(schedule, day) {
            this.changeTiming = null
            console.log('removeTime')
            day.scheduler = day.scheduler.filter(s => s.event.id != schedule.event.id)
            this.scheduler = this.scheduler.filter(s => s.id != schedule.event.id)
        },
        addNewSchedule(day) {
            this.timing.forEach(t => {
                t.scheduler.forEach(s => {
                    s.edit = false
                })
            })

            console.log('addNewSchedule')
            let days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
            let daytoset = days.indexOf(day.name)
            let date = new Date()
            let distance = daytoset - date.getDay()
            date.setDate(date.getDate() + distance)

            let newSchedule = {
                start: '00:00',
                end: '01:00',
                editStart: '00:00',
                editEnd: '01:00',
                edit: true,
                multiplier: false,
                multiplierValue: 0,
                event: {
                    id: Math.random().toString(36).substring(7),
                    title: "",
                    start: new Date(date.setHours(0, 0, 0, 0)),
                    end: new Date(date.setHours(1, 0, 0, 0)),
                    startTimeMinutes: 0,
                    endTimeMinutes: 60,
                    multiplier: false,
                    multiplierValue: 0
                }
            }

            newSchedule.event.content = this.getContentHTML(newSchedule.event)

            day.scheduler.push(newSchedule)
            day.scheduler.sort((a, b) => {
                return (a.start.split(':')[0] * 60 + a.start.split(':')[1])
                 - (b.start.split(':')[0] * 60 + b.start.split(':')[1])
            })
            this.scheduler.push(newSchedule.event)

            this.changeTiming = {
                day,
                schedule: newSchedule
            }
        },
        addNewEvent(dayName, schedule) {
            console.log('addNewEvent')
            let days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            let daytoset = days.indexOf(dayName) + 1
            let date = new Date()
            let distance = daytoset - date.getDay()
            date.setDate(date.getDate() + distance)

            let sh = +schedule.start.split(':')[0]
            let sm = +schedule.start.split(':')[1]
            let eh = +schedule.end.split(':')[0]
            let em = +schedule.end.split(':')[1]

            let event = {
                id: Math.random().toString(36).substring(7),
                title: "",
                start: new Date(date.setHours(sh, sm, 0, 0)),
                end: new Date(date.setHours(eh, em, 0, 0)),
                startTimeMinutes: sh * 60 + sm,
                endTimeMinutes: eh * 60 + em,
                multiplier: schedule.multiplier,
                multiplierValue: schedule.multiplierValue
            }

            event.content = this.getContentHTML(event)

            schedule.event = event
            this.scheduler.push(event)
        },
        getContentHTML(data) {
            if(!data || !data.id) data.id = Math.random().toString(36).substring(7)
            let html = `<label>
                        <span>Multiplier</span>
                        <input id="ch-${data.id}" data-id="${data.id}" class="calendar-ch" ${data.multiplier ? 'checked' : ''} type='checkbox'>
                        <input id="in-${data.id}" data-id="${data.id}" class="smallInput" ${data.multiplier ? '' : 'disabled'} type='number'>%
                    </label>`

            return html
        },
        listenAllMultipliers(id = null) {
            console.log('listenAllMultipliers', id)
            let inputs = document.querySelectorAll('.calendar-ch')
            if(id) inputs = document.querySelectorAll(`#ch-${id}`)
            inputs.forEach(i => {
                let input = document.querySelector(`#in-${i.dataset.id}`)
                let schedule = this.scheduler.find(s => s.id == i.dataset.id)
                if(schedule) {
                    i.checked = schedule.multiplier
                    input.value = schedule.multiplierValue || 0
                    if(i.checked) {
                        input.disabled = false
                    }
                    else {
                        input.disabled = true
                    }
                }

                i.addEventListener('change', (e) => {
                    let id = e.target.dataset.id
                    let input = document.querySelector(`#in-${id}`)
                    let schedule = this.scheduler.find(s => s.id == id)
                    let timing = this.timing.find(t => t.scheduler.find(s => s.event.id == id))
                    let timingSchedule = timing.scheduler.find(s => s.event.id == id)
                    schedule.multiplier = e.target.checked
                    timingSchedule.multiplier = e.target.checked
                    schedule.multiplierValue = input.value || 0
                    timingSchedule.multiplierValue = input.value || 0
                    if(e.target.checked) {
                        input.disabled = false
                    }
                    else {
                        input.disabled = true
                    }
                    this.scheduler.forEach(s => {
                        if(s.id == id) {
                            s.multiplier = e.target.checked
                            s.multiplierValue = input.value || 0
                        }
                    })
                })

                input.addEventListener('change', (e) => {
                    let id = e.target.dataset.id
                    let schedule = this.scheduler.find(s => s.id == id)
                    let timing = this.timing.find(t => t.scheduler.find(s => s.event.id == id))
                    let timingSchedule = timing.scheduler.find(s => s.event.id == id)
                    schedule.multiplierValue = e.target.value || 0
                    timingSchedule.multiplierValue = e.target.value || 0
                })
            })
        },
        selectAllMonth(view) {
            window.moment().weeks()
            let start = window.moment(view.startDate).weeks()
            let end = window.moment(view.endDate).weeks()
            if(window.moment().weeks() > start) start = window.moment().weeks()
            if(window.moment().weeks() > end) return
            for(let i = start; i <= end; i++) {
                if(!this.weekSelected.includes(i)) this.weekSelected.push(i)
            }
        }
    }
}
</script>

<style>

</style>