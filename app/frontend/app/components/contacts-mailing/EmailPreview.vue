<template>
    <m-modal
        ref="emailPreview"
        class="CM__preview">
        <div v-html="preview" />
    </m-modal>
</template>

<script>
export default {
    props: {
        preview: String
    },
    methods: {
        openModal() {
            this.$refs.emailPreview.openModal()
        },
        closeModal() {
            this.$refs.emailPreview.closeModal()
        }
    }
}
</script>