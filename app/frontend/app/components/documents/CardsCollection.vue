<template>
    <div class="DocumentsCardsCollection">
        <DocumentPayment />
        <m-loader
            v-if="documentLoading && mode === 'consumer'" />
        <div class="DocumentsCardsCollection__content"
            v-if="documentLoading && mode === 'dashboard'">
            <documents-placeholder
                v-for="index in 3" :key="index" />
        </div>
        <div class="DocumentsCardsCollection__content"
            v-else-if="!documentLoading && documents.length">
            <documents-card
                v-for="document in documents"
                :key="document.id"
                :document="document"
                :mode="mode"
                :isunite="isunite"
                :channel="channel"
                :can-manage-documents="canManageDocuments"
                class="DocumentsCardsCollection__content__item" />
        </div>
        <div
            v-if="documents.length < 1 && !documentLoading"
            class="DocumentsCardsCollection__NoDocuments">
            {{ $t('frontend.app.components.documents.cards_collection.have_not_documents_for_channel') }}
        </div>
        <div
            v-if="pagination && !pagination.areAllRecordsLoaded"
            class="DocumentsCardsCollection__pagination">
            <m-btn
                type="tetriary"
                :loading="loading"
                @click="loadDocumentsBunch">
                {{ $t('frontend.app.components.documents.cards_collection.show_more') }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import Document from "@models/Document"
import DocumentsPlaceholder from "./Placeholder"
import DocumentsCard from "./Card"
import Pagination from '@models/Pagination'
import DocumentPayment from '@components/documents/DocumentPayment.vue'

export default {
    name: 'DocumentsCardsCollection',
    components: {DocumentsPlaceholder, DocumentsCard, DocumentPayment},
    props: {
        paginationId: {
            type: String,
            default: ''
        },
        channel: {
            type: Object,
            default: () => {},
            required: true
        },
        mode: {
            type: String,
            default: 'consumer',
            validator: (value) => {
                return ['consumer', 'dashboard'].indexOf(value) !== -1
            }
        },
        canManageDocuments: {
            type: Boolean,
            default: false
        },
        loadIterationLimit: {
            type: Number,
            default: 5
        }
    },
    data() {
        return {
            documentLoading: true,
            innerPaginationId: null
        }
    },
    computed: {
        documents() {
            let documents = Document.query().where('channel_id', this.channel.id)
            if (this.mode === 'consumer') {
                documents = documents.where('hidden', false)
            }
            return documents.orderBy('created_at', 'desc').get()
        },
        pagination() {
            return Pagination.find(this.innerPaginationId)
        },
        loading() {
            return this.pagination ? this.pagination.loading : true
        },
        isunite() {
            return this.$railsConfig.global.project_name.toLowerCase() === "unite"
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    async mounted() {
        this.innerPaginationId = `${this.$options.name}_${this._uid}`
        await Pagination.insert({data: {id: this.innerPaginationId}})
        await this.loadDocumentsBunch()
        this.documentLoading = false
    },
    methods: {
        async loadDocumentsBunch() {
            let params = {
                channel_id: this.channel.id,
                ...this.pagination.nextPageParams,
                limit: this.loadIterationLimit
            }
            if (this.mode === 'dashboard') {
                params = {...params, dashboard: "1"}
            }
            if (this.mode === 'consumer') {
                params = {...params, hidden: false}
            }
            Pagination.update({id: this.innerPaginationId, loading: true})
            let request = await Document.api().fetch(params)
            Pagination.update({id: this.innerPaginationId, ...request.response.data.pagination, loading: false})
        }
    }
}
</script>