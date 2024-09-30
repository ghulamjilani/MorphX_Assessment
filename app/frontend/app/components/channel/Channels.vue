<template>
    <div
        id="anchorSection__network"
        class="mChannel__channels">
        <div class="channel__list__wrapp mChannel__section">
            <div class="channel__list__label">
                <div>
                    <span>{{ $t('channel_page.channels') }}</span>
                </div>
                {{ $t('channel_page.part_of') }} {{ name }}
            </div>
            <div class="channel__list">
                <div
                    v-for="channel in channels"
                    :key="channel.id"
                    class="channel__tile">
                    <channel-tile
                        class="full__width"
                        :channels-plans="channelsPlans"
                        :exist-channel="channel"
                        :current-channel-id="currentChannelId" />
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import ChannelTile from "@components/tiles/ChannelTile"

export default {
    components: {ChannelTile},
    props: {
        channels: {
            type: Array
        },
        name: String,
        channelsPlans: {},
        currentChannelId: null
    }
}
</script>

