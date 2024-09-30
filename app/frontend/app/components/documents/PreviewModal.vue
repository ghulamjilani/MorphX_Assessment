<template>
    <m-modal
        ref="originModal"
        class="DocumentsPreviewModal"
        @modalClosed="$emit('modalClosed')">
        <div class="DocumentsPreviewModal__preview">
            <document-preview :document="document" />
        </div>
        <div class="DocumentsPreviewModal__description">
            <h3>{{ $t('frontend.app.components.documents.preview_modal.description') }}:</h3>
            {{ document.description }}
        </div>
    </m-modal>
</template>

<script>
import Document from '../../store/models/Document'
import DocumentPreview from './Preview'
import MModal from '../../uikit/MModal'

export default {
    name: 'DocumentsPreviewModal',
    components: {DocumentPreview, MModal},
    props: {
        documentId: {
            type: [String, Number],
            default: null
        },
        document: {
            type: Object,
            default: null
        }
    },
    async mounted() {
        try {
            if (!this.document && this.documentId) {
                await Document.api().fetchOne({id: this.documentId})
                // await Channel.api().getPublicChannel({id: this.document.channel_id})
            }
        } finally {
            this.$refs.originModal.openModal()
        }
    }
}
</script>
