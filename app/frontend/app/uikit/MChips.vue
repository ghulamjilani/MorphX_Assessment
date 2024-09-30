<template>
    <!-- TODO: andrey, ilya fix -->
    <!-- TODO: ANDREY, ILYA REFACTOR THIS -->
    <!-- TODO: REFACTOR THIS !!! -->
    <div
        :class="{'chips__iconed': icon !== ''}"
        class="chips">
        <div v-if="justSlot">
            <slot />
        </div>
        <div
            v-if="!justSlot && !isPaid && !additionalSettings"
            class="chips__label">
            <slot />
        </div>
        <div
            v-if="isPaid && !isunite"
            class="chips__dollar">
            $
        </div>

        <!-- unite PPV, Subscribers,  -->
        <div
            v-if="!(showFreeLabel && free && !membershipFrom) && isunite && membershipFrom"
            class="chips__label chips__label__margin0 memberLevel">
            Member
        </div>

        <div
            v-if="isunite && (
                (isPaid && !only_ppv && !only_subscription) ||
                (isPaid && only_ppv && !only_subscription)
            )"
            class="chips__dollar">
            $
        </div>

        <!-- / unite PPV, Subscribers,  -->



        <div
            v-if="icon !== ''"
            class="chips__icon"
            @click="iconClick">
            <m-icon>{{ icon }}</m-icon>
        </div>
        <div
            v-if="!justSlot && isPaid && !isunite"
            class="sessionCost-tooltip fs-12">
            <div class="chips__dollar__price">
                <div
                    v-if="subscribeFrom && buy > 0"
                    class="chips__dollar__price__row">
                    Buy: <span>${{ buy }}</span>
                </div>
                <div
                    v-if="subscribeFrom && participate > 0"
                    class="chips__dollar__price__row">
                    Participate: <span>${{ participate }}</span>
                </div>
                <div
                    v-if="!subscribeFrom"
                    class="chips__dollar__price__row">
                    To see this content please contact channel owner
                </div>
            </div>
        </div>

        <!-- unite PPV, Subscribers,  -->
        <div
            v-if="!justSlot && isunite"
            class="sessionCost-tooltip fs-12"
            :class="{'sessionCost-tooltip__long': subscribeFrom && membershipFrom}">
            <div class="chips__dollar__price">
                <div
                    v-if="subscribeFrom && isPaid"
                    class="chips__dollar__price__row">
                    Buy: <span>${{ buy }}</span>
                </div>
                <div
                    v-if="subscribeFrom && membershipFrom"
                    class="chips__dollar__price__row">
                    Membership from: <span>{{ subscribeFrom }}</span>
                </div>
                <div
                    v-if="!subscribeFrom"
                    class="chips__dollar__price__row">
                    To see this content please contact channel owner
                </div>
            </div>
        </div>
        <!-- / unite PPV, Subscribers,  -->
    </div>
</template>

<script>
export default {
    name: "MChips",
    props: {
        buy: {
            type: Number,
            default: 0
        },
        participate: {
            type: Number,
            default: 0
        },
        icon: {
            type: String,
            default: ""
        },
        justSlot: {
            type: Boolean,
            default: false
        },
        additionalSettings: Object
    },
    computed: {
        isPaid() {
            if (this.buy > 0 || this.participate > 0) return true
            return false
        },
        isunite() {
            return this.$railsConfig.global.project_name.toLowerCase() === "unite"
        },
        free() {
            return !this.isPaid
        },
        showFreeLabel() {
            return this.$railsConfig.frontend?.tiles?.video_tile?.free_label
        },
        only_ppv() {
            return this.additionalSettings?.only_ppv
        },
        only_subscription() {
            return this.additionalSettings?.only_subscription
        },
        subscribeFrom() {
            return this.additionalSettings?.subscribeFrom
        },
        membershipFrom() {
            return (this.free && !this.only_ppv && this.only_subscription) ||
                (this.isPaid && !this.only_ppv && this.only_subscription) ||
                (this.isPaid && this.only_ppv && this.only_subscription)
        }
    },
    methods: {
        iconClick() {
            this.$emit("iconClick")
        }
    }
}
</script>