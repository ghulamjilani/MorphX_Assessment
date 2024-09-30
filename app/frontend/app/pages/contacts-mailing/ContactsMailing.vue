<template>
    <div class="CM">
        <remove-modal
            ref="removeModal"
            :is-select-all="isSelectAll"
            :is-one="isOne"
            :remove-contact="removeContact"
            :selected="selected"
            @updatePagination="updatePagination" />
        <letter-modal
            ref="letterModal"
            :contacts="contacts"
            :is-select-all="isSelectAll"
            :selected-prop="selected"
            :total-contacts="totalContacts"
            :all-contacts-info="allContactsInfo"
            @selectAll="selectAll"
            @selectStatus="selectStatus" />
        <div class="CM__title">
            {{ canMailing ? 'Contacts & Mailing' : 'Contacts' }}
        </div>
        <div class="CM__form__title">
            Add new contacts to your contact list:
        </div>
        <new-form
            ref="form"
            v-model="newContact"
            @addNewContacts="addNewContacts"
            @importContacts="importContacts" />
        <div class="CM__export">
            <m-btn
                type="secondary"
                @click="fetchCSV">
                Export all/selected CSV
            </m-btn>
        </div>
        <div
            v-if="canMailing"
            class="CM__write">
            <div
                class="CM__write__title">
                Write a welcome email to selected contacts:
            </div>
            <m-btn
                type="save"
                @click="openLetterModal()">
                Write Email
            </m-btn>
        </div>
        <filters
            v-model="fetchOptions"
            :is-select-all-prop="isSelectAll"
            :pagination-data="paginationData"
            :selected="selected"
            :status-options="statusOptions"
            :can-mailing="canMailing"
            :contacts="contacts"
            @clearSearch="clearSearch"
            @fetch="fetch"
            @openRemoveModal="openRemoveModal"
            @selectAll="selectAll"
            @selectAllOnPage="selectAllOnPage"
            @selectAllByStatus="selectAllByStatus" />
        <div
            v-if="isSelectAll"
            class="CM__selectedInfo">
            Selected all contacts ({{ totalContacts }})
        </div>
        <div
            v-if="!isSelectAll && selected && selected.length > 0"
            class="CM__selectedInfo">
            Selected contacts ({{ selected.length }}).
            <m-btn
                v-if="!isSelectAll && fetchOptions.q == '' && currentSearchTotal > paginationData.perPage &&
                    ((fetchOptions.status && fetchOptions.status.length === 0) ||
                        (fetchOptions.statusRaw && fetchOptions.statusRaw[0].value == 'all'))"
                :reset="true"
                @click="selectAll(true)">
                Select all contacts ({{ totalContacts }})
            </m-btn>
            <m-btn
                v-if="!isSelectAll && currentSearchTotal > paginationData.perPage &&
                    (fetchOptions.q !== '' || (fetchOptions.status && fetchOptions.status.length > 0)) &&
                    !currentSearchSelected && !isSelectedAllInGroup"
                :reset="true"
                @click="selectAllQuery(false)">
                <span>
                    Select all contacts in this query ({{ currentSearchTotal }})
                </span>
            </m-btn>
        </div>
        <table-contact
            v-model="selected"
            :contacts="contacts"
            :loading="loading"
            :selected-prop="selected"
            :table-options="tableOptions"
            :can-mailing="canMailing"
            @openRemoveModal="openRemoveModal"
            @selectStatus="selectStatus"
            @toggleTableOptions="toggleTableOptions" />

        <div class="CM__paginate">
            <p class="CM__paginate__text">
                {{ paginationData.from }}-{{ paginationData.to }} from {{ paginationData.total }}
            </p>
            <a
                :class="{'CM__paginate__disable' : paginationData.from < paginationData.perPage + 1}"
                class="CM__paginate__arrow"
                @click="fetch({prevPage: true})">
                <m-icon
                    :class="{'CM__paginate__icon__disable' : paginationData.from < paginationData.perPage + 1}"
                    class="CM__paginate__icon"
                    size="0">
                    GlobalIcon-angle-left
                </m-icon>
            </a>
            <a
                :class="{'CM__paginate__disable' : paginationData.to == paginationData.total}"
                class="CM__paginate__arrow"
                @click="fetch({nextPage: true})">
                <m-icon
                    :class="{'CM__paginate__icon__disable' : paginationData.to == paginationData.total}"
                    class="CM__paginate__icon"
                    size="0">
                    GlobalIcon-angle-right
                </m-icon>
            </a>
        </div>
    </div>
</template>

<script>
import NewForm from '@components/contacts-mailing/NewForm.vue'
import Filters from '@components/contacts-mailing/Filters.vue'
import RemoveModal from '@components/contacts-mailing/RemoveModal.vue'
import TableContact from '@components/contacts-mailing/TableContact.vue'
import LetterModal from '@components/contacts-mailing/LetterModal.vue'

import Contacts from "@models/Contacts"

