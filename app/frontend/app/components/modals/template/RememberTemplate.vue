<template>
    <div class="modal-auth-template ForgotPassword">
        <div class="ForgotPassword__title text__center fs__20">
            {{ $t('forgot_password.enter_email') }} <br> {{ $t('forgot_password.rez_link') }}
        </div>
        <m-form
            ref="forgotPassword"
            v-model="disabled"
            :form="user"
            @onSubmit="remember">
            <m-input
                v-model="user.email"
                :errored="error && disabled"
                :placeholder="$t('forgot_password.email')"
                :pure="true"
                :required="true"
                rules="required|email"
                type="email" />
            <m-btn
                :disabled="disabled || forceDisabled"
                :full="true"
                class="fs__17 margin-t__30 margin-b__30"
                size="l">
                {{ error && disabled ? $t("forgot_password.no_found") : $t('forgot_password.send_link') }}
            </m-btn>
        </m-form>
        <div class="text__center ForgotPassword__toggleButton">
            <a
                :full="true"
                class="fs__16 header__toggleModalsButton"
                @click.prevent="openLogin">{{ $t('forgot_password.back') }}</a>
        </div>
    </div>
</template>

<script>
import User from "@models/User"

export default {
    data() {
        return {
            mode: "with-email",
            user: {
                email: ""
            },
            disabled: true,
            forceDisabled: false,
            error: false
        }
    },
    watch: {
        "user.email": {
            handler(val) {
                if(val.length > 0) {
                    this.$refs.forgotPassword.checkObserver()
                    this.error = false
                    this.forceDisabled = false
                }
            }
        }
    },
    methods: {
        openLogin() {
            this.$emit("change", "login")
        },
        open() {
            this.$refs.rememberModal.openModal()
        },
        remember() {
            User.api().rememberPassword({user: this.user}).then(res => {
                this.$flash(this.$t('forgot_password.instructions'), "success")
                this.user.email = ""
                this.$refs.forgotPassword.$refs.observer.reset()
                this.$nextTick(() => {
                    this.forceDisabled = true
                    this.$eventHub.$emit("close-modal:auth")
                })
            }).catch(error => {
                this.disabled = true
                this.error = true
            })
        }
    }
}
</script>
