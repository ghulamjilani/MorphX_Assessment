<template>
    <div class="cardMK2__imgWrapper">
        <moderate-tiles
            :item="video"
            type="Session"
            :use-promo-weight="usePromoWeight" />
        <a :href="model.relative_path">
            <div class="cardMK2__chips cardMK2__liveSection">
                <m-chips :class="{'cardMK2__chips__live': sessionStarted}">
                    {{ sessionStatus === 'standart' || sessionStatus === 'started' ? 'Live ' : sessionStatus }}
                    <div v-if="sessionStatus === 'standart' && !sessionStarted">
                        &nbsp;{{ $t('frontend.app.components.card_templates.session_top.in') }} {{ millisecondsToSesions | datetimeToSession(true) }}
                    </div>
                </m-chips>
                <m-chips
                    v-if="sessionStarted"
                    class="cardMK2__liveSection__paddingless">
                    <m-icon>GlobalIcon-eye</m-icon>
                    {{ watchersCount }}
                </m-chips>
                <m-chips
                    v-if="isPrivate"
                    class="cardMK2__chips__private">
                    {{ $t('frontend.app.components.card_templates.session_top.private') }}
                </m-chips>
            </div>
            <div class="tileMK2__wrappper">
                <div
                    v-if="ageRestrictions"
                    class="tileMK2__ageRestriction"
                    :class="{'notPaidVideo': video && sessionBuy > 0}">
                    {{ ageRestrictions }}
                </div>
                <div
                    v-if="!isunite && (video && sessionBuy || sessionParticipate)"
                    class="tileMK2__chips__dollar">
                    <m-chips :just-slot="true">
                        <div class="chips__dollar">
                            $
                        </div>
                        <div
                            class="sessionCost-tooltip fs-12">
                            <div class="chips__dollar__price">
                                <div
                                    v-if="sessionBuy > 0"
                                    class="chips__dollar__price__row">
                                    {{ $t('frontend.app.components.card_templates.session_top.buy') }}: <span>${{ sessionBuy }}</span>
                                </div>
                                <div
                                    v-if="sessionParticipate > 0"
                                    class="chips__dollar__price__row">
                                    Participate: <span>${{ sessionParticipate }}</span>
                                </div>
                                <div
                                    v-if="model.immersive_purchase_price && sessionParticipate > 0"
                                    class="chips__dollar__price__row">
                                    <template v-if="model.line_slots_left > 0">
                                        ({{ model.line_slots_left }} out of {{
                                            model.max_number_of_immersive_participants
                                        }} slots left)
                                    </template>
                                    <template v-else>
                                        (Sold Out)
                                    </template>
                                </div>
                            </div>
                        </div>
                    </m-chips>
                </div>
                <div
                    v-if="free && showFreeLabel && !membershipFrom"
                    class="chips__label chips__label__anyWidth">
                    Free
                </div>
                <div
                    v-if="isunite && (video && sessionBuy || sessionParticipate || (free && only_subscription))"
                    class="tileMK2__chips__dollar">
                    <m-chips :just-slot="true">
                        <div
                            v-if="(isPaid && !only_ppv && !only_subscription) ||
                                (isPaid && only_ppv && !only_subscription)"
                            class="chips__dollar">
                            $
                        </div>
                        <div
                            v-if="membershipFrom"
                            class="chips__label chips__label__margin0 memberLevel">
                            Member
                        </div>
                        <div
                            class="sessionCost-tooltip fs-12"
                            :class="{'sessionCost-tooltip__long': subscribeFrom && membershipFrom}">
                            <div class="chips__dollar__price">
                                <div
                                    v-if="subscribeFrom && sessionBuy > 0"
                                    class="chips__dollar__price__row">
                                    {{ $t('frontend.app.components.card_templates.session_top.buy') }}: <span>${{ sessionBuy }}</span>
                                </div>
                                <div
                                    v-if="subscribeFrom && membershipFrom"
                                    class="chips__dollar__price__row">
                                    Membership from: <span>{{ subscribeFrom }}</span>
                                </div>
                                <div
                                    v-if="!subscribeFrom"
                                    class="chips__dollar__price__row">
                                    To see this content please contact channel owner
                                </div>
                                <div
                                    v-if="subscribeFrom && sessionParticipate > 0"
                                    class="chips__dollar__price__row">
                                    Participate: <span>${{ sessionParticipate }}</span>
                                </div>
                                <div
                                    v-if="subscribeFrom && model.immersive_purchase_price && sessionParticipate > 0"
                                    class="chips__dollar__price__row">
                                    <template v-if="model.line_slots_left > 0">
                                        ({{ model.line_slots_left }} out of {{
                                            model.max_number_of_immersive_participants
                                        }} slots left)
                                    </template>
                                    <template v-else>
                                        (Sold Out)
                                    </template>
                                </div>
                            </div>
                        </div>
                    </m-chips>
                </div>
            </div>
            <div
                :style="`background-image: url(${model.small_cover_url})`"
                class="cardMK2__imgContainer" />
        </a>
        <div
            class="cardMK2__socialSharing"
            @click="openShare()">
            <i class="GlobalIcon-tile-share" />
        </div>
    </div>