export default {
    components: {NewForm, Filters, RemoveModal, TableContact, LetterModal},
    data() {
        return {
            isOne: true,
            isSelectAll: false,
            paginationData: {
                to: 25,
                from: 1,
                total: 0,
                perPage: 25
            },
            newContact: {
                first_name: '',
                last_name: '',
                email: ''
            },
            removeContact: null,
            fetchOptions: {
                q: '',
                offset: 0,
                limit: 25,
                status: [],
                statusRaw: []
            },
            statusOptions: [
                {name: 'All statuses', value: "all", selectText: "Status"},
                {name: 'Contacts', value: 0, statusName: "contact", selectText: "Contacts"},
                {name: 'Subscription', value: 1, statusName: "subscription", selectText: "Subscription"},
                {name: 'Unpaid', value: 2, statusName: "unpaid", selectText: "Unpaid"},
                {name: 'Canceled', value: 3, statusName: "canceled", selectText: "Canceled"},
                {name: 'Trial', value: 4, statusName: "trial", selectText: "Trial"},
                {name: 'One time', value: 5, statusName: "one_time", selectText: "One time"},
                {name: 'Opt In', value: 6, statusName: "opt_in",  selectText: "Opt In"}
            ],
            tableOptions: null,
            loading: true,
            selected: [],
            totalContacts: 0,
            currentSearchTotal: 0,
            currentSearchSelected: false,
            allContactsInfo: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        canMailing() {
            return this.currentUser.credentialsAbility.can_mail &&
            this.currentUser?.subscriptionAbility?.can_manage_contacts_and_mailing
        },
        contacts() {
            return Contacts.query().orderBy('id', 'desc').get()
        },
        contactsStatus() {
            return Contacts.query().where('status', 'contact').get()
        },
        subscriptionsStatus() {
            return Contacts.query().where('status', 'subscription').get()
        },
        getStatusName() {
            return this.statusOptions.find(opt => opt.value == this.fetchOptions.status)?.name
        },
        isSelectedAllInGroup() {
            if(this.isSelectAll) return true
            else if(this.fetchOptions.q !== "") return false
            else {
                return !this.allContactsInfo.some(ci => this.fetchOptions.statusRaw.some(s => ci.status == s.statusName) &&
                     !this.selected.includes(ci.id))
            }
        }
    },
    watch: {
        selected(val) {
            if(this.isSelectAll && this.contacts.some(c => !val.find(s => s === c.id))) {
                this.isSelectAll = false
            }
            if(val && val.length === this.totalContacts) {
                this.isSelectAll = true
            }
            this.$eventHub.$emit("contacts-page-update")
        },
        fetchOptions: {
            handler() {
                this.currentSearchSelected = false
            },
            deep: true
        }
    },
    mounted() {
        this.addHeaderTopClass()
    },
    created() {
        this.fetch().then(() => {
            this.selectAllQuery(true)
        })
        this.$eventHub.$on('cm-clearSelected', () => {
            this.selected = []
        })
        this.$eventHub.$on('contatcts-isSelectAll', (value) => {
            this.isSelectAll = value
        })
        this.$eventHub.$on('cm-clearModal', () => {
            this.selected = []
            this.fetchOptions = {
                q: '',
                offset: 0,
                limit: 25,
                status: [],
                statusRaw: []
            }
            this.clearSearch()
        })
    },
    methods: {
        toggleTableOptions(value = null) {
            this.tableOptions = value
        },
        clearSearch() {
            this.fetchOptions.q = ''
            this.fetch()
        },
        addHeaderTopClass() {
            let bodyTag = document.body
            bodyTag.classList.add('header-top')
        },
        addNewContacts() {
            Contacts.api().create(this.newContact)
                .then((data) => {
                    this.newContact.email = ''
                    this.newContact.last_name = ''
                    this.newContact.first_name = ''
                    this.$refs.form.$refs.form.observerReset()
                    this.paginationData.to++
                    this.paginationData.total++
                    this.$flash("Contact has been successfully added.", "success")
                })
                .catch((error) => {
                    this.newContact.email = ''
                    this.newContact.last_name = ''
                    this.newContact.first_name = ''
                    this.$refs.form.$refs.form.observerReset()
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
        },
        updatePagination(data) {
            this.paginationData.total = data.pagination?.count
            this.paginationData.from = this.paginationData.total == 0 ? 0 : data.pagination?.offset + 1
            this.paginationData.to = +data.pagination?.offset + data.response.length
            if(this.isSelectAll) {
                let add = this.contacts.filter(d => !this.selected.find(p => p === d.id))
                this.selected = this.selected.concat(add.map(a => a.id))
            }
        },
        fetch(options = {}) {
            this.loading = true
            if (options.nextPage) {
                this.fetchOptions.offset = this.fetchOptions.offset + this.paginationData.perPage
            }
            if (options.prevPage) {
                this.fetchOptions.offset = this.fetchOptions.offset - this.paginationData.perPage
            }
            if(this.isSelectAll || this.selected.length == 0) {
                this.fetchOptions.ids = "all"
            }
            this.fetchOptions.status = this.fetchOptions.statusRaw.map(so => so.value)
            if(this.fetchOptions.status[0] == "all") {
                delete this.fetchOptions.status
            }
            return new Promise((resolve, reject) => {
                Contacts.api()[options.onlyData ? "fetchOnlyData" : "fetch"](this.fetchOptions).then((data) => {
                    if(!options.onlyData) this.updatePagination(data.response?.data)
                    this.loading = false
                    if((!this.fetchOptions.status || this.fetchOptions.status.length === 0)
                        && this.fetchOptions.q === "") {
                        this.totalContacts = data.response?.data.pagination?.count
                    }
                    this.currentSearchTotal = data.response?.data.pagination?.count
                    this.$eventHub.$emit("contacts-page-update")
                    this.addAllContactsInfo(data.response?.data.response)
                    resolve(data)
                }).catch(error => {
                    this.loading = false
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                    reject()
                })
            })
        },
        fetchCSV() {
            if(this.isSelectAll || this.selected.length == 0) {
                this.fetchOptions.ids = "all"
            }
            else {
                this.fetchOptions.ids = this.selected
            }
            this.fetchOptions.status = this.fetchOptions.statusRaw.map(so => so.value)
            if(this.fetchOptions.status[0] == "all") {
                delete this.fetchOptions.status
            }
            Contacts.api().fetchCSV(this.fetchOptions).then((res) => {
                let encodedUri = encodeURI("data:text/csv;charset=utf-8," + res.response.data)
                let link = document.createElement("a")
                link.setAttribute("href", encodedUri)
                link.setAttribute("download", "contacts.csv")
                document.body.appendChild(link) // Required for FF
                link.click()
                delete this.fetchOptions.ids
            })
        },
        openLetterModal() {
            this.$refs.letterModal.openModal()
        },
        openRemoveModal(contact, one = true) {
            this.isOne = one
            if (contact) {
                this.removeContact = JSON.parse(JSON.stringify(contact))
            }
            this.$refs.removeModal.openModal()
        },
        importContacts(event) {
            Contacts.api().importFromCSV({file: event.target.files[0]}).then((data) => {
                this.updatePagination(data.response?.data)
                this.$flash("Contacts has been successfully updated.", "success")
            })
                .catch((error) => {
                    this.$flash("File couldn’t be processed")
                })
                .then(() => {
                    event.target.value = ""
                })
        },
        selectAll(value) {
            this.isSelectAll = value
            if (value) {
                let add = this.contacts.filter(d => !this.selected.find(p => p === d.id))
                this.selected = this.selected.concat(add.map(a => a.id))
            } else {
                this.selected = []
            }
            this.fetch().then(() => {
                if(value) {
                    this.selected = this.contacts.map(c => c.id)
                }
                else {
                    this.selected = []
                }
            })
        },
        selectAllOnPage(value) {
            if(value) {
                let add = this.contacts.filter(c => !this.selected.find(s => s === c.id))
                this.selected = this.selected.concat(add.map(a => a.id))
            }
            else {
                this.selected = this.selected.filter(s => !this.contacts.find(c => c.id === s))
            }
        },
        selectAllByStatus(flag) {
            this.isSelectAll = flag
            this.fetch().then(() => {
                if(flag) {
                    this.selected = this.contacts.map(c => c.id)
                }
                else {
                    this.selected = []
                }
            })
        },
        selectStatus(status, type) {
            if (!type && !this.isSelectAll) {
                if (status == 'contacts') {
                    this.selected = this.subscriptionsStatus.filter(d => {
                        return this.selected.find(p => p === d.id)
                    })
                } else {
                    this.selected = this.contactsStatus.filter(d => {
                        return this.selected.find(p => p === d.id)
                    })
                }
            } else if (type) {
                if (status == 'contacts') {
                    let add = this.contactsStatus.filter(d => !this.selected.find(p => p === d.id))
                    this.selected = this.selected.concat(add.map(a => a.id))
                } else {
                    let add = this.subscriptionsStatus.filter(d => !this.selected.find(p => p === d.id))
                    this.selected = this.selected.concat(add.map(a => a.id))
                }
            }
        },
        selectAllQuery(preload = false) {
            let oldOptions = JSON.parse(JSON.stringify(this.fetchOptions))
            this.fetchOptions.limit = this.currentSearchTotal
            this.fetchOptions.offset = 0
            this.fetch({onlyData: true}).then((data) => {
                this.fetchOptions.limit = oldOptions.limit
                this.fetchOptions.offset = oldOptions.offset
                if(!preload) {
                    let add = data.response?.data.response.filter(c => !this.selected.find(s => s === c.id))
                    this.selected = this.selected.concat(add.map(a => a.id))
                    this.$nextTick(() => {
                        this.currentSearchSelected = true
                    })
                }
                this.addAllContactsInfo(data.response?.data.response)
            })
        },
        addAllContactsInfo(data) {
            if(data) {
                let add = data.filter(c => !this.allContactsInfo.find(s => s.id === c.id))
                this.allContactsInfo = this.allContactsInfo.concat(add)
            }
        }
    }
}
</script>
