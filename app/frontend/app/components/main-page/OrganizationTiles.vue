<template>
    <div>
        <div
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container organizationTiles">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ useStandartTitle ? $t('home_page.titles.organizations') : title }}
                </h3>
                <a
                    v-if="showSeeMore"
                    class="homePage__title__more"
                    href="/organizations">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div
                v-if="isScrollable"
                class="TileSlider__Wrapper">
                <div
                    v-if="loading"
                    class="TileSlider">
                    <vue-horizontal-list
                        id="horScroll"
                        :items="organizations"
                        :options="options">
                        <template #default="{item}">
                            <organization-tile
                                :organization="item"
                                :use-promo-weight="promoWeight" />
                        </template>
                    </vue-horizontal-list>
                </div>
            </div>

            <div
                v-if="!isScrollable"
                class="TileSlider__Wrapper">
                <div
                    v-if="loading"
                    class="RUWS__container">
                    <organization-tile
                        v-for="item in organizations"
                        :key="item.id"
                        :organization="item"
                        :use-promo-weight="promoWeight" />
                </div>
                <div
                    v-else
                    class="RUWS__container">
                    <tile-placeholder class="OrganizationTile" />
                    <tile-placeholder class="OrganizationTile" />
                    <tile-placeholder class="OrganizationTile" />
                    <tile-placeholder class="OrganizationTile" />
                </div>
                <m-btn
                    v-if="showMore && organizations.length < count"
                    :loading="showMoreLoading"
                    class="comments__showMore"
                    type="secondary"
                    @click="LoadOrganizations">
                    Show more
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
import VueHorizontalList from 'vue-horizontal-list'
import TilePlaceholder from "@components/TilePlaceholder"
import OrganizationTile from "@components/tiles/OrganizationTile"
import Organization from "@models/Organization"

export default{
  components: {TilePlaceholder, OrganizationTile, VueHorizontalList},
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
    itemsCount: Number,
    orderBy: String,
    order: String,
    showMore: {
        type: Boolean,
        default: false
    },
    loadCount: {
        type: Number,
        default: 8
    },
    isScrollable: {
        type: Boolean,
        default: true
    }
  },
  data() {
    return {
      organizations: [],
      loading: false,
      count: 0,
      showMoreLoading: false,
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
  computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    },
    showSeeMore() {
        return this.$route.name == "MainPage"
    }
  },
  mounted() {
    this.LoadOrganizations()
  },
  methods: {
    LoadOrganizations() {
      this.showMoreLoading = true
      Organization.api().getOrganizations({
          show_on_home: (this.onlyShowOnHome ? true : null),
          hide_on_home: (this.hideOnHome ? false : null),
          limit: this.isScrollable ? this.itemsCount || 12 : this.loadCount,
          offset: this.organizations.length,
          order_by: this.orderBy ? this.orderBy : "views_count",
          order: this.order ? this.order : "desc",
          promo_weight: (this.promoWeight ? '1' : '')
      }).then((res) => {
          this.count = res.response.data.pagination?.count
          this.organizations = this.organizations.concat(res.response.data.response.organizations.map(e => {
              let obj = e.organization
              obj.user = e.user
              return obj
          }))
          this.showMoreLoading = false
          this.loading = true
          this.$eventHub.$emit('home-page:scroll__organizations', (this.organizations.length))
          this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
      })
    }
  }
}
</script>
