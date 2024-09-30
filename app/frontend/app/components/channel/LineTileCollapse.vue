<template>
    <div
        class="ChannelDocuments"
        :class="(isConsumer ? 'consumer' : 'dashboard') + '_view'">
        <channel-line-tile
            v-if="!isConsumer"
            :channel="channel"
            :is-opened="isOpened"
            @documentsUploader="$refs.documentsUploader.open()"
            @showDocuments="showChanelDocuments()" />
        <div
            v-if="isOpened"
            @click.stop.prevent>
            <documents-cards-collection
                :channel="channel"
                :loadIterationLimit="20"
                mode="dashboard"
                :can-manage-documents="channel.can_manage_documents" />
        </div>
        <documents-uploader
            ref="documentsUploader"
            :channel-id="channel.id"
            multiple
            :accepted-files-extensions="acceptedFilesExtensions"
            :max-file-number="maxFileNumber"
            :max-file-size="maxFileSize" />
    </div>
</template>

<script>
import ChannelLineTile from './LineTile'
import DocumentsCardsCollection from "../documents/CardsCollection"
import DocumentsUploader from '../documents/Uploader'

// TODO: collapse content should be slot
export default {
    name: 'ChannelLineTileCollapse',
    components: {DocumentsCardsCollection, ChannelLineTile, DocumentsUploader},
    props: {
        channel: {type: Object},
        isConsumer: {type: Boolean, default: false}
    },
    data() {
        return {
            isOpened: this.isConsumer,
            acceptedFilesExtensions: ['pdf'],
            maxFileNumber: 10,
            maxFileSize: 100,
        }
    },
    methods: {
        showChanelDocuments() {
            this.isOpened = !this.isOpened
        }
    }
}
</script>