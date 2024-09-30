 ### Example

Empty modal
```vue
<template>
  <div class="demo">
    <m-btn @click="open">Open modal</m-btn>
    <m-modal ref="demoModal">
      Your modal
    </m-modal>
  </div>
</template>

<script>
export default {
  methods: {
    open(){
      this.$refs.demoModal.openModal()
    },
    close(){
      this.$refs.demoModal.closeModal()
    }
  }
}
</script>
```