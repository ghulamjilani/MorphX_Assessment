<template>
    <m-modal
        ref="editPostModal"
        :backdrop="false"
        :confirm="true"
        :text-confirm="textConfirm()"
        class="editPostModal">
        <new-post
            :edit-post="editPost"
            :channel-id="channelId"
            @close="close"
            @created="createdPost"
            @update="update" />
    </m-modal>
</template>

<script>
import NewPost from './NewPost'

export default {
    components: {NewPost},
    props: {
        editPost: {},
        channelId: {
            type: Number,
            default: null
        }
    },
    methods: {
        open() {
            this.$refs.editPostModal.openModal()
        },
        textConfirm() {
            if (this.editPost?.status == 'draft') return 'Are you sure to close without saving as draft?'
            return 'Are you sure to close this tab?'
        },
        close(create = false) {
            if (!create && this.editPost?.status == 'draft') {
                if (confirm('Are you sure to close without saving as draft?')) {
                    this.$eventHub.$emit('clearData-post')
                    this.$refs.editPostModal.closeModal(false, false)
                } else {
                    return
                }
            } else if (!create && this.editPost?.status) {
                if (confirm('Are you sure to close this tab?')) {
                    this.$eventHub.$emit('clearData-post')
                    this.$refs.editPostModal.closeModal(false, false)
                } else {
                    return
                }
            } else {
                this.$refs.editPostModal.closeModal(false, false)
            }
        },
        update(post) {
            this.$emit("updated", post)
        },
        createdPost(post) {
            this.$emit("created", post)
        }
    }
}
</script>