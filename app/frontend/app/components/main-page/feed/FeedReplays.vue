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
                        <replay-top
                            type="Video"
                            :video="item" />
                    </template>
                    <template #bottom>
                        <replay-bottom
                            :home-page="true"
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
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Feed from "@models/Feed"
import InfiniteLoading from "vue-infinite-loading"

export default {
    components: {ReplayBottom, ReplayTop, TilePlaceholder, InfiniteLoading},
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
    methods: {
        loadModels($state = null) {
            this.loader = true
            Feed.api().getReplays({
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
                    e.abstract_session = e.session
                    e.type = "Video"
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
