<template>
    <div
        v-click-outside="closeTooltip"
        v-tooltip="tooltipOptions"
        :class="[randColor(), mode]"
        :style="position"
        class="mb-schedule-item"
        @click="onClick">
        <div class="organizers">
            <div
                :style="photo"
                class="photo" />
            <div
                v-if="calendarItemData && calendarItemData.creator_first_name"
                class="name text-ellipsis">
                <div class="text-ellipsis">
                    {{ calendarItemData.creator_first_name }}
                </div>
                <div class="text-ellipsis">
                    {{ calendarItemData.creator_last_name }}
                </div>
            </div>
        </div>
        <div class="text-ellipsis">
            <div class="time text-ellipsis">
                {{ start_time | formattedDate(false, true) | lowercase }}
                -
                {{ end_time | formattedDate(false, true) | lowercase }}

                <i class="GlobalIcon-stream-camera" />
            </div>
            <div class="title text-ellipsis">
                {{ calendarItemData.title }}
            </div>
        </div>
    </div>
</template>

<script>
import calendaritem from "@mixins/calendaritem.js"
import ClickOutside from "vue-click-outside"
import utils from '@helpers/utils'

const Random = require("yy-random")

export default {
    directives: {
        ClickOutside
    },
    mixins: [calendaritem],
    computed: {
        toolTipContent() {
            let popUpHtml = `
      <div class="organizers">
        <div class="photo" style="background-image: url(${this.photoSrc})"></div>
        <div class="name text-ellipsis">
          <div class="text-ellipsis">${this.calendarItemData.creator_first_name}</div>
          <div class="text-ellipsis">${this.calendarItemData.creator_last_name}</div>
        </div>
      </div>

      <div>
        ${this.$options.filters.formattedDate(this.start_time, false, true).toLowerCase()}
        - 
        ${this.$options.filters.formattedDate(this.end_time, false, true).toLowerCase()}
      </div>
      <div class="class-description-name">${this.calendarItemData.title}</div>
      <div>
        <b>Type:</b>
        Online Session <i class="GlobalIcon-stream-camera"></i>
      </div>
      `

            return popUpHtml
        },
        position() {
            // todo: andrey refactor
            if (this.isDayMode) {
                this.refreshPositionTrigger
                return {
                    left: `${this.minuteLength * this.start_time.diff(this.hour0, "minutes")}px`,
                    width: `${this.minuteLength * this.end_time.diff(this.start_time, "minutes")}px`
                }
            }
            return {}
        },
        photoSrc() {
            return this.calendarItemData.creator_avatar_url
        },
        start_time() {
            return utils.dateToTimeZone(this.calendarItemData.start_at, true)
        },
        end_time() {
            return utils.dateToTimeZone(this.calendarItemData.end_at, true)
        }
    },
    methods: {
        randColor() {
            if (this.schedulerFor == "mbs-user") {
                Random.seed(this.calendarItemData.title)
            } else {
                Random.seed(this.calendarItemData.creator_avatar_url + this.calendarItemData.creator_first_name + this.calendarItemData.creator_last_name)
            }
            return `c${Random.range(1, 11)}`
        }
    }
}
</script>
