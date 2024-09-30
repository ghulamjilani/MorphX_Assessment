<template>
    <div class="datefilterMK2">
        <m-select
            v-model="dateValue"
            :options="options"
            :placeholder="placeholder"
            :pure="true"
            type="date">
            <m-datepicker
                v-model="date"
                :borderless="true"
                :placeholders="['From', 'To']"
                :range="true"
                class="datefilterMK2__datepicker" />
        </m-select>
    </div>
</template>

<script>
/**
 * @displayName DateFilter
 * @example ./docs/mdatefilter.md
 */
export default {
    props: {
        /**
         * @model
         */
        value: {},
        placeholder: String
    },
    data() {
        return {
            options: [
                {name: "Date", value: "date", hidden: true},
                {name: "All Time", value: "all"},
                {name: "Today", value: "today"},
                {name: "This week", value: "this_week"},
                {name: "This month", value: "this_month"},
                {name: "This year", value: "this_year"}
            ],
            date: {
                start: new Date(),
                end: new Date()
            },
            dateValue: "date"
        }
    },
    watch: {
        date(val) {
            this.dateValue = "date"
            this.$emit("input", {
                date: {
                    start: moment(this.date.start).tz("Europe/London").startOf('day'),
                    end: moment(this.date.end).tz("Europe/London").endOf('day')
                },
                dateValue: this.dateValue
            })
            this.$emit("change", {
                date: {
                    start: moment(this.date.start).tz("Europe/London").startOf('day'),
                    end: moment(this.date.end).tz("Europe/London").endOf('day')
                },
                dateValue: this.dateValue
            })
        },
        dateValue(val) {
            if (val) {
                let dateR = {start: null, end: null}

                switch (val) {
                    case 'today':
                        dateR.start = moment().tz("Europe/London").startOf('day')
                        dateR.end = moment().tz("Europe/London").endOf('day')
                        break
                    case 'this_week':
                        dateR.start = moment().tz("Europe/London").startOf('week').startOf('day')
                        dateR.end = moment().tz("Europe/London").endOf('week').endOf('day')
                        break
                    case 'this_month':
                        dateR.start = moment().tz("Europe/London").startOf('month').startOf('day')
                        dateR.end = moment().tz("Europe/London").endOf('month').endOf('day')
                        break
                    case 'this_year':
                        dateR.start = moment().tz("Europe/London").startOf('year').startOf('day')
                        dateR.end = moment().tz("Europe/London").endOf('year').endOf('day')
                        break
                }

                if (val !== "date") {
                    this.$emit("input", {
                        date: dateR,
                        dateValue: val
                    })
                    this.$emit("change", {
                        date: dateR,
                        dateValue: val
                    })
                }
            }
        }
    },
    created() {
        if (this.value.date) {
            this.date = this.value.date
            this.dateValue = "date"
        } else {
            this.dateValue = this.value.dateValue
        }
    }
}
</script>

