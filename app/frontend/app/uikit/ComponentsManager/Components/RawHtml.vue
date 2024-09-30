<template>
    <div
        class="componentManager__rawHtml quill-text"
        :style="style">
        <div v-html="formattedRawHtml" />
    </div>
</template>

<script>
export default {
  props: {
    rawHtml: String,
    background: String
  },
  computed: {
    host() {
      return this.$railsConfig?.global?.host
    },
    formattedRawHtml() {
      return this.rawHtml.replace(/{host}/ig, this.host)
    },
    style() {
      return `background-color: ${this.background};`
    }
  }
}
</script>

<style>

</style>