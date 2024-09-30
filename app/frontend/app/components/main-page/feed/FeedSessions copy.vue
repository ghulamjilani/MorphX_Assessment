<template>
    <div>
        <div
            v-if="videos.sessions.length || !loading || dontHide"
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ title }}
                </h3>
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
import Feed from "@models/Feed"
import VueHorizontalList from 'vue-horizontal-list'

export default {
    components: {TilePlaceholder, SessionTop, SessionBottom, VueHorizontalList},
    props: {
        dontHide: {
            type: Boolean,
            default: false
        },
        title: String,
        // useStandartTitle: {
        //     type: Boolean,
        //     default: false
        // },
        // onlyShowOnHome: Boolean,
        // hideOnHome: {
        //     type: Boolean,
        //     default: false
        // },
        // promoWeight: Boolean,
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
                    // {end: 640, size: 1.2},
                    {start: 0, end: 620, size: 1},
                    {start: 620, end: 899, size: 2},
                    {start: 900, size: 4},
                    // {start: 1950, end: 2249, size: 5},
                    // {start: 2250, size: 6},
                    // {size: 4}
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
            Feed.api().getSessions({
                // show_on_home: (this.onlyShowOnHome ? true : null),
                // hide_on_home: (this.hideOnHome ? false : null),
                limit: this.itemsCount || 12,
                order_by: "start_at",
                order: this.order,
                // searchable_type: "Session",
                // promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.videos.sessions = []
                this.loading = true
                this.videos.sessions = this.videos.sessions.concat(res.response.data.response.map(e => {
                    // e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    // return Object.assign(e.searchable_model, e.document)
                    e.session.presenter_user = e.presenter
                    e.session.url_params = e.room
                    e.session.organization = e.organization
                    e.session.small_cover_url = e.session.small_cover_url || "/assets/channels/default_cover-238a756a6c5900804711f3881eb627eb308b79d96e1bdf273597da62faab8a25.jpg"

                    return e.session
                }))
                // this.$eventHub.$emit('home-page:scroll__live', (this.videos.sessions.length))
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        }
    }
}
</script>
