<template>
    <div>
        <div
            v-if="owner.bio"
            class="ownerModal__body">
            <div class="ownerModal__title ownerModal__title__border">
                <div class="ownerModal__label">
                    {{ $t('channel_page.about') }}
                </div>
                <div>
                    <a
                        v-for="social in owner.social_links"
                        :key="social.id"
                        :href="social.url"
                        class="ownerModal__social"
                        target="_blank">
                        <m-icon
                            v-if="social.provider == 'explicit'"
                            size="1.6rem">
                            GlobalIcon-website
                        </m-icon>
                        <m-icon
                            v-else-if="social.provider == 'google+'"
                            size="1.6rem">
                            GlobalIcon-google
                        </m-icon>
                        <m-icon
                            v-else
                            size="1.6rem">
                            GlobalIcon-{{ social.provider }}
                        </m-icon>
                    </a>
                </div>
            </div>
            <div class="ownerModal__description">
                {{ description }}
            </div>
            <div class="ownerModal__title">
                <button
                    v-if="owner.bio && owner.bio.length > cropReadMore"
                    class="btn__reset ownerModal__readMore"
                    @click="toggleReadMore">
                    {{ readMore ? $t('channel_page.read_less') : $t('channel_page.read_more') }}
                </button>
            </div>
        </div>
        <div
            v-if="loading"
            class="ownerModal__classes">
            <div class="ownerModal__title">
                <div class="ownerModal__label">
                    {{ $t('channel_page.sessions_by') }}
                </div>
            </div>
            <div class="ownerModal__content">
                <div class="mChannel__tiles__items placeholder">
                    <tile-placeholder class="cardMK2" />
                    <tile-placeholder class="cardMK2" />
                    <tile-placeholder class="cardMK2" />
                    <tile-placeholder class="cardMK2" />
                </div>
            </div>
        </div>
        <div
            v-else-if="videos.videos.length || videos.sessions.length"
            class="ownerModal__classes">
            <div class="ownerModal__title">
                <div class="ownerModal__label">
                    {{ $t('channel_page.sessions_by') }} {{ owner.public_display_name }}
                </div>
            </div>
            <div class="ownerModal__content">
                <div class="mChannel__tiles__list">
                    <div class="mChannel__tiles__items">
                        <template v-for="(video) in videos.sessions">
                            <m-card :key="video.id">
                                <template #top>
                                    <session-top :video="video" />
                                </template>
                                <template #bottom>
                                    <session-bottom :video="video" />
                                </template>
                            </m-card>
                        </template>
                        <template v-for="(video) in videos.videos">
                            <m-card :key="video && video.id">
                                <template #top v-if="video.type == 'video'">
                                    <replay-top
                                        :video="video" />
                                </template>
                                <template #top v-else-if="video.type == 'recording'">
                                    <recording-top
                                        :video="video" />
                                </template>
                                <template #bottom v-if="video.type == 'video'">
                                    <replay-bottom
                                        :video="video" />
                                </template>
                                <template #bottom v-else-if="video.type == 'recording'">
                                    <recording-bottom
                                        :video="video" />
                                </template>
                            </m-card>
                        </template>
                    </div>
                </div>
            </div>
            <a
                v-if="!enterprise && videos.sessions.length + videos.videos.length > (lim - 1)"
                :href="'/search?utf8=✓&ford=rank&fcra=' + owner.id"
                target="_blank">
                <div class="ownerModal__view-all">
                    {{ $t('channel_page.view_all') }}
                </div>
            </a>
        </div>
        <div
            v-else
            class="ownerModal__classes">
            <div class="ownerModal__classes__svg">
                <no-videos-yet />
                <div
                    v-if="isUserChannel"
                    class="ownerModal__classes__svg__text">
                    {{ $t('channel_page.no_videos') }}
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'
import SessionBottom from '@components/card-templates/SessionBottom.vue'
import SessionTop from '@components/card-templates/SessionTop.vue'
import TilePlaceholder from "@components/TilePlaceholder"
import Video from "@models/Video"
import Recording from "@models/Recording"
import Session from "@models/Session"
import NoVideosYet from './NoVideosYet.vue'

export default {
    components: {ReplayTop, ReplayBottom, RecordingTop, RecordingBottom, SessionBottom, SessionTop, NoVideosYet, TilePlaceholder},
    props: {
        owner: Object,
        limit: Number,
        isUserChannel: Boolean
    },
    data() {
        return {
            lim: this.limit,
            videos: {
                sessions: [],
                videos: []
            },
            cropReadMore: 400,
            readMore: false,
            loading: true,
            enterprise: false
        }
    },
    computed: {
        description() {
            if (this.owner.bio?.length <= this.cropReadMore) this.readMore = true
            return this.readMore ? this.owner.bio : this.owner.bio?.slice(0, this.cropReadMore) + "..."
        }
    },
    watch: {
        owner: {
            handler(val) {
                if (val) {
                    this.preloadVideos()
                }
            },
            deep: true
        }
    },
    mounted() {
        this.preloadVideos()
        this.enterprise = this.$railsConfig.global.enterprise
    },
    methods: {
        preloadVideos() {
            if (!this.owner.id) return
            this.loading = true
            Session.api().searchApi({
                user_id: this.owner.id,
                limit: this.lim,
                offset: 0,
                order_by: "start_at",
                order: "asc",
                end_after: moment().tz("Europe/London").toISOString()
            }).then((res) => {
                this.videos.sessions = res.response.data.response.sessions?.map(e => {
                    e.type = "session"
                    return e
                })
                this.$emit('sessions', {sessions: this.videos.sessions})
                this.lim -= res.response.data.pagination?.count
                let started = this.videos.sessions.find(e => e.session.start_now)
                if (this.lim <= 0) this.loading = false
                if (started) {
                    this.videos.sessions = this.videos.sessions.filter(e => e.session.id !== started.session.id)
                    this.videos.sessions = [started].concat(this.videos.sessions)
                }
                if (this.lim > 0) {
                    Video.api().searchApi({
                        user_id: this.owner.id,
                        limit: this.lim,
                        offset: 0,
                        order_by: "created_at",
                        order: "desc"
                    }).then((res) => {
                        this.videos.videos = res.response.data.response.videos?.map(e => {
                            e.type = "video"
                            return e
                        })
                        Recording.api().searchApi({
                            user_id: this.owner.id,
                            limit: this.lim,
                            offset: 0,
                            order_by: "created_at",
                            order: "desc"
                        }).then((res) => {
                            if (res.response.data.response.videos) {
                                this.videos.videos.push(res.response.data.response.videos?.map(e => {
                                    e.type = "recording"
                                    return e
                                }))
                                this.videos.videos.sort((a, b) => {
                                    return new Date(b.created_at) - new Date(a.created_at)
                                })
                            }
                            this.loading = false
                        })
                    })
                }
            })
        },
        toggleReadMore() {
            this.readMore = !this.readMore
        }
    }
}
</script>