<template>
    <div>
        <div
            v-if="models.length || !loading || dontHide"
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ title }}
                </h3>
            </div>
            <div
                v-if="loading && models.length"
                class="RUWS__container">
                <m-card
                    v-for="item in models"
                    :key="item.id">
                    <template #top>
                        <session-top
                            :video="item"
                            type="Session"
                            :use-promo-weight="false" />
                    </template>
                    <template #bottom>
                        <session-bottom
                            :show-organization="true"
                            :video="item" />
                    </template>
                </m-card>
            </div>
            <div
                v-if="!loading || (dontHide && !models.length)"
                class="TileSlider__Wrapper">
                <div
                    class="mChannel__tiles__list">
                    <div class="mChannel__tiles__items placeholder">
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                    </div>
                </div>
            </div>
            <m-btn
                v-if="showMore && models.length < count"
                :loading="loader"
                class="comments__showMore"
                type="secondary"
                @click="infiniteHandler">
                Show more
            </m-btn>
            <infinite-loading
                v-if="infinity"
                ref="InfiniteLoading"
                spinner="waveDots"
                @infinite="infiniteHandler">
                <div slot="no-more" />
                <div
                    slot="no-results"
                    class="history__body__no-results" />
            </infinite-loading>
        </div>
    </div>
</template>

<script>
import SessionBottom from '@components/card-templates/SessionBottom.vue'
import SessionTop from '@components/card-templates/SessionTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Feed from "@models/Feed"
import InfiniteLoading from "vue-infinite-loading"

export default {
    components: {SessionBottom, SessionTop, TilePlaceholder, InfiniteLoading},
    props: {
        dontHide: {
            type: Boolean,
            default: false
        },
        infinity: {
            type: Boolean,
            default: false
        },
        orderBy: String,
        title: String,
        showMore: {
            type: Boolean,
            default: false
        },
        loadCount: {
            type: Number,
            default: 8
        },
        // onlyShowOnHome: Boolean,
        // hideOnHome: {
        //     type: Boolean,
        //     default: false
        // },
        // promoWeight: Boolean,
        order: String
    },
    data() {
        return {
            models: [],
            loading: false,
            loader: false,
            count: 0
        }
    },
    watch: {
        loadCount() {
            this.loading = false
            this.models = []
            this.loadModels()
        },
        orderBy() {
            this.loading = false
            this.models = []
            this.loadModels()
        }
    },
    mounted() {
        this.loadModels()
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
        loadModels($state = null) {
            this.loader = true
            Feed.api().getSessions({
                limit: this.loadCount,
                offset: this.models.length,
                order_by: this.orderBy,
                order: this.order,
                // searchable_type: "Video",
                // show_on_home: (this.onlyShowOnHome ? true : null),
                // hide_on_home: (this.hideOnHome ? false : null),
                // promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.count = res.response.data.pagination?.count
                this.loading = true
                this.loader = false
                this.models = this.models.concat(res.response.data.response.map(e => {
                    e.presenter_user = e.presenter
                    e.url_params = e.room
                    // e.organization = e.organization
                    e.small_cover_url = e.session.small_cover_url || "/assets/channels/default_cover-238a756a6c5900804711f3881eb627eb308b79d96e1bdf273597da62faab8a25.jpg"
                    e.type = "Session"
                    // e.searchable_model.total_views_count = e.document.views_count
                    // return Object.assign(e.searchable_model, e.document)
                    return e
                }))
                if (this.infinity && $state) {
                    if (this.models.length >= res.response.data.pagination?.count || res.response.data.response.documents.length === 0) {
                        $state.complete()
                    } else {
                        $state.loaded()
                    }
                }
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        },
        infiniteHandler($state) {
            this.loadModels($state)
        }
    }
}
</script>
