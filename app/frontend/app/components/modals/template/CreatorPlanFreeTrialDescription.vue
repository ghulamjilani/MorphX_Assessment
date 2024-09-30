<template>
    <div>
        <label>Free {{
            planPackage.plans.find((el) => {
                return el.formatted_interval === interval
            }).trial_period_days
        }}-day
            Trial</label>
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
                <div class="buyCreatorPlan__left-part__planWrapper__body__plants">
                    <div class="plant1">
                        <image-pl1 class="plant1__top" />
                        <img
                            :src="$img['bp_pl_bottom']"
                            class="plant1__bottom">
                    </div>
                    <image-pl2 class="plant2" />
                </div>
            </div>
        </div>
        <div class="buyCreatorPlan__left-part__planWrapper__body__description">
            <b>{{ $t('pricing_page.modals.first_question') }}</b>
            <div>
                {{ $t('pricing_page.modals.first_answer') }} <b> {{ chargeDate }} </b>
            </div>
            <b>{{ $t('pricing_page.modals.second_question') }}</b>
            <div>
                {{ $t('pricing_page.modals.second_answer') }}
            </div>
            <b>{{ $t('pricing_page.modals.third_question') }}</b>
            <div>
                <span v-if="planPackage.name == 'Professional'">
                    {{ planPackage.features.find((el) => { return el.code === 'storage' }).value | shortNumber(false, 0) }}
                    {{ $t('frontend.app.components.modals.template.creator_plan_free_trial_description.tera_bytes') }}
                </span>
                <span v-else>
                    {{ planPackage.features.find((el) => { return el.code === 'storage' }).value }}
                    {{ $t('frontend.app.components.modals.template.creator_plan_free_trial_description.giga_bayes') }}
                </span>
                {{ $t('pricing_page.modals.storage_space') }};
                <span>
                    {{
                        unlimitedOrvalue(planPackage.features.find((el) => {
                            return el.code === 'max_channels_count'
                        }).value)
                    }}
                </span>
                {{ $t('pricing_page.modals.channels') }};
                {{ $t('pricing_page.modals.max_session_dur') }}
                <p class="margin__center">
                    <b>{{ $t('pricing_page.modals.note') }}:</b> {{ $t('pricing_page.modals.note_add') }}
                </p>
            </div>
        </div>
    </div>
</template>

<script>
import ImagePl1 from "../../../assets/images/BusinessPlans/ImagePl1"
import ImagePl2 from "../../../assets/images/BusinessPlans/ImagePl2"
import utils from '@helpers/utils'
import filtersv2 from "@helpers/filtersv2"

export default {
    components: {
        ImagePl1,
        ImagePl2
    },
    props: [
        'planPackage',
        'interval'
    ],
    computed: {
        chargeDate() {
            let trial_period_days = this.planPackage.plans.find((el) => {
                return el.formatted_interval === this.interval
            }).trial_period_days
            return utils.dateToTimeZone(moment(), true).add(trial_period_days, 'days').format('MMMM DD, YYYY')
        }
    },
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
        },
        unlimitedOrvalue(value) {
            return value == '-1' ? 'Unlimited' : value
        }
    }
}
</script>