<template>
    <m-modal
        ref="buyCreatorPlan"
        class="buyCreatorPlan">
        <div class="buyCreatorPlan__left-part">
            <creator-plan-description
                :interval="interval"
                :plan-package="planPackage" />
        </div>

        <div class="buyCreatorPlan__right-part">
            <payment
                :is-trial="false"
                :purchased-item="planPackagePaymentObject"
                :vuex-model="serviceSubscription"
                submit-btn-text="Complete Purchase" />
        </div>
    </m-modal>
</template>

<script>
import CreatorPlanDescription from './template/CreatorPlanDescription'
import Payment from './template/Payment'
import eventHub from "@helpers/eventHub.js"
import ServiceSubscription from '@models/ServiceSubscription'

export default {
    components: {Payment, CreatorPlanDescription},
    data() {
        return {
            planPackage: {},
            interval: '',
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
            this.$refs.buyCreatorPlan.openModal()
        },
        close() {
            if (this.$refs.buyCreatorPlan) this.$refs.buyCreatorPlan.closeModal()
        }
    }
}
</script>