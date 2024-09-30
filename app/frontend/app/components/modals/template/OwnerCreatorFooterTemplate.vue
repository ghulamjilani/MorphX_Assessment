<template>
    <div
        v-if="(owner.channels_as_invited_presenter || channels_as_owner) && (owner.channels_as_invited_presenter.length || channels_as_owner.length)"
        class="mChannel__channels__footer">
        <div class="channel__list__wrapp mChannel__section">
            <div
                v-if="channels_as_owner.length"
                class="channel__list__label">
                <div>
                    <span>Owner</span>
                </div>
            </div>
            <div class="channel__list">
                <div
                    v-for="channel in channels_as_owner"
                    :key="channel.id"
                    class="channel__tile">
                    <channel-tile
                        :channels-plans="channel.subscription && [{
                            id: channel.id,
                            plans: channel.subscription.plans
                        }]"
                        :exist-channel="channel"
                        class="full__width" />
                </div>
            </div>
            <div
                v-if="owner.channels_as_invited_presenter.length"
                class="channel__list__label">
                <div>
                    <span>{{ $t('components.modals.template.owner_creator_footer_template.creator_at', {creator_upper: $t('dictionary.creator_upper')}) }}</span>
                </div>
            </div>
            <div class="channel__list">
                <router-link
                    v-for="channel in owner.channels_as_invited_presenter"
                    :key="channel.id"
                    :to="{ name: 'channel-slug',params: { id: channel.relative_path.split('/')[2], slug: channel.relative_path.split('/')[3] }}"
                    class="channel__tile">
                    <channel-tile
                        :channels-plans="channel.subscription && [{
                            id: channel.id,
                            plans: channel.subscription.plans
                        }]"
                        :exist-channel="channel" />
                </router-link>
            </div>
        </div>
    </div>
</template>

<script>
import ChannelTile from "@components/tiles/ChannelTile"

export default {
    components: {ChannelTile},
    props: {
        owner: {
            type: Object
        }
    },
    computed: {
        channels_as_owner() {
            return this.owner?.channels_as_owner?.map(e => {
                e.user = this.owner
                return e
            })
        }
    },
    mounted() {
        if (window.spaMode == "monolith") {
            this.$router?.beforeEach((to, from, next) => {
                location.href = location.origin + to.path
            })
        }
    }
}
</script>