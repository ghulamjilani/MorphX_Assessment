<template>
    <div
        v-if="products.length"
        id="anchorSection__store"
        class="channelProducts">
        <div class="channelProducts__title">
            <div>
                <span>{{ $t('frontend.app.components.channel.products.title') }}</span>
            </div>
        </div>
        <div class="channelProducts__list">
            <product-tile
                v-for="product in paginatedProducts"
                :key="product.id"
                :product="product" />
        </div>
        <div class="text__center">
            <m-btn
                v-if="pagination.count > pagination.offset"
                class="channelProducts__showMore"
                type="secondary"
                :loading="showMoreLoading"
                @click="showMore">
                {{ $t('channel_page.show_more') }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import ProductTile from "@components/tiles/ProductTile"
import Products from "@models/Products"

export default {
  components: {
    ProductTile
  },
  props: {
    channel: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      pagination: {
        offset: 0,
        limit: 10,
        count: -1
      },
      showMoreLoading: false,
      products: []
    }
  },
  computed: {
    paginatedProducts() {
      return this.products.slice(0, this.pagination.offset)
    }
  },
  watch: {
    channel() {
      this.pagination.offset = 0
      this.products = []
      this.fetch()
    }
  },
  mounted() {
    this.pagination.offset = 0
    this.products = []
    this.fetch()
  },
  methods: {
    showMore() {
      this.showMoreLoading = true
      console.log("show more")
      this.pagination.offset += this.pagination.limit
    },
    fetch() {
      Products.api().fetchLists({
        model_id: this.channel.id,
        model_type: "Channel"
      }).then(res => {
        this.products = res.response.data.response.lists.map(l => l.products.map(p => p.product)).flat()
        // this.products = this.products.concat(res.response.data.response.products.map(p=>p.product))
        this.pagination.count = this.products.length
        this.pagination.offset += this.pagination.limit
        this.$eventHub.$emit("channel-navlinks", {name: 'store', value: this.products.length > 0})
      }).catch(err => {
        this.$eventHub.$emit("channel-navlinks", {name: 'store', value: false})
        console.log(err)
      }).finally(() => {
        this.showMoreLoading = false
      })
    }
  }
}
</script>

<style>

</style>