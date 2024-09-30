<template>
    <m-card>
        <template #top>
            <recording-top
                :video="recording"
                :type="recording.type" />
        </template>
        <template #bottom>
            <recording-bottom
                :video="recording"
                :type="recording.type"
                :search-page="true" />
        </template>
    </m-card>
</template>

<script>
import Recording from "@models/Recording"
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'

export default {
    components: {RecordingTop, RecordingBottom},
    props: ["itemId"],
    computed: {
        recording() {
            return Recording.query().whereId(this.itemId).first()
        }
    }
}
</script>
