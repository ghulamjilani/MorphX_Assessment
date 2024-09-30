<template>
    <div class="FS">
        <div class="FS__title">
            Free Subscriptions
        </div>
        <subscription-form
            :options-channel="optionsChannel"
            @addNewFreeSubscription="addNewFreeSubscription" />
        <table-pagination
            v-if="freeSubscriptions.length"
            :pagination-data="paginationData"
            @prevPage="prevPage"
            @nextPage="nextPage" />
        <table-subscriptions
            :free-subscriptions="freeSubscriptions"
            :loading="loading" />
    </div>
</template>

<script>
import Channel from "@models/Channel"
import SubscriptionForm from "./NewFreeSubscriptionForm.vue"
import TablePagination from "./TablePagination.vue"
import TableSubscriptions from "./TableFreeSubscriptions.vue"

export default {
    name: "FreeSubscriptionsVueDashboardContent",
    components: {
        SubscriptionForm,
        TablePagination,
        TableSubscriptions
    },
    data() {
        return {
            optionsChannel: [],
            freeSubscriptions: [],
            loading: true,
            paginationData: {
                offset: 0,
                limit: 20,
                perPage: 20,
                total: 0
            }
        }
    },
    mounted() {
        this.getChannelsForSubscriptions()
        this.getFreeSubscriptions()
    },
    methods: {
        prevPage() {
            this.paginationData.offset = this.paginationData.offset - this.paginationData.perPage
            this.paginationData.limit = this.paginationData.limit - this.paginationData.perPage
            this.getFreeSubscriptions()
        },
        nextPage() {
            this.paginationData.offset = this.paginationData.offset + this.paginationData.perPage
            this.paginationData.limit = this.paginationData.limit + this.paginationData.perPage
            this.getFreeSubscriptions()
        },
        getChannelsForSubscriptions() {
            Channel.api().getChannelsForSubscriptions()
                .then((res) => {
                    this.optionsChannel = [
                        ...res.response.data.response.map((channel) => {
                            return {
                                name: channel.title,
                                value: channel.id
                            }
                        })
                    ]
                })
                .catch((error) => {
                    console.log(error)
                })
        },
        getFreeSubscriptions() {
            this.loading = true
            Channel.api().getFreeSubscriptions({offset: this.paginationData.offset, limit: this.paginationData.limit})
                .then((res) => {
                    this.freeSubscriptions = res.response.data.response
                    this.paginationData.total = res.response.data.pagination.count
                    this.loading = false
                })
                .catch((error) => {
                    console.log(error)
                    this.loading = false
                })
        },
        addNewFreeSubscription(params) {
            Channel.api().addNewFreeSubscription(params)
                .then((res) => {
                    this.$flash(this.$t('controllers.free_subscriptions_controller.email_queued'), "success")
                    this.loading = true
                    setTimeout(()=> {
                        this.getFreeSubscriptions()
                    }, 2000)
                })
                .catch((error) => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    }
                    else {
                        this.$flash("Something went wrong please try again later")
                    }
                    console.log(error)
                })
        }
    }
}
</script>
