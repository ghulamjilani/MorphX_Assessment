<template>
    <div
        :class="{'Mloader__white' : white, 'Mloader__dark' : dark}"
        :style="{transform: global ? 'translate(-50%, -50%) scale(' + currentSize + ')' : ''}"
        class="Mloader">
        <img
            :src="$img['logo_small']"
            class="Mloader__image">
        <div class="Mloader__bg" />
    </div>
</template>

<script>
/**
 * @example ./docs/mloader.md
 */
export default {
    props: {
        size: {
            type: String,
            default: 'm'
        },
        white: {
            type: Boolean,
            default: false
        },
        dark: {
            type: Boolean,
            default: false
        },
        global: {
            type: Boolean,
            default: true
        }
    },
    computed: {
        currentSize() {
            if (this.size == "s") return 0.5
            if (this.size == "m") return 1
            if (this.size == "l") return 1.5
        }
    }
}
</script>