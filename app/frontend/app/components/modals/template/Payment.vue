<template>
    <m-form
        v-model="disabled"
        :form="cardInfo"
        @onSubmit="submit">
        <label>{{ topText }}</label>
        <div class="buyCreatorPlan__right-part__nav">
            <label class="margin-r__20">{{ $t('pricing_page.modals.credit_card') }}</label>
            <div v-if="isTrial">
                <i class="GlobalIcon-info" />
                <span class="color__secondary fs__14">{{ $t('pricing_page.modals.you_wont_be_charged') }}</span>
            </div>
        </div>
        <template v-if="((cards && cards.length > 0) && !addingCard)">
            <m-select
                v-model="choosenCard"
                :options="cards"
                :without-error="true" />
            <m-btn
                class="buyCreatorPlan__right-part__addCard"
                tag="div"
                @click="toggleAddingCard">
                {{ $t('frontend.app.components.modals.payment.add_card') }}
            </m-btn>
        </template>
        <template v-else>
            <m-btn
                v-if="cards && cards.length > 0"
                class="buyCreatorPlan__right-part__savedCard"
                tag="div"
                @click="toggleAddingCard">
                {{ $t('frontend.app.components.modals.payment.saved_card') }}
            </m-btn>

            <div :id="stripeCardElementId">
                <!-- A Stripe Element will be inserted here. -->
            </div>
            <div id="card-element-errors"
                 role="alert">
                 <!-- A Stripe Element errors will be inserted here. -->
            </div>
            <m-input
                v-model="cardInfo.name"
                :placeholder="$t('pricing_page.modals.cardholder_name')"
                :pure="true"
                class="margin-t__30"
                rules="required"
                id="cardholder_name"/>
            <div class="buyCreatorPlan__right-part__inputs">
                <m-select
                    v-model="cardInfo.country"
                    :label="$t('pricing_page.modals.country')"
                    :options="countriesOptions" />
                <m-input
                    v-if="isNeedToShowZip"
                    v-model="cardInfo.zip_code"
                    :placeholder="$t('pricing_page.modals.zip_code')"
                    :pure="true"
                    rules="required" />
            </div>
        </template>

        <div class="buyCreatorPlan__right-part__inputs buyCreatorPlan__right-part__inputs__alwaysRow">
            <m-input
                v-model="coupon"
                class="buyCreatorPlan__couponInput"
                :class="{'active': coupon == currentActivatedCoupon}"
                field-id="coupon"
                :placeholder="$t('pricing_page.modals.coupon_placeholder')"
                :pure="true"
                @enter="applyCode" />
            <m-btn
                class="buyCreatorPlan__applyButton"
                :square="true"
                :tag="'div'"
                :loading="couponLoading"
                type="bordered"
                @click="applyCode">
                {{ $t('pricing_page.modals.apply') }}
            </m-btn>
        </div>

        <div
            v-if="couponResultPrice"
            class="buyCreatorPlan__right-part__text">
            {{ $t('pricing_page.modals.coupon_activated_text_' + couponResultPrice.coupon.duration,
                  {discount: (couponResultPrice.coupon.percent_off ? couponResultPrice.coupon.percent_off + "%"
                      : formattedPrice(couponResultPrice.coupon.amount_off, purchasedItem.money_currency)), duration_in_months: couponResultPrice.coupon.duration_in_months }) }}
        </div>

        <div class="buyCreatorPlan__right-part__table">
            <!--        <div>-->
            <!--          <b>{{purchasedItem.price}}</b> per month billed annually-->
            <!--          <b v-if="purchasedItem.trial_period_days && +purchasedItem.trial_period_days !== 0">-->
            <!--            after {{purchasedItem.trial_period_days}} days free trial-->
            <!--          </b>-->
            <!--        </div>-->
            <div class="buyCreatorPlan__right-part__table__line margin-b__10 color__secondary">
                <span>{{ $t('pricing_page.modals.price') }}</span>
                <b>{{ priceLocaleString | formattedPrice(purchasedItem.money_currency) }}</b>
            </div>
            <div class="buyCreatorPlan__right-part__table__line margin-b__10 color__secondary">
                <span>{{ $t('pricing_page.modals.tax') }}</span>
                <b>$0.00</b>
            </div>
            <div
                v-if="currentActivatedCoupon"
                class="buyCreatorPlan__right-part__table__line buyCreatorPlan__right-part__table__line__hr padding-b__5 margin-b__10 color__secondary">
                <span>
                    {{ $t('pricing_page.modals.savings') }}
                    <span class="buyCreatorPlan__couponActivated">({{ $t('pricing_page.modals.coupon') }}: {{ currentActivatedCoupon }})</span>
                </span>
                <b>{{ savingsLocaleString | formattedPrice(purchasedItem.money_currency) }}</b>
            </div>
            <div class="buyCreatorPlan__right-part__table__line">
                <b>{{ $t('pricing_page.modals.total_amount') }}</b>
                <b>{{ totalLocaleString | formattedPrice(purchasedItem.money_currency) }}</b>
            </div>
        </div>
        <m-btn
            :disabled="(!choosenCard && disabled) || loading"
            class="full__width padding-t__5 padding-b__5"
            size="s"
            type="main">
            {{ loading ? 'Processing' : submitBtnText }}
        </m-btn>
    </m-form>
</template>

<script>
import countries from "@utils/countries"
import eventHub from "@helpers/eventHub.js"
import ServiceSubscription from "@models/ServiceSubscription"
import filtersv2 from "@helpers/filtersv2"
import PaymentMethod from "@models/PaymentMethod"

