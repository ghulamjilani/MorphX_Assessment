import Vue from 'vue/dist/vue.esm'
import {ValidationProvider, ValidationObserver, extend} from 'vee-validate'
import {required, email, min, max, regex} from 'vee-validate/dist/rules'

import User from "./store/models/User"

// Add a rules
extend('required', {
    ...required,
    message: 'This field is required'
})

extend('email', {
    ...email,
    message: 'Please enter a valid email address'
})

extend('min', {
    ...min,
    message: 'Please enter at least 2 characters'
})

extend('min-length', {
    validate(value, args) {
        if (value?.trim().length >= +args[0]) return true
        else return `Please enter at least ${args[0]} characters`
    }
})
extend('max-length', {
    validate(value, args) {
        if (value?.trim().length <= +args[0]) return true
        else return `Please enter less than ${args[0]} characters.`
    }
})

extend('regex', {
    ...regex,
    message: 'Invalid format'
})

extend('requiredVcalendar', {
    validate(value, args) {
        if (typeof value === 'object') {
            return !!value.start && !!value.end
        } else if (typeof value === 'string') {
            return !!value?.trim()
        }
        return false
    },
    message: 'This field is required'
})

extend('requiredAge', {
    validate(value, args) {
        if (typeof value === 'string') {
            return new Date(value) <= new Date().setFullYear(new Date().getUTCFullYear() - args[0])
        }
        return false
    },
    message: 'Your age is not eligible'
})

extend('server_canUseEmail', {
    validate(value, args) {
        return new Promise(resolve => {
            User.api().checkEmail({email: value}).then(res => {
                return resolve({
                    valid: !!res?.response?.data
                })
            }).catch(err => {
                return resolve({
                    valid: false
                })
            })
        })
    },
    message: 'This email is already in use'
})

extend('passwordStrength', (value) => {
    let score = 0;
    let letters = {};
    let acceptableScore = 30;
    let strongScore = 80;
    let lengthMore6 = value.replace(/ /g, "").length > 5;
    let includeLowercase = !!value.match(/[a-zа-я]+/);
    let includeUppercase = !!value.match(/[A-ZА-Я]+/);
    let includeNumber = !!value.match(/[0-9]+/);
    let includeSpecialChar = !!value.match(/[!@_#%&\-\$\^\*]+/);
    let lengthLess128 = value.length < 128;
    let isPasswordValid = includeLowercase &&
        includeUppercase &&
        includeNumber &&
        lengthMore6 &&
        lengthLess128;
    let passwordStrength = "weak"

    if (isPasswordValid) {
        score += 30;

        if (includeSpecialChar) {
            score += 10
        }

        for (let i = 0; i < value.length; i++) {
            letters[value[i]] = (letters[value[i]] || 0) + 1;
            score += 5.0 / letters[value[i]];
        }

        if (score > acceptableScore) {
            passwordStrength = 'acceptable'
        }
        if (score > strongScore) {
            passwordStrength = 'strong'
        }
    }

    return passwordStrength != 'weak';
})

Vue.component('ValidationObserver', ValidationObserver)
Vue.component('ValidationProvider', ValidationProvider)
