<template>
    <m-modal
        ref="viewmodal"
        class="componentsBuilder__viewModal"
        :backdrop="false"
        @modalClosed="modalClosed">
        <template #header>
            <div class="componentsBuilder__viewModal__header">
                <h3> {{ title }} </h3>
                Show <m-toggle v-model="editing" /> Edit
            </div>
        </template>
        <components-manager
            v-if="groupName"
            :editing-by-default="editing"
            :group="groupName" />
    </m-modal>
</template>

<script>
export default {
  data() {
    return {
      groupName: null,
      title: null,
      editing: true
    }
  },
  watch: {
    editing(val) {
      this.$eventHub.$emit("componentSettings:switchEditing", val)
    }
  },
  mounted() {
    this.$eventHub.$on("open-modal:cb_viewmodal", (data) => {
      this.groupName = data.groupName
      this.title = data.title
      this.open()
    })
  },
  methods: {
    open(){
      this.$refs.viewmodal.openModal()
    },
    close(){
      this.$refs.viewmodal.closeModal()
    },
    modalClosed() {
      this.groupName = null
      this.title = null
      this.editing = true
    }
  }
}
</script>

<style>

</style>