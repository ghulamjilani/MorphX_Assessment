<template>
    <m-modal
        ref="modal"
        :confirm="waitingFiles.length !== 0 || uploadingFiles.length !== 0"
        text-confirm="Not uploaded files will be cancelled. Are you sure?"
        @modalClosed="modalClosed">
        <template #header>
            <h3 class="title">{{ $t('frontend.app.components.documents.uploader.upload_documents') }}</h3>
        </template>
        <template #default>
            <div class="DocumentsUploader">
                <input
                    id="file_input"
                    ref="fileInput"
                    type="file"
                    name="file_input"
                    :accept="acceptFileTypes"
                    :multiple="multiple"
                    @change="handleFilesSelection">
                <div
                    class="drop-area"
                    :class="{dragover: dragover}"
                    @drop.prevent="handleFilesSelection($event)"
                    @dragleave="dragover = false"
                    @dragenter.prevent="dragover = false"
                    @dragover.prevent="dragover = true">
                    <div class="dotsWrapp">
                        <div class="dot1" />
                        <div class="dot2" />
                        <div class="dot3" />
                        <div class="dot4" />
                        <div class="dot5" />
                        <div class="dot6" />
                        <div class="dot7" />
                        <div class="dot8" />
                    </div>
                    <span>
                        <label for="file_input">{{ $t('frontend.app.components.documents.uploader.select_file') }}</label>
                        <div>{{ $t('frontend.app.components.documents.uploader.or_drop_file') }}</div>
                    </span>
                    <i class="GlobalIcon-upload upload-icon" />
                </div>
                <div class="restrictions">
                    <div>
                        {{ $t('frontend.app.components.documents.uploader.supported_file_formats') }}:
                        <i>{{ acceptedFilesExtensions.map(el => '.' + el).join(', ') }}</i>
                    </div>
                    <div>
                        {{ $t('frontend.app.components.documents.uploader.max_files') }}: <i>{{ maxFileNumber }}</i>
                        <br>
                        {{ $t('frontend.app.components.documents.uploader.max_size') }}: <i>{{ maxFileSize }} MB</i>
                    </div>
                </div>
                <documents-uploader-item
                    v-for="fileInfo in selectedFiles"
                    :key="fileInfo.id"
                    :file-info="fileInfo"
                    @remove-document="deleteUpload" />
            </div>
        </template>
    </m-modal>
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import DocumentsUploaderItem from '@components/documents/UploaderItem'
import Document from "@models/Document"
import {DirectUpload} from "activestorage"
import mime from "mime"

export default {
    name: 'DocumentsUploader',
    components: {DocumentsUploaderItem},
    props: {
        channelId: {
            type: Number,
            required: true
        },
        acceptedFilesExtensions: {
            type: Array,
            default: () => ['*']
        },
        maxFileNumber: {
            type: Number,
            default: 10
        },
        maxFileSize: {
            type: Number,
            default: 100 // MB
        },
        multiple: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            dragover: false,
            uploadUrl: '/api/v1/user/active_storage/direct_uploads',
            selectedFiles: {},
            maxSizeOfUploadingFilesStream: 100,
            exts: {'.indd': 'application/x-indesign', '*': '*/*'}
        }
    },
    computed: {
        acceptFileTypes() {
            const arr_types = this.acceptedFilesExtensions.map(ext =>
                [ext, mime.getType(ext), this.exts[ext]].flat()
            ).flat().filter(t => t)
            return [...new Set(arr_types)].join(',') || '*/*'
        },
        waitingFiles() {
            return Object.values(this.selectedFiles).filter((fileInfo) => !fileInfo.error && fileInfo.status === 'waiting')
        },
        uploadingFiles() {
            return Object.values(this.selectedFiles).filter((fileInfo) => fileInfo.status === 'uploading')
        }
    },
    watch: {
        selectedFiles: {
            handler: function(){
                if (this.waitingFiles.length > 0 && this.uploadingFiles.length < this.maxSizeOfUploadingFilesStream){
                    this.handleFile(this.waitingFiles[0].id)
                }
            },
            deep: true
        }
    },
    methods: {
        open() {
            this.selectedFiles = {}
            this.$refs.modal.openModal()
        },
        close() {
            alert('close')
        },
        handleFilesSelection(e) {
            this.dragover = false
            let files = e.dataTransfer ? e.dataTransfer.files : e.target.files
            let timestamp = Date.now()
            for (let i = 0; i < files.length; i++) {
                let file = files[i]
                const fileInfo = {
                    id: `${timestamp}_${i}`,
                    file: file,
                    name: file.name,
                    file_size: file.size,
                    progress: 0,
                    status: 'waiting',
                    error: this.validate(file)
                }
                Vue.set(this.selectedFiles, fileInfo.id, fileInfo)
            }
            this.$refs['fileInput'].value = ''
        },
        async handleFile(id) {
            let fileInfo = this.selectedFiles[id]
            fileInfo.status = 'uploading'
            const blob = await this.upload(fileInfo)
            Document.api().create({
                file: blob.signed_id,
                channel_id: this.channelId,
                hidden: true
            }).then(r => {
                Vue.set(this.selectedFiles, fileInfo.id, {...fileInfo, status: 'done', document_id: r.response.data.response.id})
                this.$eventHub.$emit('documentCountUpdate')
            }).catch(error => {
                Vue.set(this.selectedFiles, fileInfo.id, {...fileInfo, status: 'done', error: error.response.data.message})
                this.$flash(fileInfo.error)
            })
        },
        validate(file) {
            let error = null
            if (!this.isAllowedFile(file.type)) {
                error = this.$t('frontend.app.components.documents.uploader.file_format_not_supported')
            } else if (file.size > this.maxFileSize * 1024 * 1024) { //mb
                error = this.$t('frontend.app.components.documents.uploader.file_too_large')
            }
            if (error) {
                this.$flash(error, "warning", 2000)
            }
            return error
        },
        isAllowedFile(type) {
            return this.acceptedFilesExtensions.includes('*') ||
                this.acceptedFilesExtensions.includes(mime.getExtension(type))
        },
        async upload(fileInfo) {
            return new Promise((resolve, reject) => {
                const upload = new DirectUpload(fileInfo.file, this.uploadUrl, {
                    directUploadWillStoreFileWithXHR: (request) => {
                        request.upload.addEventListener("progress", event => {
                            Vue.set(this.selectedFiles, fileInfo.id, {...fileInfo, progress: parseInt(Math.round((event.loaded / event.total) * 100))})
                        })
                    }
                })
                upload.create((error, blob) => {
                    if (error) return reject(error)
                    resolve(blob)
                })
            })
        },
        async deleteUpload(fileInfo) {
            if (!fileInfo.error) {
                await Document.api().remove({id: fileInfo.document_id})
                this.$eventHub.$emit('documentCountUpdate')
            }
            this.$flash('Document has been removed', 'success')
            Vue.delete(this.selectedFiles, fileInfo.id)
        },
        modalClosed() {
            this.selectedFiles = {}
        }
    }
}
</script>