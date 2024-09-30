<template>
    <div
        class="confirm trigger"
        @click="open">
        <slot>
            <button class="btn btn-l btn-borderred-light">
                Confirm
            </button>
        </slot>
    </div>
</template>

<script>
export default {
    props: {
        title: {type: String, default: 'Confirm'},
        body: {type: String, default: 'Are you sure?'}
    },
    methods: {
        open() {
            this.$eventHub.$emit("open-modal", {
                className: 'ConfirmModal withLightBody withOuterFooter',
                title: this.title,
                body: this.body,
                actions: {
                    ok: {name: 'Confirm', action: this.confirm}
                }
            })
        },
        confirm() {
            this.$emit('onConfirm')
        }
    }
}
</script>
