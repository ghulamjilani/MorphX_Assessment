<template>
    <m-dropdown close-by-self-click>
        <m-option
            @click="downloadDocument">
            Download
        </m-option>
        <m-option>
            <m-confirm
                v-bind="confirmContent"
                @onConfirm="removeDocument">
                Delete
            </m-confirm>
        </m-option>
    </m-dropdown>
</template>

<script>
import Document from "@models/Document"

export default {
    name: 'DocumentsOptionsDropdown',
    props: {
        document: {
            type: Object,
            default: () => {},
            required: true
        }
    },
    computed: {
        confirmContent() {
            return {title: 'Remove File', body: `Are you sure you want to remove "${this.document.filename}" document?`}
        }
    },
    methods: {
        async removeDocument() {
            await Document.api().remove(this.document)
            this.$eventHub.$emit('documentCountUpdate')
            this.$flash('Document has been removed', 'success')
        },
        async copyDocumentLink() {
            await navigator.clipboard.writeText(this.document.download_url)
            this.$flash('Copied', 'success')
        },
        downloadDocument() {
            window.open(this.document.downloadUrl, '_blank')
        }
    }
}
</script>