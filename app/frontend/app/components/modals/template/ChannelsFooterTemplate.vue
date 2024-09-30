<template>
    <div class="mChannel__channels__footer">
        <div class="channel__list__wrapp mChannel__section">
            <div class="channel__list__label">
                <div>
                    <span>Channels</span>
                </div>
            </div>
            <div class="channel__list">
                <div
                    v-for="channel in channels"
                    :key="channel.id"
                    class="channel__tile">
                    <channel-tile
                        :exist-channel="channel" />
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
        }
    }
}
</script>