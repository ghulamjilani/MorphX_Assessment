<template>
    <div
        :class="className"
        class="cardMK2">
        <div class="cardMK2__top">
            <!-- @slot Top\Left part -->
            <slot name="top" />
        </div>
        <div class="cardMK2__bottom">
            <!-- @slot Bottom\Right part -->
            <slot name="bottom" />
        </div>
    </div>
</template>

<script>
/**
 * @example ./docs/mcard.md
 * @displayName Card
 */
export default {
    props: {
        /**
         * @values horizontal, vertical
         */
        orientation: {
            type: String,
            default: 'vertical'
        },
        /**
         * Size of card
         */
        size: {
            type: String,
            default: "medium"
        }
    },
    data() {
        return {}
    },
    computed: {
        className() {
            let name = "cardMK2__" + this.orientation
            name += " cardMK2__" + this.orientation + "__" + this.size
            return name
        }
    }
}
</script>