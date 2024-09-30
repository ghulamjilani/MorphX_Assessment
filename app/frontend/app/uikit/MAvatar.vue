<template>
    <div
        class="bookingLabel__wrapper avatar"
        :class="'avatar__' + size"
        @click="() => $emit('click')">
        <i
            v-if="canBook && $railsConfig.global.booking && $railsConfig.global.booking.enabled"
            v-tooltip="'This Creator available for Booking'"
            class="bookingLabel GlobalIcon-calendar"
            :class="'bookingLabel__' + starSize" />
        <img
            v-if="src"
            :src="src"
            :alt="alt">
    </div>
</template>

<script>
export default {
  props: {
    size: {
      type: String,
      default: 'm' // xs: 2.6, s:3, m:4, l:6, xl:10, sl:15, xxl:20
    },
    starSize: {
      type: String,
      default: 'l' // xs: 2.6, s:3, m:4, l:6, xl:10, sl:15, xxl:20
    },
    src: {
      type: String,
      default: '',
      required: true
    },
    alt: {
      type: String,
      default: ''
    },
    canBook: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style>

</style>