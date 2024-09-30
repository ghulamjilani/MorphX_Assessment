<template>
    <div>
        <div
            v-if="articles.length || loading || dontHide"
            :id="title ? title.toLowerCase().replace(/ /g, '_') : 'blog'"
            class="container organizationTiles">
            <div
                v-if="!channelId"
                class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ channelId ? $t('frontend.app.components.channel.blog.community') : title }}
                </h3>
                <a
                    class="homePage__title__more"
                    href="/search?ford=views_count&ft=Blog::Post">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div class="TileSlider__Wrapper">
                <div
                    v-if="!loading"
                    class="TileSlider">
                    <vue-horizontal-list
                        id="horScroll"
                        :items="articles"
                        :options="options">
                        <template #default="{item}">
                            <article-tile
                                :article="item"
                                :use-promo-weight="promoWeight" />
                        </template>
                    </vue-horizontal-list>
                </div>
                <div v-if="loading || (dontHide && !articles.length)">
                    <!-- Placeholder -->
                    <div class="mChannel__tiles__list">
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
    </div>
</template>

<script>
import ArticleTile from '@components/tiles/ArticleTile.vue'
import Search from "@models/Search"

import VueHorizontalList from 'vue-horizontal-list'
import TilePlaceholder from "@components/TilePlaceholder"

export default {
    components: {
    ArticleTile,
    VueHorizontalList,
    TilePlaceholder
  },
  props: {
    channelId: Number,
    orderBy: String,
    title: String,
    onlyShowOnHome: Boolean,
        hideOnHome: {
            type: Boolean,
            default: false
        },
    promoWeight: Boolean,
    order: String,
    dontHide: {
        type: Boolean,
        default: false
    },
    itemsCount: Number
  },

  data() {
    return {
      articles: [],
      loading: false,
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
  watch: {
      orderBy() {
          this.reload()
      },
      onlyShowOnHome() {
        this.reload()
      },
      order() {
        this.reload()
      },
      promoWeight() {
        this.reload()
      }
  },
  mounted() {
      this.loadArticles()
  },
    methods: {
      reload() {
          this.loading = true
          this.articles = []
          this.loadArticles()
      },
      loadArticles() {
            this.loading = true
            let options = {}

            if(this.channelId) {
                options = {
                    channel_id: this.channelId,
                    order_by: "views_count",
                    order: "desc",
                    limit: 12,
                    searchable_type: "Blog::Post"
                }
            }
            else {
                options = {
                    limit: this.itemsCount || 12,
                    offset: this.articles.length,
                    order_by: this.orderBy,
                    order: this.order,
                    searchable_type: "Blog::Post",
                    show_on_home: (this.onlyShowOnHome ? true : null),
                    hide_on_home: (this.hideOnHome ? false : null),
                    promo_weight: (this.promoWeight ? '1' : null)
                }
            }

            Search.api().searchApi(options).then((res) => {
                this.articles = res.response.data.response.documents.map(e => {
                    return Object.assign(e.searchable_model.post, e.document)
                })
                this.loading = false
                this.$eventHub.$emit('home-page:scroll__articles', (this.articles.length))
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        }
    }
}
</script>

<style>

</style>