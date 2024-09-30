<template>
    <div class="ownerModal__message">
        <div class="ownerModal__message__title">
            Send Message
        </div>
        <div class="ownerModal__message__subject">
            <m-input
                v-model="message.subject"
                :maxlength="50"
                field-id="subject"
                label="Subject*"
                rules="required" />
        </div>
        <div
            :class="{'ownerModal__message__quill__wrapper__error' : validateRequired()}"
            class="ownerModal__message__quill__wrapper">
            <vue-editor
                v-model="message.body"
                :editor-options="editorSettings"
                placeholder="Message*"
                @text-change="textChange" />
            <div class="ownerModal__message__bottom">
                <div
                    v-if="validateRequired()"
                    class="mTextArea__bottom__errors">
                    This field is required
                </div>
                <div class="mTextArea__bottom__counter">
                    {{ textLength() }}/2000
                </div>
            </div>
        </div>
        <div class="ownerModal__message__buttons">
            <m-btn
                class="ownerModal__message__buttons__cancel"
                type="bordered"
                @click="$emit('cancel')">
                Cancel
            </m-btn>
            <m-btn
                :disabled="disabledSend()"
                type="save"
                @click="send()">
                Send
            </m-btn>
        </div>
    </div>
</template>

<script>
import axios from "@plugins/axios.js"
import {VueEditor} from "vue2-editor"

export default {
    components: {VueEditor},
    props: {
        recipient: Object,
        monolit: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            message: {
                body: "",
                subject: ""
            },
            oldText: "",
            editorSettings: {
                modules: {
                    toolbar: {
                        container: [
                            []
                        ]
                    }
                }
            }
        }
    },
    methods: {
        textChange() {
            let text = document.querySelector('.ql-editor p')
            if (text && this.textLength() > 2000) {
                text.innerHTML = this.oldText
            }
            this.oldText = text.innerHTML
        },
        textLength() {
            let text = document.querySelector('.ql-editor p')
            if (this.message === "") {
                return 0
            }
            if (text) {
                let br = text.querySelectorAll('br')
                return (text.innerText.length) - (br.length)
            } else {
                return 0
            }
        },
        validateRequired() {
            if (this.oldText && (this.textLength() < 1)) return true
            return false
        },
        disabledSend() {
            if (this.message.body.length > 0 && this.message.subject.length > 0) return false
            return true
        },
        send() {
            axios.post('/messages', {
                message: {
                    recipient: this.recipient.id,
                    body: this.message.body,
                    subject: this.message.subject
                }
            }).then(() => {
                if (this.monolit) {
                    $.showFlashMessage("Message has been sent", {type: 'success'})
                } else {
                    this.$flash("Message has been sent", "success")
                }
                this.$emit('cancel')
            }).catch(error => {
                if (error?.response?.data?.message) {
                    if (this.monolit) {
                        $.showFlashMessage(error.response.data.message, {type: 'error'})
                    } else {
                        this.$flash(error.response.data.message)
                    }
                } else {
                    if (this.monolit) {
                        $.showFlashMessage('Something went wrong please try again later', {type: 'error'})
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                }
            })
        }
    }
}
</script>

