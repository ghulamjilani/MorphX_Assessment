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
                v-if="calendarItemData.staff"
                class="name text-ellipsis">
                <div class="text-ellipsis">
                    {{ calendarItemData.staff.first_name }}
                </div>
                <div class="text-ellipsis">
                    {{ calendarItemData.staff.last_name }}
                </div>
            </div>
        </div>
        <div class="text-ellipsis">
            <div class="time text-ellipsis">
                {{ calendarItemData.start_time | formattedDate(false, true) | lowercase }}
                -
                {{ calendarItemData.end_time | formattedDate(false, true) | lowercase }}
            </div>
            <div class="title text-ellipsis">
                {{ calendarItemData.class_description.name }}
            </div>
        </div>
    </div>
</template>

<script>
import calendaritem from "@mixins/calendaritem.js"
import ClickOutside from "vue-click-outside"

const Random = require("yy-random")

export default {
    directives: {
        ClickOutside
    },
    mixins: [calendaritem],
    computed: {
        toolTipContent() {
            let popUpHtml = ""

            // todo: fix bg
            if (this.calendarItemData.staff) {
                popUpHtml = `
        <div class="organizers">
          <div class="photo" style="background-image: url(${this.calendarItemData.staff.image_url})"></div>
          <div class="name text-ellipsis">
            <div class="text-ellipsis">${this.calendarItemData.staff.first_name}</div>
            <div class="text-ellipsis">${this.calendarItemData.staff.last_name}</div>
          </div>
        </div>
        `
            }

            popUpHtml += `
      <div>
        ${this.$options.filters.formattedDate(this.start_time, false, true).toLowerCase()}
        - 
        ${this.$options.filters.formattedDate(this.end_time, false, true).toLowerCase()}
      </div>
      <div class="class-description-name">${this.calendarItemData.class_description.name}</div>
      <div>
        <b>City:</b>
        ${this.calendarItemData.location.city}
      </div>
      <div>
        <b>Address:</b> 
        ${this.calendarItemData.location.address}
        ${this.calendarItemData.location.address2 ? "," : ""}
        ${this.calendarItemData.location.address2}
      </div>
      <div>
        <b>Phone:</b>
        (${this.calendarItemData.location.phone_extension}) ${this.calendarItemData.location.phone}
      </div>
      `

            if (this.calendarItemData.staff) {
                popUpHtml += `<div class="staff-bio"> <b>Bio:</b> ${this.calendarItemData.staff.bio}</div>`
            }

            return popUpHtml
        },
        position() {
            // todo: andrey refactor
            if (this.isDayMode) {
                this.refreshPositionTrigger

                // let start_time = moment( this.hour0.format().split('T')[0] + 'T' + this.calendarItemData.start_time.split(' ')[1].split(' ')[0] )

                return {
                    left: `${this.minuteLength * this.start_time.diff(this.hour0, "minutes")}px`,
                    with: `${this.end_time.diff(this.start_time, "minutes")}px`
                }
            }
            return {}
        },
        photoSrc() {
            return this.calendarItemData.staff.image_url
        },
        start_time() {
            return moment(this.calendarItemData.start_time)
        },
        end_time() {
            return moment(this.calendarItemData.end_time)
        }
    },
    methods: {
        randColor() {
            if (this.schedulerFor == "mbs-user") {
                Random.seed(JSON.stringify(this.calendarItemData.class_description))
            } else {
                Random.seed(JSON.stringify(this.calendarItemData.staff))
            }
            return `c${Random.range(1, 11)}`
        }
    }
}
</script>
