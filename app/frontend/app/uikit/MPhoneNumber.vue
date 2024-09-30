<template>
    <div class="m-phone-number">
        <m-select
            v-model="phoneCode"
            :options="countryCodes"
            :uid="selectUid"
            class="m-phone-number__select"
            label="Phone (optional)"
            type="text" />
        <m-input
            v-model="phoneNumber"
            name="userPhone"
            field-id="su_phone"
            :placeholder="'0123456789'"
            :pure="true"
            class="m-phone-number__input"
            onkeyup="this.value = this.value.replace(/[^\d]/g,'');"
            autocomplete="no"
            type="tel" />
    </div>
</template>

<script>
import {countries} from 'countries-list'
import eventHub from "../helpers/eventHub.js"

export default {
    data() {
        return {
            countryCodes: [],
            phoneCode: '1',
            phoneNumber: '',
            selectUid: uid(),
            output: '',
            code: 'US'
        }
    },
    watch: {
        phoneCode(val) {
            this.output = `${val}${this.phoneNumber}`
            this.code = this.countryCodes.find((e) => {
                if (e.value == val) return e
            }).code
            this.$emit("code", this.code)
            this.$emit("input", this.output)
            this.$emit("change", this.output)
        },
        phoneNumber(val) {
            this.checkNumbers(val)
            this.output = `${this.phoneCode}${val}`
            this.$emit("input", this.output)
            this.$emit("change", this.output)
        }
    },
    created() {
        this.$emit("code", this.code)
        for (let country in countries) {
            this.countryCodes.push({
                code: Object.entries(country)[0][1] + Object.entries(country)[1][1],
                order: country == 'US' ? 1 : 2,
                name: `${countries[country].emoji} ${countries[country].name} +${countries[country].phone}`,
                value: countries[country].phone,
                nameSelected: `${countries[country].emoji} +${countries[country].phone}`
            })
        }

        this.countryCodes.sort((a, b) => {
            return a.order - b.order
        })

        eventHub.$on('open-m-select-menu', () => {
            this.$nextTick(() => {
                if (this.$el.querySelector('.dropdownMK2__menu')) {
                    this.$el.querySelector('.dropdownMK2__menu').style.width = `${this.$el.offsetWidth}px`
                }
            })
        })
    },
    methods: {
        checkNumbers(val) { // type="number" erase 0, pater="..." not working
            let newVal = val.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1')
            if (val !== newVal) {
                this.$nextTick(() => {
                    this.phoneNumber = newVal
                })
            }
        }
    }
}
</script>