<template>
    <div
        v-if="isPlatformOwner && isMainPage && !componentsBuilderActive"
        class="moderateTile"
        :class="{
            'top-right': true
        }">
        <div class="moderateTile__status">
            <div
                v-if="item && usePromoWeight"
                v-tooltip="'Promo Weight'"
                class="moderateTile__roundedBlock">
                PW {{ item.promo_weight || item.promo_weigh || 0 }}
            </div>
            <div
                v-if="hided"
                v-tooltip="'Hided on Home'"
                class="moderateTile__circleBlock">
                <m-icon
                    class="moderateTile__dropdown__icon">
                    GlobalIcon-eye-off
                </m-icon>
            </div>
        </div>
        <div class="moderateTile__block">
            <m-dropdown
                ref="moderateDropdown"
                class="moderateTile__dropdown">
                <m-option
                    v-if="!hided"
                    @click="hideOnHome(true)">
                    Hide on Home
                </m-option>
                <m-option
                    v-if="hided"
                    @click="hideOnHome(false)">
                    Return to Home
                </m-option>
                <m-option @click="openPromoWeight">
                    Change Promo Weight
                </m-option>
            </m-dropdown>
        </div>
    </div>
</template>

<script>
import PlatformOwner from "@models/PlatformOwner"

export default {
  props: [
    "item",
    "type",
    "usePromoWeight"
  ],
  data() {
    return {
      hided: false,
      componentsBuilderActive: false
    }
  },
  computed: {
    currentUser() {
      return this.$store.getters["Users/currentUser"]
    },
    isPlatformOwner() {
      return this.currentUser?.platform_role == 'platform_owner'
    },
    isMainPage() {
      return this.$route.name == 'MainPage'
    }
  },
  mounted() {
    this.$eventHub.$on("componentSettings:EditingChanged", flag => {
      this.componentsBuilderActive = flag
    })
  },
  methods: {
    hideOnHome(hide = true) {
      let id = this.item.id
      if(!id) {
        id = this.item.session?.id
      }
      PlatformOwner.api().hideOnHome({model_id: id, model_type: this.type, hide_on_home: hide}).then(res => {
        this.hided = !this.hided
        this.$refs.moderateDropdown.close()
      })
    },
    openPromoWeight() {
      this.$refs.moderateDropdown.close()
      this.$eventHub.$emit("open-modal:promo-weight", {item: this.item, model_type: this.type})
    }
  }
}
</script>

<style>

</style>