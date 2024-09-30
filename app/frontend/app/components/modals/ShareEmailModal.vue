<template>
    <m-modal
        ref="shareEmailModal"
        class="shareEmailModal">
        <h4 class="shareEmailModal__title">
            Send a mail
        </h4>
        <m-form
            v-model="disabled"
            :form="emailSend"
            class="shareEmailModal__form"
            @onSubmit="send">
            <div>
                <span>To</span>
                <m-input
                    v-model="emailSend.emails"
                    :pure="true"
                    placeholder="Email"
                    rules="required" />
            </div>
        </m-form>
        <template #black_footer>
            <div class="shareEmailModal__send">
                <m-btn
                    size="s"
                    type="main"
                    @click="send">
                    Send
                </m-btn>
            </div>
        </template>
    </m-modal>
</template>

<script>
import Share from "@models/Share"

export default {
    props: {
        model_type: {},
        model_id: {}
    },
    data() {
        return {
            emailSend: {
                emails: "",
                model_type: this.model_type,
                model_id: this.model_id
            },
            disabled: true
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })
    },
    methods: {
        open() {
            this.$refs.shareEmailModal.openModal()
        },
        close() {
            this.$refs.shareEmailModal.closeModal()
        },
        send() {
            Share.api().shareEmail(this.emailSend).then(res => {
                this.$flash("Your email has been sent successfully", "success")
                this.close()
            }).catch(error => this.$flash("At least one email should be set", "warning"))
        }
    }
}
</script>