<template>
    <div class="CM__table__wrapper">
        <table
            v-if="!loading && contacts.length"
            class="CM__table">
            <thead
                v-if="!modal"
                class="CM__table__head">
                <tr>
                    <th />
                    <th class="CM__table__head__th">
                        Name
                    </th>
                    <th class="CM__table__head__th">
                        Email
                    </th>
                    <th class="CM__table__head__th">
                        Subscribe Status
                    </th>
                    <th />
                </tr>
            </thead>
            <thead
                v-else
                class="CM__recipient__table__head">
                <tr>
                    <!-- <th class="CM__recipient__table__head__first" /> -->
                    <th class="CM__recipient__table__head__th">
                        <m-checkbox
                            v-model="isSelectAll"
                            class="CM__recipient__table__all">
                            All
                        </m-checkbox>
                    </th>
                    <!-- <th class="CM__recipient__table__head__th">
                        <m-checkbox v-model="isAllSubscriptions">
                            All Subscriptions
                        </m-checkbox>
                    </th>
                    <th class="CM__recipient__table__head__th CM__recipient__table__head__contacts">
                        <m-checkbox v-model="isAllContacts">
                            All Contacts
                        </m-checkbox>
                    </th> -->
                </tr>
            </thead>
            <tbody v-if="!modal">
                <validation-observer
                    v-for="contact in tableContacts"
                    :key="(modal ? 'm': 't') + contact.id"
                    :ref="`editContactValidate-${contact.id}`"
                    v-slot="{ validate }"
                    class="CM__table__body__tr"
                    tag="tr"
                    @click="selectContact(contact)">
                    <td
                        :class="{'CM__table__check__first' : modal}"
                        class="CM__table__check">
                        <m-checkbox
                            v-model="selected"
                            :class="{'CM__all__checkbox' : modal}"
                            :val="contact.id" />
                    </td>
                    <td
                        class="CM__table__name"
                        data-th="Name">
                        <m-input
                            v-show="contact.isEdit"
                            v-model="currentContact(contact).name"
                            :field-id="modal ? contact.name + ' modal' : contact.name"
                            :maxlength="50"
                            :rules="nameRules"
                            class="CM__table__inputs"
                            placeholder="Name"
                            @enter="switchEdit(contact, validate)" />
                        <div class="CM__table__name__wrapper">
                            <span
                                v-show="!contact.isEdit"
                                class="CM__table__name__title">
                                {{ contact.name }}
                            </span>
                        </div>
                    </td>
                    <td
                        class="CM__table__email"
                        data-th="Email">
                        <m-input
                            v-show="contact.isEdit"
                            v-model="currentContact(contact).email"
                            :field-id="modal ? contact.email + ' modal' : contact.email"
                            :maxlength="128"
                            :validation-debounce="400"
                            class="CM__table__inputs"
                            placeholder="Email"
                            rules="required|email"
                            type="email"
                            @enter="switchEdit(contact, validate)" />
                        <div class="CM__table__email__wrapper">
                            <span
                                v-show="!contact.isEdit"
                                class="display-data">
                                {{ contact.email }}
                            </span>
                        </div>
                    </td>
                    <td
                        :class="{'CM__table__subscription' : contact.status == 'subscription'}"
                        class="CM__table__status"
                        data-th="Status">
                        <span>{{ contact.status.replace(/_/g, " ") }}</span>
                    </td>
                    <td
                        v-if="!modal"
                        data-th="Options">
                        <div class="CM__table__options__wrapper">
                            <div
                                class="CM__table__options"
                                @click="() => {switchEdit(contact, validate), toggleTableOptions()}">
                                <m-icon
                                    class="CM__table__options__icon"
                                    size="0">
                                    GlobalIcon-edit
                                </m-icon>
                                {{ contact.isEdit ? 'Save' : 'Edit' }}
                            </div>
                            <div
                                class="CM__table__options"
                                @click="() => {openRemoveModal(contact), toggleTableOptions()}">
                                <m-icon
                                    class="CM__table__options__icon"
                                    size="0">
                                    GlobalIcon-trash
                                </m-icon>
                                Remove
                            </div>
                        </div>
                    <!-- <m-icon size="0" class="CM__table__dots" @click="toggleTableOptions(contact.id)"> GlobalIcon-dots-3 </m-icon>
        <div @click="toggleTableOptions()" class="channelFilters__icons__options__cover" v-show="tableOptions == contact.id" />
        <div class="channelFilters__icons__options" v-if="tableOptions == contact.id">
          <div class="CM__table__dots__options" @click="() => {copy(contact.email), toggleTableOptions()}">
            <m-icon class="CM__table__dots__options__icon" size="0">GlobalIcon-copy2</m-icon>
            Copy email
          </div>
          <div class="CM__table__dots__options" @click="() => {switchEdit(contact, validate), toggleTableOptions()}">
            <m-icon class="CM__table__dots__options__icon" size="0">GlobalIcon-edit</m-icon>
            {{contact.isEdit ? 'Save' : 'Edit'}}
          </div>
          <div @click="() => {openRemoveModal(contact), toggleTableOptions()}" class="CM__table__dots__options">
            <m-icon class="CM__table__dots__options__icon" size="0">GlobalIcon-trash</m-icon>
            Delete
          </div>
        </div> -->
                    </td>
                </validation-observer>
            </tbody>
            <template v-if="modal">
                <RecycleScroller
                    v-slot="{ item }"
                    class="scroller"
                    :items="tableContacts"
                    :item-size="20"
                    key-field="id"
                    min-item-size="0"
                    list-tag="tbody"
                    item-tag="tr">
                    <td
                        :class="{'CM__table__check__first' : modal, 'hidden-parrent': false && selected.length > 0 && !selected.includes(item.id)}"
                        class="CM__table__check"
                        @click="selectContact(item)">
                        <m-checkbox
                            v-model="selected"
                            :class="{'CM__all__checkbox' : modal}"
                            :val="item.id" />
                    </td>
                    <td
                        class="CM__table__name"
                        data-th="Name"
                        @click="selectContact(item)">
                        <div class="CM__table__name__wrapper">
                            <span
                                class="CM__table__name__title">
                                {{ item.name }}
                            </span>
                        </div>
                    </td>
                    <td
                        class="CM__table__email"
                        data-th="Email"
                        @click="selectContact(item)">
                        <div class="CM__table__email__wrapper">
                            <span
                                class="display-data">
                                {{ item.email }}
                            </span>
                        </div>
                    </td>
                    <td
                        :class="{'CM__table__subscription' : item.status == 'subscription'}"
                        class="CM__table__status"
                        data-th="Status">
                        <span>{{ item.status.replace(/_/g, " ") }}</span>
                    </td>
                </RecycleScroller>
            </template>
        </table>
        <m-loader
            v-else-if="loading"
            class="CM__loader" />
        <div
            v-else
            class="CM__empty">
            No contacts found
        </div>
    </div>
