<template>
    <div class="addComponent">
        <m-btn
            class="text__capitalize"
            size="m"
            @click="addRow">
            <m-icon
                size="1.8rem">
                GlobalIcon-plus-circle
            </m-icon>
            Add row
        </m-btn>
    </div>
</template>

<script>
export default {
  props: {
    group: String
  },
  data() {
    return {

    }
  },
  methods: {
    addRow() {
      this.$eventHub.$emit("open-modal:componentSettings", this.group, null)
    }
  }
}
</script>

<style>

</style>