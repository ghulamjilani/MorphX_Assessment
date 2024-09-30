<template>
    <m-card>
        <template #top>
            <replay-top
                :video="video"
                :type="video.type" />
        </template>
        <template #bottom>
            <replay-bottom
                :video="video"
                :type="video.type"
                :search-page="true" />
        </template>
    </m-card>
</template>

<script>
import Video from "@models/Video"
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'

export default {
    components: {ReplayTop, ReplayBottom},
    props: ["itemId"],
    computed: {
        video() {
            return Video.query().whereId(this.itemId).first()
        }
    }
}
</script>
