<template>
    <div
        class="documentThumbnail"
        @click="$emit('openDocumentPreviewModal')">
        <img
            v-if="document.lg_preview_path"
            :src="document.lg_preview_path">
        <div
            v-if="document.file_extension"
            :class="['ext', document.file_extension]">
            {{ document.file_extension }}
        </div>
    </div>
</template>

<script>
export default {
    name: 'DocumentThumbnail',
    props: {
        document: {
            type: Object,
            default: () => {}
        }
    }
}
</script>
