<template>
    <div class="v-contacts">
        <div class="col-md-12 main-content-section edit_contacts_main">
            <div class="technicalPage__label">
                Contacts
            </div>
            <div class="row margin-left-0 margin-right-0">
                <p>
                    Add new contacts or edit your contact list:
                </p>
                <div class="new_userAndImport_users">
                    <div>
                        <validation-observer
                            ref="addNewContactValidate"
                            v-slot="{ handleSubmit }">
                            <form
                                id="new_user"
                                class="form-inline formtastic user form_V2 edit_contacts">
                                <validation-provider
                                    v-slot="{ errors }"
                                    rules="required|email"
                                    vid="email">
                                    <div class="input-block required">
                                        <input
                                            v-model="newCntact.email"
                                            :class="{error: errors.length}"
                                            placeholder="Email"
                                            type="email"
                                            @blur="$refs.addNewContactValidate.reset()">
                                        <div class="errorContainerWrapp">
                                            <span class="error">{{ errors[0] }}</span>
                                        </div>
                                    </div>
                                </validation-provider>
                                <button
                                    class="btn btn-m btn-grey-solid margin-left-22"
                                    @click.prevent="handleSubmit(addNewContacts)">
                                    Add to contact list
                                </button>
                            </form>
                        </validation-observer>
                    </div>
                    <div>
                        <form
                            id="import_users"
                            class="form-inline formtastic user form_V2 edit_contacts">
                            <p>
                                Or select file to upload new contacts
                            </p>
                            <label class="btn btn-m btn-borderred-grey margin-left-10">
                                <input
                                    accept=".csv"
                                    class="inputfile hidden"
                                    type="file"
                                    @change="importContacts">
                                Select file
                            </label>
                        </form>
                    </div>
                </div>
            </div>
            <div class="filters_for_contacts margin-bottom-10">
                <div class="selectAll">
                    <label
                        class="checkbox choice margin-top-10"
                        for="select-all-contacts"
                        @click.prevent="selectAll()">
                        <input
                            id="select-all-contacts"
                            v-model="isSelectAll"
                            class="select-all"
                            type="checkbox">
                        <span>Select All</span>
                    </label>
                    <div
                        v-show="selected.length"
                        class="remove_link"
                        @click="openRemoveModal(null, false)">
                        <i class="VideoClientIcon-trash-2 fs-17 margin-left-20" />
                        <span>Remove</span>
                    </div>
                </div>
                <div class="responsive">
                    <div class="search">
                        <input
                            v-model.trim="fetchOptions.q"
                            placeholder="Search"
                            type="text"
                            @keyup.enter="fetch">
                        <i
                            class="VideoClientIcon-Search"
                            @click="fetch" />
                    </div>
                    <div class="select">
                        <dropdown
                            v-model="fetchOptions.status"
                            :options="statusOptions"
                            placeholder="Status"
                            @change="fetch" />
                    </div>
                </div>
                <div class="custom-paginate">
                    <p class="margin-bottom-0">
                        {{ paginationData.from }}-{{ paginationData.to }} from {{ paginationData.total }}
                    </p>
                    <a
                        :disabled="paginationData.from < paginationData.perPage + 1"
                        class="btn btn-m btn-circle prev_page"
                        @click="fetch({prevPage: true})">
                        <i class="VideoClientIcon-angle-leftF" />
                    </a>
                    <a
                        :disabled="paginationData.to == paginationData.total"
                        class="btn btn-m btn-circle prev_page"
                        @click="fetch({nextPage: true})">
                        <i class="VideoClientIcon-angle-rightF" />
                    </a>
                </div>
            </div>
            <table class="table responsiveTable full-width contacts-table">
                <thead>
                    <tr class="hideForPhone">
                        <th />
                        <th class="name">
                            Name
                        </th>
                        <th>Email</th>
                        <th>Status</th>
                        <th />
                    </tr>
                </thead>
                <tbody>
                    <validation-observer
                        v-for="contact in contacts"
                        :key="contact.id"
                        :ref="`editContactValidate-${contact.id}`"
                        v-slot="{ validate }"
                        tag="tr">
                        <td>
                            <label
                                class="checkbox choice wysiwyg-float-left"
                                @click.prevent="selectContact(contact)">
                                <input
                                    v-model="contact.isSelected"
                                    :value="contact.id"
                                    class="contact-cb"
                                    name="contacts[]"
                                    type="checkbox">
                                <span />
                            </label>
                        </td>
                        <td data-th="Name">
                            <span
                                v-show="!contact.isEdit"
                                class="display-data">
                                {{ contact.name }}
                            </span>
                            <validation-provider
                                v-show="contact.isEdit"
                                v-slot="{ errors }"
                                class="edit-contact-form"
                                name="name"
                                rules="required"
                                tag="div"
                                vid="name">
                                <input
                                    v-model="editContact.name"
                                    class="edit-data edit-name"
                                    placeholder="Name"
                                    type="text">
                                <div class="errorContainerWrapp">
                                    <span class="error">{{ errors[0] }}</span>
                                </div>
                            </validation-provider>
                        </td>
                        <td
                            class="preventEmailOverflow"
                            data-th="Email">
                            <span
                                v-show="!contact.isEdit"
                                class="display-data">
                                {{ contact.email }}
                            </span>
                            <validation-provider
                                v-show="contact.isEdit"
                                v-slot="{ errors }"
                                name="email"
                                rules="required|email"
                                vid="email">
                                <input
                                    v-model="editContact.email"
                                    class="edit-data edit-email"
                                    placeholder="Email"
                                    type="email">
                                <div class="errorContainerWrapp">
                                    <span class="error">{{ errors[0] }}</span>
                                </div>
                            </validation-provider>
                        </td>
                        <td data-th="Status">
                            <span>{{ contact.status.replace(/_/g, " ") | capitalize }}</span>
                        </td>
                        <td
                            class="phone-inline"
                            data-th="Options">
                            <div class="full-width text-right">
                                <a
                                    class="edit_link"
                                    @click="switchEdit(contact, validate)">
                                    <i class="VideoClientIcon-editF fs-17" />
                                    <span v-if="contact.isEdit">Save</span>
                                    <span v-else>Edit</span>
                                </a>
                                <a
                                    class="remove_link"
                                    rel="nofollow"
                                    @click.prevent="openRemoveModal(contact)">
                                    <i class="VideoClientIcon-trash-2 fs-17" />
                                    <span>Remove</span>
                                </a>
                            </div>
                        </td>
                    </validation-observer>
                </tbody>
            </table>
        </div>

        <modal ref="removeModal">
            <template #header>
                <h2 class="title">
                    Remove Contact<span v-if="!isOne">s</span>
                </h2>
            </template>

            <template #body>
                <div class="bodyWrapper remove">
                    Are you sure you want to remove
                    <template v-if="isOne">
                        <b>{{ removeContact.email }}</b> contact?
                    </template>
                    <template v-else>
                        <b>{{ selected.length }}</b> contacts?
                    </template>
                </div>
            </template>

            <template #footer>
                <div class="modal-buttons">
                    <button
                        class="btn btn-l btn-borderred-light"
                        @click="$refs.removeModal.closeModal">
                        Cancel
                    </button>
                    <button
                        class="btn btn-l btn-red"
                        @click="remove">
                        Remove
                    </button>
                </div>
            </template>
        </modal>
    </div>
