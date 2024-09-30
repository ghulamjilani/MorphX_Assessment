<template>
    <div class="mChannel__tiles">
        <share-modal />
        <div
            :class="{'mChannel__tiles__affixWrapp__hidden' : !videos.sessions.length && !videos.videos.length}"
            class="mChannel__tiles__affixWrapp">
            <div
                :class="{'active': scrolled}"
                class="mChannel__tiles__affix">
                <div class="mChannel__tiles__affix__container">
                    <c-filters
                        v-if="videos.sessions.length || videos.videos.length"
                        ref="cfilters"
                        :channel="channel"
                        :members="members"
                        :organization_relative_path="organization_relative_path"
                        :owner="owner"
                        :subscription_features="subscription_features"
                        @updateSearch="search"
                        @updateTilesList="updateTiles" />
                    <scrollactive
                        ref="scrollactive_el"
                        :class="{'mChannel__tiles__nav__ios' : ios}"
                        :duration="800"
                        :offset="offsetScroll"
                        active-class="active"
                        bezier-easing-value=".5,0,.35,1"
                        class="mChannel__tiles__nav">
                        <a
                            v-if="videos.sessions.length"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__live">
                            {{ $t('channel_page.live') }}
                        </a>
                        <a
                            v-if="videos.videos.length"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__allVideos">
                            {{ $t('channel_page.all_videos') }}
                        </a>
                        <!-- <a
                            v-if="postsCount > 0"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__blog">
                            {{ $t('frontend.app.components.channel.page.most_resent_posts') }}
                        </a> -->
                        <a
                            v-if="documents.length > 0 && haveActiveSubscriptions"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__documents">
                            {{ $t('channel_page.documents') }}
                        </a>
                        <a
                            v-if="reviews && reviews.length"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__reviews">
                            {{ $t('channel_page.reviews') }}
                        </a>
                        <a
                            v-if="isCommunityAvailable"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__community">
                            {{ $t('views.dashboard.navigationsidebar.community') }}
                        </a>
                        <a
                            v-if="navLinks.store"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__store">
                            {{ $t('channel_page.store') }}
                        </a>
                        <a
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__about">
                            {{ $t('channel_page.about') }}
                        </a>
                        <a
                            v-if="channels.length > 1"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            href="#anchorSection__network">
                            {{ $t('channel_page.network') }}
                        </a>
                    </scrollactive>
                </div>
            </div>
        </div>
        <div
            v-if="!loading && videos.query.length === 0 && !emptySearch"
            class="mChannel__tiles__list">
            <div
                v-if="videos.sessions"
                class="mChannel__tiles__items">
                <template v-for="(video, index) in videos.sessions">
                    <m-card
                        v-if="index < sessionsCount"
                        :id="index === 0 ? 'anchorSection__live' : null"
                        :key="video.id"
                        :class="index === 0 ? 'anchorSection' : null">
                        <template #top>
                            <session-top :video="video" />
                        </template>
                        <template #bottom>
                            <session-bottom :video="video" />
                        </template>
                    </m-card>
                </template>
                <template v-for="(video, index) in videos.videos">
                    <m-card
                        v-if="video && index < videosCount"
                        :id="index === 0 ? 'anchorSection__allVideos' : null"
                        :key="video && video.id"
                        :class="index === 0 ? 'anchorSection' : null">
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
            <div class="text__center">
                <m-btn
                    v-if="(videos.videos.length + videos.sessions.length) > offset"
                    class="mChannel__tiles__show-more"
                    type="secondary"
                    @click="showMore">
                    {{ $t('channel_page.show_more') }}
                </m-btn>
            </div>
        </div>
        <div
            v-else-if="!loading"
            class="mChannel__tiles__list">
            <div class="mChannel__tiles__items">
                <div
                    v-if="emptySearch"
                    class="mChannel__tiles__emptySearch">
                    {{ $t('channel_page.no_results') }}
                </div>
                <template v-for="video in videos.query">
                    <m-card date-test="333"
                        :id="video.anchorSection"
                        :key="video.id">
                        <template #top v-if="video.document.searchable_type === 'Session'">
                            <session-top
                                :video="video.searchable_model" />
                        </template>
                        <template #top v-else-if="video.document.searchable_type === 'Video'">
                            <replay-top
                                :type="video.document.searchable_type"
                                :video="video.searchable_model" />
                        </template>
                        <template #top v-else-if="video.document.searchable_type === 'Recording'">
                            <recording-top
                                :type="video.document.searchable_type"
                                :video="video.searchable_model" />
                        </template>
                        <template #bottom v-if="video.document.searchable_type === 'Session'">
                            <session-bottom
                                :video="video.searchable_model" />
                        </template>
                        <template #bottom v-else-if="video.document.searchable_type === 'Video'">
                            <replay-bottom
                                :type="video.document.searchable_type"
                                :video="video.searchable_model" />
                        </template>
                        <template #bottom v-else-if="video.document.searchable_type === 'Recording'">
                            <recording-bottom
                                :type="video.document.searchable_type"
                                :video="video.searchable_model" />
                        </template>
                    </m-card>
                </template>
            </div>
            <div class="text__center">
                <m-btn
                    v-if="searchShowMore"
                    class="mChannel__tiles__show-more"
                    type="secondary"
                    @click="showMoreSearch">
                    {{ $t('channel_page.show_more') }}
                </m-btn>
            </div>
        </div>
        <div
            v-if="loading"
            class="mChannel__tiles__list">
            <div class="mChannel__tiles__items placeholder">
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
                <tile-placeholder class="cardMK2" />
            </div>
        </div>
    </div>
