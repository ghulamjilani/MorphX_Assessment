<template>
    <div class="calendar-day-pop-up">
        <component
            :is="scheduleItem.calendar_component_name"
            v-for="scheduleItem in scheduleItems"
            :key="scheduleItem.id"
            :calendar-item-data="scheduleItem"
            :scheduler-for="schedulerFor"
            mode="month" />
    </div>
</template>
<script>
import MbScheduleItem from "@components/mindbodyonline/schedule/MbScheduleItem.vue"
import SessionCalendarItem from "@components/mindbodyonline/schedule/SessionCalendarItem.vue"
import VideoCalendarItem from "@components/calendar/VideoCalendarItem.vue"

export default {
    components: {MbScheduleItem, SessionCalendarItem, VideoCalendarItem},
    props: ['scheduleItems', 'schedulerFor']
}
</script>
<style lang="scss">
.calendar-day-pop-up {
    padding: 1rem 0;
    width: 20rem;
}
</style>