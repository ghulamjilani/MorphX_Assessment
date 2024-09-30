<template>
    <validation-provider
        ref="provider"
        v-slot="v"
        :rules="rules"
        tag="div">
        <div class="input__calendar input__field">
            <date-picker
                v-model="date"
                :is-range="range"
                :masks="masks"
                :max-date="maxDate"
                :popover="popover"
                class="display__inline-block full__width"
                @popoverDidShow="openYearFirst && openYear()"
                @input="inputChange"
                @selected="onChange">
                <template
                    v-if="!range"
                    #default="{ inputValue,inputEvents,togglePopover }">
                    <input
                        ref="datePickInput"
                        :class="{'input__field__without-label': !label}"
                        :placeholder="label ? ' ' : getPlaceholder"
                        :value="(typeof date != 'string' && date.start == null) ? '' : inputValue"
                        type="text"
                        @focusout="dateInputIsFocused = false"
                        v-on="inputEvents">
                    <m-icon
                        v-if="iconCalendar"
                        class="input__calendar__icon input__field__icon"
                        @click="() => {togglePopover({ placement: 'bottom-start' })}">
                        GlobalIcon-empty-calendar
                    </m-icon>
                    <label
                        v-if="label"
                        class="label"> {{ label }} </label>
                    <div class="input__field__bottom">
                        <div
                            v-if="v.errors[0]"
                            class="input__field__bottom__errors">
                            {{ v.errors[0] }}
                        </div>
                    </div>
                </template>
                <template
                    v-else
                    #default="{ inputValue, togglePopover }">
                    <div
                        class="input__calendar__range-fields"
                        @click="() => { togglePopover({ placement: 'bottom-start', positionFixed:'fixed' })}">
                        <div class="input__calendar__input-field">
                            <input
                                :class="{'input__field__without-border': borderless}"
                                :placeholder="(labels && labels[0]) ? ' ' : placeholders[0]"
                                :value="inputValue.start"
                                readonly
                                type="text">
                            <label
                                v-if="labels && labels[0]"
                                class="label"> {{ labels[0] }} </label>
                            <m-icon class="input__calendar__icon input__field__icon">
                                GlobalIcon-calendar
                            </m-icon>
                        </div>
                        <span class="input__calendar__input-spacer">-</span>
                        <div class="input__calendar__input-field">
                            <input
                                :class="{'input__field__without-border': borderless}"
                                :placeholder="(labels && labels[1]) ? ' ' : placeholders[1]"
                                :value="inputValue.end"
                                readonly
                                type="text">
                            <label
                                v-if="(labels && labels[1])"
                                class="label"> {{ labels[1] }} </label>
                            <m-icon class="input__calendar__icon input__field__icon">
                                GlobalIcon-calendar
                            </m-icon>
                        </div>
                    </div>
                </template>
            </date-picker>
        </div>
    </validation-provider>
</template>

<script>
import DatePicker from 'v-calendar/lib/components/date-picker.umd'

/**
 * Datepicker https://vcalendar.io/api/v2.0/datepicker.html
 * @example ./docs/mdatepicker.md
 * @displayName Datepicker
 */
export default {
    components: {DatePicker},
    props: {
        /**
         * @model
         */
        iconCalendar: Boolean,
        value: {
            type: [Date, Object, String],
            default: null
        },
        /**
         * @name
         */
        name: {
            type: String,
            default: 'calendar'
        },
        /**
         * Placeholder
         * @default ""
         */
        placeholder: {
            type: String,
            default: ""
        },
        /**
         * Placeholder on focus
         * @default ""
         */
        placeholderOnFocus: {
          type: String,
          default: null
        },
        /**
         * Is range values
         * @values true, false
         * @default false
         */
        range: {
            type: Boolean,
            default: false
        },
        /**
         * Label
         * @default From
         */
        label: {
            type: String,
            default: ''
        },
        /**
         * Labels for range
         * @default null
         */
        labels: {
            type: Array,
            default: null
        },
        /**
         * Placeholders for range
         * @default null
         */
        placeholders: {
            type: Array,
            default: null
        },
        /**
         * Max date
         * @default null
         */
        maxDate: {
            // type: String,
            default: null
        },
        /**
         * Validation rules
         */
        rules: {
            type: String,
            default: ""
        },
        /**
         * Borderless field without border
         * @values: true, false
         * @default false
         */
        borderless: {
            type: Boolean,
            default: false
        },
        customMask: {},
      /**
       * openYearFirst open popover witch open year for select
       * @default false
       */
        openYearFirst:{
          default: false
        },
      /**
       * openYearFirst open popover witch open year for select
       * @values: Object
       * Description: Visibility mode for the input/slot popover (hover-focus, hover, focus, visible, hidden)
       */
       popover: Object
    },
    data() {
        return {
            date: {
                start: null,
                end: null
            },
            dateInputIsFocused: false,
            masks: this.customMask ? this.customMask : {input: 'MM/DD/YYYY'}
        }
    },
    computed:{
        getPlaceholder: function () {
            if(this.dateInputIsFocused && this.placeholderOnFocus){ //if focused and props exist
                return this.placeholderOnFocus  //change placeholder form props
            }
            return this.placeholder
        }
    },
    watch: {
        date(val) {
            this.$emit("input", JSON.parse(JSON.stringify(val)))
        },
        value: {
            handler(val) {
                if (!val || new Date(val?.start).getTime() != new Date(this.date.start).getTime()
                    || new Date(val?.end).getTime() != new Date(this.date.end).getTime()) {
                    if (!val || val?.start === null) {
                        this.date = {
                            start: null,
                            end: null
                        }
                    } else {
                        this.date = JSON.parse(JSON.stringify(val))
                    }
                }
            },
            deep: true
        }
    },
    methods: {
        openYear() {
            setTimeout(() => {
                if(document.querySelector('.vc-title')) document.querySelector('.vc-title').click()
                this.$nextTick(() => {
                    if(document.querySelector('.vc-nav-title')) document.querySelector('.vc-nav-title').click()
                })
                  setTimeout(() => {
                    this.$refs.datePickInput.focus() //make focus for input
                    this.dateInputIsFocused = true //show placeholder for focused state
                  }, 100)
            }, 100)
        },
        onChange() {
            this.$emit("changed", JSON.parse(JSON.stringify(this.date)))
        },
        inputChange() {
            this.$emit("changed", JSON.parse(JSON.stringify(this.date)))
        }
    }

}
</script>

<style lang="scss">
body {
    .vc-container {
        border: 1px solid var(--border__separator);
        background: var(--bg__content);
        color: var(--tp__main);

        .vc-highlight, .vc-highlight.vc-highlight-base-middle {
            background-color: var(--btn__main);
            border-color: var(--btn__main);
        }
    }

    .vc-title {
        color: var(--tp__main) !important;
    }

    .vc-popover-content-wrapper {
        color: red;
    }
}
</style>