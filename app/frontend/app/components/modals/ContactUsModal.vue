<template>
    <m-modal
        ref="contactsUsModal"
        class="contactsUsModal">
        <div class="contactsUsModal__content">
            <div class="contactsUsModal__content__leftSide">
                <contact-img />
            </div>
            <div class="contactsUsModal__content__rightSide">
                <label>Talk with our sales team</label>

                <m-form
                    v-model="disabled"
                    :form="contactForm"
                    @onSubmit="submit">
                    <m-input
                        v-model="contactForm.name"
                        :maxlength="200"
                        field-id="name"
                        label="Name*"
                        name="name"
                        rules="required" />

                    <m-input
                        v-model="contactForm.email"
                        :maxlength="200"
                        field-id="email"
                        label="Email*"
                        name="email"
                        rules="required|email"
                        type="email" />

                    <m-phone-number
                        v-model="contactForm.phoneNumber"
                        field-id="phoneNumber" />

                    <m-input
                        v-model="contactForm.companyName"
                        :maxlength="200"
                        field-id="companyName"
                        label="Company Name (Optional)"
                        name="companyName" />

                    <m-input
                        v-model="contactForm.message"
                        :max-counter="2000"
                        :maxlength="2000"
                        :textarea="true"
                        field-id="message"
                        label="Message*"
                        name="message"
                        rules="required" />
                    <vue-recaptcha
                        v-if="isRecaptchaEnabled"
                        class="margin-t__20"
                        :sitekey="this.$railsConfig.global.recaptcha.site_key"
                        :loadRecaptchaScript="true"
                        @verify="verifyRecaptcha"
                        @expired="isCaptchaValid = false" />

                    <m-btn
                        :disabled="disabled || !isCaptchaValid"
                        size="m"
                        type="main">
                        Send
                    </m-btn>
                </m-form>
            </div>
        </div>
    </m-modal>
</template>

<script>
import ContactImg from './ContactImg'
import axios from "@plugins/axios.js"
import VueRecaptcha from 'vue-recaptcha';

export default {
    components: {ContactImg, VueRecaptcha},
    data() {
        return {
            service_name: 'Morphx',
            project_name: 'morphx',
            isCaptchaValid: true,
            disabled: true,
            contactForm: {
                name: '',
                email: '',
                phoneNumber: '',
                companyName: '',
                message: '',
                'g-recaptcha-response': ''
            }
        }
    },
    computed: {
        isRecaptchaEnabled() {
            return this.$railsConfig.global.recaptcha.enabled && !this.$railsConfig.global.recaptcha.forms_disabled?.support_contact_us
        }
    },
    mounted() {
        this.service_name = this.$railsConfig.global.service_name
        this.project_name = this.$railsConfig.global.project_name
    },
    methods: {
        open() {
            this.$refs.contactsUsModal.openModal()
        },
        close() {
            if (this.$refs.contactsUsModal) this.$refs.contactsUsModal.closeModal()
        },
        submit() {
            axios.post('/api/v1/public/support_messages/contact_us', {
                first_name: this.contactForm.name,
                company: this.contactForm.companyName,
                email: this.contactForm.email,
                phone: this.contactForm.phoneNumber,
                about: this.contactForm.message,
                'g-recaptcha-response': this.contactForm['g-recaptcha-response']
            }).then(() => {
                this.$flash('Message sent', 'success')
                this.contactForm = {
                    name: '',
                    email: '',
                    phoneNumber: '',
                    companyName: '',
                    message: '',
                    'g-recaptcha-response': ''
                }
                this.close()
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        verifyRecaptcha(code) {
            this.contactForm['g-recaptcha-response'] = code
            this.isCaptchaValid = true
        }
    }
}
</script>