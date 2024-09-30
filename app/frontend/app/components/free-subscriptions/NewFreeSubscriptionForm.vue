<template>
    <div class="FS__form__wrapper">
        <m-form
            ref="form"
            class="FS__form"
            @onSubmit="addNewFreeSubscription">
            <div class="FS__form__row">
                <m-input
                    ref="email"
                    v-model="newFreeSubscription.email"
                    :class="{hide_error: isEmailOrCSV_error}"
                    :maxlength="128"
                    :validation-debounce="400"
                    label="Email"
                    :rules="rulesEmail"
                    type="email" />
                <div class="FS__form__csv">
                    <div class="FS__form__csv__title">
                        Or select CSV-file to upload contact
                        <br>
                        <div :class="{'input__field__bottom__errors': UploadFile.error}">
                            Upload file: <b v-text="UploadFile.name" />
                        </div>
                    </div>
                    <label class="btn btn__bordered btn__normal">
                        <input
                            type="file"
                            class="inputfile hidden"
                            accept=".csv"
                            ref="inputfile"
                            @change="change">
                        Select file
                    </label>
                </div>
            </div>
            <div class="input__field__bottom">
                <div
                    v-if="isEmailOrCSV_error"
                    class="input__field__bottom__errors">
                    Email or CSV-file is required
                </div>
            </div>
            <div class="FS__form__legend">
                <div>
                    <m-icon
                        class="FS__form__legend__icon"
                        size="0">
                        GlobalIcon-info
                    </m-icon>
                    The CSV-file needs to have the following information: <b>First Name | Last Name | Email</b> so
                    that the parsing works correctly.
                </div>
            </div>
            <m-select
                v-model="newFreeSubscription.duration_in_months"
                :options="optionsDuration"
                label="Duration*"
                rules="required" />
            <m-select
                v-model="newFreeSubscription.channel_id"
                :options="optionsChannel"
                label="Channel*"
                rules="required" />
            <div class="FS__form__tools">
                <m-btn
                    :disabled="disabled"
                    tag-type="submit"
                    type="save">
                    Invite
                </m-btn>
            </div>
        </m-form>
    </div>
</template>

<script>
export default {
    name: "NewFreeSubscriptionForm",
    props: {
        optionsChannel: Array
    },
    data() {
        return {
            optionsDuration: [
                { name: "1 Month", value: 1 },
                { name: "3 Months", value: 3 },
                { name: "6 Months", value: 6 },
                { name: "1 Year", value: 12 }
            ],
            disabled: false,
            isEmailOrCSV_error: false,
            newFreeSubscription: {
                email: "",
                file: "",
                duration_in_months: null,
                channel_id: null
            },
            UploadFile: {
                name: "",
                error: false
            }
        }
    },
    computed: {
        rulesEmail() {
            return this.newFreeSubscription.file ? "email" : "required|email"
        },
        emailValidationRequired() {
            if (this.$refs.email?.$children[0].$data.errors[0] == "This field is required") {
                this.isEmailOrCSV_error = true
            }
            else {
                this.isEmailOrCSV_error = false
            }
            return
        }
    },
    methods: {
        change(event) {
            let file = event.target.files[0]
            if (file) {
                let regexp = /\.csv$/;
                if (regexp.test(file.name)) {
                    this.newFreeSubscription.file = file
                    this.UploadFile.name = file.name
                    this.UploadFile.error = false
                }
                else {
                    this.UploadFile.name = "invalid file format",
                    this.UploadFile.error = true
                }
            }
        },
        addNewFreeSubscription() {
            this.$emit('addNewFreeSubscription', this.newFreeSubscription)
            Object.assign(this.$data.newFreeSubscription, this.$options.data().newFreeSubscription)
            Object.assign(this.$data.UploadFile, this.$options.data().UploadFile)
            this.$refs.inputfile.value = null;
            this.$refs.form.observerReset()
        }
    }
}
</script>
