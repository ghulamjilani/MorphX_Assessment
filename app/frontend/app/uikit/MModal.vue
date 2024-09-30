<template>
    <transition
        name="fade"
        @after-enter="afterFadeEnter">
        <div
            v-if="show"
            class="MK2-modal">
            <div
                class="MK2-modal__backdrop"
                @click="closeModal(true)" />

            <transition
                name="dialogFade"
                @after-leave="afterDialogFadeLeave">
                <div v-if="showDialog">
                    <div class="MK2-modal__dialog">
                        <span
                            v-if="close"
                            class="GlobalIcon-clear MK2-modal__close"
                            @click="closeModal(false)" />
                        <div class="MK2-modal__header">
                            <!-- @slot Use this slot header -->
                            <slot name="header" />
                        </div>

                        <div class="MK2-modal__body">
                            <!-- @slot Use this slot body -->
                            <slot />
                        </div>

                        <div class="MK2-modal__footer">
                            <!-- @slot Use this slot footer -->
                            <slot name="footer" />
                        </div>
                    </div>
                    <slot name="black_footer" />
                </div>
            </transition>
        </div>
    </transition>
</template>

<script>
/**
 * The only true modal.
 * @example ./docs/mmodal.md
 * @displayName Modal
 */
export default {
    name: "MModal",
    props: {
        backdrop: {
            type: Boolean,
            default: true
        },
        textConfirm: {
            type: String,
            default: ''
        },
        confirm: {
            type: Boolean,
            default: false
        },
        close: {
            type: Boolean,
            default: true
        }
    },
    data() {
        return {
            show: false,
            showDialog: false
        }
    },
    methods: {
        closeModal(isBackdrop = false, confirmVal = true) {
            if (!this.backdrop && isBackdrop) return
            if (confirmVal && this.confirm && this.textConfirm) {
                if (confirm(this.textConfirm)) {
                    this.showDialog = false
                    document.querySelector("body").classList.remove("overflow-hidden")
                    if (document.querySelector(".MK2-modal"))
                        document.querySelector(".MK2-modal").classList.add("overflow-hidden")
                    this.$emit('modalClosed')
                } else {
                    return
                }
            }
            this.showDialog = false
            document.querySelector("body").classList.remove("overflow-hidden")
            if (document.querySelector(".MK2-modal"))
                document.querySelector(".MK2-modal").classList.add("overflow-hidden")
            this.$emit('modalClosed')
        },
        openModal() {
            this.show = true
            document.querySelector("body").classList.add("overflow-hidden")
        },
        afterFadeEnter() {
            this.showDialog = true
        },
        afterDialogFadeLeave() {
            this.show = false
        }
    }
}
</script>