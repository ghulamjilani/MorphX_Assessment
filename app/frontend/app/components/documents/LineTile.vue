<template>
    <div
        class="DocumentsLineTile"
        :class="[{mark_hidden: document.hidden}, (isConsumer ? 'consumer' : 'dashboard') + '_view']">
        <img
            v-if="document.lg_preview_path"
            :src="document.lg_preview_path">
        <div
            v-else
            class="preview"
            v-text="document.fileExt" />
        <div class="content">
            <div
                class="title"
                v-text="document.filename" />
            <div
                class="description"
                v-text="document.description" />
            <div class="bottom">
                <div>
                    <i class="GlobalIcon-disc-space" />
                    {{ document.formattedFileSize }}
                </div>
                <div>
                    <i class="GlobalIcon-empty-calendar" />
                    {{ document.formattedCreatedAt }}
                </div>
            </div>
        </div>
        <div
            v-if="canManageDocuments"
            class="actions"
            @click.stop.prevent="">
            <i
                :class="'GlobalIcon-eye' + (document.hidden ? '-off' : '')"
                @click="toggleVisibility" />
            <m-dropdown>
                <m-option @click="modal = true">
                    Open
                </m-option>
                <m-option
                    @click="downloadDocument">
                    Download
                </m-option>
                <m-option
                    @click="copyDocumentLink">
                    Copy link
                </m-option>
                <m-option
                    @click="openSettingsModal">
                    Settings
                </m-option>
                <m-option>
                    <m-confirm
                        v-bind="confirmContent"
                        @onConfirm="removeDocument">
                        Delete
                    </m-confirm>
                </m-option>
            </m-dropdown>
        </div>
        <documents-preview-modal
            v-if="modal"
            :document="document" />
    </div>
</template>

<script>
import Document from "@models/Document"
import DocumentsPreviewModal from './PreviewModal'

export default {
    name: 'DocumentsLineTile',
    components: {DocumentsPreviewModal},
    props: {
        document: {type: Object, required: true},
        isConsumer: {type: Boolean, default: false},
        canManageDocuments: {type: Boolean, default: false}
    },
    data() {
        return {
            modal: false
        }
    },
    computed: {
        confirmContent() {
            return {title: 'Remove File', body: `Are you sure you want to remove "${this.document.filename}" document?`}
        }
    },
    methods: {
        async toggleVisibility() {
            const params = {id: this.document.id, hidden: !this.document.hidden}
            await Document.api().update(params)
        },
        downloadDocument() {
            window.open(this.document.downloadUrl, '_blank')
        },
        async copyDocumentLink() {
            await navigator.clipboard.writeText(this.document.download_url)
            this.$flash('Copied', 'success')
        },
        async removeDocument() {
            await Document.api().remove(this.document)
            this.$flash('Document has been removed', 'success')
        },
        openSettingsModal() {
            this.$eventHub.$emit('open-modal', {
                title: 'Document Settings',
                component: {
                    name: 'DocumentsSettings',
                    params: {document_id: this.document.id}
                }
            })
        }
    }
}
</script>