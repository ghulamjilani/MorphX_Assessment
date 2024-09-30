<template>
    <m-modal
        ref="removeModal"
        class="CM__Rmodal">
        <template #header>
            <div class="CM__Rmodal__title">
                Remove Contact{{ isOne ? '' : 's' }}
            </div>
        </template>
        <div class="CM__Rmodal__body">
            Are you sure you want to remove
            {{ isOne && removeContact ? removeContact.email + ' contact?' : (isSelectAll ? 'all contacts?' : selected.length + ' contacts?') }}
        </div>
        <template #black_footer>
            <div class="CM__Rmodal__buttons__wrapper">
                <div class="CM__Rmodal__buttons">
                    <m-btn
                        size="s"
                        type="secondary"
                        @click="closeModal">
                        Cancel
                    </m-btn>
                    <m-btn
                        size="s"
                        type="main"
                        @click="remove">
                        Remove
                    </m-btn>
                </div>
            </div>
        </template>
    </m-modal>
</template>

<script>
import Contacts from "@models/Contacts"

export default {
    props: {
        isOne: Boolean,
        removeContact: Object,
        selected: Array,
        isSelectAll: Boolean
    },
    methods: {
        openModal() {
            this.$refs.removeModal.openModal()
        },
        closeModal() {
            if (this.$refs.removeModal) this.$refs.removeModal.closeModal()
        },
        remove() {
            if (this.isOne) {
                Contacts.api().remove({ids: [this.removeContact.id]}).then((data) => {
                    this.$refs.removeModal.closeModal()
                    this.$emit('updatePagination', data.response.data)
                    this.$flash("Contact has been successfully removed.", "success")
                    this.$eventHub.$emit('cm-clearSelected')
                })
            } else {
                let ids = this.isSelectAll ? 'all' : this.selected
                Contacts.api().remove({ ids }).then((data) => {
                    this.$refs.removeModal.closeModal()
                    this.$emit('updatePagination', data.response.data)
                    this.$flash("Contacts has been successfully removed.", "success")
                    this.$eventHub.$emit('cm-clearSelected')
                })
            }
        }
    }
}
</script>