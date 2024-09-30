<template>
    <label class="toggleMK2 switch">
        <slot />
        <input
            v-model="checked"
            :value="val"
            type="checkbox"
            :disabled="disabled"
            @change="change">
        <span class="slider round" />
    </label>
</template>

<script>
/**
 * @displayName Toggle
 */
export default {
    props: {
        /**
         * @model
         */
        value: {
            type: [Boolean, Array, String],
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