</template>

<script>
import dropdown from "@components/common/Dropdown"
import Contacts from "@models/Contacts"
import Modal from "@components/common/Modal"

export default {
    components: {dropdown, Modal},
    data() {
        return {
            isSelectAll: false,
            paginationData: {
                to: 50,
                from: 1,
                total: 0,
                perPage: 50
            },
            newCntact: {
                email: ''
            },
            editContact: {
                id: null,
                name: '',
                email: ''
            },
            removeContact: null,
            fetchOptions: {
                q: '',
                offset: 0,
                limit: 50,
                status: undefined
            },
            statusOptions: [
                {name: 'All statuses', value: undefined},
                {name: 'Contacts', value: 0},
                {name: 'Subscription', value: 1},
                {name: 'Unpaid', value: 2},
                {name: 'Canceled', value: 3},
                {name: 'Trial', value: 4},
                {name: 'One time', value: 5},
                {name: 'Opt In', value: 6}
            ]
        }
    },
    computed: {
        contacts() {
            return Contacts.query().orderBy('id', 'desc').get()
        },
        selected() {
            return Contacts.query().where('isSelected', true).orderBy('id', 'desc').get()
        }
    },
    mounted() {
        this.addHeaderTopClass()
    },
    created() {
        Contacts.api().fetch(this.fetchOptions).then((data) => {
            this.updatePagination(data.response?.data)
        })
    },
    methods: {
        addHeaderTopClass() {
            let bodyTag = document.body
            bodyTag.classList.add('header-top')
        },
        addNewContacts() {
            Contacts.api().create(this.newCntact)
                .then((data) => {
                    this.newCntact.email = ''
                    this.$refs.addNewContactValidate.reset()
                    this.paginationData.to++
                    this.paginationData.total++
                    $.showFlashMessage("Contact has been successfully added.", {type: "success"})
                })
                .catch((error) => {
                    let message = error.response?.data?.message
                    if (message) {
                        this.$refs.addNewContactValidate.setErrors({
                            email: [message]
                        })
                    }
                })
        },
        updatePagination(data) {
            this.paginationData.total = data.pagination?.count
            this.paginationData.from = data.pagination?.offset + 1
            this.paginationData.to = +data.pagination?.offset + data.response.length
        },
        fetch(options = {}) {
            if (options.nextPage) {
                this.fetchOptions.offset = this.fetchOptions.offset + this.paginationData.perPage
            }
            if (options.prevPage) {
                this.fetchOptions.offset = this.fetchOptions.offset - this.paginationData.perPage
            }
            Contacts.api().fetch(this.fetchOptions).then((data) => {
                this.updatePagination(data.response?.data)
            })
            this.isSelectAll = false
        },
        openRemoveModal(contact, one = true) {
            this.isOne = one
            if (contact) {
                this.removeContact = JSON.parse(JSON.stringify(contact))
            }
            this.$refs.removeModal.openModal()
        },
        remove() {
            if (this.isOne) {
                Contacts.api().remove({ids: [this.removeContact.id]}).then((data) => {
                    this.$refs.removeModal.closeModal()
                    this.updatePagination(data.response.data)
                    $.showFlashMessage("Contact has been successfully removed.", {type: "success"})
                })
            } else {
                Contacts.api().remove({
                    ids: this.selected.map((contact) => {
                        return contact.id
                    })
                }).then((data) => {
                    this.$refs.removeModal.closeModal()
                    this.isSelectAll = false
                    this.updatePagination(data.response.data)
                    $.showFlashMessage("Contacts has been successfully removed.", {type: "success"})
                })
            }
        },
        importContacts(event) {
            Contacts.api().importFromCSV({file: event.target.files[0]}).then((data) => {
                this.updatePagination(data.response?.data)
                $.showFlashMessage("Contact has been successfully updated.", {type: "success"})
            })
                .catch((error) => {
                    $.showFlashMessage("File couldn’t be processed", {type: "error"})
                })
                .then(() => {
                    event.target.value = ""
                })
        },
        selectContact(contact) {
            if (!contact.isEdit) {
                Contacts.update({
                    where: contact.id,
                    data: {isSelected: !contact.isSelected}
                })
            }
            document.querySelector("#send-email-button").disabled = !this.selected.length
        },
        selectAll() {
            this.isSelectAll = !this.isSelectAll
            Contacts.update({
                where: record => true,
                data: {isSelected: this.isSelectAll}
            })
        },
        switchEdit(contact, validate) {
            if (contact.isEdit) {
                validate().then((valid) => {
                    if (valid) {
                        Contacts.api().update({
                            id: this.editContact.id,
                            name: this.editContact.name,
                            email: this.editContact.email
                        })
                            .then(() => {
                                Contacts.update({
                                    where: contact.id,
                                    data: {isEdit: false}
                                })
                                $.showFlashMessage("Contact has been successfully updated.", {type: "success"})
                            })
                            .catch((error) => {
                                let message = error.response?.data?.message
                                message = message || 'Oops, something went wrong.'
                                $.showFlashMessage(message, {type: "error"})
                            })
                    }
                })
            } else {
                this.editContact = JSON.parse(JSON.stringify(contact))
                Contacts.update({
                    where: contact.id,
                    data: {isEdit: true}
                })
            }
        }
    }
}
</script>
