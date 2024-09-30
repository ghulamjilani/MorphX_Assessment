<template>
    <div>
        <label>{{ $t('frontend.app.components.modals.template.creator_plan_description.business_plan_info') }}</label>
        <div class="buyCreatorPlan__left-part__planWrapper">
            <div class="buyCreatorPlan__left-part__planWrapper__head" />
            <div class="buyCreatorPlan__left-part__planWrapper__body">
                <div class="planTile__wrapp">
                    <template>
                        <div class="planTile planTile__type4">
                            <div class="cube__wrapp">
                                <div class="cube cube__front" />
                                <div class="cube cube__back" />
                                <div class="cube cube__right" />
                                <div class="cube cube__left" />
                                <div class="cube cube__top" />
                                <div class="cube cube__bottom" />
                            </div>
                        </div>
                    </template>
                </div>
                <b class="fs__22">{{ getCurrentPlan(planPackage, interval).nickname }}</b>
                <span>{{ planPackage.description }}</span>
                <b class="fs__32 padding-t__10 padding-b__15">
                    {{ getIntervalAmount(planPackage, interval) }}
                </b>
                <span>{{ $t('frontend.app.components.modals.template.creator_plan_description.plus_overcharge') }}</span>
                <div class="tl__spacesWrap">
                    <div
                        v-if="planPackage.name == 'Professional'"
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-disc-space" />
                        {{ planPackage.features.find((el) => { return el.code === 'storage' }).value | shortNumber(false, 0) }}
                        {{ $t('frontend.app.components.modals.template.creator_plan_description.tera_bytes') }}
                    </div>
                    <div
                        v-else-if="planPackage.name == 'Enterprise'"
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-disc-space" /> {{ $t('frontend.app.components.modals.template.creator_plan_description.unlimited') }}
                    </div>
                    <div
                        v-else
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-disc-space" />
                        {{ planPackage.features.find((el) => { return el.code === 'storage' }).value }}
                        {{ $t('frontend.app.components.modals.template.creator_plan_description.giga_bayes') }}
                    </div>

                    <div
                        v-if="planPackage.name == 'Enterprise'"
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-stream-video" /> {{ $t('frontend.app.components.modals.template.creator_plan_description.over') }}
                        ({{ $t('frontend.app.components.modals.template.creator_plan_description.live') }})
                    </div>
                    <div
                        v-else
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-stream-video" />
                        {{ planPackage.features.find((el) => { return el.code === 'streaming_time' }).value }}
                        {{ $t('frontend.app.components.modals.template.creator_plan_description.min') }} (({{ $t('frontend.app.components.modals.template.creator_plan_description.live') }})
                    </div>

                    <div
                        v-if="planPackage.name == 'Enterprise'"
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-users" /> {{ $t('frontend.app.components.modals.template.creator_plan_description.over') }}
                        ({{ $t('frontend.app.components.modals.template.creator_plan_description.interactive') }})
                    </div>
                    <div
                        v-else
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-users" />
                        {{ planPackage.features.find((el) => { return el.code === 'interactive_streaming_time' }).value }}
                        {{ $t('frontend.app.components.modals.template.creator_plan_description.min') }}
                        ({{ $t('frontend.app.components.modals.template.creator_plan_description.interactive') }})
                    </div>

                    <div
                        v-if="planPackage.name == 'Enterprise'"
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-play" /> {{ $t('frontend.app.components.modals.template.creator_plan_description.over') }}
                        ({{ $t('frontend.app.components.modals.template.creator_plan_description.videos') }})
                    </div>
                    <div
                        v-else
                        class="tl__spacesWrap__spaces">
                        <i class="GlobalIcon-play" />
                        <!-- {{ planPackage.features.find((el) => { return el.code === 'transcoding_time' }).value }} -->
                        <!-- {{ $t('frontend.app.components.modals.template.creator_plan_description.min') }} -->
                        <!-- ({{ $t('frontend.app.components.modals.template.creator_plan_description.videos') }}) -->
                        {{ (planPackage.features.find((el) => { return el.code === 'transcoding_time' }).value  / 1024 ) | shortNumber(false, 1) }}
                        {{ $t('frontend.app.components.modals.template.creator_plan_description.tera_bytes') }} {{ $t('frontend.app.components.modals.template.creator_plan_description.video_playback') }}
                    </div>
                </div>
                <div class="buyCreatorPlan__left-part__planWrapper__body__plants">
                    <div class="plant1">
                        <image-pl1 class="plant1__top" />
                        <img
                            :src="$img['bp_pl_bottom']"
                            class="plant1__bottom">
                    </div>
                    <image-pl2 class="plant2" />
                    <div class="plant3">
                        <image-pl1r class="plant1__top" />
                        <img
                            :src="$img['bp_pl_bottom']"
                            class="plant1__bottom">
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import ImagePl1 from "../../../assets/images/BusinessPlans/ImagePl1"
import ImagePl1r from "../../../assets/images/BusinessPlans/ImagePl1r"
import ImagePl2 from "../../../assets/images/BusinessPlans/ImagePl2"
import filtersv2 from "@helpers/filtersv2"

export default {
    components: {
        ImagePl1,
        ImagePl1r,
        ImagePl2
    },
    props: [
        'planPackage',
        'interval'
    ],
    methods: {
        localeString(amount, options) {
            return filtersv2.formattedPrice(amount, options)
        },
        getIntervalAmount(planPackage, interval) {
            let plan = this.getCurrentPlan(planPackage, interval)
            return this.localeString(plan.amount, plan.money_currency)
        },
        getCurrentPlan(planPackage, interval) {
            return planPackage.plans.find((el) => {
                return el.formatted_interval === interval
            })
        }
    }
}
</script>