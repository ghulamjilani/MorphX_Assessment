<template>
    <div class="pricing-page">
        <business-plans v-if="!isCustomPage" />
        <custom-pricing v-else />
    </div>
</template>

<script>
import BusinessPlans from './BusinessPlans.vue'
import CustomPricing from './CustomPricing.vue'

  export default {
    components: {
      BusinessPlans,
      CustomPricing
    },
    computed: {
      pricingConfig() {
        return this.$railsConfig.frontend?.pricing
      },
      isCustomPage() {
        return this.pricingConfig?.custom_page
      }
    }
  }
</script>