<template>
    <!-- TODO: andrey check tooltip placement -->
    <div>
        <m-input
            ref="input"
            v-model="password"
            :errors="false"
            :field-id="fieldId"
            :label="!pureLabel ? label : ' '"
            :maxlength="maxlength"
            :placeholder="!purePlaceholder ? placeholder : ' '"
            :pure="pure"
            :required="required"
            :rules="rules"
            :type="show ? 'text' : 'password'"
            class="passwordInput"
            @blur="onBlur"
            @enter="() => { $emit('enter') }"
            @focus="onFocus">
            <template #icon>
                <m-icon
                    :name="icons[show]"
                    :size="sizeIcon"
                    @click="showPassword" />
            </template>
            <template
                v-if="password.length"
                #passStrength>
                <div class="passStrength">
                    <div
                        :class="passwordStrength"
                        class="passStrength__indicatorItem" />
                    <div
                        :class="{
                            'acceptable': passwordStrength === 'acceptable',
                            'strong': passwordStrength === 'strong'
                        }"
                        class="passStrength__indicatorItem" />
                    <div
                        :class="{
                            'strong': passwordStrength === 'strong'
                        }"
                        class="passStrength__indicatorItem" />
                </div>
            </template>
            <template
                v-if="password.length"
                #bottom>
                <div
                    v-show="passwordStrength"
                    :class="passwordStrength"
                    class="passStrength__Message">
                    {{ passwordStrength }} {{ $t('sign_up.password') }}
                </div>
            </template>
        </m-input>
        <div
            v-show="focused && passwordStrength === 'weak'"
            class="passStrength__Wrap">
            <div class="passStrength__toolTip">
                {{ $t('sign_up.use') }}
                <b>{{ $t('sign_up.characters') }},</b>
                {{ $t('sign_up.including') }}
                <b>{{ $t('sign_up.uppercase') }}</b>
                {{ $t('sign_up.letter') }}, {{ $t('sign_up.one') }}
                <b>{{ $t('sign_up.lowercase') }}</b>
                {{ $t('sign_up.letter') }}, {{ $t('sign_up.and_one') }}
                <b>{{ $t('sign_up.numeric') }}</b>
                {{ $t('sign_up.character') }}
            </div>
        </div>
    </div>
</template>

<script>
/**
 * @displayName Strong Password
 * @example ./docs/mstrongpassword.md
 */
export default {
    name: "MStrongPassword",
    props: {
        required: {
            type: Boolean,
            default: false
        },
        rules: {
            type: String,
            default: ""
        },
        placeholder: {
            type: String,
            default: "Password"
        },
        label: {
            type: String,
            default: "Password"
        },
        pureLabel: {
            type: Boolean,
            default: false
        },
        purePlaceholder: {
            type: Boolean,
            default: false
        },
        pure: {
            type: Boolean,
            default: true
        },
        sizeIcon: {
            type: String,
            default: '1.4rem'
        },
        fieldId: {
            type: String,
            default: 'input_id'
        },
        maxlength: {}
    },
    data() {
        return {
            password: "",
            focused: false,
            passwordStrength: "",
            strengths: ["weak", "acceptable", "strong"],
            icons: {
                true: "GlobalIcon-eye",
                false: "GlobalIcon-eye-off"
            },
            show: false
        }
    },
    watch: {
        password(val) {
            this.calculatePasswordStrength()
            this.$emit("input", this.password)
        }
    },
    methods: {
        showPassword() {
            this.show = !this.show
        },
        onFocus() {
            this.focused = true
        },
        onBlur() {
            this.focused = false
        },
        // TODO: andrey refactor?
        calculatePasswordStrength() {
            let password = this.password
            let score = 0
            let letters = {}
            let acceptableScore = 30
            let strongScore = 80
            let lengthMore6 = password.replace(/ /g, "").length > 5
            let includeLowercase = !!password.match(/[a-zа-я]+/)
            let includeUppercase = !!password.match(/[A-ZА-Я]+/)
            let includeNumber = !!password.match(/[0-9]+/)
            let includeSpecialChar = !!password.match(/[!@_#%&\-\$\^\*]+/)
            let lengthLess128 = password.length < 128
            let isPasswordValid = includeLowercase &&
                includeUppercase &&
                includeNumber &&
                lengthMore6 &&
                lengthLess128
            let passwordStrength = "weak"

            if (isPasswordValid) {
                score += 30

                if (includeSpecialChar) {
                    score += 10
                }

                for (let i = 0; i < password.length; i++) {
                    letters[password[i]] = (letters[password[i]] || 0) + 1
                    score += 5.0 / letters[password[i]]
                }

                if (score > acceptableScore) {
                    passwordStrength = 'acceptable'
                }
                if (score > strongScore) {
                    passwordStrength = 'strong'
                }
            }

            this.passwordStrength = passwordStrength
        }
    }
}
</script>
