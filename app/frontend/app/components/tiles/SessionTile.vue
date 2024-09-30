<template>
    <m-card>
        <template #top>
            <session-top
                :video="video" />
        </template>
        <template #bottom>
            <session-bottom
                :video="video"
                :showOrganization="true" />
        </template>
    </m-card>
</template>

<script>
import Session from "@models/Session"
import SessionTop from '@components/card-templates/SessionTop.vue'
import SessionBottom from '@components/card-templates/SessionBottom.vue'

export default {
    components: {SessionTop, SessionBottom},
    props: ["itemId"],
    computed: {
        video() {
            return Session.query().whereId(this.itemId).first()
        }
    }
}
</script>