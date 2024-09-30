<template>
    <div class="modal-auth-template ">
        <section v-show=" mode==='subsPlans' " />
        <m-modal
            ref="demoModal"
            class="PlansModal"
            @modalClosed="modalClosed">
            <template #header>
                <div class="PlansModal__Title text__bold">
                    {{ $t('subscriptions.plan_info.subscription_plans') }}
                </div>
            </template>
            <span
                v-if="subscription"
                class="subsDescription">
                {{ subscription.description }}
            </span>
            <div
                v-if="subscription"
                class="PlansModal__plansWrapper">
                <div
                    v-for="plan in subscription.plans"
                    :key="plan.id"
                    class="PlansModal__planItem">
                    <!-- add class recommended if that's recommended plan-->
                    <!-- <div class="PlansModal__planItem__recommended">
          <span class="padding-r__15">Recommended</span>
          <i class="GlobalIcon-check-circle fs__18"></i>
        </div> -->
                    <div class="PlansModal__topWrapper">
                        <span class="fs__18 lh__l text__bold">{{ plan.im_name }}</span>
                        <!-- <div class="margin-t__25 margin-b__30">
            <span class="PlansModal__economy">Save up 5%</span>
            <span class="PlansModal__economy">($15.00 / per month)</span>
          </div> -->
                    </div>
                    <div class="PlansModal__listWrapper">
                        <span class="PlansModal__listWrapper__currency">{{ plan.formatted_price }}</span>
                        <div class="PlansModal__lists">
                            <div class="PlansModal__list">
                                <i class="GlobalIcon-empty-calendar" />
                                <span v-if="plan.interval_count > 1">{{
                                    plan.interval_count + " " + plan.interval + 's'
                                }}</span>
                                <span v-else>{{ plan.interval_count + " " + plan.interval }}</span>
                            </div>
                            <div
                                v-if="plan.trial_period_days && +plan.trial_period_days !== 0"
                                class="PlansModal__list underline">
                                <i class="GlobalIcon-check-circle" />
                                <span>{{
                                    $t('subscriptions.plan_info.trial_days_included', {days: plan.trial_period_days})
                                }}</span>
                            </div>
                            <div
                                v-else
                                class="PlansModal__list disabled underline">
                                <i class="GlobalIcon-check-circle" />
                                <span>{{ $t('subscriptions.plan_info.free_trial') }}</span>
                            </div>
                            <div
                                class="PlansModal__list padding-t__30"
                                :class="{ disabled: !plan.im_livestreams }">
                                <i class="GlobalIcon-stream-video" />
                                <span>{{ $t('subscriptions.plan_info.include_streams') }}</span>
                            </div>
                            <div
                                class="PlansModal__list"
                                :class="{ disabled: !plan.im_interactives }">
                                <i class="GlobalIcon-users" />
                                <span>{{ $t('subscriptions.plan_info.include_interactives') }}</span>
                            </div>
                            <div
                                class="PlansModal__list"
                                :class="{ disabled: !plan.im_replays }">
                                <i class="GlobalIcon-play" />
                                <span>{{ $t('subscriptions.plan_info.include_replays') }}</span>
                            </div>
                            <div
                                class="PlansModal__list"
                                :class="{ disabled: !plan.im_uploads }">
                                <i class="GlobalIcon-upload" />
                                <span>{{ $t('subscriptions.plan_info.include_uploads') }}</span>
                            </div>
                            <div
                                class="PlansModal__list"
                                :class="{ disabled: !plan.im_channel_conversation }">
                                <i class="GlobalIcon-message-square" />
                                <span>{{ $t('subscriptions.plan_info.include_channel_conversation') }}</span>
                            </div>
                        </div>
                        <m-btn
                            class="margin-t__30 full__width"
                            size="s"
                            type="bordered"
                            @click="openPlan(plan, subscription)">
                            Buy
                        </m-btn>
                    </div>
                </div>
            </div>
        </m-modal>
    </div>
</template>

<script>

export default {
    name: "SubscriptionPlans",
    props: {
        // subscription: {}
    },
    data() {
        return {
            mode: "subsPlans",
            subscription: null,
            channel: null
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })
        this.$eventHub.$on("open-modal:subscriptionPlans", (subscription, channel = null) => {
            this.subscription = subscription
            this.channel = channel
            this.$nextTick(() => {
                location.hash = "#subscription_plans"
            })
            this.open()
        })
    },
    methods: {
        open() {
            this.$refs.demoModal.openModal()
        },
        close() {
            if (this.$refs.demoModal) this.$refs.demoModal.closeModal()
            this.subscription = null
            this.modalClosed()
        },
        capitalizeFirstLetter(string) {
            return string.charAt(0).toUpperCase() + string.slice(1)
        },
        openPlan(plan, subscription) {
            this.close()
            if (this.currentUser) {
                this.$eventHub.$emit("open-modal:planInfo", plan, subscription, this.channel)
            } else {
                this.$eventHub.$emit("open-modal:auth", "sign-up", {
                    action: "close-and-emit-subscribe",
                    event: "open-modal:planInfo",
                    data: {
                        plan, subscription, channel: this.channel
                    }
                })
            }
        },
        modalClosed() {
            // location.hash = "" destroy everything
            history.pushState("", document.title, window.location.pathname + window.location.search)
        }
    }
}
</script>
