<template>
    <transition
        name="fade"
        @after-enter="afterFadeEnter">
        <div
            v-if="show"
            class="v-modal">
            <div
                class="v-modal__backdrop"
                @click="closeModal()" />

            <transition
                name="dialogFade"
                @after-leave="afterDialogFadeLeave">
                <div
                    v-if="showDialog"
                    class="v-modal__dialog">
                    <div class="v-modal__header">
                        <slot name="header" />
                        <button
                            class="v-modal__close"
                            type="button"
                            @click="closeModal()">
                            <i class="VideoClientIcon-iPlus" />
                        </button>
                    </div>

                    <div class="v-modal__body">
                        <div class="unobtrusive-flash-container" />
                        <slot name="body" />
                    </div>

                    <div class="v-modal__footer">
                        <slot name="footer" />
                    </div>
                </div>
            </transition>
        </div>
    </transition>
</template>

<script>
export default {
    name: "Modal",
    data() {
        return {
            show: false,
            showDialog: false
        }
    },
    methods: {
        closeModal() {
            this.showDialog = false
            document.querySelector("body").classList.remove("overflow-hidden")
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


<style lang="scss" scoped>
.v-modal__close {
    color: var(--tp__main);
}

.v-modal {
    position: fixed;
    top: 0;
    right: 0;
    bottom: 0;
    left: 0;
    z-index: 1030;
    overflow-x: hidden;
    overflow-y: auto;

    &__backdrop {
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;
        background-color: rgba(0, 0, 0, 0.3);
        z-index: 1;
    }

    &__dialog {
        position: relative;
        width: 600px;
        background-color: var(--bg__content);
        border-radius: 5px;
        margin: 50px auto 80px;
        display: flex;
        flex-direction: column;
        z-index: 2;
        @media screen and (max-width: 992px) {
            width: 90%;
        }
    }

    &__close {
        width: 30px;
        height: 30px;
    }

    &__header {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        padding: 20px 20px 10px;

        .VideoClientIcon-iPlus {
            display: inline-block;
            transform: rotate(45deg);
        }
    }

    &__body {
        padding: 10px 20px 10px;
        overflow: auto;
        display: flex;
        flex-direction: column;
        align-items: stretch;
    }

    &__footer {
        padding: 10px 0;
        position: relative;
    }
}

.fade-enter-active,
.fade-leave-active {
    opacity: 1;
    transition: opacity 0.25s;
}

.fade-enter,
.fade-leave-to {
    opacity: 0;
}

.dialogFade-enter-active,
.dialogFade-leave-active {
    opacity: 1;
    transform: translateY(0px);
    transition: all 0.3s;
}

.dialogFade-enter,
.dialogFade-leave-to {
    opacity: 0;
    transform: translateY(-30px);
}
</style>

<!--  START -->
<!-- vue global modals styles  -->
<style lang="scss">
.v-modal {
    &__header {
        .title {
            color: #095F73;
            font-weight: bold;
        }
    }

    &__body {
        .modalInputs {
            width: 100%;
            display: flex;
            flex-direction: column;
            padding-bottom: 30px;

            label {
                padding-bottom: 10px;
                line-height: 13px;
                margin-bottom: 0;
            }

            input {
                padding: 0;
                font-size: 15px;
            }

            .error {
                font-size: 14px;
                color: #f23535;
            }
        }
    }

    .bodyWrapper {
        padding: 20px;
        background: rgba(9, 95, 115, 0.05);
        border: 1px solid rgba(9, 95, 115, 0.2);
        border-radius: 10px;

        &.edit {
            margin-bottom: 20px;
            padding: 20px;
            width: 100%;
            background: rgba(9, 95, 115, 0.05);
            border: 1px solid rgba(9, 95, 115, 0.2);
            border-radius: 10px;
        }

        &.remove {
            background: var(--bg__secondary);
            padding: 20px;
            border-radius: 10px;
            border-color: var(--border__content__sections);
            overflow-x: hidden;
            text-overflow: ellipsis;
        }
    }

    .modal-buttons {
        display: flex;
        justify-content: flex-end;
        position: absolute;
        top: 40px;
        right: 0;

        .btn {
            width: 100px;

            &:last-child {
                margin-left: 15px;
            }
        }

        .btn[disabled] {
            color: white !important;
            pointer-events: all !important;
        }
    }
}
</style>
<!-- vue global modals styles  -->
<!--  END -->
