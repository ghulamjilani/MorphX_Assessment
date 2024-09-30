<template>
    <div class="componentsBuilder">
        <h3>{{ $t("frontend.app.pages.components_builder.components_manager") }}</h3>
        <view-modal />

        <div class="componentsBuilder__list">
            <div
                v-for="item in listOfComponents"
                :key="item.groupName"
                class="componentsBuilder__listItem"
                @click="openManager(item)">
                {{ item.title }}
            </div>
        </div>
    </div>
</template>

<script>
import ViewModal from '@components/components_builder/ViewModal.vue'
export default {
  components: { ViewModal },
  data() {
    return {
      listOfComponents: [
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.test"),
          groupName: "test-modal"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.homepage"),
          groupName: "homepage"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.feed"),
          groupName: "my_feed"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.organizationpage"),
          groupName: "organizationsage"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.terms"),
          groupName: "terms-of-use"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.privacy_policy"),
          groupName: "privacy-policy"
        },
        {
          title: this.$t("frontend.app.pages.components_builder.tiles.sandbox"),
          groupName: "sandbox"
        }
      ]
    }
  },
  methods: {
    openManager(item) {
      this.$eventHub.$emit("open-modal:cb_viewmodal", item)
    }
  }
}
</script>

<style>

</style>