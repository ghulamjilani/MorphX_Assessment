<template>
    <div
        :class="['DocumentsUploaderItem',{'done': isDone}]">
        <div
            class="DocumentsUploaderItem_progress"
            :style="{ width: [isDone ? 100 : progress || 0] + '%' }" />
        <div
            class="DocumentsUploaderItem_wrap">
            <div
                v-if="filetype"
                :class="['ext', filetype]">
                {{ filetype }}
            </div>
            <div class="title">
                {{ filename }} - <i class="size">({{ fileSize }})</i>
            </div>
            <div class="row-wrap">
                <div
                    v-if="isError"
                    class="error-msg">
                    <i class="GlobalIcon-Warning" />
                    {{ isError }}
                </div>
                <div
                    v-else
                    class="percent">
                    {{ isDone ? 100 : progress || 0 }}%
                </div>
            </div>
            <m-confirm
                v-if="isDone"
                class="GlobalIcon-trash"
                v-bind="confirmContent"
                @onConfirm="removeDocument">
            </m-confirm>
            <i
                v-else
                class="confirm GlobalIcon-trash">
            </i>
        </div>
    </div>
</template>

<script>
import utils_h from '@utils/helper'

export default {
    props: {
        fileInfo: {
            type: Object,
            required: true
        }
    },
    computed: {
        filename() {
            return this.fileInfo.title || this.fileInfo.name || this.fileInfo.file_path?.split('/')?.pop()
        },
        filetype() {
            return this.filename?.slice(this.filename.lastIndexOf(".")+1);
        },
        fileSize() {
            return utils_h.formatBytes(this.fileInfo.file_size, 0)
        },
        progress() {
            return this.fileInfo.progress
        },
        isDone() {
            return !!this.fileInfo.document_id
        },
        isError() {
            return this.fileInfo.error
        },
        confirmContent() {
            return {title: 'Remove File', body: `Are you sure you want to remove "${this.filename}" document?`}
        }
    },
    methods: {
        removeDocument() {
            this.$emit('remove-document', this.fileInfo)
        }
    }
}
</script>
