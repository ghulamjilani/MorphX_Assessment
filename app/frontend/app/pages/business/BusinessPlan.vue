<template>
    <div class="business_plan">
        <div
            v-if="serviceSubscriptionId"
            class="business_plan__current">
            <label>{{ $t('frontend.app.pages.business.business_plan.current_plan') }}</label>
            <div class="business_plan__current__main_info">
                <div class="business_plan__current__main_info__logo">
                    <template>
                        <div class="planTileWrapper">
                            <div
                                v-if="serviceSubscriptionName == 'Starter'"
                                class="planTile planTile__type2">
                                <div class="cube__wrapp">
                                    <div class="cube cube__front" />
                                    <div class="cube cube__back" />
                                    <div class="cube cube__right" />
                                    <div class="cube cube__left" />
                                    <div class="cube cube__top" />
                                    <div class="cube cube__bottom" />
                                </div>
                            </div>
                            <div
                                v-if="serviceSubscriptionName == 'Pro' || serviceSubscriptionName == 'Premium'"
                                class="planTile planTile__type3">
                                <div class="cube__wrapp">
                                    <div class="cube cube__front" />
                                    <div class="cube cube__back" />
                                    <div class="cube cube__right" />
                                    <div class="cube cube__left" />
                                    <div class="cube cube__top" />
                                    <div class="cube cube__bottom" />
                                </div>
                            </div>
                            <div
                                v-if="serviceSubscriptionName == 'Partner' || serviceSubscriptionName == 'Professional'"
                                class="planTile planTile__type4">
                                <div class="cube__wrapp">
                                    <div class="cube cube__front" />
                                    <div class="cube cube__back" />
                                    <div class="cube cube__right" />
                                    <div class="cube cube__left" />
                                    <div class="cube cube__top" />
                                    <div class="cube cube__bottom" />
                                </div>
                            </div>
                            <div
                                v-if="serviceSubscriptionName == 'Enterprise'"
                                class="planTile planTile__type5">
                                <div class="cube__wrapp">
                                    <div class="cube cube__front" />
                                    <div class="cube cube__back" />
                                    <div class="cube cube__right" />
                                    <div class="cube cube__left" />
                                    <div class="cube cube__top" />
                                    <div class="cube cube__bottom" />
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
                <div class="business_plan__current__main_info__description">
                    <p class="fs__18 color__h2 padding-b__5 lh__xl text__bold">
                        {{ serviceSubscriptionName }}
                        <span>({{ $t(`frontend.app.pages.business.business_plan.statuses.${serviceSubscriptionServiceStatus}`) }})</span>
                    </p>
                    <p class="fs__15 padding-b__5 lh__xl">
                        {{ serviceSubscriptionDescription }}
                    </p>
                    <p class="fs__13 color__secondary lh__l">
                        {{ $t('frontend.app.pages.business.business_plan.auto_renewal', {serviceSubscriptionAmount, date: dateToformat(serviceSubscription.current_period_end, 'MMMM DD, YYYY')}) }}
                    </p>
                </div>
                <div class="business_plan__current__main_info__buttons">
                    <m-btn
                        v-if="trial"
                        :disabled="activating"
                        size="s"
                        type="main"
                        @click="activateSubscription">
                        <span v-if="activating">{{ $t('frontend.app.pages.business.business_plan.activating') }}</span>
                        <span v-else>{{ $t('frontend.app.pages.business.business_plan.activate') }}</span>
                    </m-btn>
                    <m-btn
                        v-if="isManuallyPayAvailable"
                        :disabled="activating"
                        size="s"
                        type="main"
                        @click="manuallyPay">
                        <span v-if="activating">{{ $t('frontend.app.pages.business.business_plan.activating') }}</span>
                        <span v-else>{{ $t('frontend.app.pages.business.business_plan.activate') }}</span>
                    </m-btn>
                    <m-btn
                        v-if="serviceSubscriptionServiceStatus !== 'pending_deactivation'"
                        size="s"
                        type="bordered"
                        @click="openCancelSubscriptionModal()">
                        {{ $t('frontend.app.pages.business.business_plan.cancel_subscription') }}
                    </m-btn>
                    <m-btn
                        v-if="serviceSubscriptionServiceStatus === 'pending_deactivation'"
                        size="s"
                        type="bordered"
                        @click="cancelDeactivation()">
                        {{ $t('frontend.app.pages.business.business_plan.cancel_deactivation') }}
                    </m-btn>
                </div>
            </div>
            <div class="business_plan__current__features">
                <div>
                    <i class="GlobalIcon-disc-space" />
                    <span v-if="serviceSubscriptionName == 'Enterprise'">
                        <b>{{ $t('frontend.app.pages.business.business_plan.unlimited') }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.storage') }}
                    </span>
                    <span v-else>
                        <template v-if="serviceSubscriptionStorage >= 1024">
                            <b>{{ serviceSubscriptionStorage/1024 }}</b>
                            {{ $t('frontend.app.pages.business.business_plan.tera_bytes') }} {{ $t('frontend.app.pages.business.business_plan.storage') }}
                        </template>
                        <template v-else>
                            <b>{{ serviceSubscriptionStorage }}</b>
                            {{ $t('frontend.app.pages.business.business_plan.giga_bayes') }} {{ $t('frontend.app.pages.business.business_plan.storage') }}
                        </template>
                    </span>
                </div>
                <div>
                    <i class="GlobalIcon-stream-video" />
                    <span v-if="serviceSubscriptionName == 'Enterprise'">
                        <b>{{ $t('frontend.app.pages.business.business_plan.over') }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.min_live') }}
                    </span>
                    <span v-else>
                        <b>{{ unlimitedOrvalue(serviceSubscriptionLiveMin) }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.min_live') }}
                    </span>
                </div>
                <div>
                    <i class="GlobalIcon-users" />
                    <span v-if="serviceSubscriptionName == 'Enterprise'">
                        <b>{{ $t('frontend.app.pages.business.business_plan.over') }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.min_interactive') }}
                    </span>
                    <span v-else>
                        <b>{{ unlimitedOrvalue(serviceSubscriptionInteractiveMin) }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.min_interactive') }}
                    </span>
                </div>
                <div>
                    <i class="GlobalIcon-play" />
                    <span v-if="serviceSubscriptionName == 'Enterprise'">
                        <b>{{ $t('frontend.app.pages.business.business_plan.over') }}</b>
                        <!-- {{ $t('frontend.app.pages.business.business_plan.min_videos') }} -->
                        {{ $t('frontend.app.pages.business.business_plan.tera_bytes') }} {{ $t('frontend.app.pages.business.business_plan.playback') }}
                    </span>
                    <span v-else>
                        <b>{{ (unlimitedOrvalue(serviceSubscriptionReplaysMin) / 1024 ) | shortNumber(false, 1) }}</b>
                        <!-- {{ $t('frontend.app.pages.business.business_plan.min_videos') }} -->
                        {{ $t('frontend.app.pages.business.business_plan.tera_bytes') }} {{ $t('frontend.app.pages.business.business_plan.playback') }}
                    </span>
                </div>
                <div>
                    <i class="GlobalIcon-tv-icon" />
                    <span v-if="serviceSubscriptionName == 'Enterprise' || serviceSubscriptionName == 'Partner' || serviceSubscriptionName == 'Professional'">
                        <b>{{ $t('frontend.app.pages.business.business_plan.unlimited') }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.channels') }}
                    </span>
                    <span v-else-if="serviceSubscriptionName == 'Pro' || serviceSubscriptionName == 'Premium'">
                        <b>{{ unlimitedOrvalue(serviceSubscriptionChannels) }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.channels') }}
                    </span>
                    <span v-else>
                        <b>{{ unlimitedOrvalue(serviceSubscriptionChannels) }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.channel') }}
                    </span>
                </div>
                <div v-if="serviceSubscriptionName == 'Enterprise'">
                    <i class="GlobalIcon-user-plus" />
                    <span>
                        <b>{{ $t('frontend.app.pages.business.business_plan.unlimited') }}</b>
                        <!-- {{ $t('frontend.app.pages.business.business_plan.admins_creators', {creators_upper: $t('dictionary.creators_upper')}) }} -->
                        {{ $t('frontend.app.pages.business.business_plan.admins_creators') }}
                    </span>
                </div>
                <div v-if="serviceSubscriptionName == 'Premium'  || serviceSubscriptionName == 'Partner' || serviceSubscriptionName == 'Professional'">
                    <i class="GlobalIcon-user-plus" />
                    <span v-html="$t('frontend.app.pages.business.business_plan.count_creators_admins', {serviceSubscriptionmMnageCreators, serviceSubscriptionManageAdmins})"/>
                </div>
                <div v-if="serviceSubscriptionName == 'Pro'">
                    <i class="GlobalIcon-user-plus" />
                    <span>
                        <b>{{ unlimitedOrvalue(serviceSubscriptionMaxUsersCount) }}</b>
                        {{ $t('frontend.app.pages.business.business_plan.admin') }}
                    </span>
                </div>
            </div>
            <div
                v-if="paymentMethods.length"
                class="business_plan__current__payment_methods">
                <table>
                    <thead>
                        <tr>
                            <th>{{ $t('frontend.app.pages.business.business_plan.payment_method') }}</th>
                            <th>{{ $t('frontend.app.pages.business.business_plan.details') }}</th>
                            <th>{{ $t('frontend.app.pages.business.business_plan.expire') }}</th>
                            <th />
                        </tr>
                    </thead>
                    <tbody>
                        <tr
                            v-for="paymentMethod in paymentMethods"
                            :key="paymentMethod.id"
                            paymentMethods>
                            <td
                                class="tdWithImg"
                                data-attr="Payment Method">
                                <!-- <img :src="$img['mastercard']" alt> -->
                                {{ paymentMethod.brand }}
                            </td>
                            <td data-attr="Details">
                                Account *****{{ paymentMethod.last4 }} (USD)
                            </td>
                            <td data-attr="Expire">
                                {{ paymentMethod.exp_month }}/{{ paymentMethod.exp_year }}
                            </td>
                            <td
                                class="options text__right"
                                data-attr="">
                                <span
                                    class="margin-r__30 cursor-pointer"
                                    @click="goTo('/profile/edit_billing', true)"
                                    @click.middle="goTo('/profile/edit_billing', true)">
                                    {{ $t('frontend.app.pages.business.business_plan.remove') }}</span>
                                <m-btn
                                    sise="m"
                                    type="secondary"
                                    @click="goTo('/profile/edit_billing', true)"
                                    @click.middle="goTo('/profile/edit_billing', true)">
                                    {{ $t('frontend.app.pages.business.business_plan.change_card') }}
                                </m-btn>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
        <div
            v-else
            class="business_plan__placeholder">
            <no-plan-image />
            <span v-html="$t('frontend.app.pages.business.business_plan.no_subscription')" />
            <m-btn
                size="s"
                type="main"
                @click="goTo('/pricing')"
                @click.middle="goTo('/pricing', true)">
                {{ $t('frontend.app.pages.business.business_plan.choose_plan') }}
            </m-btn>
        </div>

        <div
            v-if="serviceSubscriptionId"
            class="business_plan__billing_history">
            <billing-history
                :plan-name="serviceSubscriptionName"
                :purchased_item_id="serviceSubscriptionId"
                purchased_item_type="StripeDb::ServiceSubscription" />
        </div>
        <cancel-modal
            ref="cancelSubscriptionModal"
            :service-subscription-id="serviceSubscriptionId" />
    </div>
</template>

<script>
import BillingHistory from '@components/business/BillingHistory.vue'
import noPlanImage from '@components/business/noPlanImage'
import CancelModal from '@components/business/CancelModal.vue'

import ServiceSubscription from '@models/ServiceSubscription'
import PaymentMethod from '@models/PaymentMethod'
import Organization from '@models/Organization'

import filters from "@helpers/filters"
import filtersv2 from "@helpers/filtersv2"

export default {
    components: {
        BillingHistory,
        noPlanImage,
        CancelModal
    },
    data() {
        return {
            serviceSubscriptionId: null,
            activating: false,
            orgSelect: false
        }
    },
    computed: {
        trial() {
            return this.serviceSubscriptionServiceStatus === 'trial'
        },
        isManuallyPayAvailable() {
            return this.serviceSubscriptionServiceStatus === 'grace' || this.serviceSubscriptionServiceStatus === 'suspended' || this.serviceSubscriptionServiceStatus === 'trial_suspended'
        },
        getOrganizationLogo() {
            if (!this.currentOrganization) return null
            return this.currentOrganization.logo_url
        },
        getOrganizationPath() {
            if (!this.currentOrganization) return null
            return location.origin + this.currentOrganization.relative_path
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        organizations() {
            return this.$store.getters["Users/organizations"]
        },
        credentialsAbility() {
            if (this.currentUser) return this.currentUser.credentialsAbility
            return null
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        serviceSubscription() {
            return ServiceSubscription.query().whereId(this.serviceSubscriptionId).first() || {}
        },
        paymentMethods() {
            return PaymentMethod.all()
        },
        serviceSubscriptionName() {
            return this.serviceSubscription?.plan?.name
        },
        serviceSubscriptionDescription() {
            return this.serviceSubscription?.plan_package?.description
        },
        serviceSubscriptionAmount() {
            return filtersv2.formattedPrice(this.serviceSubscription?.plan.amount)
        },
        serviceSubscriptionServiceStatus() {
            return this.serviceSubscription?.service_status
        },
        serviceSubscriptionStatus() {
            return this.serviceSubscription?.status
        },
        serviceSubscriptionStorage() {
            let val =  this.serviceSubscription?.features?.find((el) => {
                return el.code === 'storage'
            }).value
            return parseInt(val)
        },
        serviceSubscriptionLiveMin() {
            return this.serviceSubscription?.features?.find((el) => {
                return el.code === 'streaming_time'
            }).value
        },
        serviceSubscriptionInteractiveMin() {
            return this.serviceSubscription?.features?.find((el) => {
                return el.code === 'interactive_streaming_time'
            }).value
        },
        serviceSubscriptionReplaysMin() {
            return this.serviceSubscription?.features?.find((el) => {
                return el.code === 'transcoding_time'
            }).value
        },
        serviceSubscriptionChannels() {
            return this.serviceSubscription?.features?.find((el) => {
                return el.code === 'max_channels_count'
            }).value
        },
        serviceSubscriptionManageAdmins() {
            let manage_admins = this.serviceSubscription?.features?.find((el) => {
                return el.code === 'manage_admins'
            }).value == 'true'
            let userCount = ''
            if (manage_admins) {
                userCount = this.serviceSubscription?.features?.find((el) => {
                    return el.code === 'max_admins_count'
                }).value
            }
            return userCount == '-1' ? this.$t('frontend.app.pages.business.business_plan.unlimited') : userCount
        },
        serviceSubscriptionmMnageCreators() {
            let manage_creators = this.serviceSubscription?.features?.find((el) => {
                return el.code === 'manage_creators'
            }).value == 'true'
            let userCount = ''
            if (manage_creators) {
                userCount = this.serviceSubscription?.features?.find((el) => {
                    return el.code === 'max_creators_count'
                }).value
            }
            return userCount == '-1' ? this.$t('frontend.app.pages.business.business_plan.unlimited') : userCount
        },
        serviceSubscriptionMaxUsersCount() {
            let manage_admins = this.serviceSubscription?.features?.find((el) => {
                return el.code === 'manage_admins'
            }).value == 'true'
            let manage_creators = this.serviceSubscription?.features?.find((el) => {
                return el.code === 'manage_creators'
            }).value == 'true'
            let userCount = 0

            if (manage_admins) {
                userCount += parseInt(this.serviceSubscription?.features?.find((el) => {
                    return el.code === 'max_admins_count'
                }).value)
            }

            if (manage_creators) {
                userCount += parseInt(this.serviceSubscription?.features?.find((el) => {
                    return el.code === 'max_creators_count'
                }).value)
            }

            return userCount
        },
        serviceSubscriptionPlanId() {
            return this.serviceSubscription?.plan?.id
        }
    },
    mounted() {
        ServiceSubscription.api().current().then((data) => {
            this.serviceSubscriptionId = data.response.data.response.id
        }).catch(() => {
        })

        PaymentMethod.api().fetch()
    },
    methods: {
        cancelDeactivation() {
            ServiceSubscription.api().cancelDeactivation({id: this.serviceSubscription.id}).then(() => {
                this.$flash('Deactivation was canceled successfully', "success")
                ServiceSubscription.api().current()
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        toggleOrgSelect() {
            this.orgSelect = !this.orgSelect
        },
        setCurrentOrganization(company) {
            let result = confirm("Your current organization will be changed?")
            if (result) {
                Organization.api().setCurrentOrganization({id: company.id}).then(() => {
                    location.reload()
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
        },
        openCancelSubscriptionModal() {
            this.$refs.cancelSubscriptionModal.openModal()
        },
        closeCancelSubscriptionModal() {
            this.$refs.cancelSubscriptionModal.closeModal()
        },
        unlimitedOrvalue(value) {
            return value == '-1' || value < 0 ? 'Unlimited' : value
        },
        activateSubscription() {
            this.activating = true
            ServiceSubscription.api().activateSubscription({
                id: this.serviceSubscription.id,
                cancel_trial: 1
            }).then(() => {
                ServiceSubscription.api().current().then(() => {
                    location.reload()
                    if (this.serviceSubscriptionStatus !== 'active') {
                        // this.$flash('Activation failed')
                    } else {
                        this.$flash('Subscription was activated successfully', "success")
                    }
                }).catch((error) => {
                    if (error.response.status === 404) {
                        this.serviceSubscription.$delete()
                    }
                })
                this.closeCancelSubscriptionModal()
            }).catch((error) => {
                let message = error?.response?.data?.message
                if (message) {
                    if (message == 'This customer has no attached payment source or default payment method.') {
                        message = 'Please configure your Payment Method in menu Settings → Payments & Payouts'
                    }
                    this.$flash(message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            }).then(() => {
                this.activating = false
            })
        },
        manuallyPay() {
            this.activating = true
            ServiceSubscription.api().ManuallyPay({id: this.serviceSubscription.id}).then(() => {
                ServiceSubscription.api().current().then(() => {
                    location.reload()
                    if (this.serviceSubscriptionStatus !== 'active') {
                        // this.$flash('Activation failed')
                    } else {
                        this.$flash('Subscription was activated successfully', "success")
                    }
                }).catch((error) => {
                    if (error.response.status === 404) {
                        this.serviceSubscription.$delete()
                    }
                })
                this.closeCancelSubscriptionModal()
            }).catch((error) => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            }).then(() => {
                this.activating = false
            })
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
                this.closeCancelSubscriptionModal()
                this.$flash('Subscription was canceled successfully', "success")
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