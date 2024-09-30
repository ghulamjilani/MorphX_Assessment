<template>
    <div class="modal-auth-template ">
        <m-modal
            ref="demoModal"
            class="PlanInfoModal"
            @modalClosed="onModalClose">
            <div class="PlanInfoModal__wrapper">
                <div class="PlanInfoModal__leftPart">
                    <div class="subsPlansModal__Title text__bold margin-b__30">
                        Subscription Plan Info
                    </div>
                    <div class="PlanInfoModal__section1">
                        <img
                            :src="channel && channel.image_gallery_url ? channel.image_gallery_url : ''"
                            alt>
                        <div class="PlanInfoModal__section1__circle__parent">
                            <div class="PlanInfoModal__section1__circle">
                                <div class="PlanInfoModal__section1__circle__child" />
                            </div>
                        </div>
                        <span class="PlanInfoModal__section1__planName">{{ plan.im_name }}</span>
                        <div class="PlanInfoModal__section1__info">
                            <div class="PlanInfoModal__section1__info__top">
                                <div class="PlanInfoModal__section1__info__item">
                                    <i class="GlobalIcon-empty-calendar padding-r__10 fs__18" />
                                    <span v-if="plan.interval_count > 1">{{
                                        plan.interval_count + " " + plan.interval
                                    }}s</span>
                                    <span v-else>{{ plan.interval_count + " " + plan.interval }}</span>
                                </div>
                                <div
                                    v-if="plan.trial_period_days && +plan.trial_period_days !== 0"
                                    class="PlanInfoModal__section1__info__bottom text__center">
                                    <div class="PlanInfoModal__section1__info__item">
                                        <i class="GlobalIcon-check-circle padding-r__10 fs__18" />
                                        <span>{{ plan.trial_period_days }} days FREE TRIAL</span>
                                    </div>
                                </div>
                                <div v-else>
                                    <div class="PlanInfoModal__section1__info__item disabled">
                                        <i class="GlobalIcon-check-circle padding-r__10 fs__18" />
                                        <span>FREE TRIAL</span>
                                    </div>
                                </div>
                                <div class="line" />
                                <div
                                    :class="{disabled: !plan.im_livestreams}"
                                    class="PlanInfoModal__section1__info__item">
                                    <i class="GlobalIcon-stream-video padding-r__10 fs__18" />
                                    <span>Online Streams</span>
                                </div>
                                <div
                                    :class="{disabled: !plan.im_interactives}"
                                    class="PlanInfoModal__section1__info__item">
                                    <i class="GlobalIcon-users padding-r__10 fs__18" />
                                    <span>Interactive Sessions</span>
                                </div>
                                <div
                                    :class="{disabled: !plan.im_replays}"
                                    class="PlanInfoModal__section1__info__item">
                                    <i class="GlobalIcon-play padding-r__10 fs__18" />
                                    <span>Replays</span>
                                </div>
                                <div
                                    :class="{disabled: !plan.im_uploads}"
                                    class="PlanInfoModal__section1__info__item">
                                    <i class="GlobalIcon-upload padding-r__10 fs__18" />
                                    <span>Uploads</span>
                                </div>
                                <div
                                    class="PlanInfoModal__section1__info__item"
                                    :class="{ disabled: !plan.im_channel_conversation }">
                                    <i class="GlobalIcon-message-square padding-r__10 fs__18" />
                                    <span>{{ $t('frontend.app.components.modals.payment.include_channel_conversation') }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="PlanInfoModal__section2">
                        <div>
                            <i class="GlobalIcon-gift padding-r__10 fs__18" />
                            <span class="text__bold fs__16">Gift subscription for a friend</span>
                        </div>
                        <m-input
                            v-model="emailGift"
                            :disabled="isGift === 1"
                            :pure="true"
                            placeholder="Enter recipient email" />
                        <m-btn
                            class="full__width borderredButton"
                            size="s"
                            type="bordered"
                            @click="sendGift">
                            Confirm email
                        </m-btn>
                    </div>
                    <span v-if="giftSuccess">You are buying a {{ plan.interval_count + " " + plan.interval }}
                        gift subscription plan for {{ giftName }} ({{ emailGift }}) <br></span>
                    <span
                        v-if="giftError !== ''"
                        class="PlanInfoModal__gift-error">{{ giftError }} <br></span>
                    *Trial period is not included with gift subscriptions
                </div>

                <m-form
                    v-model="disabled"
                    :form="cardInfo"
                    class="PlanInfoModal__rightPart"
                    @onSubmit="submit">
                    <div class="subsPlansModal__Title text__bold">
                        Payment Method
                    </div>
                    <div class="PlanInfoModal__disabledButton">
                        Credit Card
                    </div>
                    <template v-if="((cards && cards.length > 0) && !addingCard)">
                        <m-select
                            v-model="choosenCard"
                            :options="cards" />
                        <m-btn
                            tag="div"
                            @click.prevent="toggleAddingCard">
                            {{ $t('frontend.app.components.modals.payment.add_card') }}
                        </m-btn>
                    </template>
                    <template v-else>
                        <m-btn
                            v-if="cards && cards.length > 0"
                            class="subsPlansModal__savedCard"
                            tag="div"
                            @click.prevent="toggleAddingCard">
                            {{ $t('frontend.app.components.modals.payment.saved_card') }}
                        </m-btn>

                        <div id="stripe-card-element">
                            <!-- A Stripe Element will be inserted here. -->
                        </div>
                        <!-- <m-input :pure="true" placeholder="Card number" /> -->
                        <m-input
                            v-model="cardInfo.name"
                            :pure="true"
                            class="CardNameInput"
                            placeholder="Name on Card*"
                            rules="required" />
                        <div class="PlanInfoModal__rightPart__flexInputs">
                            <m-select
                                v-model="cardInfo.country"
                                :options="options"
                                label="Country*" />
                            <m-input
                                v-if="isNeedToShowZip"
                                v-model="cardInfo.zip"
                                :pure="true"
                                placeholder="Zip Code*"
                                rules="required" />
                        </div>
                    </template>
                    <div class="PlanInfoModal__rightPart__label">
                        <!-- BROKEN SECTION -->
                        <!--<b>{{plan.formatted_price}}</b> per month billed annually-->
                        <!--<b v-if="plan.trial_period_days && +plan.trial_period_days !== 0">-->
                        <!--after {{plan.trial_period_days}} days free trial-->
                        <!--</b>-->
                    </div>
                    <div class="PlanInfoModal__rightPart__table">
                        <div class="margin-b__10">
                            <span>Price</span>
                            <b>{{ plan.formatted_price }}</b>
                        </div>
                        <div class="margin-b__15">
                            <span>Tax</span>
                            <b>$0</b>
                        </div>
                        <div class="PlanInfoModal__rightPart__table__bottom">
                            <b>Total amount</b>
                            <b>{{ plan.formatted_price }}</b>
                        </div>
                    </div>
                    <m-btn
                        :disabled="(!choosenCard && disabled) || loading"
                        class="full__width margin-t__10 padding-t__5 padding-b__5"
                        size="s"
                        type="main">
                        {{ loading ? 'Processing' : 'Submit Payment' }}
                    </m-btn>
                </m-form>
            </div>
        </m-modal>
    </div>
</template>

<script>
import Channel from "@models/Channel"
import SelfSubscription from "@models/SelfSubscription"
import countries from "@utils/countries"
import PaymentMethod from "@models/PaymentMethod"

export default {
    name: "PlanInfo",
    data() {
        return {
            // mode: "planInfo",
            subscription: {},
            plan: {},
            options: countries,
            emailGift: "",
            isGift: 0,
            giftSuccess: false,
            giftError: "",
            giftName: "",
            model: null,
            stripe: null,
            card: null,
            cardInfo: {
                name: "",
                country: "US",
                zip: ""
            },
            disabled: true,
            loading: false,
            channel: null,
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
            return window.ConfigGlobal.stripe.public_key
        },
        isNeedToShowZip() {
            let zipCountries = ["US"]
            return zipCountries.includes(this.cardInfo.country)
        }
    },
    watch: {
        currentUser() {
            this.checkPaymentMethods()
        }
    },
    mounted() {
        this.$eventHub.$on("open-modal:planInfo", (plan, subscription, channel) => {
            this.channel = channel
            this.subscription = subscription
            this.plan = plan
            this.giftName = ""
            this.emailGift = ""
            this.giftSuccess = false
            this.isGift = 0
            this.cardInfo = {
                name: "",
                country: "US",
                zip: ""
            }
            if(this.currentUser?.country && this.currentUser?.country != "")
                this.cardInfo.country = this.currentUser.country
            this.open()
        })
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })

        this.checkPaymentMethods()
    },
    methods: {
        open() {
            this.$refs.demoModal.openModal()
            if(this.cards.length == 0) {
                setTimeout(() => {
                    this.initStripe()
                }, 1000)
            }
        },
        close() {
            if (this.$refs.demoModal) this.$refs.demoModal.closeModal()
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
            card.mount('#stripe-card-element')
            this.stripe = stripe
            this.card = card
        },
        async submit() {
            this.loading = true
            // todo: await if choosenCard
            let result = {}
            if(!this.choosenCard) result = await this.stripe.createToken(this.card)
            if (result.error) {
                this.loading = false
                this.$flash(result.error.message, "error")
            } else {
                // Send the token to your server.
                let model = {}
                if(this.choosenCard) {
                    model = {
                        stripe_token: this.choosenCard,
                        plan_id: this.plan.id,
                    }
                }
                else {
                    model = {
                        stripe_token: result.token ? result.token.id : result.id,
                        plan_id: this.plan.id,
                        country: this.cardInfo.country,
                        zip_code: this.cardInfo.zip
                    }
                }
                if (this.isGift === 1) {
                    model['gift'] = 1
                    model['recipient'] = this.emailGift
                }
                Channel.api().SubscribeByPlan(model).then(res => {
                    if(res.response.data.response.service_status !== "deactivated") {
                        if (this.isGift === 1) {
                            this.$flash(`Successfully purchased gift subscription for ${this.emailGift} to ${this.plan.im_name}`, "success")
                        } else {
                            SelfSubscription.api().getSubscriptions()
                            this.$eventHub.$emit("channel-subscribed")
                            this.$flash(`Successfully subscribed to ${this.plan.im_name}`, "success")
                        }
                        this.emailGift = ""
                        this.giftSuccess = false
                        this.isGift = 0
                        this.loading = false
                        this.$eventHub.$emit("SubscriptionsPlanModal:subscribed")
                        this.close()
                    }
                    else {
                        this.$flash("Payment failed")
                        this.loading = false

                        if (this.isGift !== 1) {
                            SelfSubscription.api().getSubscriptions()
                        }
                    }
                }).catch((error) => {
                    this.loading = false
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
                // stripeTokenHandler(result.token);
            }
        },
        sendGift() {
            SelfSubscription.api().checkEmail({id: this.subscription.id, email: this.emailGift}).then(res => {
                this.giftError = ""
                this.giftSuccess = res.response.data.response.is_valid
                if (this.giftSuccess) {
                    this.isGift = 1
                    this.giftName = res.response.data.response.name
                } else {
                    this.giftError = res.response.data.response.message
                }
            })
        },
        toggleAddingCard() {
            if(!this.addingCard) {
                this.addingCard = true
                this.choosenCard = null
                setTimeout(() => {
                    this.initStripe()
                }, 1000)
            }else {
                this.addingCard = false
                this.choosenCard = this.defaultCard
            }
        },
        onModalClose() {
            this.addingCard = false
            this.choosenCard = this.defaultCard
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
                })
            }
        }
    }
}
</script>
