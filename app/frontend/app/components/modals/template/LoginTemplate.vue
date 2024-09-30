<template>
    <div class="modal-auth-template">
        <section v-show=" mode==='with-email' ">
            <div class="logo__sl margin__center margin-b__25">
                <img
                    :src="getAvatar"
                    alt="">
            </div>
            <!-- :TODO alt = userName-->
            <m-form
                v-model="disabled"
                :form="user"
                class="text__center"
                @onSubmit="login">
                <m-input
                    v-model="user.email"
                    :placeholder="$t('log_in.email')"
                    :pure="true"
                    field-id="login_email"
                    rules="required|email"
                    type="email" />
                <m-password
                    v-model="user.password"
                    :errored="errorLogin"
                    :maxlength="128"
                    :placeholder="$t('log_in.password')"
                    :pure="true"
                    class="inputWithIcon"
                    field-id="login_password"
                    rules="required|min-length:6" />
                <m-btn
                    :disabled="disabled"
                    :full="true"
                    class="header__loginSignUp margin-t__30 margin-b__30"
                    size="l"
                    tag-type="submit">
                    {{ (errorLogin && disabled) ? $t('log_in.invalid_email') : $t('log_in.log_in') }}
                </m-btn>
                <div
                    v-if="socialLoginProp.enabled"
                    :class="{'padding-b__10': guest}"
                    class="padding-t__30 padding-b__30">
                    <a
                        :full="true"
                        class="fs__16 header__toggleModalsButton"
                        @click="toggleMode">{{ $t('log_in.more_login') }}</a>
                </div>
                <div
                    v-if="guest"
                    class="padding-t__0 padding-b__30">
                    <a
                        :full="true"
                        class="fs__16 header__toggleModalsButton"
                        @click="guestLogin">{{ $t('log_in.guest') }}</a>
                </div>
            </m-form>
        </section>
        <section v-show=" mode==='with-social' ">
            <div class="padding-t__20 padding-b__20 text__center fs__28">
                {{ $t('log_in.welcome_to') }} {{ service_name }}!
            </div>
            <div v-if="socialLoginProp.enabled">
                <div v-if="socialLoginProp.facebook.enabled">
                    <div v-if="socialLoginProp.facebook.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('facebook')">
                            <img
                                :src="$img['facebookL']"
                                alt="socialName">
                            <span>{{ $t('log_in.with_facedook') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <img
                                :src="$img['facebookL']"
                                alt="socialName">
                            <span>{{ $t('log_in.with_facedook') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.gplus.enabled">
                    <div v-if="socialLoginProp.gplus.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('gplus')">
                            <img
                                :src="$img['googleL']"
                                alt="socialName">
                            <span>{{ $t('log_in.with_google') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <img
                                :src="$img['googleL']"
                                alt="socialName">
                            <span>{{ $t('log_in.with_google') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.apple.enabled">
                    <div v-if="socialLoginProp.apple.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('apple')">
                            <i class="GlobalIcon-apple" />
                            <span>{{ $t('log_in.with_apple') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-apple" />
                            <span>{{ $t('log_in.with_apple') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.instagram.enabled">
                    <div v-if="socialLoginProp.instagram.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('instagram')">
                            <i class="GlobalIcon-instagram" />
                            <span>{{ $t('log_in.with_instagram') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-instagram" />
                            <span>{{ $t('log_in.with_instagram') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.twitter.enabled">
                    <div v-if="socialLoginProp.twitter.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('twitter')">
                            <i class="GlobalIcon-twitter" />
                            <span>{{ $t('log_in.with_twitter') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-twitter" />
                            <span>{{ $t('log_in.with_twitter') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.linkedin.enabled">
                    <div v-if="socialLoginProp.linkedin.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('linkedin')">
                            <i class="GlobalIcon-linkedin" />
                            <span>{{ $t('log_in.with_linkedin') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-linkedin" />
                            <span>{{ $t('log_in.with_linkedin') }}</span>
                        </div>
                    </div>
                </div>
            </div>
            <m-btn
                :full="true"
                class="margin-t__30 margin-b__30 fs__16 text__normal"
                size="l"
                @click="toggleMode">
                {{ $t('log_in.with_email') }}
            </m-btn>
        </section>
        <div class="text__center buttonsSection">
            <span v-if="signUpProp">{{ $t('log_in.no_acc') }} <a
                href=""
                @click.prevent="openSignUp">{{ $t('log_in.sign_up') }}</a></span>
            <p class="margin__center">
                <a
                    href=""
                    @click.prevent="openRemember">{{ $t('log_in.forgot_pass') }}</a>
            </p>
        </div>
    </div>
</template>

<script>
import User from "@models/User"
import {setCookie, deleteCookie} from "@utils/cookies"
import helper from "@utils/helper"
import eventHub from "@helpers/eventHub.js"

export default {
    props: {
        signUpProp: Boolean,
        socialLoginProp: Object,
        demo: Boolean,
        afterSignAction: Object,
        guest: Boolean
    },
    data() {
        return {
            mode: "with-email",
            user: {
                email: "",
                password: ""
            },
            avatar: "",
            disabled: true,
            errorLogin: false,
            service_name: String
        }
    },
    computed: {
        getAvatar() {
            return this.avatar !== "" ? this.avatar : this.$img['male_default']
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        pageOrganization() {
            return this.$store.getters["Users/pageOrganization"]
        }
    },
    watch: {
        "user.email"(val) {
            this.callAvatar(val)
        },
        user: {
            handler(val) {
                this.errorLogin = false
            },
            deep: true
        }
    },
    mounted() {
        this.service_name = this.$railsConfig.global.service_name
    },
    methods: {
        callAvatar: helper.debounce(function (val) {
            if (val.includes('@') && val.includes('.')) {
                User.api().getAvatar({email: val}).then(res => {
                    this.avatar = res.response.data.response.url
                })
            }
        }, 400),
        openSignUp() {
            this.$emit("change", "sign-up")
        },
        openRemember() {
            this.$emit("change", "remember")
        },
        toggleMode() {
            if (this.mode === "with-email") this.mode = "with-social"
            else this.mode = "with-email"
        },
        guestLogin() {
            this.$emit("change", "guest")
        },
        login() {

            let userData = this.user

            if(window.spaMode === "monolith") {
                userData["ref_url"] = location.pathname
                if(window.Immerss?.session) {
                    userData["ref_model"] = {
                        id: window.Immerss.session.id,
                        type: "Session"
                    }
                }
                if(window.Immerss?.recording) {
                    userData["ref_model"] = {
                        id: window.Immerss.recording.id,
                        type: "Recording"
                    }
                }
                if(window.Immerss?.replay) {
                    userData["ref_model"] = {
                        id: window.Immerss.replay.id,
                        type: "Video"
                    }
                }
            } else {
                userData["ref_url"] = location.pathname
                if(this.pageOrganization) {
                    userData["ref_model"] = {
                        id: this.pageOrganization.id,
                        type: "Organization"
                    }
                }
            }

            User.api().login(userData).then(res => {
                deleteCookie('_guest_jwt')
                deleteCookie('_guest_jwt_refresh')
                setCookie("_unite_session_jwt", res.response.data.response.jwt_token, +(parseJwt(res.response.data.response.jwt_token)?.exp + '000'))
                setCookie("_cable_jwt", res.response.data.response.jwt_token, +(parseJwt(res.response.data.response.jwt_token)?.exp + '000'), location.hostname)
                setCookie("_unite_session_jwt_refresh", res.response.data.response.jwt_token_refresh, +(parseJwt(res.response.data.response.jwt_token_refresh)?.exp + '000'))
                localStorage.setItem("_unite_session_uid", parseJwt(res.response.data.response.jwt_token).id)
                localStorage.setItem("_unite_session_jwt_refresh", res.response.data.response.jwt_token_refresh)
                this.$store.dispatch("Users/setCurrents", res.response.data.response)
                this.$emit("close")
                this.$eventHub.$emit("authorization")
                User.api().currentUser().then(res => {
                    this.$store.dispatch("Users/setCurrents", res.response.data.response)
                })

                if (this.signup_token || this.afterSignAction.action == 'redirect-to-wizard') {
                    this.$emit("close")
                    if(this.$railsConfig.global.service_subscriptions?.enabled) {
                        location.href = location.origin + '/pricing'
                    } else {
                        location.href = location.origin + '/wizard/business'
                    }
                }

                if (this.afterSignAction.action == 'close-and-emit') {
                    this.$emit("close")
                    eventHub.$emit(this.afterSignAction.event, this.afterSignAction.data)
                } else if (this.afterSignAction.action == 'close-and-emit-res') {
                    this.$emit("close")
                    eventHub.$emit(this.afterSignAction.event, res.response.data.response.user)
                } else if (this.afterSignAction.action == 'close-and-reload') {
                    this.$emit("close")
                    if(this.afterSignAction.data?.link) {
                        window.open_after_signup(this.afterSignAction.data.link)
                    }
                    if(this.afterSignAction?.buy) {
                        window.open_after_signup("buy")
                    }
                    setTimeout(() => {
                        location.reload()
                    },1000)
                }
                else if(this.afterSignAction.action == 'close-and-emit-subscribe') {
                    this.$emit("close")
                    eventHub.$emit(this.afterSignAction.event,
                        this.afterSignAction.data.plan,
                        this.afterSignAction.data.subscription,
                        this.afterSignAction.data.channel)
                }
                else if(this.afterSignAction.action == 'close') {
                    this.$emit("close")
                }
                else {
                    setTimeout(() => {
                      if (this.currentUser && this.currentUser.has_memberships) {
                          this.goTo('/dashboard/sessions_presents')
                        } else if (this.currentUser && this.currentUser.can_become_a_creator) {
                            // regular user
                            // if default_location and not page with organization or recording/replay/session
                            if(res.response.data.response.current_organization?.default_location &&
                                res.response.data.response.current_organization?.membership_type == 'guest' &&
                                (!this.pageOrganization &&
                                !window.Immerss?.recording &&
                                !window.Immerss?.replay &&
                                !window.Immerss?.session)
                            ) {
                                location.href = res.response.data.response.current_organization.default_location
                            }
                            else {
                                this.$emit("close")
                                if(window.spaMode === "monolith") location.reload()
                            }
                        } else {
                            // creator
                            this.goTo('/dashboard/sessions_presents')
                        }

                    }, 1000)
                }

            }).catch(error => {
                this.errorLogin = true
                this.disabled = true
            })
        },
        socialLogin(provider) {
            this.goTo(`/users/auth/${provider}?redirect_path_after_social_signup=${location.href}`)
        }
    }
}
</script>