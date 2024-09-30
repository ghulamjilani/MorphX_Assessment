<template>
    <div class="modal-auth-template">
        <section v-show=" mode==='with-email' ">
            <m-form
                id="signUpForm"
                ref="form"
                v-model="disabled"
                :form="user"
                @onSubmit="signUp">
                <m-input
                    v-model="user.first_name"
                    :maxlength="50"
                    :placeholder="$t('sign_up.first_n')"
                    :pure="true"
                    :rules="nameRules"
                    field-id="su_fname"
                    name="first_name" />
                <m-input
                    v-model="user.last_name"
                    :maxlength="50"
                    :placeholder="$t('sign_up.last_n')"
                    :pure="true"
                    :rules="nameRules"
                    field-id="su_lname"
                    name="last_name" />
                <m-datepicker
                    v-if="!skipGenderAndBirthday"
                    ref="birthday"
                    v-model="user.birthdate"
                    :custom-mask="{input: 'DD MMMM YYYY'}"
                    :placeholder-on-focus="'MM/DD/YYYY'"
                    :icon-calendar="true"
                    :max-date="getMaxDate"
                    :placeholder="$t('sign_up.birthday')"
                    :popover="{ visibility: 'click' }"
                    :open-year-first="true"
                    rules="requiredVcalendar|requiredAge:13" />
                <m-select
                    v-if="!skipGenderAndBirthday"
                    v-model="user.gender"
                    :inherit="true"
                    :options="genderOptions"
                    :placeholder="$t('sign_up.gender')"
                    class="padding-t__10"
                    rules="required" />
                <m-phone-number
                    v-if="signUpPhone"
                    v-model="user.user_account_attributes.phone"
                    field-id="phone"
                    @code="setCountryCode" />
                <m-input
                    v-model="user.email"
                    :maxlength="128"
                    :placeholder="$t('sign_up.email')"
                    :pure="true"
                    :readonly="isInvitation"
                    :rules="`required|email${isInvitation ? '' : '|server_canUseEmail'}`"
                    :validation-debounce="400"
                    field-id="su_email"
                    autocomplete="username"
                    name="EmAil"
                    type="email" />
                <m-strong-password
                    v-model="user.password"
                    :maxlength="128"
                    class="inputWithIcon"
                    field-id="su_password"
                    autocomplete="current-password"
                    rules="required|passwordStrength" />
                <m-checkbox
                    v-if="skipGenderAndBirthday"
                    v-model="confirm13"
                    class="header__loginSignUp__confirm13">
                    {{ $t('sign_up.confirm13') }}
                </m-checkbox>
                <m-btn
                    :disabled="!signUpEnabled"
                    :full="true"
                    class="header__loginSignUp margin-t__30 margin-b__30"
                    size="l"
                    tag-type="submit">
                    {{ 'Sign Up' }}
                </m-btn>
                <div
                    v-if="socialLoginProp.enabled && !isInvitation"
                    class="text__center margin-b__30">
                    <a
                        :full="true"
                        class="fs__16 header__toggleModalsButton"
                        @click="toggleMode">{{ $t('sign_up.more_sign_up') }}</a>
                </div>
                <div
                    v-if="guest"
                    class="text__center padding-t__0 margin-b__30">
                    <a
                        :full="true"
                        class="fs__16 header__toggleModalsButton"
                        @click="guestLogin">{{ $t('sign_up.guest') }}</a>
                </div>
            </m-form>
        </section>
        <section v-show=" mode==='with-social' ">
            <!-- <div class="avatar logo__xl">
        <img :src="$img['avatar']" alt="userName">
      :TODO alt = userName-->
            <div class="padding-t__20 padding-b__20 text__center fs__28">
                {{ $t('sign_up.welcome_to') }} {{ serviceName }}!
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
                            <span>{{ $t('sign_up.with_facedook') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <img
                                :src="$img['facebookL']"
                                alt="socialName">
                            <span>{{ $t('sign_up.with_facedook') }}</span>
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
                            <span>{{ $t('sign_up.with_google') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <img
                                :src="$img['googleL']"
                                alt="socialName">
                            <span>{{ $t('sign_up.with_google') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.apple.enabled">
                    <div v-if="socialLoginProp.apple.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('apple')">
                            <i class="GlobalIcon-apple" />
                            <span>{{ $t('sign_up.with_apple') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-apple" />
                            <span>{{ $t('sign_up.with_apple') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.instagram.enabled">
                    <div v-if="socialLoginProp.instagram.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('instagram')">
                            <i class="GlobalIcon-instagram" />
                            <span>{{ $t('sign_up.with_instagram') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-instagram" />
                            <span>{{ $t('sign_up.with_instagram') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.twitter.enabled">
                    <div v-if="socialLoginProp.twitter.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('twitter')">
                            <i class="GlobalIcon-twitter" />
                            <span>{{ $t('sign_up.with_twitter') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-twitter" />
                            <span>{{ $t('sign_up.with_twitter') }}</span>
                        </div>
                    </div>
                </div>
                <div v-if="socialLoginProp.linkedin.enabled">
                    <div v-if="socialLoginProp.linkedin.active">
                        <div
                            class="socialBlock"
                            @click="socialLogin('linkedin')">
                            <i class="GlobalIcon-linkedin" />
                            <span>{{ $t('sign_up.with_linkedin') }}</span>
                        </div>
                    </div>
                    <div v-else>
                        <div class="socialBlock socialBlock__disable">
                            <i class="GlobalIcon-linkedin" />
                            <span>{{ $t('sign_up.with_linkedin') }}</span>
                        </div>
                    </div>
                </div>
            </div>
            <m-btn
                :full="true"
                class="margin-t__25 margin-b__25 fs__16 text__normal"
                size="l"
                @click="toggleMode">
                {{ $t('sign_up.with_email') }}
            </m-btn>
        </section>
        <div class="text__center buttonsSection">
            <div>
                {{ $t('sign_up.agree_to') }} {{ serviceName }}'s <a
                    href="/pages/terms-of-use"
                    target="_blank">{{ $t('footer.terms_of_use') }} </a>{{ $t('sign_up.and') }} <a
                        href="/pages/privacy-policy"
                        target="_blank">{{ $t('footer.privacy_police') }}</a>
            </div>
            <div>
                {{ $t('sign_up.have_acc') }} <a
                    href=""
                    @click.prevent="openLogin">{{ $t('sign_up.log_in') }}</a>
            </div>
            <br>
            <a
                v-if="guest"
                :full="true"
                class="fs__16 header__toggleModalsButton"
                @click="guestLogin">{{ $t('sign_up.guest') }}</a>
        </div>
    </div>
</template>

<script>
import User from "@models/User"
import {setCookie, deleteCookie} from "@utils/cookies"
import eventHub from "@helpers/eventHub.js"

export default {
    props: {
        socialLoginProp: {
            type: [Boolean, Object]
        },
        serviceName: String,
        afterSignAction: Object,
        guest: Boolean,
        defaultMode: {
            type: String,
            default: "with-social"
        }
    },
    data() {
        return {
            nameRules: {
                required: true,
                min: 2,
                regex: /^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\s.\'\"\`\-]+$/
            },
            mode: "with-social",
            user: {
                first_name: "",
                last_name: "",
                birthdate: null,
                gender: "",
                email: "",
                password: "",
                user_account_attributes: {
                    phone: '',
                    country: ''
                }
            },
            isInvitation: false,
            genderOptions: [
                {value: "male", name: "Male"},
                {value: "female", name: "Female"},
                {value: "hidden", name: "Private"}
            ],
            disabled: true,
            confirm13: false,
            signup_token: null
        }
    },
    computed: {
        getMaxDate() {
            return new Date().setFullYear(new Date().getUTCFullYear() - 13)
        },
        skipGenderAndBirthday() {
            return this.$railsConfig.global.skip_gender_and_birthdate
        },
        signUpEnabled() {
            let flag = !this.disabled
            // for additional checks
            if (this.skipGenderAndBirthday && !this.confirm13) flag = false // skipGenderAndBirthday check
            if (!this.skipGenderAndBirthday && this.user.gender === '') flag = false // standart check
            return flag
        },
        signUpPhone() {
            return this.$railsConfig.global.sign_up.phone
        },
        pageOrganization() {
            return this.$store.getters["Users/pageOrganization"]
        }
    },
    watch: {
        socialLoginProp: {
            handler(val) {
                if (!val.enabled) {
                    this.mode = "with-email"
                }
            },
            deep: true,
            immediate: true
        },
        mode(val) {

        },
        "user.birthdate": {
            handler(val) {
                this.$refs.birthday?.$refs?.provider?.validate()
            }
        }
    },
    mounted() {
        this.checkInvitation()
        this.checkSignUpToken()

        if(this.defaultMode == "with-email") this.mode = "with-email"

        this.detectCountry()
    },
    methods: {
        setCountryCode(val) {
            this.user.user_account_attributes.country = val
        },
        openLogin() {
            this.$emit("change", "login")
        },
        toggleMode() {
            if (this.mode === "with-email") this.mode = "with-social"
            else this.mode = "with-email"
        },
        guestLogin() {
            this.$emit("change", "guest")
        },
        signUp() {
            if (this.skipGenderAndBirthday) {
                delete this.user.birthdate
                delete this.user.gender
            }
            if (!this.signUpPhone) {
                delete this.user.user_account_attributes.phone
            }
            let user = this.user
            let signup_token = {token: this.signup_token}
            this.disabled = true
            if (this.isInvitation) {
                this.registrationByInvitationToken()
                return
            }

            var ref_url = null, ref_model = null

            if(window.spaMode === "monolith") {
                ref_url = location.pathname
                if(window.Immerss?.session) {
                    ref_model = {
                        id: window.Immerss.session.id,
                        type: "Session"
                    }
                }
                if(window.Immerss?.recording) {
                    ref_model = {
                        id: window.Immerss.recording.id,
                        type: "Recording"
                    }
                }
                if(window.Immerss?.replay) {
                    ref_model = {
                        id: window.Immerss.replay.id,
                        type: "Video"
                    }
                }
            } else {
                ref_url = location.pathname
                if(this.pageOrganization) {
                    ref_model = {
                        id: this.pageOrganization.id,
                        type: "Organization"
                    }
                }
            }

            let sendData = { user, signup_token }
            if(ref_url) sendData.ref_url = ref_url
            if(ref_model) sendData.ref_model = ref_model

            User.api().signUp(sendData).then(res => {
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
                    this.$flash('Welcome! You have signed up successfully.', 'success')
                    if (this.afterSignAction.action == 'close-and-emit') {
                        this.$emit("close")
                        eventHub.$emit(this.afterSignAction.event, this.afterSignAction.data)
                    }
                    if (this.afterSignAction.action == 'close-and-emit-res') {
                        this.$emit("close")
                        eventHub.$emit(this.afterSignAction.event, res.response.data.response.user)
                    }
                    if (this.signup_token || this.afterSignAction.action == 'redirect-to-wizard') {
                        this.$emit("close")
                        location.href = location.origin + '/wizard/business'
                    }
                    if(this.afterSignAction.action == "default") {
                        if(window.spaMode === "monolith") location.reload()
                        this.$emit("close")
                    }
                    if (this.afterSignAction.action == 'close-and-reload') {
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
                    if(this.afterSignAction.action == 'close-and-emit-subscribe') {
                        this.$emit("close")
                        eventHub.$emit(this.afterSignAction.event,
                            this.afterSignAction.data.plan,
                            this.afterSignAction.data.subscription,
                            this.afterSignAction.data.channel)
                    }
                    if(this.afterSignAction.action == 'close') {
                        this.$emit("close")
                    }
                })
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash('Email has already been taken')
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            }).then(() => {
                this.disabled = false
            })
        },
        socialLogin(provider) {
            this.goTo(`/users/auth/${provider}?redirect_path_after_social_signup=${location.href}`)
        },
        registrationByInvitationToken() {
            let params = this.searchToObject()
            this.user.invitation_token = params.invitation_token
            let redirectUrl = (new URL(location.href)).searchParams.get("return_to_after_connecting_account")
            User.api().registrationByInvitationToken({
                user: this.user,
                invitation_token: params.invitation_token
            }).then(res => {
                this.$flash('Welcome! You have signed up successfully.', 'success')
                setTimeout(() => {
                    if(redirectUrl) {
                        location.href = redirectUrl
                    } else if (res?.response?.data?.location) {
                        location.href = res.response.data.location
                    } else {
                        if(this.$railsConfig.global.service_subscriptions?.enabled) {
                            location.href = location.origin + '/pricing'
                        } else {
                            location.href = location.origin + "/dashboard"
                        }
                    }
                }, 1000)
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error?.response?.data?.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        checkInvitation() {
            if (location.pathname === "/users/invitation/accept") {
                this.mode = "with-email"
                let params = this.searchToObject()
                if (params.invitation_token) {
                    User.api().getInvitationTokenInfo({token: params.invitation_token}).then(res => {
                        this.user.first_name = res.response.data.first_name
                        this.user.last_name = res.response.data.last_name
                        this.user.email = res.response.data.email
                        this.isInvitation = true
                        this.$nextTick(() => {
                            this.$refs.form.observerReset()
                        })
                    })
                }
            }
        },
        searchToObject() {
            var pairs = window.location.search.substring(1).split("&"),
                obj = {},
                pair,
                i

            for (i in pairs) {
                if (pairs[i] === "") continue

                pair = pairs[i].split("=")
                obj[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
            }

            return obj
        },
        getUrlParams() {
            return window.location.search.slice(1)
                .split('&')
                .reduce(function _reduce(/*Object*/ a, /*String*/ b) {
                    b = b.split('=')
                    a[b[0]] = decodeURIComponent(b[1])
                    return a
                }, {})
        },
        checkSignUpToken() {
            let urlParams = this.getUrlParams()
            if(urlParams.signup_token) {
                User.api().checkSignUpToken({signup_token: urlParams.signup_token}).then(res => {
                    let token = res.response.data.response?.signup_token?.token
                    if(token) {
                        this.signup_token = token
                    }
                })
            }
        },
        detectCountry() {
            // this.user.tzinfo = window.moment().tz(Intl.DateTimeFormat().resolvedOptions().timeZone).format('Z')
            this.user.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
            fetch('https://api.ipregistry.co/?key=tryout')
                .then((response) => {
                    return response.json()
                })
                .then((payload) => {
                    this.user.user_account_attributes.country = payload.location.country.code
                })
        }
    }
}
</script>