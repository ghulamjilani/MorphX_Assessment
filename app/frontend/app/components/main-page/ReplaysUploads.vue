<template>
    <div>
        <div
            v-if="videos.videos.length || !loading"
            class="container">
            <div class="homePage__title__wrapper">
                <h3
                    :id="replays ? 'replays' : 'uploads'"
                    class="homePage__title">
                    {{ replays ? $t('home_page.titles.replays') : $t('home_page.titles.uploads') }}
                </h3>
                <a
                    class="homePage__title__more"
                    href="/search?ford=views_count&ft=Video">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div class="TileSlider__Wrapper">
                <div
                    v-if="loading"
                    class="TileSlider TileSlider__arrow">
                    <vue-horizontal-list
                        id="horScroll"
                        :items="videos.videos"
                        :options="options">
                        <template #default="{item}">
                            <m-card>
                                <template #top v-if="item.type == 'video'">
                                    <replay-top
                                        :video="item" />
                                </template>
                                <template #top v-else-if="item.type == 'recording'">
                                    <recording-top
                                        :video="item" />
                                </template>
                                <template #bottom v-if="item.type == 'video'">
                                    <replay-bottom
                                        :home-page="true"
                                        :video="item"
                                        :use-promo-weight="promoWeight" />
                                </template>
                                <template #bottom v-else-if="item.type == 'recording'">
                                    <recording-bottom
                                        :home-page="true"
                                        :video="item"
                                        :use-promo-weight="promoWeight" />
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
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Search from "@models/Search"
import VueHorizontalList from 'vue-horizontal-list'

export default {
    components: {ReplayBottom, ReplayTop, RecordingBottom, RecordingTop, TilePlaceholder, VueHorizontalList},
    props: {
        replays: Boolean
    },
    data() {
        return {
            videos: {
                videos: []
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
        this.loadVideos()
        window.carousel = this.$refs.carousel
    },
    methods: {
        loadVideos() {
            Search.api().searchApi({
                show_on_home: true,
                limit: 10,
                order_by: "listed_at",
                order: "desc",
                searchable_type: this.replays ? "Video" : "Recording"
            }).then((res) => {
                this.loading = true
                this.videos.videos = this.videos.videos.concat(res.response.data.response.documents?.map(e => {
                    e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    return e.searchable_model
                }))
                if (this.replays) {
                    this.$eventHub.$emit('home-page:scroll__replays', (this.videos.videos.length))
                } else {
                    this.$eventHub.$emit('home-page:scroll__uploads', (this.videos.videos.length))
                }
            })
        }
    }
}
</script>
