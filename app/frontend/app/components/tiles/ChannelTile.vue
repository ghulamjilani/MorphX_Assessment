<template>
    <div
        :id="`channel_tile_${channel.id}`"
        :data-id="channel.id"
        class="ChannelsTile"
        data-type="channel">
        <a
            :href="channel.relative_path"
            class="ChannelsTile__img">
            <div
                :style="backgroundImage"
                class="ChannelsTile__img__container" />
            <div
                :style="OrganizationImage"
                class="ChannelsTile__img__organization" />
        </a>
        <moderate-tiles
            :item="channel"
            type="Channel"
            :use-promo-weight="usePromoWeight" />
        <div class="ChannelsTile__body">
            <a
                :href="channelPath"
                :title="channel.title"
                class="ChannelsTile__body__name">
                {{ channel.title }}
            </a>
            <div
                v-if="channel.organization"
                class="ChannelsTile__body__owner">
                <a
                    @click="goToDefaultChannel()">
                    {{ $t('channel_tile.part_of') }} {{ channel.organization.name }}
                </a>
            </div>
            <div class="ChannelsTile__body__category">
                {{ channelCateName }}
            </div>
            <div class="ChannelsTile__body__since">
                {{ $t('channel_tile.since') }} {{ year }}
                <div class="ChannelsTile__body__since__dot" />
                {{ channel.past_sessions_count }} {{ $t('channel_tile.streams') }}
            </div>
            <div class="ChannelsTile__btns"
                v-if="!currentFollow &&
                    (selfSubscriptions || (channel.plans || channel.subscription && channel.subscription.plans) && getStartedPlan(channel))">
                <div
                    v-if="selfSubscriptions"
                    class="ChannelsTile__subscribed">
                    {{ $t('channel_tile.subscribed') }}
                </div>
                <div
                    v-else-if="(channel.plans || channel.subscription && channel.subscription.plans) && getStartedPlan(channel)"
                    class="ChannelsTile__subscribe"
                    @click="openSubsPlans">
                    {{ $t('channel_tile.subscribe') }} {{ getStartedPlan(channel) }}
                </div>
            </div>
            <div class="ChannelsTile__btns"
                v-else-if="!currentFollow">
                <m-btn
                    v-show="!selfFollows && !currentFollow"
                    class="avatarBlock__item__content__follow"
                    size="s"
                    type="bordered"
                    @click="followChannel(channel)">
                    {{ $t('channel_tile.follow_channel') }}
                </m-btn>
                <m-btn
                    v-show="selfFollows && !currentFollow"
                    class="avatarBlock__item__content__following avatarBlock__item__content__following__channel"
                    size="s"
                    type="secondary"
                    @click="unFollowChannel(channel)"
                    @mouseover.native="handleChannelHover($event)"
                    @mouseleave.native="handleChannelBlur($event)">
                    {{ $t('channel_tile.following_channel') }}
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
import Channel from "@models/Channel"
import User from "@models/User"
import SelfFollows from "@models/SelfFollows"
import SelfSubscription from "@models/SelfSubscription"
import SelfFreeSubscription from "@models/SelfFreeSubscription"

export default {
    components: {  },
    props: {
        existChannel: Object,
        itemId: Number,
        channelsPlans: Array,
        search: Boolean,
        currentChannelId: null,
        usePromoWeight: Boolean
    },
    computed: {
        currentFollow() {
            if(!this.channel.user && !this.channel.organizer) return false
            return this.channel.user ? this.currentUser?.id === this.channel.user.id : this.currentUser?.id === this.channel.organizer?.id
        },
        selfFollows() {
            return SelfFollows.query().where('id', this.channel.id).exists()
        },
        channel() {
            return this.existChannel ? this.existChannel : Channel.query().whereId(this.itemId).first()
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        backgroundImage() {
            if (this.channel?.image_gallery_url) return {backgroundImage: `url(${this.channel.image_gallery_url})`}
        },
        OrganizationImage() {
            if (this.channel?.organization?.logo_url) return {backgroundImage: `url(${this.channel.organization.logo_url})`}
        },
        year() {
            return new Date(this.channel.created_at).getFullYear()
        },
        selfSubscriptions() {
            if (this.currentUser && this.channel) {
                return SelfFreeSubscription.query().where('channel_id', this.channel.id).exists() || SelfSubscription.query().where('channel_id', this.channel.id).where('status', (value) => value == "trialing" || value == "active").exists()
            } else {
                return false
            }
        },
        channelCateName() {
            return this.channel?.category_name || this.channel?.channel_category?.name
        },
        channelPath(){
            if (this.currentChannelId && this.existChannel?.id) {
                if (this.currentChannelId !== this.existChannel?.id) {
                    return location.origin + this.channel.relative_path
                }
                else {
                    return '#'
                }
            }
            else {
                return location.origin + this.channel.relative_path
            }
        }
    },
    mounted() {
        // this.getSelfSubscription()
        // this.getSelfFreeSubscription()
    },
    methods: {
        getSelfSubscription() {
            return new Promise((resolve) => {
                if (this.currentUser) {
                    SelfSubscription.api().getSubscriptions().then(() => {
                        resolve()
                    })
                } else {
                    resolve()
                }
            })
        },
        getSelfFreeSubscription() {
            return new Promise((resolve) => {
                if (this.currentUser) {
                    SelfFreeSubscription.api().getSubscriptions().then(() => {
                        resolve()
                    })
                } else {
                    resolve()
                }
            })
        },
        openSubsPlans() {
            this.$eventHub.$emit("close-modal:all")
            this.$eventHub.$emit("open-modal:subscriptionPlans", this.channel.subscription, this.channel)
            // this.$refs.subsPlans.open()
        },
        goToDefaultChannel(){
            Channel.api().defaultOrganizationChannel({id: this.channel.organization.id})
                .then((res) => {
                    if (location.pathname !== '/channels'+res.response.data.response.organization.default_location) {
                        this.goTo(location.origin + res.response.data.response.organization.default_location)
                    }
                })
                .catch((error) => {
                    console.log(error)
                })
        },
        getStartedPlan(channel) {
            if(!channel.subscription.can_be_subscribed) return null

            let channelsPlans = this.channelsPlans ? this.channelsPlans : [{
                            id: channel.id,
                            plans: this.channel?.subscription?.plans
                        }]
            console.log("-----------------------", channelsPlans)
            let chp = channelsPlans?.find(e => e.id === channel.id)
            if (!chp || !chp.plans) return 0
            let str = ""
            let minPrice = 10000000
            chp.plans.forEach(e => {
                if (minPrice > +e.amount) {
                    minPrice = +e.amount
                    str = e.formatted_price
                }
            })
            return str
        },
        unFollowChannel(channel) {
            User.api().userUnFollow({followable_type: "Channel", followable_id: channel.id}).then((res) => {
                SelfFollows.delete(channel.id)
            })
        },
        handleChannelHover(event) {
            event.target.innerText = this.$t('channel_tile.unfollow_channel')
        },
        handleChannelBlur(event) {
            event.target.innerText = this.$t('channel_tile.following_channel')
        },
        followChannel(channel) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                User.api().userFollow({followable_type: "Channel", followable_id: channel.id}).then((res) => {
                    SelfFollows.api().getFollows({followable_type: "Channel"})
                })
            }
        }
    }
}
</script>
