<template>
    <div class="CM__form__wrapper">
        <div class="CM__form">
            <m-form
                ref="form"
                v-model="disabled"
                @onSubmit="$emit('addNewContacts')">
                <div class="CM__form__top">
                    <m-input
                        v-model="newContact.first_name"
                        :maxlength="50"
                        :rules="nameRules"
                        class="CM__form__name"
                        field-id="first_name"
                        label="First Name*"
                        name="first_name" />
                    <m-input
                        v-model="newContact.last_name"
                        :maxlength="50"
                        :rules="nameRules"
                        class="CM__form__surname"
                        field-id="last_name"
                        label="Last Name*"
                        name="last_name" />
                </div>
                <div>
                    <m-input
                        v-model="newContact.email"
                        :maxlength="128"
                        :validation-debounce="400"
                        field-id="email"
                        label="Email*"
                        rules="required|email"
                        type="email" />
                </div>
                <div class="CM__form__tools">
                    <m-btn
                        :disabled="disabled"
                        tag-type="submit"
                        type="save">
                        Add to contact list
                    </m-btn>
                    <div class="CM__form__csv">
                        <div class="CM__form__csv__title">
                            Or select CSV-file to upload new contacts
                        </div>
                        <label class="btn btn__bordered btn__normal">
                            <input
                                accept=".csv"
                                class="inputfile hidden"
                                type="file"
                                @change="importContacts">
                            Select file
                        </label>
                    </div>
                </div>
                <div class="CM__form__legend">
                    <div>
                        <m-icon
                            class="CM__form__legend__icon"
                            size="0">
                            GlobalIcon-info
                        </m-icon>
                        The CSV-file needs to have the following information: <b>First Name | Last Name | Email</b> so
                        that the parsing works correctly.
                    </div>
                </div>
            </m-form>
        </div>
    </div>
</template>

<script>
export default {
    props: ["value"],
    data() {
        return {
            nameRules: {
                required: true,
                min: 2,
                regex: /^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\s.\'\"\`\-]+$/
            },
            newContact: {
                first_name: '',
                last_name: '',
                email: ''
            },
            disabled: false
        }
    },
    watch: {
        value(val) {
            if (val !== this.newContact) {
                this.newContact = val
            }
        },
        newContact: {
            handler(val) {
                this.$emit('input', val)
            },
            deep: true
        }
    },
    methods: {
        importContacts(event) {
            this.$emit('importContacts', event)
        }
    }
}
</script>