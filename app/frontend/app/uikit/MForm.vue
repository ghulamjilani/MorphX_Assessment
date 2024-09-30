<template>
    <validation-observer
        ref="observer"
        v-slot="{ handleSubmit, invalid }">
        <form
            :data-invalid="isInvalid(invalid)"
            @submit.prevent="handleSubmit(onSubmit)"
            @keypress.enter="() => { $emit('enterPressed') }">
            <slot />
        </form>
    </validation-observer>
</template>

<script>
/**
 * @example ./docs/mform.md
 * @displayName Form
 */
export default {
    props: {
        form: {}
    },
    data() {
        return {
            invalid: false
        }
    },
    watch: {
        invalid(val) {
            this.$emit("input", val)
        }
    },
    methods: {
        isInvalid(invalid) {
            this.invalid = invalid
            return this.invalid
        },
        onSubmit() {
            this.$emit("onSubmit")
        },
        observerReset() {
            this.$refs.observer.reset()
        },
        checkObserver() {
            this.$emit("input", this.invalid)
        }
    }
}
</script>

