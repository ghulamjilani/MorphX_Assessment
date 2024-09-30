<template>
    <div class="CM">
        <div class="CM__title">
            {{ $t('frontend.app.components.documents.dashboard_documents_content.documents') }}
        </div>
        <channel-line-tile-collapse
            v-for="channel in channels"
            :key="channel.id"
            :channel="channel" />
    </div>
</template>

<script>
import ChannelLineTileCollapse from '@components/channel/LineTileCollapse'
import Channel from "@models/Channel"

export default {
    name: 'DashboardDocumentsContent',
    components: {ChannelLineTileCollapse},
    data() {
        return {
            channels: []
        }
    },
    computed: {
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        }
    },
    mounted() {
        this.getChannels()
    },
    methods: {
        async getChannels() {
            const res = await Channel.api().getChannels({organization_id: this.currentOrganization.id})
            this.channels = res.response.data.response.channels
        }
    }
}
</script>
