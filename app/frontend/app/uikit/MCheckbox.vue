<template>
    <label
        :class="{disabled: disabled && !disabledWithNormalStyle}"
        class="checkboxMK2"
        @click="() => $emit('click')">
        {{ text }}
        <slot />
        <input
            v-model="checked"
            :disabled="disabled"
            :value="val"
            class="checkboxMK2__input"
            type="checkbox"
            @change="change">
        <span class="checkboxMK2__checkmark"><i class="checkboxMK2__icon" :class="icon" /></span>
    </label>
</template>

<script>
/**
 * @displayName Checkbox
 * @example ./docs/mcheckbox.md
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
        },
        disabledWithNormalStyle: {
            type: Boolean,
            default: false
        },
        text: {
            type: String
        },
        icon: {
            type: String,
            default: "GlobalIcon-check"
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
        }
    }
}
</script>