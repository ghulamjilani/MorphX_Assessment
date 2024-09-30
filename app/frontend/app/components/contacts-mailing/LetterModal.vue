<template>
    <div>
        <email-preview
            ref="emailPreview"
            :preview="preview" />
        <m-modal
            ref="letterModal"
            :backdrop="false"
            class="CM__Lmodal">
            <m-form
                ref="form"
                class="CM__Lmodal__form">
                <div class="CM__Lmodal__form__title">
                    Write Email
                </div>
                <m-select
                    v-model="message.template_id"
                    :options="templateOptions"
                    :without-error="true"
                    class="CM__Lmodal__form__select"
                    label="Select Template"
                    type="default" />
                <m-input
                    v-model="message.subject"
                    :maxlength="128"
                    class="CM__Lmodal__form__email"
                    field-id="email"
                    label="Email Subject*"
                    rules="required" />
                <div class="CM__recipient__wrapper">
                    <div
                        class="CM__recipient"
                        @click="toggleShowContacts">
                        <div class="CM__recipient__top">
                            <div class="CM__recipient__label">
                                Recipient*
                            </div>
                        </div>
                        <div
                            v-if="!isSelectAll"
                            class="CM__recipient__tags">
                            <m-chips
                                v-for="(recipient) in shortSelected"
                                :key="recipient"
                                class="tagsMK2__tag">
                                {{ recipientName(recipient) }}
                                <m-icon
                                    class="tagsMK2__icon"
                                    size=".8rem"
                                    @click="removeContact(recipient)">
                                    GlobalIcon-clear
                                </m-icon>
                            </m-chips>
                            <m-chips
                                v-if="selected.length - shortSelected.length > 0"
                                class="tagsMK2__tag"
                                @click="toggleShowContacts">
                                more ({{ selected.length - shortSelected.length }})
                            </m-chips>
                        </div>
                        <div
                            v-else
                            class="CM__recipient__tags">
                            <m-chips
                                class="tagsMK2__tag">
                                All Contacts ({{ totalContacts }})
                                <m-icon
                                    class="tagsMK2__icon"
                                    size=".8rem"
                                    @click="removeAllContacts">
                                    GlobalIcon-clear
                                </m-icon>
                            </m-chips>
                        </div>
                    </div>
                    <span
                        v-if="!isSelectAll"
                        class="GlobalIcon-angle-down selectArrow"
                        :class="{'up': showContacts, 'down': !showContacts}"
                        @click="toggleShowContacts" />
                    <div
                        v-if="showContacts"
                        class="CM__recipient__table__wrapper">
                        <!-- <m-input
                            v-model.trim="searchText"
                            :errors="false"
                            :maxlength="60"
                            :pure="true"
                            debounce="500"
                            field-id="search"
                            placeholder="Search...">
                            <template #icon>
                                <m-icon
                                    v-if="searchText.length"
                                    class="CM__filters__search__cross"
                                    size="0"
                                    @click="clearSearch()">
                                    GlobalIcon-clear
                                </m-icon>
                                <m-icon
                                    class="CM__filters__search__lens"
                                    size="0">
                                    GlobalIcon-search
                                </m-icon>
                            </template>
                        </m-input> -->
                        <table-contact
                            v-model="selected"
                            :contacts="contacts"
                            :is-select-all-prop="isSelectAll"
                            :loading="loading"
                            :modal="true"
                            :selected-prop="selected"
                            :can-mailing="canMailing"
                            :all-contacts-info="allContactsInfo"
                            :search-text="searchText"
                            class="CM__recipient__table customScroll"
                            @selectAll="selectAll"
                            @selectStatus="selectStatus" />
                    </div>
                </div>
                <vue-editor
                    ref="editor"
                    v-model="message.body"
                    :editor-options="editorSettings"
                    class="CM__recipient__quill"
                    placeholder="Type your text here..." />
            </m-form>
            <div class="CM__form__legend">
                <div>
                    <m-icon
                        class="CM__form__legend__icon"
                        size="0">
                        GlobalIcon-info
                    </m-icon>
                    Note: <b>[username]</b> shortcode will be automatically replaced with user's name.
                </div>
                <m-btn
                    :disabled="validateForm"
                    @click="getPreview()">
                    Preview
                </m-btn>
            </div>
            <template #black_footer>
                <div class="CM__Lmodal__buttons__wrapper">
                    <div class="CM__Lmodal__buttons">
                        <m-btn
                            size="s"
                            type="secondary"
                            @click="closeModal">
                            Cancel
                        </m-btn>
                        <m-btn
                            :disabled="validateForm"
                            size="s"
                            type="main"
                            @click="sendLetter()">
                            Send
                        </m-btn>
                    </div>
                </div>
            </template>
        </m-modal>
    </div>
</template>

