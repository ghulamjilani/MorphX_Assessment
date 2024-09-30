<template>
    <div class="searchPage pageComponent">
        <div id="sessions">
            <div class="componentsManager">
                <div class="componentManager">
                    <div class="container">
                        <filters
                            :for-model="forModel" />
                    </div>
                </div>
                <div class="componentManager">
                    <div class="container">
                        <tiles-collection
                            :for-model="forModel" />
                    </div>
                </div>
            </div>
        </div>
        <share-modal />
        <user-info-modal />
        <booking-payment />
    </div>
</template>

<script>
import Filters from "@components/Filters"
import TilesCollection from "@components/TilesCollection"
import multiModels from "@mixins/multiModels.js"
import eventHub from "@helpers/eventHub.js"
import SelfFollows from "@models/SelfFollows"
import ShareModal from '@components/modals/ShareModal'
import UserInfoModal from '@components/modals/UserInfoModal'
import {mapActions, mapGetters} from 'vuex'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    name: 'Search',
    components: {
        Filters,
        TilesCollection,
        ShareModal,
        UserInfoModal, BookingPayment
    },
    mixins: [multiModels],
    computed: {
        ...mapGetters({
            isLoading: 'searchLoadingStatus',
            searchParams: 'getSearchParams',
            searchList: 'getSearchList'
        }),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    data() {
        return {
            forModel: 'search',
            isAllLoaded: false
        }
    },
    watch: {
        currentUser: {
            handler(val) {
                if (val) {
                    SelfFollows.api().getFollows({followable_type: "Channel"})
                    SelfFollows.api().getFollows({followable_type: "User"})
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        const that = this
        window.onscroll = function (ev) {
            if (!that.isLoading && !that.isAllLoaded && (window.innerHeight + window.scrollY) >= (document.body.scrollHeight - 150) && that.searchList.length) {
                that.handleGetList()
            }
        }
        eventHub.$on("applyFilter", () => {
            this.isAllLoaded = false
        })
    },
    methods: {
        ...mapActions({
            setLoader: 'SET_SEARCH_LOADER'
        }),
        handleGetList() {
            this.setLoader(true)
            this.model.api().search(this.searchParams, {newPage: true}).then((r) => {
                var isAllLoaded = r.response.data?.pagination?.current_page >= r.response.data?.pagination?.total_pages
                this.isAllLoaded = isAllLoaded
            })
                .catch((e) => console.log(e))
                .finally(() => {
                    this.setLoader(false)
                })
        },
        mounted() {
            this.setLoader(true)
        }
    }
}
</script>