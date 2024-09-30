<template>
    <div class="modal-auth-template ">
        <m-modal
            ref="bookingPaymentModal"
            class="BookingPayment"
            @modalClosed="onModalClose">
            <div class="BookingPayment__wrapper">
                <div class="BookingPayment__leftPart">
                    <div class="subsPlansModal__Title text__bold margin-b__30">
                        Booking Payment
                    </div>
                    <div
                        v-if="booking && booking.owner && booking.bookingSlot"
                        class="BookingPayment__top">
                        <!--TODO: Ready for component 'avatar'-->
                        <div class="avatar avatar__xl">
                            <div class="bookingLabel__wrapper avatar__img__wrapper">
                                <i
                                    v-tooltip="'This Creator available for Booking'"
                                    class="bookingLabel bookingLabel__l GlobalIcon-calendar" />
                                <img
                                    v-tooltip="booking.owner.public_display_name"
                                    class="avatar__img"
                                    :alt="booking.owner.public_display_name"
                                    :src="booking.owner.avatar_url">
                            </div>
                            <div class="avatar__name">
                                {{ booking.owner.public_display_name }}
                            </div>
                        </div>

                        <div class="BookingPayment__top__info">
							<div class="BookingPayment__top__info__label">
								Private Booked Session
								<br>
								{{ booking.bookingSlot.name }}
								<div>
									<span>${{ priceToShow }}</span>
								</div>
							</div>
                            <div class="BookingPayment__top__info__top">
                                <div class="BookingPayment__top__info__item">
                                    <span>
                                        <i class="GlobalIcon-empty-calendar" />
                                    </span>
                                    {{ booking.date.date }}
                                </div>
                                <div class="BookingPayment__top__info__item">
                                    <span>
                                        <i class="GlobalIcon-clock" />
                                    </span>
                                    {{ booking.duration.duration }} min.
                                </div>
                                <div
                                    v-if="booking.bookingSlot.replay"
                                    class="BookingPayment__top__info__item">
                                    <span>
                                        <i class="GlobalIcon-play" />
                                    </span>
                                    Include Replays
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <m-form
                    v-if="booking && booking.owner && booking.bookingSlot"
                    v-model="disabled"
                    :form="cardInfo"
                    class="BookingPayment__rightPart"
                    @onSubmit="submit">
                    <div class="subsPlansModal__Title text__bold">
                        Payment Method
                    </div>
                    <div class="BookingPayment__disabledButton">
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
                        <div class="BookingPayment__rightPart__flexInputs">
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
                    <div class="BookingPayment__rightPart__label">
                        <!-- BROKEN SECTION -->
                        <!--<b>{{plan.formatted_price}}</b> per month billed annually-->
                        <!--<b v-if="plan.trial_period_days && +plan.trial_period_days !== 0">-->
                        <!--after {{plan.trial_period_days}} days free trial-->
                        <!--</b>-->
                    </div>
                    <div class="BookingPayment__rightPart__table">
                        <div class="margin-b__10">
                            <span>Price</span>
                            <b>${{ priceToShow }}</b>
                        </div>
                        <div class="margin-b__15">
                            <span>Tax</span>
                            <b>$0</b>
                        </div>
                        <div class="BookingPayment__rightPart__table__bottom">
                            <b>Total amount</b>
                            <b>${{ priceToShow }}</b>
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
import countries from "@utils/countries"
import PaymentMethod from "@models/PaymentMethod"
import Booking from "@models/Booking"

export default {
    name: "BookingPayment",
    data() {
        return {
            options: countries,
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
            cards: null,
            choosenCard: null,
            addingCard: false,
            defaultCard: null,
            booking: null
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
        },
        priceToShow() {
            return parseFloat(this.booking.price_cents/100).toFixed(2)
        }
    },
    watch: {
        currentUser() {
            this.checkPaymentMethods()
        }
    },
    mounted() {
        this.$eventHub.$on("open-modal:bookingPayment", (booking) => {
            this.booking = booking
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
            this.$refs.bookingPaymentModal.openModal()
            if(this.cards.length == 0) {
                setTimeout(() => {
                    this.initStripe()
                }, 1000)
            }
        },
        close() {
            if (this.$refs.bookingPaymentModal) this.$refs.bookingPaymentModal.closeModal()
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
                        stripe_card: this.choosenCard
                    }
                }
                else {
                    model = {
                        stripe_token: result.token ? result.token.id : result.id,
                        country: this.cardInfo.country,
                        zip_code: this.cardInfo.zip
                    }
                }

                model.booking_slot_id = this.booking.bookingSlot.id
                model.duration = this.booking.duration.duration
                model.price_id = this.booking.duration.id
                let start = window.moment.tz(this.booking.date.date + " " + this.booking.date.time, this.currentUser.timezone)
                let end = window.moment.tz(this.booking.date.date + " " + this.booking.date.time, this.currentUser.timezone)
                end.add(this.booking.duration.duration, "minutes")
                model.start_at = start.format()
                model.end_at = end.format()
                model.comment = this.booking.comment
                model.price_cents = this.booking.price_cents

                Booking.api().createBook({booking: model}).then(res => {
                    console.log(res)
                    // this.$eventHub.$emit("close-modal:all")
                    this.$eventHub.$emit("booking:created", res.response.data)
                    this.$flash("Booked!", "success")
                    this.loading = false
                    this.close()
                }).catch((error) => {
                    this.$eventHub.$emit('payment-failed')
                    this.loading = false
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
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