<script>
import {Quill, VueEditor} from "vue2-editor"
import utils from '@helpers/utils'
import Emoji from "./../../assets/js/quill-emoji"
import "quill-emoji/dist/quill-emoji.css"
import TableContact from './TableContact.vue'
import Contacts from "@models/Contacts"
import Mail from "@models/Mail"
import EmailPreview from './EmailPreview.vue'

var Font = Quill.import('formats/font')
Font.whitelist = ['Roboto']
Quill.register(Font, true)

if(!Quill.imports["modules/quill-emoji"]) Quill.register("modules/quill-emoji", Emoji)
Quill.register(
    {
        "formats/emoji": Emoji.EmojiBlot,
        "modules/short_name_emoji": Emoji.ShortNameEmoji,
        "modules/toolbar_emoji": Emoji.ToolbarEmoji,
        "modules/textarea_emoji": Emoji.TextAreaEmoji
    },
    true
)

export default {
    components: {VueEditor, TableContact, EmailPreview},
    props: {
        selectedProp: Array,
        contacts: Array,
        isSelectAll: Boolean,
        totalContacts: Number,
        allContactsInfo: Array
    },
    data() {
        return {
            selected: null,
            loading: false,
            showContacts: false,
            preview: null,
            templates: [],
            message: {
                template_id: 'email_general',
                subject: '',
                contact_ids: [],
                body: ''
            },
            fetchOptions: {
                q: '',
                offset: 0,
                limit: 50,
                status: undefined
            },
            searchText: "",


            editorSettings: {
                modules: {
                    toolbar: {
                        container: [
                            [{header: [1, 2, 3, 4, 5, 6, false]}],
                            [
                                {align: ""},
                                {align: "center"},
                                {align: "right"},
                                {align: "justify"}
                            ],
                            ["bold", "italic", "underline", "strike"],
                            ["emoji"]
                        ]
                    },
                    toolbar_emoji: true,
                    short_name_emoji: true,
                    textarea_emoji: false,
                    "emoji-shortname": true
                }
            }
        }
    },
    computed: {
        templateOptions() {
            return this.templates.map(e => {
                return {
                    name: e.title,
                    value: e.id
                }
            })
        },
        validateForm() {
            return this.message.subject == '' || !this.message.contact_ids.length || this.message.body == ''
        },
        canMailing() {
            return this.$store.getters["Users/currentUser"]?.credentialsAbility?.can_mail
        },
        shortSelected() {
            return this.selected.slice(0, 25)
        }
    },
    watch: {
        selectedProp: {
            handler(val) {
                this.selected = val
                this.message.contact_ids = val
            },
            deep: true,
            immediate: true
        },
        isSelectAll(val) {
            this.message.contact_ids = val ? 'all' : this.selected
        }
    },
    mounted() {
        this.$eventHub.$on('clearSearch', () => {
            this.fetchOptions.q = ''
        })
    },
    methods: {
        getPreview() {
            Mail.api().getPreview(this.message).then((data) => {
                this.preview = data.response.data.email.preview
                this.$refs.emailPreview.openModal()
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        getTemplates() {
            Mail.api().getTemplates().then((data) => {
                this.templates = data.response.data.templates.map(t => t.template)
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        clearModal() {
            this.message = {
                template_id: 'email_general',
                subject: '',
                contact_ids: [],
                body: ''
            }
            this.$eventHub.$emit('cm-clearModal')
        },
        selectStatus(status, type) {
            this.$emit('selectStatus', status, type)
        },
        clearSearch() {
            this.fetchOptions.q = ''
            this.fetch()
        },
        fetch: utils.debounce(function () {
            this.loading = true
            Contacts.api().fetch(this.fetchOptions).then(() => {
                this.loading = false
            })
        }, 400),
        selectAll(value) {
            this.$emit('selectAll', value)
            this.showContacts = false
        },
        removeContact(contact) {
            this.$eventHub.$emit('cm-selectedTag', contact)
        },
        removeAllContacts() {
            this.$emit('selectAll', false)
        },
        toggleShowContacts(event) {
            if(this.isSelectAll) return
            if (event.target.classList.contains('tagsMK2__icon')) return
            this.showContacts = !this.showContacts
            this.$nextTick(() => {
                if (this.showContacts) document.getElementById('search').focus()
            })
        },
        sendLetter() {
            this.message.contact_ids = this.isSelectAll ? 'all' : this.selected
            Mail.api().sendEmail(this.message).then(() => {
                this.$flash('Your email has been successfully sent', 'success')
                this.closeModal()
                this.clearModal()
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        openModal() {
            this.$refs.letterModal.openModal()
            if (!this.templates.length) this.getTemplates()
        },
        closeModal() {
            this.$refs.letterModal.closeModal()
        },
        recipientName(recipient) {
            let contact = this.allContactsInfo.find(c => c.id === recipient)
            return contact?.name
        }
    }
}
</script>