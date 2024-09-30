<template>
    <div>
        <div
            v-if="videos.videos.length || !loading"
            :id="useStandartTitle ? 'discover' : title.toLowerCase().replace(/ /g, '_')"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ useStandartTitle ? $t(`home_page.titles.discover`) : title }}
                </h3>
                <a
                    :href="'/search?ford=' + (orderBy == 'listed_at' ? 'new' : 'views_count')"
                    class="homePage__title__more">{{
                        $t('home_page.titles.see_more')
                    }}</a>
            </div>
            <div
                v-if="loading"
                class="RUWS__container">
                <m-card
                    v-for="item in videos.videos"
                    :key="item.id">
                    <template #top v-if="item.type == 'video'">
                        <replay-top
                            :video="item"
                            :use-promo-weight="promoWeight" />
                    </template>
                    <template #top v-else-if="item.type == 'recording'">
                        <recording-top
                            :video="item"
                            :use-promo-weight="promoWeight" />
                    </template>
                    <template #bottom v-if="item.type == 'video'">
                        <replay-bottom
                            :home-page="true"
                            :video="item" />
                    </template>
                    <template #bottom v-else-if="item.type == 'recording'">
                        <recording-bottom
                            :home-page="true"
                            :video="item" />
                    </template>
                </m-card>
            </div>
            <div
                v-else
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
                v-if="showMore && videos.videos.length < count"
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
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Search from "@models/Search"
import InfiniteLoading from "vue-infinite-loading"

export default {
    components: {ReplayBottom, ReplayTop, RecordingBottom, RecordingTop, TilePlaceholder, InfiniteLoading},
    props: {
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
        order: String
    },
    data() {
        return {
            videos: {
                videos: []
            },
            loading: false,
            loader: false,
            count: 0
        }
    },
    watch: {
        loadCount() {
            this.loading = false
            this.videos.videos = []
            this.loadVideos()
        },
        orderBy() {
            this.loading = false
            this.videos.videos = []
            this.loadVideos()
        }
    },
    mounted() {
        this.loadVideos()
    },
    methods: {
        loadVideos($state = null) {
            this.loader = true
            Search.api().searchApi({
                limit: this.loadCount,
                offset: this.videos.videos.length,
                order_by: this.orderBy,
                order: this.order,
                searchable_type: "Video,Recording",
                show_on_home: (this.onlyShowOnHome ? true : null),
                hide_on_home: (this.hideOnHome ? false : null),
                promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.count = res.response.data.pagination?.count
                this.loading = true
                this.loader = false
                this.videos.videos = this.videos.videos.concat(res.response.data.response.documents.map(e => {
                    e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    e.searchable_model.total_views_count = e.document.views_count
                    return Object.assign(e.searchable_model, e.document)
                }))
                if (this.infinity && $state) {
                    if (this.videos.videos.length >= res.response.data.pagination?.count || res.response.data.response.documents.length === 0) {
                        $state.complete()
                    } else {
                        $state.loaded()
                    }
                }
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        },
        infiniteHandler($state) {
            this.loadVideos($state)
        }
    }
}
</script>
