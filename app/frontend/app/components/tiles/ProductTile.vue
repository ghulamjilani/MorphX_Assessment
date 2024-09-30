<template>
    <div class="productTile">
        <img
            class="productTile__image"
            :src="product.image_url"
            @click="openProduct">
        <div class="productTile__content">
            <div
                class="productTile__title"
                @click="openProduct">
                <span>{{ product.title }}</span>
            </div>
            <div class="productTile__description">
                <span>{{ product.short_description }}</span>
            </div>
            <div class="productTile__button">
                <m-btn
                    :style="product.price_cents > 0 ? '' : 'visibility: hidden'"
                    type="secondary"
                    size="s"
                    :square="true"
                    @click="openProduct">
                    {{ price }}
                </m-btn>
            </div>
        </div>
        <moderate-tiles :item="product" />
    </div>
</template>

<script>
// import getSymbolFromCurrency from 'currency-symbol-map'

export default {
  props: {
    product: {
      type: Object,
      required: true
    }
  },
  data() {
    return {}
  },
  computed: {
    price() {
      if(this.product.price_cents == 0) return null

      // let sign = getSymbolFromCurrency(this.product.price_currency) || "$"
      let sign =  "$"
      return sign + (this.product.price_cents / 100).toFixed(2)
    }
  },
  methods: {
    openProduct() {
      this.goTo(this.product.url, true)
      // this.$router.push({
      //   name: 'product',
      //   params: {
      //     id: product.id,
      //     channel: this.currentChannelId
      //   }
      // })
    }
  }

}
</script>

<style>

</style>