</template>

<script>
import CFilters from "@components/common/CFilters"
import SessionBottom from '@components/card-templates/SessionBottom.vue'
import SessionTop from '@components/card-templates/SessionTop.vue'
import ReplayBottom from '@components/card-templates/ReplayBottom.vue'
import ReplayTop from '@components/card-templates/ReplayTop.vue'
import RecordingBottom from '@components/card-templates/RecordingBottom.vue'
import RecordingTop from '@components/card-templates/RecordingTop.vue'
import ShareModal from '@components/modals/ShareModal'
import TilePlaceholder from "@components/TilePlaceholder"
import Session from "@models/Session"
import Search from "@models/Search"
import Document from "@models/Document"

export default {
    components: {CFilters, SessionBottom, SessionTop, ReplayBottom, ReplayTop, RecordingBottom, RecordingTop, ShareModal, TilePlaceholder},
    props: {
        channel: {
            type: Object
        },
        organization_relative_path: String,
        subscription_features: {},
        members: {},
        owner: {},
        channels: {},
        priority: {
            type: Number,
            default: null
        },
        postsCount: {
            type: Number,
            default: 0
        }
    },
    data() {
        return {
            offsetScroll: 0,
            loadCount: 8,
            sessionsCount: 8,
            offset: 16,
            scrolled: false,
            posBoxA: 0,
            videos: {
                sessions: [],
                videos: [],
                query: []
            },
            lastSearchParams: {},
            searchShowMore: true,
            searchLoadCount: 8,
            searchOffset: 16,
            emptySearch: false,
            sessionsChannel: null,
            loadVideos: true,
            loadSessions: true,
            reviews: null,
            navLinks: {
                store: false
            },
            triesToAnchor: 0,
            maxTriesToAnchor: 10
        }
    },
    computed: {
        ios() {
            return this.$device.ios() && this.$device.orientation === 'landscape'
        },
        videosCount() {
            let leftSessions = this.videos?.sessions.length - this.sessionsCount
            leftSessions = leftSessions > 0 ? 0 : leftSessions
            return this.offset - this.sessionsCount - leftSessions
        },
        isCommunityAvailable() {
            return this.channel?.can_create_post || this.channel?.display_empty_blog || this.channel?.posts?.count > 0 || this.postsCount > 0
            // return this.subscription_features?.can_manage_blog
        },
        documents() {
            return Document.query()
                .where('channel_id', this.channel.id)
                .where('hidden', false)
                .orderBy('id', 'desc').get()
        },
        haveActiveSubscriptions() {
            return this.channel?.subscription?.plans?.find(plan => plan.active)
        },
        loading() {
            return this.loadVideos || this.loadSessions
        }
    },
    mounted() {
        this.$eventHub.$on('priority', (val) => {
            if (this.priority == val && this.channel) {
                this.preloadVideos()
            }
        })
        window.addEventListener('scroll', this.calcPosOfBox)
        this.handleScroll()
        setTimeout(() => {
            this.removeActiveClass()
        }, 500)

        this.$eventHub.$on('loaded-by-priority', () => {
            this.moveToAnchor()
        })

    },
    created() {
        this.$eventHub.$on("reset-priority", () => {
            this.reviews = null
        })
        this.$eventHub.$on('channel-review', (val) => {
            this.reviews = val
        })
        window.addEventListener('resize', () => {
            this.offsetScrollMath()
        })
        this.$eventHub.$on("channel-subscribed", () => {
            this.$refs.cfilters?.clearSearchList()
            this.preloadVideos()
        })

        this.$eventHub.$on("channel-navlinks", (data) => {
            this.navLinks[data.name] = data.value
        })

        window.addEventListener('scroll', this.handleScroll)

        this.sessionsChannel = initSessionsChannel()

        this.sessionsChannel.bind(sessionsChannelEvents.sessionStarted, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionStarted, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.sessionStopped, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionStopped, data)
            this.videos.sessions = this.videos.sessions.filter(e => e.session.id !== data.session_id)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.sessionCancelled, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.sessionCancelled, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.livestreamMembersCount, (data) => {
            this.$eventHub.$emit(sessionsChannelEvents.livestreamMembersCount, data)
        })
        this.sessionsChannel.bind(sessionsChannelEvents.liveGuideForceRefresh, (data) => {
            this.preloadVideos()
            this.$eventHub.$emit(sessionsChannelEvents.liveGuideForceRefresh, data)
        })
    },
    destroyed() {
        // window.removeEventListener('scroll')
    },
    methods: {
        removeActiveClass() {
            if (document.querySelector('.mChannel__tiles__affix')) document.querySelector('.mChannel__tiles__affix').classList.remove('active')
            document.querySelectorAll('.scrollactive-item').forEach(element => {
                element.classList.remove('active')
            })
        },
        offsetScrollMath() {
            let el = document.querySelector('.mChannel__tiles__nav')
            if (!el) return
            let styles = window.getComputedStyle(el)
            let margin = parseFloat(styles['marginTop']) + parseFloat(styles['marginBottom'])
            this.offsetScroll = (document.querySelector('.header__container').offsetHeight + el.offsetHeight + margin)
        },
        showMore() {
            this.offset += this.loadCount
            Search.api().searchApi({
                channel_id: this.channel.id,
                limit: this.loadCount,
                offset: this.videos.videos.length,
                order_by: "listed_at",
                order: "desc",
                searchable_type: "Video,Recording"
            }).then((res) => {
                this.videos.videos = this.videos.videos.concat(res.response.data.response.documents?.map(e => {
                    e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    e.searchable_model.total_views_count = e.document.views_count
                    return e.searchable_model
                }))
            })
        },
        searchVideo() {
            return new Promise((resolve, reject) => {
                Search.api().searchApi({
                    channel_id: this.channel.id,
                    limit: 30,
                    offset: 0,
                    order_by: "listed_at",
                    order: "desc",
                    searchable_type: "Video,Recording"
                }).then((res) => {
                    this.loadVideos = false
                    this.videos.videos = res.response.data.response.documents?.map(e => {
                        e.searchable_model.type = e.document.searchable_type.toLowerCase()
                        e.searchable_model.total_views_count = e.document.views_count
                        return e.searchable_model
                    })
                    resolve()
                })
            })
        },
        searchSession() {
            return new Promise((resolve, reject) => {
                Session.api().searchApi({
                    channel_id: this.channel.id,
                    limit: 8,
                    offset: 0,
                    order_by: "start_at",
                    order: "asc",
                    end_after: moment().tz("Europe/London").toISOString()
                }).then((res) => {
                    this.loadSessions = false
                    this.videos.sessions = res.response.data.response.sessions?.map(e => {
                        e.type = "session"
                        return e
                    })
                    let started = this.videos.sessions.find(e => e.session.start_now)
                    if (started) {
                        this.videos.sessions = this.videos.sessions.filter(e => e.session.id !== started.session.id)
                        this.videos.sessions = [started].concat(this.videos.sessions)
                    }
                    this.$nextTick(() => {
                        this.loadSessions = false
                        this.offsetScrollMath()
                    })
                    resolve()
                })
            })
        },
        preloadVideos() {
            this.videos.videos = []
            this.videos.sessions = []
            this.videos.query = []
            this.loadVideos = true
            this.loadSessions = true
            this.emptySearch = false
            this.searchVideo().then(() => {
                this.searchSession().then(() => {
                    this.$eventHub.$emit('check-priority', 2)
                })
            })
        },
        search(params) {
            if (!params.limit) {
                params["limit"] = 16
                params["offset"] = 0
                this.offset = 16
                this.searchShowMore = true
            }
            this.lastSearchParams = params
                        this.loadVideos = true
            this.loadSessions = true
            Search.api().searchApi(params).then((res) => {
                this.loadVideos = false
                this.loadSessions = false
                this.updateTiles(res)
            })
        },
        updateTiles(res) {
            this.videos.query = res && res.response ? res.response.data.response.documents : res
            if (res.response && res.response.data.response.documents.length === 0) {
                this.emptySearch = true
            } else {
                this.emptySearch = res === []
            }
            if (this.videos.query.length < this.searchOffset) {
                this.searchShowMore = false
            }

            let foundFirstonDemand = false
            let foundFirstonLive = false
            this.videos.query.forEach(e => {
                e.searchable_model.total_views_count = e.document.views_count
                if (!foundFirstonDemand && (e.document.searchable_type === "Video" || e.document.searchable_type === "Recording")) {
                    foundFirstonDemand = true
                    e.anchorSection = "anchorSection__allVideos"
                }
                if (!foundFirstonLive && e.document.searchable_type === "Session") {
                    foundFirstonLive = true
                    e.anchorSection = "anchorSection__live"
                }
            })
        },
        addTiles(res) {
            this.videos.query = this.videos.query.concat(res.response.data.response.documents)
            if (this.videos.query.length < this.searchOffset) {
                this.searchShowMore = false
            }
        },
        showMoreSearch() {
            let params = this.lastSearchParams
            params["limit"] = this.searchLoadCount
            params["offset"] = this.videos.query.length
            this.searchOffset = this.videos.query.length + this.searchLoadCount
            this.lastSearchParams = params
            Search.api().searchApi(params).then((res) => {
                this.addTiles(res)
            })
        },
        calcPosOfBox() {
            if (document.querySelector('.mChannel__tiles__affixWrapp')) {
                this.posBoxA = document.querySelector('.mChannel__tiles__affixWrapp').offsetTop
            }
            if (!navigator.userAgent.includes("Firefox") && document.querySelector('.scrollactive-nav') && document.querySelector('.scrollactive-nav').querySelector('.active')) {
                document.querySelector('.scrollactive-nav').querySelector('.active').scrollIntoViewIfNeeded()
            }
        },

        handleScroll() {
            this.scrolled = window.scrollY + 10 > this.posBoxA
        },

        // check elements after last block was loaded, if they are in viewport, scroll to them
        moveToAnchor() {
            setTimeout(() => {
                let anchor = location.hash
                if (anchor) {
                    let el = document.querySelector(anchor)
                    if (el) {
                        this.$refs.scrollactive_el.scrollToHashElement()
                        this.triesToAnchor = this.maxTriesToAnchor
                    }
                    else {
                        if (this.triesToAnchor < this.maxTriesToAnchor) {
                            this.triesToAnchor++
                            this.moveToAnchor()
                        }
                    }
                }
            }, 500)
        }
    }
}
</script>