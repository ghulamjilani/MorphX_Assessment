<template>
    <div class="restorePassword">
        <div class="restorePassword__banner__wrapper">
            <div class="restorePassword__banner">
                <div class="restorePassword__image__wrapper">
                    <imageSvg class="restorePassword__image" />
                    <div class="restorePassword__banner__title">
                        {{ $t('restore_password.reset_pass') }}
                    </div>
                </div>
            </div>
        </div>
        <div class="restorePassword__form__wrapper">
            <div class="restorePassword__form">
                <div class="restorePassword__form__title">
                    {{ $t('restore_password.change_pass') }}
                </div>
                <m-form v-model="disabled">
                    <m-strong-password
                        v-model="form.password"
                        :label="$t('restore_password.new_pass')"
                        :maxlength="128"
                        :pure="false"
                        :pure-placeholder="true"
                        class="restorePassword__form__inputs"
                        field-id="password"
                        rules="required|passwordStrength"
                        size-icon="1.8rem"
                        @enter="enterPassword" />
                    <m-password
                        v-model="form.password_confirmation"
                        :errored="errorRestore"
                        :errors="false"
                        :label="$t('restore_password.rep_pass')"
                        :maxlength="128"
                        :pure-label="false"
                        class="restorePassword__form__inputs restorePassword__form__rep"
                        field-id="password_confirmation"
                        size-icon="1.8rem"
                        @enter="enterPasswordConf" />
                    <div
                        v-if="errorRestore"
                        class="input__field__bottom__errors restorePassword__errors">
                        {{ $t('restore_password.incorrect_pass') }}
                    </div>
                </m-form>
                <m-btn
                    :disabled="disabled || errorRestore"
                    class="restorePassword__form__button"
                    @click="send">
                    {{ $t('restore_password.change_pass') }}
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
import {setCookie} from "@utils/cookies"

import imageSvg from './imageSvg.vue'

import User from '@models/User'

export default {
    components: {imageSvg},
    data() {
        return {
            pass_confirm: null,
            pass: null,
            form: {
                password: "",
                password_confirmation: "",
                reset_password_token: null
            },
            errorRestore: false,
            disabled: false,
            user: {
                email: '',
                password: ''
            }
        }
    },
    watch: {
        form: {
            handler(val) {
                if (this.form.password_confirmation != this.form.password) {
                    this.errorRestore = true
                } else {
                    this.errorRestore = false
                }
            },
            deep: true
        }
    },
    mounted() {
        this.form.reset_password_token = this.$route.query.reset_password_token
        this.$nextTick(() => {
            this.pass_confirm = document.getElementById('password_confirmation')
            this.pass = document.getElementById('password')
        })
    },
    methods: {
        enterPassword() {
            if (this.pass.classList == '' && this.form.password) this.pass_confirm.focus()
        },
        enterPasswordConf() {
            if (this.pass_confirm.classList == '' && this.form.password_confirmation) this.send()
        },
        send() {
            User.api().updateUser(this.form).then((res) => {
                this.$flash(this.$t('restore_password.changed_pass'), 'success')
                this.user.email = res.response.data.response.user.email
                this.user.password = this.form.password
                this.login()
            }).catch(error => {
                this.$flash(this.$t('restore_password.invalid_token'))
            })
        },
        login() {
            User.api().login(this.user).then(res => {
                setCookie("_unite_session_jwt", res.response.data.response.jwt_token, +(parseJwt(res.response.data.response.jwt_token)?.exp + '000'))
                setCookie("_cable_jwt", res.response.data.response.jwt_token, +(parseJwt(res.response.data.response.jwt_token)?.exp + '000'), location.hostname)
                setCookie("_unite_session_jwt_refresh", res.response.data.response.jwt_token_refresh, +(parseJwt(res.response.data.response.jwt_token_refresh)?.exp + '000'))
                localStorage.setItem("_unite_session_jwt_refresh", res.response.data.response.jwt_token_refresh)
                this.$store.dispatch("Users/setCurrents", res.response.data.response)
                User.api().currentUser().then(res => {
                    this.$store.dispatch("Users/setCurrents", res.response.data.response)
                    this.goTo('/')
                })
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash(this.$t('restore_password.error'))
                }
            })
        }
    }
}
</script>