<template>
    <div class="modal-auth-template">
        <section>
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
                    v-model="user.birthdate"
                    :custom-mask="{input: 'DD MMMM YYYY'}"
                    :placeholder-on-focus="'MM/DD/YYYY'"
                    :icon-calendar="true"
                    :max-date="getMaxDate"
                    :placeholder="$t('sign_up.birthday')"
                    :popover="{ visibility: 'click' }"
                    :open-year-first="true"
                    rules="requiredVcalendar" />
                <m-select
                    v-if="!skipGenderAndBirthday"
                    ref="genderField"
                    v-model="user.gender"
                    :inherit="true"
                    :options="genderOptions"
                    :placeholder="$t('sign_up.gender')"
                    class="padding-t__10"
                    rules="required" />
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
                    {{ 'Submit' }}
                </m-btn>
                <div
                    class="text__center margin-b__30">
                    <a
                        :full="true"
                        class="fs__16 header__toggleModalsButton"
                        @click="skipForNow">{{ $t('sign_up.skip_for_now') }}</a>
                </div>
            </m-form>
        </section>
    </div>
</template>

<script>
import User from "@models/User"

export default {
    data() {
        return {
            nameRules: {
                required: true,
                min: 2,
                regex: /^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\s.\'\"\`\-]+$/
            },
            mode: "with-email",
            user: {
                first_name: "",
                last_name: "",
                birthdate: null,
                gender: "",
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
            errorMessage: "This email is already in use",
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
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.user.first_name = this.currentUser.first_name
        this.user.last_name = this.currentUser.last_name
        this.user.birthdate = this.currentUser.birthdate
        this.user.email = this.currentUser.email
        this.user.gender = this.currentUser.gender
        if(this.currentUser.gender && this.currentUser.gender != "") {
            this.$refs["genderField"]?.updateOption(this.genderOptions.find(g => g.value == this.currentUser.gender))
        }
    },
    methods: {
        setCountryCode(val) {
            this.user.user_account_attributes.country = val
        },
        skipForNow() {
            this.$emit("close")
        },
        signUp() {
            if (this.skipGenderAndBirthday) {
                delete this.user.birthdate
                delete this.user.gender
            }
            if (!this.signUpPhone) {
                delete this.user.user_account_attributes
            }
            let user = this.user
            this.disabled = true
            console.log("--------", this.user.gender)

            if(this.signup_token) {
                user["signup_token"] = {token: this.signup_token}
            }

            User.api().updateCurrentUser({user}).then(() => {
                this.$flash('Saved!', "success")
                this.$emit("close")
            }).catch(error => {
                if (error?.response?.data?.message) {
                    // this.$flash('Email has already been taken')
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            }).then(() => {
                this.disabled = false
            })
        }
    }
}
</script>