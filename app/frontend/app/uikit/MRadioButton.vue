<template>
    <!-- TODO: andrey check padding for text -->
    <label class="radioMK2 container">
        <slot />
        <input
            v-model="checked"
            :value="val"
            type="radio"
            :disabled="disabled"
            @change="change">
        <span class="checkmark" />
    </label>
</template>

<script>
/**
 * @displayName Radio
 */
export default {
    props: {
        /**
         * @model
         */
        value: {
            type: [Boolean, Array, String, Number],
            default: false
        },
        val: {},
        disabled: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            checked: this.value
        }
    },
    watch: {
        value(val) {
            if (val !== this.checked) {
                this.checked = val
            }
        }
    },
    methods: {
        change() {
            this.$emit("input", this.checked)
            this.$emit("change", this.checked)
        }
    }
}
</script>