export default {
    props: {
        /**
         * {
         *    price: 123,
         *    trial_period_days: 123
         * }
         */
        purchasedItem: {
            type: Object
        },
        topText: {
            type: String,
            default: 'Payment Details'
        },
        submitBtnText: {
            type: String,
            default: 'Submit Payment'
        },
        vuexModel: {
            required: true
        },
        isTrial: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            stripeCardElementId: uid(),
            stripe: null,
            cardInfo: {
                name: '',
                country: 'US',
                zip_code: ''
            },
            coupon: "",
            couponLoading: false,
            currentActivatedCoupon: "",
            couponResultPrice: null,
            countriesOptions: countries,
            disabled: true,
            loading: false,
            cards: null,
            choosenCard: null,
            addingCard: false,
            defaultCard: null
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        stripe_key() {
            return this.$railsConfig.global.stripe.public_key
        },
        priceLocaleString() {
            return this.purchasedItem.price
        },
        totalLocaleString() {
            let price = this.purchasedItem.price
            if(this.couponResultPrice) {
                price = this.couponResultPrice.total
            }
            return price
        },
        savingsLocaleString() {
            if(this.couponResultPrice?.savings) {
                return this.couponResultPrice.savings
            }
            return null
        },
        isNeedToShowZip() {
            let zipCountries = ["US"]
            return zipCountries.includes(this.cardInfo.country)
        }
    },
    mounted() {
        if(this.currentUser.country && this.currentUser.country != "")
            this.cardInfo.country = this.currentUser.country

            this.checkPaymentMethods()
    },
    methods: {
        async submit() {
            this.loading = true
            let result = {}
            if(!this.choosenCard) result = await this.stripe.createToken(this.card)
            if (result.error) {
                this.loading = false
                eventHub.$emit('payment-stripe-createToken-failed', result.error)
                this.$flash(result.error.message, "error")
            } else {
                eventHub.$emit('payment-stripe-createToken-success')
                // Send the token to your server.
                let payload =  {}
                if(this.choosenCard) {
                    payload = {...{plan_id: this.purchasedItem.stripe_id}, ...{stripe_token: this.choosenCard}}
                } else {
                    payload = {...this.cardInfo, ...{plan_id: this.purchasedItem.stripe_id}, ...{stripe_token: result.token ? result.token.id : result.id}}
                }

                payload.trial = this.isTrial ? 1 : 0

                if(this.currentActivatedCoupon !== "") payload.coupon = this.currentActivatedCoupon

                this.vuexModel.api().paymentAction(payload).then(res => {
                    if(res.response.data.response.service_status !== "deactivated") {
                        eventHub.$emit('payment-success')
                        this.$flash(`Successfully subscribed to ${this.purchasedItem.name}`, "success")
                        this.loading = false
                    }
                    else {
                        this.$flash("Payment failed")
                        this.loading = false
                    }
                }).catch((error) => {
                    eventHub.$emit('payment-failed')
                    this.loading = false
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
            // }).catch(error => {
            //     console.log(error)
            //     eventHub.$emit('payment-failed')
            //     this.$flash('Something went wrong please try again later')
            //     this.loading = false
            // })
        },
        initStripe() {
            var stripe = Stripe(this.stripe_key)
            var elements = stripe.elements()
            var style = {
                base: {
                    color: window.getComputedStyle(document.body, null).getPropertyValue('color'),
                    fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
                    fontSmoothing: 'antialiased',
                    fontSize: '16px',
                    '::placeholder': {
                        color: '#aab7c4'
                    }
                },
                invalid: {
                    color: '#FF530D',
                    iconColor: '#FF530D'
                }
            }
            var card = elements.create('card', {hidePostalCode: true, iconStyle: 'solid', style: style})
            card.mount(`#${this.stripeCardElementId}`)
            this.stripe = stripe
            this.card = card
            card.on('change', function (event) {
              let displayError = document.getElementById('card-element-errors');
              if (event.error) {
                displayError.textContent = event.error.message;
              } else {
                displayError.textContent = '';
              }
            })
        },
        applyCode() {
            this.couponLoading = true
            ServiceSubscription.api().applyCoupon({
                plan_id: this.purchasedItem.stripe_id,
                coupon: this.coupon
            }).then(res => {
                this.couponLoading = false
                this.currentActivatedCoupon = this.coupon
                this.couponResultPrice = res.response.data.response
            }).catch(error => {
                this.couponLoading = false
                if(error?.response?.data?.message)
                    this.$flash(error.response.data.message)
            })
        },
        formattedPrice(amount, options) { // for i18n variable
            return filtersv2.formattedPrice(amount, options)
        },
        toggleAddingCard() {
            if(!this.addingCard) {
                this.addingCard = true
                this.choosenCard = null
                setTimeout(() => {
                    this.initStripe()
                }, 1000)
            } else {
                this.addingCard = false
                this.choosenCard = this.defaultCard
            }
        },
        checkPaymentMethods() {
            if(this.currentUser) {
                PaymentMethod.api().fetch().then(res => {
                    this.choosenCard = res.response.data.response?.default_card
                    this.defaultCard = res.response.data.response?.default_card
                    this.cards = res.response.data.response?.cards.map(card => {
                        card.name = "**** **** **** " + card.last4
                        card.value = card.id
                        return card
                    })

                    if(this.cards.length == 0) {
                        setTimeout(() => {
                            this.initStripe()
                        }, 2000)
                    }
                })
            }
        }
    }
}
</script>