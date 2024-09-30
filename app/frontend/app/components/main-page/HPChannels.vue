<template>
    <div>
        <!-- <subs-plans-template /> -->
        <!-- <plan-info :channel="channel" /> -->
        <div
            v-if="channels.length || !loading"
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ useStandartTitle ? $t('home_page.titles.channels') : title }}
                </h3>
                <a
                    class="homePage__title__more"
                    href="/search?ford=views_count&ft=Channel">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div class="TileSlider__Wrapper">
                <div
                    v-if="loading"
                    class="TileSlider">
                    <vue-horizontal-list
                        id="horScroll"
                        :items="channels"
                        :options="options">
                        <template #default="{item}">
                            <channel-tile
                                :use-promo-weight="promoWeight"
                                :channels-plans="channelsPlans"
                                :exist-channel="item" />
                        </template>
                    </vue-horizontal-list>
                </div>
                <div
                    v-else
                    class="mChannel__tiles__list">
                    <div class="mChannel__tiles__items placeholder">
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import TilePlaceholder from "@components/TilePlaceholder"
import ChannelTile from "../tiles/ChannelTile"
import planInfo from '../modals/planInfo'
import VueHorizontalList from 'vue-horizontal-list'
import SelfFollows from "@models/SelfFollows"
import Search from "@models/Search"
import SelfSubscription from "@models/SelfSubscription"
import SelfFreeSubscription from "@models/SelfFreeSubscription"

export default {
    components: {TilePlaceholder, VueHorizontalList, ChannelTile, planInfo},
    props: {
        title: String,
        useStandartTitle: {
            type: Boolean,
            default: false
        },
        onlyShowOnHome: Boolean,
        hideOnHome: {
            type: Boolean,
            default: false
        },
        promoWeight: Boolean,
        orderBy: String,
        order: String,
        itemsCount: Number
    },
    data() {
        return {
            channel: {},
            channels: [],
            loading: false,
            subscription: {},
            options: {
                responsive: [
                    {end: 640, size: 1.2},
                    {start: 641, end: 767, size: 2.5},
                    {start: 768, end: 991, size: 2.5},
                    {start: 992, end: 1199, size: 3},
                    {start: 1950, end: 2249, size: 5},
                    {start: 2250, size: 6},
                    {size: 4}
                ],
                list: {
                    windowed: 992
                }
            },
            channelsPlans: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    watch: {
        currentUser: {
            handler(val) {
                if (val) {
                    SelfFollows.api().getFollows({followable_type: "Channel"})
                    SelfSubscription.api().getSubscriptions()
                    SelfFreeSubscription.api().getSubscriptions()
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.LoadChannels()
        this.$eventHub.$on('home-page:openSubsPlans', (subscription, channel) => {
            this.subscription = subscription
            this.channel = channel
            this.openSubsPlans()
        })
    },
    methods: {
        openSubsPlans() {
            this.$refs.subsPlans.open()
        },
        findChannelPlans(item) {
            return item.subscription?.plans || []
        },
        LoadChannels() {
            Search.api().searchApi({
                show_on_home: (this.onlyShowOnHome ? true : null),
                hide_on_home: (this.hideOnHome ? false : null),
                limit: this.itemsCount || 12,
                order_by: this.orderBy ? this.orderBy : "listed_at",
                order: this.order ? this.order : "asc",
                searchable_type: "Channel",
                promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.channels = res.response.data.response.documents.map(e => {
                    let obj = e.searchable_model.channel
                    obj.channel_category = e.searchable_model.channel_category
                    obj.user = e.searchable_model.user
                    return Object.assign(obj, e.document)
                })
                this.channels.forEach(ch => {
                    if (ch.subscription?.plans) {
                        let sorted = ch.subscription.plans.sort((a, b) => {
                            return a.amount - b.amount
                        })
                        this.channelsPlans.push({
                            id: ch.id,
                            plans: sorted
                        })
                        ch.plans = sorted
                    }
                })
                this.loading = true
                this.$eventHub.$emit('home-page:scroll__channels', (this.channels.length))
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        }
    }
}
</script>