</template>

<script>
import Contacts from "@models/Contacts"

export default {
    props: {
        contacts: Array,
        tableOptions: Number,
        loading: Boolean,
        modal: {
            type: Boolean,
            default: false
        },
        selectedProp: Array,
        isSelectAllProp: Boolean,
        canMailing: Boolean,
        allContactsInfo: Array,
        searchText: String
    },
    data() {
        return {
            nameRules: {
                required: true,
                min: 2,
                regex: /^[A-Za-zА-Яа-яÄäÖöÜüẞß][A-Za-zА-Яа-яÄäÖöÜüẞß0-9\s.\'\"\`\-]+$/
            },
            editContact: [],
            isSelectAll: false,
            isAllContacts: false,
            isAllSubscriptions: false,
            selected: []
        }
    },
    computed: {
        tableContacts() {
            if (this.modal) {
                if(this.isSelectAll) return []
                // if(this.searchText !== "") return this.allContactsInfo.filter(c => c.name.toLowerCase().includes(this.searchText.toLowerCase()))
                return this.allContactsInfo
                // this.selected.length === 0 ? this.allContactsInfo :
                // [...this.allContactsInfo].sort((a, b) => this.selected.includes(b.id) - this.selected.includes(a.id))
            }
            else {
                return this.contacts
            }
        }
    },
    watch: {
        selectedProp: {
            handler(val) {
                if (this.selectedProp && this.selected != this.selectedProp) this.selected = this.selectedProp
            },
            deep: true,
            immediate: true
        },
        isSelectAllProp: {
            handler(val) {
                this.isSelectAll = this.isSelectAllProp
            },
            deep: true,
            immediate: true
        },
        value(val) {
            if (val !== this.selected) {
                this.selected = val
            }
        },
        selected: {
            handler(val) {
                if(this.contacts.some(c => !val.find(s => s === c.id))) {
                    this.$eventHub.$emit('contatcts-isSelectAll', false)
                }
                if(val && val.length === this.totalContacts) {
                    this.$eventHub.$emit('contatcts-isSelectAll', true)
                }
                this.$emit('input', val)
            },
            deep: true
        },
        isSelectAll(val, oldVal) {
            if(val) {
                this.selectAll()
            }
            if(oldVal && !val) {
                this.$eventHub.$emit('contatcts-isSelectAll', false)
                this.$emit('input', [])
            }
        },
        isAllContacts() {
            this.allContacts()
        },
        isAllSubscriptions() {
            this.allSubscriptions()
        }
    },
    mounted() {
        this.$eventHub.$on('cm-selectedTag', (val) => {
            this.selectContact(val)
        })
    },
    methods: {
        selectAll() {
            this.$emit('selectAll', this.isSelectAll)
            if (!this.isSelectAll) {
                this.isAllContacts = false
                this.isAllSubscriptions = false
            }
        },
        currentContact(contact) {
            return this.editContact.find(c => c.id === contact.id) || {}
        },
        allContacts() {
            this.$emit('selectStatus', "contacts", this.isAllContacts)
        },
        allSubscriptions() {
            this.$emit('selectStatus', "subscriptions", this.isAllSubscriptions)
        },
        selectContact(contact) {
            let cId = contact?.id ? contact.id : contact
            if (this.modal) {
                if (this.selected.some(s => s == cId)) {
                    this.selected = this.selected.filter(s => s !== cId)
                } else {
                    this.selected.push(cId)
                }
                this.$emit('input', this.selected)
            }
        },
        copy(value) {
            this.$clipboard(value)
            this.$flash("Сopied!", "success")
        },
        toggleTableOptions(value = null) {
            this.$emit('toggleTableOptions', value)
        },
        openRemoveModal(contact, one = true) {
            this.$emit('openRemoveModal', contact, one)
        },
        switchEdit(contact, validate) {
            if (contact.isEdit) {
                validate().then((valid) => {
                    if (valid) {
                        let currentContact = this.editContact.find(c => c.id === contact.id)
                        Contacts.api().update({
                            id: currentContact.id,
                            name: currentContact.name,
                            email: currentContact.email
                        })
                            .then(() => {
                                Contacts.update({
                                    where: contact.id,
                                    data: {isEdit: false}
                                })
                                this.$flash("Contact has been successfully updated.", "success")
                            })
                            .catch((error) => {
                                let message = error.response?.data?.message
                                message = message || 'Oops, something went wrong.'
                                this.$flash(message)
                            })
                    }
                })
            } else {
                this.editContact.push(JSON.parse(JSON.stringify(contact)))
                Contacts.update({
                    where: contact.id,
                    data: {isEdit: true}
                })
            }
        }
    }
}
</script>