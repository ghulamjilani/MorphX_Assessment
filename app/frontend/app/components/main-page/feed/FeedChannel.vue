<template>
    <div class="feedChannel">
        <div class="feedChannel__top">
            <router-link
                :to="'/channels'+channel.relative_path"
                class="feedChannel__logo"
                :style="'background-image: url(' + channel.logo_url + ');'" />
            <div class="feedChannel__description">
                <router-link
                    :to="'/channels'+channel.relative_path"
                    class="feedChannel__name"> {{ channel.title }}
                    <span class="feedChannel__organization">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.part_of') }}
                        {{ subscription.organization.name }}</span>
                </router-link>
                <div class="feedChannel__subscription name" v-if="subscription.channel_subscription">
                    <span v-tooltip="subscription.channel_subscription.description">{{ subscription.plan.nickname }}</span>
                </div>
                <div class="feedChannel__subscription name" v-if="subscription.free_plan">
                    <span v-tooltip="subscription.free_plan.description">{{ subscription.free_plan.name }}</span>
                </div>
                <div class="feedChannel__subscribe">
                    <div class="feedChannel__subscribe__date" v-if="subscription.subscription">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.subscribe_started') }}
                        {{ subscription.subscription.created_at | dateToformat('MMM DD YYYY') }}</div>
                    <div class="feedChannel__subscribe__date" v-if="subscription.free_subscription">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.subscribe_started') }}
                        {{ subscription.free_subscription.start_at | dateToformat('MMM DD YYYY') }}</div>

                    <div class="feedChannel__subscribe__duration" v-if="subscription.subscription">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.subscribe_ended') }}
                        {{ subscription.subscription.current_period_end | dateToformat('MMM DD YYYY') }}</div>

                    <div class="feedChannel__subscribe__duration" v-if="subscription.free_subscription">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.subscribe_ended') }}
                        {{ subscription.free_subscription.end_at | dateToformat('MMM DD YYYY') }}</div>

                    <div class="feedChannel__subscribe__content">
                        {{ $t('frontend.app.components.main_page.feed.feed_channels.content_type') }}
                        <m-icon
                            v-tooltip="'Livestreams'"
                            :class="{'active': plan.im_livestreams || plan.livestreams}">GlobalIcon-stream-video</m-icon>
                        <m-icon
                            v-tooltip="'Interactive'"
                            :class="{'active': plan.im_interactives || plan.interactives}">GlobalIcon-users</m-icon>
                        <m-icon
                            v-tooltip="'Replays'"
                            :class="{'active': plan.im_replays || plan.replays}">GlobalIcon-play</m-icon>
                        <m-icon
                            v-tooltip="'Uploads'"
                            :class="{'active': plan.im_uploads || plan.uploads}">GlobalIcon-upload</m-icon>
                        <m-icon
                            v-tooltip="'Group Conversations'"
                            :class="{'active': plan.im_channel_conversation}">GlobalIcon-message-square</m-icon>
                    </div>
                </div>
            </div>
        </div>
        <div class="feedChannel__bottom">
            <h3 v-if="lives.length">Live events</h3>
            <vue-horizontal-list
                v-if="lives.length && !loading"
                id="horScroll1"
                :items="lives"
                :options="options">
                <template #default="{item}">
                    <div class="feedChannel__tile">
                        <m-card>
                            <template #top>
                                <session-top :video="item" />
                            </template>
                            <template #bottom>
                                <session-bottom
                                    :show-organization="true"
                                    :video="item" />
                            </template>
                        </m-card>
                    </div>
                </template>
            </vue-horizontal-list>

            <h3 v-if="videos.length && !loading">Last videos</h3>
            <vue-horizontal-list
                v-if="videos.length"
                id="horScroll2"
                :items="videos"
                :options="options">
                <template #default="{item}">
                    <m-card>
                        <template #top v-if="item.type == 'video'">
                            <replay-top
                                :video="item" />
                        </template>
                        <template #top v-else-if="item.type == 'recording'">
                            <recording-top
                                :video="item" />
                        </template>
                        <template #bottom v-if="item.type == 'video'">
                            <replay-bottom
                                :home-page="true"
                                :video="item" />
                        </template>
                        <template #bottom v-else-if="item.type == 'recording'">
                            <recording-bottom
                                :home-page="true"
                                :video="item" />
                        </template>
                    </m-card>
                </template>
            </vue-horizontal-list>

            <div
                v-if="loading"
                class="mChannel__tiles__list">
                <div class="mChannel__tiles__items placeholder">
                    <!-- <tile-placeholder class="cardMK2" /> -->
                    <tile-placeholder class="cardMK2" />
                    <tile-placeholder class="cardMK2" />
                    <tile-placeholder class="cardMK2" />
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import SessionBottom from '@components/card-templates/SessionBottom.vue'
import SessionTop from '@components/card-templates/SessionTop.vue'

import Search from "@models/Search"
import VueHorizontalList from 'vue-horizontal-list'

export default {
  components: {SessionTop, SessionBottom, VueHorizontalList, ReplayBottom, ReplayTop, RecordingBottom, RecordingTop, TilePlaceholder},
  props: {
    subscription: Object
  },
  data() {
    return {
      lives: [],
      videos: [],
      loading: true,
      options: {
        responsive: [
            {end: 640, size: 1.2},
            {start: 641, end: 767, size: 2.5},
            {size: 3}
        ],
        list: {
            windowed: 992
        }
      }
    }
  },
    computed: {
        channel() {
            return this.subscription.channel
        },
        plan() {
            if(this.subscription.plan) return this.subscription.plan
            else if(this.subscription.free_plan) return this.subscription.free_plan
        }
    },
  mounted() {
    this.loadVideos()
    this.loadLives()
  },
  methods: {
      loadLives() {
        Search.api().searchApi({
            limit: 10,
            order_by: "listed_at",
            order: "asc",
            channel_id: this.channel.id,
            searchable_type:"Session"
        }).then((res) => {
            // this.loading = false
            this.lives = res.response.data.response.documents?.map(e => {
                e.searchable_model.type = e.document.searchable_type.toLowerCase()
                return e.searchable_model
            })
        })
    },
    loadVideos() {
        Search.api().searchApi({
            limit: 10,
            order_by: "listed_at",
            order: "desc",
            channel_id: this.channel.id,
            searchable_type:"Video,Recording"
        }).then((res) => {
            this.loading = false
            this.videos = res.response.data.response.documents?.map(e => {
                e.searchable_model.type = e.document.searchable_type.toLowerCase()
                return e.searchable_model
            })
        })
    }
  }
}
</script>

<style>

</style>