<template>
    <div>
        <div
            v-if="videos.sessions.length || !loading || dontHide"
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ useStandartTitle ? $t('home_page.titles.live_experiences') : title }}
                </h3>
                <a
                    class="homePage__title__more"
                    href="/search?ford=new&ft=Session">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div class="TileSlider__Wrapper">
                <div
                    v-if="loading && !dontHide"
                    class="TileSlider TileSlider__arrow">
                    <vue-horizontal-list
                        id="horScroll"
                        :items="videos.sessions"
                        :options="options">
                        <template #default="{item}">
                            <m-card>
                                <template #top>
                                    <session-top
                                        :video="item"
                                        :use-promo-weight="promoWeight" />
                                </template>
                                <template #bottom>
                                    <session-bottom
                                        :show-organization="true"
                                        :video="item" />
                                </template>
                            </m-card>
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
import SessionBottom from '@components/card-templates/SessionBottom.vue'
import SessionTop from '@components/card-templates/SessionTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Search from "@models/Search"
import VueHorizontalList from 'vue-horizontal-list'

export default {
    components: {TilePlaceholder, SessionTop, SessionBottom, VueHorizontalList},
    props: {
        dontHide: {
            type: Boolean,
            default: false
        },
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
        order: String,
        itemsCount: Number
    },
    data() {
        return {
            videos: {
                sessions: []
            },
            loading: false,
            startX: null,
            startY: null,
            dragElement: null,
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
            }
        }
    },
    mounted() {
        this.loadSessions()
    },
    created() {
        this.sessionsChannel = initSessionsChannel()

        this.sessionsChannel.bind(sessionsChannelEvents.sessionStarted, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionStarted, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.sessionStopped, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionStopped, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.sessionCancelled, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionCancelled, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.livestreamMembersCount, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.livestreamMembersCount, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.liveGuideForceRefresh, (data) => {
            this.loadSessions()
            this.$eventHub.$emit(sessionsChannelEvents.liveGuideForceRefresh, data)
        })
    },
    methods: {
        loadSessions() {
            Search.api().searchApi({
                show_on_home: (this.onlyShowOnHome ? true : null),
                hide_on_home: (this.hideOnHome ? false : null),
                limit: this.itemsCount || 12,
                order_by: "start_at",
                order: this.order,
                searchable_type: "Session",
                promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.videos.sessions = []
                this.loading = true
                this.videos.sessions = this.videos.sessions.concat(res.response.data.response.documents?.map(e => {
                    e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    return Object.assign(e.searchable_model, e.document)
                }))
                this.$eventHub.$emit('home-page:scroll__live', (this.videos.sessions.length))
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        }
    }
}
</script>
