<template>
    <div
        v-show="isShow && !loading"
        class="row show_more recordings">
        <div class="padding-bottom-40 text-center">
            <a
                class="btn btn-m btn-grey-solis"
                href=""
                @click.prevent="showMore()">Show More</a>
        </div>
    </div>
</template>

<script>
import query from "@mixins/query.js"
import multiModels from "@mixins/multiModels.js"
import eventHub from "@helpers/eventHub.js"

export default {
    mixins: [query, multiModels],
    props: ['forModel', 'channel_id'],
    data() {
        return {
            offset: 0,
            limit: 12,
            totalCount: -1,
            current_page: -1,
            total_pages: -1,
            loading: true
        }
    },
    computed: {
        isShow() {
            return this.totalCount > this.limit && this.total_pages > this.current_page
        }
    },
    created() {
        eventHub.$on('searchResponse', ({type, data}) => {
            if (type === this.forModel) {
                this.totalCount = data.pagination?.count
                this.offset = data.pagination?.offset
                this.total_pages = data.pagination?.total_pages
                this.current_page = data.pagination?.current_page
            }
        }),
            eventHub.$on('loadingChange', ({type, data}) => {
                if (type === this.forModel) {
                    this.loading = data.loading
                }
            })
    },
    methods: {
        showMore() {
            eventHub.$emit('showMore', {
                data: {
                    offset: this.offset += this.limit,
                    limit: this.limit
                }, type: this.forModel
            })
        }
    }
}
</script>