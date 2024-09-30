<template>
    <div class="cardMK2__imgWrapper">
        <moderate-tiles
            :item="model"
            type="Video"
            :use-promo-weight="usePromoWeight" />
        <a :href="model.relative_path">
            <div class="cardMK2__chips">
                <m-chips v-if="type === 'Video' || video.type === 'video'">{{ $t('frontend.app.components.card_templates.replay_top.replay') }}</m-chips>
                <m-chips
                    v-if="isPrivate"
                    class="cardMK2__chips__private">
                    {{ $t('frontend.app.components.card_templates.replay_top.private') }}
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
                    v-if="abstract && (!abstract.recorded_free || model.only_subscription)"
                    class="tileMK2__chips__dollar">
                    <m-chips
                        :additional-settings="{
                            only_ppv: model.only_ppv,
                            only_subscription: model.only_subscription,
                            subscribeFrom: subscribeFrom
                        }"
                        :buy="+abstract.recorded_purchase_price" />
                </div>
                <div
                    v-if="showFreeLabel && free && !membershipFrom"
                    class="chips__label chips__label__anyWidth">
                    Free
                </div>
            </div>
            <div class="cardMK2__playButton">
                <i class="GlobalIcon-play-btn" />
            </div>
            <div
                :style="`background-image: url(${model.poster_url})`"
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
        type: {},
        usePromoWeight: Boolean
    },
    computed: {
        model() {
            return this.video.video || this.video
        },
        abstract() {
            return this.video.abstract_session
        },
        ageRestrictions() {
            switch(this.abstract?.age_restrictions) {
                case 1: return '18+'
                case 2: return '21+'
                default: return null
            }
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
        isPrivate() {
            return !!this.model?.private
        },
        showFreeLabel() {
            return this.$railsConfig.frontend?.tiles?.video_tile?.free_label
        },
        free() {
            return this.abstract?.recorded_free
        },
        isPaid() {
            return !this.free
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
    },
    methods: {
        openLink(isMiddle = false) {
            this.goTo(location.origin + this.model.relative_path, isMiddle)
        },
        openShare() {
            this.$eventHub.$emit("open-modal:share",
                {
                    model:
                        this.model,
                        type: this.video.type ? (this.video.type === "video" ? "Video" : this.type) : this.type
                }
            )
        }
    }
}
</script>