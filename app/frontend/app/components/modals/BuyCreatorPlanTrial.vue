<template>
    <m-modal
        ref="buyCreatorPlanTrial"
        class="buyCreatorPlanTrial buyCreatorPlan">
        <div class="buyCreatorPlan__left-part">
            <creator-plan-free-trial-description
                :interval="interval"
                :plan-package="planPackage" />
        </div>

        <div class="buyCreatorPlan__right-part">
            <payment
                :is-trial="true"
                :purchased-item="planPackagePaymentObject"
                :submit-btn-text="!currentUser || !currentUser.subscriptionAbility || currentUser.subscriptionAbility.have_trial_service_subscription ? 'Start Free Trial' : 'Buy'"
                :vuex-model="serviceSubscription"
                top-text="Payment Details" />

            <div class="buyCreatorPlan__right-part__terms">
                {{ $t('pricing_page.modals.addition') }} {{ service_name }} {{
                    $t('pricing_page.modals.addition_part_2')
                }}
                <a
                    href="/pages/terms-of-use"
                    target="_blank">{{ $t('footer.terms_of_use') }}</a> {{
                        $t('pricing_page.modals.and')
                    }} <a
                    href="/pages/privacy-policy"
                    target="_blank">{{ $t('footer.privacy_police') }}.</a>
            </div>
        </div>
    </m-modal>
</template>

<script>
import CreatorPlanFreeTrialDescription from './template/CreatorPlanFreeTrialDescription'
import Payment from './template/Payment'
import eventHub from "@helpers/eventHub.js"
import ServiceSubscription from '@models/ServiceSubscription'

export default {
    components: {Payment, CreatorPlanFreeTrialDescription},
    data() {
        return {
            planPackage: {},
            interval: '',
            userModel: null,
            service_name: null,
            serviceSubscription: null,
            planPackagePaymentObject: {
                stripe_id: '',
                price: '',
                trial_period_days: '',
                name: '',
                money_currency: null
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    created() {
        this.serviceSubscription = ServiceSubscription
    },
    mounted() {
        eventHub.$on('payment-success', () => {
            this.goTo('/wizard/business')
            this.close()
        })
    },
    methods: {
        open(planPackage, interval) {
            this.planPackage = planPackage
            this.interval = interval
            let plan = planPackage.plans.find((el) => {
                return el.formatted_interval === this.interval
            })
            this.planPackagePaymentObject.stripe_id = plan.stripe_id
            this.planPackagePaymentObject.price = plan.amount
            this.planPackagePaymentObject.trial_period_days = plan.trial_period_days
            this.planPackagePaymentObject.money_currency = plan.money_currency
            this.planPackagePaymentObject.name = planPackage.name
            this.$refs.buyCreatorPlanTrial.openModal()
        },
        close() {
            if (this.$refs.buyCreatorPlanTrial) this.$refs.buyCreatorPlanTrial.closeModal()
        }
    }
}
</script>