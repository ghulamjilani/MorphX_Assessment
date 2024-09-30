<template>
    <div class="v-tile-collection">
        <template v-if="loading && forModel !== 'search' && !isShowMore">
            <tile-placeholder />
            <tile-placeholder />
            <tile-placeholder />
        </template>

        <template v-else-if="forModel !== 'search'">
            <div
                v-if="(!collection || collection.length == 0) && !loading"
                class="no-items">
                There are no
                <span v-if="isSession">Sessions</span>
                <span v-else-if="isVideo">Replays</span>
                <span v-else-if="isRecording">Uploads</span>
                <span v-else-if="isSearch">Search results</span>
            </div>
            <component
                :is="`${forModel}-tile`"
                v-for="item in collection"
                :key="item.id"
                :item-id="item.id"
                :search="true" />
            <div
                v-if="loading && isShowMore"
                class="spinnerSliderVue margin-bottom-40">
                <div class="bounceS1" />
                <div class="bounceS2" />
                <div class="bounceS3" />
            </div>
        </template>

        <div
            v-if="forModel === 'search'"
            :class="{'two-column': isTwoColumn}"
            class="search-wrap">
            <div
                v-for="item in collection"
                :key="item.$index"
                class="searchTile"
                :class="item.type.toLowerCase().replace('::', '')">
                <component
                    :is="`${item.type.toLowerCase().replace('::', '')}-tile`"
                    :item-id="item.id"
                    :search="true" />
            </div>
            <div
                v-show="(!collection || collection.length == 0) && !isLoading"
                class="no-items">
                There are no
                <span v-if="isSession">Sessions</span>
                <span v-else-if="isVideo">Replays</span>
                <span v-else-if="isRecording">Uploads</span>
                <span v-else-if="isSearch">Search results</span>
            </div>
            <div
                v-if="isLoading"
                class="spinnerSliderVue">
                <div class="bounceS1" />
                <div class="bounceS2" />
                <div class="bounceS3" />
            </div>
        </div>
    </div>
</template>

<script>
import query from "@mixins/query.js"
import multiModels from "@mixins/multiModels.js"
import eventHub from "@helpers/eventHub.js"
import {mapGetters} from 'vuex'
import SessionTile from "@components/tiles/SessionTile"
import VideoTile from "@components/tiles/VideoTile"
import RecordingTile from "@components/tiles/RecordingTile"
import ChannelTile from "@components/tiles/ChannelTile"
import UserTile from "@components/tiles/UserTile"
import ArticleTile from "@components/tiles/ArticleTile"
import TilePlaceholder from "@components/TilePlaceholder"

export default {
    components: {SessionTile, VideoTile, RecordingTile, ChannelTile, UserTile, TilePlaceholder,
    'blogpost-tile': ArticleTile},
    mixins: [query, multiModels],
    props: ["forModel", "channel_id"],
    data() {
        return {
            loading: true,
            isShowMore: false
        }
    },
    computed: {
        ...mapGetters({
            isLoading: 'searchLoadingStatus',
            isTwoColumn: 'isSearchInTwoColumn'
        }),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    created() {
        if (!this.isSearch) {
            eventHub.$on('sortChange', ({type, data}) => {
                if (type === this.forModel) {
                    this.orderBy = data.sort
                }
            })
            eventHub.$on('loadingChange', ({type, data}) => {
                if (type === this.forModel) {
                    this.loading = data.loading
                    this.isShowMore = !!data?.showMore?.offset
                }
            })
        }
    }
}
</script>
