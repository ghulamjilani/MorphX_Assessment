import device from "current-device";

const Random = require('yy-random')

export default {
    props: [
        // base
        'mode',
        'schedulerFor',
        'calendarItemData',

        // timeline position
        'hour0',
        'minutesCount',
        'minuteLength',
    ],
    data() {
        return {
            isTooltipOpen: false,
            refreshPositionTrigger: uid()
        }
    },
    computed: {
        toolTipContent() {
            return "Tooltip content"
        },
        tooltipOptions() {
            let options = {
                content: this.toolTipContent,
                classes: ['mb-schedule-item-pop-up'],
                placement: 'right'
            }

            if (device.mobile()) {
                options.trigger = 'manual'
                options.show = this.isTooltipOpen,
                    options.boundariesElement = 'window',
                    options.placement = 'bottom',
                    options.autoHide = true
            }

            return options
        },
        isDayMode() {
            return this.mode === 'day'
        },
        isMonthMode() {
            return this.mode === 'month'
        },
        isYearMode() {
            return this.mode === 'year'
        },
        photo() {
            return {backgroundImage: `url(${this.photoSrc})`}
        },
    },
    methods: {
        randColor() {
            Random.seed(JSON.stringify(this.calendarItemData))
            return `c${Random.range(1, 11)}`
        },
        closeTooltip() {
            this.isTooltipOpen = false
        },
        onClick() {
            if (device.mobile()) {
                this.isTooltipOpen = !this.isTooltipOpen
            }
        },
        refreshPosition() {
            this.refreshPositionTrigger = uid()
            this.width = this.$parent.$el.offsetWidth
        },
    },
    mounted() {
        if (this.isDayMode) {
            this.refreshPosition()
        }
    }
}