</template>

<script>
export default {
    props: {
        video: {},
        usePromoWeight: Boolean
    },
    data() {
        return {
            millisecondsToSesions: 0,
            sessionStatus: 'standart', // standart, started, Completed, Cancelled
            watchers: -1
        }
    },
    computed: {
        model() {
            return this.video.session || this.video
        },
        ageRestrictions() {
            switch(this.model?.age_restrictions) {
                case 1: return '18+'
                case 2: return '21+'
                default: return null
            }
        },
        sessionStarted() {
            return ((this.isLive || new Date(this.model.start_at) < new Date()) &&
                (this.sessionStatus === 'standart') || this.sessionStatus === 'started')
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        watchersCount() {
            return this.watchers === -1 ? this.model.watchers_count : this.watchers
        },
        isLive() {
            return this.model.url_params?.status == 'running' || this.model.url_params?.status == 'started'
        },
        sessionBuy() {
            if (this.model.livestream_purchase_price && this.model.livestream_purchase_price !== '0.0') {
                return +this.model.livestream_purchase_price
            }
            return 0
        },
        sessionParticipate() {
            if (this.model.immersive_purchase_price && this.model.immersive_purchase_price !== '0.0') {
                return +this.model.immersive_purchase_price
            }
            return 0
        },
        isunite() {
            return this.$railsConfig.global.project_name.toLowerCase() === "unite"
        },
        subscribeFrom() {
            if(this.video?.channel?.subscription?.plans?.length > 0) {
                let minPrice = 10000000
                let str = ""
                this.video.channel.subscription.plans.forEach(e => {
                    if (minPrice > +e.amount) {
                        minPrice = +e.amount
                        str = e.formatted_price
                    }
                })
                return str
            }
            return null
        },
        isPaid() {
            return this.sessionBuy || this.sessionParticipate
        },
        free() {
            return !this.isPaid
        },
        only_ppv() {
            return this.model?.only_ppv
        },
        only_subscription() {
            return this.model?.only_subscription
        },
        membershipFrom() {
            return (this.free && !this.only_ppv && this.only_subscription) ||
                (this.isPaid && !this.only_ppv && this.only_subscription) ||
                (this.isPaid && this.only_ppv && this.only_subscription)
        },
        isPrivate() {
            return !!this.model?.private
        },
        showFreeLabel() {
            return this.$railsConfig.frontend?.tiles?.video_tile?.free_label
        }
    },
    watch: {
        video: {
            handler(val) {
                if (val.session.cancelled_at) {
                    this.sessionStatus = this.$t('frontend.app.components.card_templates.session_top.canceled')
                }
                if (val.session.stopped_at) {
                    this.sessionStatus = this.$t('frontend.app.components.card_templates.session_top.completed')
                }
            },
            deep: true
        }
    },
    mounted() {
        this.updateMillisecondsToSesions()
        this.counterStarter()
        this.updateSessionStatusComponentData()

        this.$eventHub.$on(sessionsChannelEvents.sessionStarted, (data) => {
            if (data.session_id === this.model.id) {
                this.sessionStatus = 'started'
            }
        })
        this.$eventHub.$on(sessionsChannelEvents.sessionStopped, (data) => {
            if (data.session_id === this.model.id) {
                this.sessionStatus = this.$t('frontend.app.components.card_templates.session_top.completed')
            }
        })
        this.$eventHub.$on(sessionsChannelEvents.sessionCancelled, (data) => {
            if (data.session_id === this.model.id) {
                this.sessionStatus = this.$t('frontend.app.components.card_templates.session_top.canceled')
            }
        })
        this.$eventHub.$on(sessionsChannelEvents.livestreamMembersCount, (data) => {
            if (data.session_id === this.model.id) {
                this.watchers = data.count
            }
        })
    },
    methods: {
        openLink(isMiddle = false) {
            this.goTo(location.origin + this.model.relative_path, isMiddle)
        },
        updateMillisecondsToSesions() {
            if (this.model?.url_params?.status == 'running' || this.model?.url_params?.status == 'started') return 0

            if (this.model?.start_at) {
                let tz = this.currentUser?.manually_set_timezone || 'Europe/London'
                let ms = moment(this.model?.start_at).tz(tz) - moment().tz(tz)
                // if(ms < 0 && this.sessionStatus === 'standart') this.sessionStatus = 'started'
                this.millisecondsToSesions = ms > 0 ? ms : 0
            }
        },
        counterStarter() {
            let _24hInMills = 86400000
            if (this.millisecondsToSesions < _24hInMills) {
                let interval = setInterval(() => {
                    this.updateMillisecondsToSesions()
                    this.updateSessionStatusComponentData()
                    if (this.millisecondsToSesions <= 0) {
                        clearInterval(interval)
                    }
                }, 1000)
            }
        },
        openShare() {
            this.$eventHub.$emit("open-modal:share", {model: this.video, type: "Session"})
        },
        updateSessionStatusComponentData() {
            if (this.millisecondsToSesions <= 0) {
                this.sessionStatus = 'started'
            }
        }
    }
}
</script>