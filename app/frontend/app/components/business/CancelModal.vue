<template>
    <m-modal
        ref="cancelSubscriptionModal"
        class="cancelSubscriptionModal">
        <h2>{{ $t('components.business.cancel_modal.cancel_subscription') }}</h2>
        <span class="margin-b__10">
            <span v-if="serviceSubscriptionServiceStatus == 'active'" v-html="$t('components.business.cancel_modal.cancel_active_bsiness_plan', {serviceSubscriptionName, date: dateToformat(serviceSubscription.current_period_end, 'MMMM DD, YYYY')})" />
            <span v-else-if="serviceSubscriptionServiceStatus == 'trial'" v-html="$t('components.business.cancel_modal.cancel_bsiness_plan', {serviceSubscriptionServiceStatus, serviceSubscriptionName})" />
            <span v-else v-html="$t('components.business.cancel_modal.cancel_bsiness_plan', {serviceSubscriptionName})" />
        </span>
        <!--p v-html="$t('components.business.cancel_modal.you_also_can')" /-->
        <div class="buttonsSection">
            <m-btn
                size="s"
                type="secondary"
                @click="closeModal">
                {{ $t('components.business.cancel_modal.btns.close') }}
            </m-btn>
            <m-btn
                size="s"
                type="main"
                @click="cancelSubscription">
                {{ $t('components.business.cancel_modal.btns.cancel_subscription') }}
            </m-btn>
        </div>
    </m-modal>
</template>

<script>
import ServiceSubscription from '@models/ServiceSubscription'
import filters from "@helpers/filters"

export default {
    props: {
        serviceSubscriptionId: Number
    },
    computed: {
        serviceSubscription() {
            return ServiceSubscription.query().whereId(this.serviceSubscriptionId).first() || {}
        },
        serviceSubscriptionServiceStatus() {
            if (this.serviceSubscription?.service_status == 'trial' || this.serviceSubscription?.service_status == 'trial_suspended') {
                return 'trial'
            }
            else {
                return this.serviceSubscription?.service_status
            }
        },
        serviceSubscriptionName() {
            return this.serviceSubscription?.plan?.name
        }
    },
    methods: {
        openModal() {
            this.$refs.cancelSubscriptionModal.openModal()
        },
        closeModal() {
            this.$refs.cancelSubscriptionModal.closeModal()
        },
        cancelSubscription() {
            ServiceSubscription.api().cancelSubscription({
                id: this.serviceSubscription.id
            }).then(() => {
                ServiceSubscription.api().current().catch((error) => {
                    if (error.response.status === 404) {
                        this.serviceSubscription.$delete()
                    }
                })
                this.closeModal()
                this.$flash('Subscription was canceled successfully', "success")
                setTimeout(() => {
                    this.$router.go(this.$router.currentRoute);
                    // this.$router.replace({ name: 'dashboard', force: true });
                }, 2000)
            }).catch((error) => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        dateToformat(value, format) {
            return filters.dateToformat(value, format)
        }
    }
}
</script>