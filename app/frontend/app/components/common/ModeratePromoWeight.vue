<template>
    <div class="moderatePromoWeight">
        <m-modal ref="mpwModal">
            <div class="moderatePromoWeight__modal">
                <div class="moderatePromoWeight__modal__title">
                    Change Promo Weight
                </div>
                <div class="moderatePromoWeight__modal__body">
                    <div class="moderatePromoWeight__modal__body__input">
                        <m-input
                            v-model="promoWeight"
                            type="number"
                            :min="-100"
                            :max="100"
                            step="1"
                            :number="true"
                            placeholder="0"
                            class="moderatePromoWeight__modal__body__input__field" />
                    </div>
                    <div class="moderatePromoWeight__modal__body__slider">
                        <vue-slider
                            v-model="promoWeight"
                            :min="-100"
                            :max="100"
                            :step="1"/>
                    </div>
                    <p>
                        Promo weight 100 will be first, -100 last
                    </p>
                </div>
                <div class="moderatePromoWeight__modal__footer">
                    <m-btn
                        class="moderatePromoWeight__modal__footer__btn"
                        size="s"
                        @click="savePromoWeight">
                        Save
                    </m-btn>
                </div>
            </div>
        </m-modal>
    </div>
</template>

<script>
import VueSlider from 'vue-slider-component'
import PlatformOwner from "@models/PlatformOwner"

export default {
  components: {VueSlider},
  data() {
    return {
      item: null,
      type: "",
      promoWeight: 0
    }
  },
  mounted() {
    this.$eventHub.$on("open-modal:promo-weight", this.openModal)
  },
  methods: {
    openModal(data) {
      this.item = data.item
      this.type = data.model_type
      this.promoWeight = data.item.promo_weight || data.item.promo_weigh || 0
      this.$refs.mpwModal.openModal()
    },
    closeModal() {
      this.$refs.mpwModal.closeModal()
    },
    savePromoWeight() {
      let id = this.item.id
      if(!id) {
        id = this.item.session?.id
      }
      PlatformOwner.api().setPromoWeight({
          model_id: id,
          model_type: this.type,
          promo_weight: this.promoWeight
        }).then(res => {
          this.item.promo_weight = this.promoWeight
        this.$refs.mpwModal.closeModal()
      })
    }
  }
}
</script>

<style>

</style>