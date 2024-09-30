export default {
    required(value) {
        const _value = typeof value === 'string' ? value.trim() : value;
        return !_value ? 'VALIDATION.FIELD:REQUIRED' : true
    },
    minFirstName(value) {
        const _value = value && value.trim().length < 2
        return _value ? 'VALIDATION.FIELD:FIRSTNAME:MIN' : true
    },
    textInput(value) {
        const regExp = /^[a-zA-Z\- ]+$/
        return value && !regExp.test(value) ? 'VALIDATION.FIELD:INVALID' : true
    },
    minLastName(value) {
        const _value = value && value.trim().length < 2
        return _value ? 'VALIDATION.FIELD:LASTNAME:MIN' : true
    },
    passwordSpace(password) {
        return password && password.includes(' ') ? 'VALIDATION.FIELD:SPACE' : true
    },
    maxString(value) {
        const _value = value && value.length > 50
        return _value ? 'VALIDATION.STRING:MAX' : true
    },
    isEmail(email) {
        const regExp = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-||_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+([a-z]+|\d|-|\.{0,1}|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])?([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i
        return email && !regExp.test(email.trim()) ? 'VALIDATION.FIELD:EMAIL:INVALID' : true
    },
    isPasswordValid(password) {
        const regExp = /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/
        return password && !regExp.test(password) ? 'VALIDATION.PASS:INVALID' : true
    }
}