<template>
    <div
        class="pollItem"
        :class="{'active': isActive}"
        @click="openPollInfo">
        <div class="pollItem__details">
            <div class="pollItem__top">
                <div class="pollItem__question">
                    {{ pollItem.question }}
                </div>

                <div class="pollItem__settings">
                    <!--
                    <m-icon
                        v-tooltip="'Hide in creation list'"
                        size="1.8rem">
                        GlobalIcon-eye
                    </m-icon>
                     <m-icon
                        v-tooltip="'Edit'"
                        size="1.8rem">
                        GlobalIcon-Pensil2
                    </m-icon>
                    <m-icon
                        v-tooltip="'Lock from editing'"
                        size="1.8rem">
                        GlobalIcon-lock
                    </m-icon>
                    -->
                    <!-- TODO: m-dropdown -->
                    <m-dropdown
                        ref="pollItemDropdown"
                        class="pollItem__dropdown">
                        <m-option
                            @click="pollEdit">
                            Edit
                        </m-option>
                        <!--
                        <m-option
                            @click="pollArchive">
                            Send to archive
                        </m-option>
						-->
                        <m-option
                            @click="pollDelete">
                            Delete
                        </m-option>
                    </m-dropdown>
                </div>
            </div>

            <div class="pollItem__hr" />

            <div class="pollItem__bottom">
                <div class="pollItem__votes">
                    {{ pollItem.votes_count || 0 }} votes
                </div>
				<span>•</span>
                <div class="pollItem__used">
                    {{ pollItem.polls_count || 0 }} times used
                </div>
            </div>
        </div>

        <m-modal
            ref="editPollModal"
            :backdrop="false"
            @close="closeEditPollModal">
            <template slot="header">
                <h3 class="modal-title">
                    Poll Update
                </h3>
            </template>

            <PollCreateUpdateForm
                :poll-item="pollItem"
                :is-poll-create="false"
                @close="closeEditPollModal" />
        </m-modal>
    </div>
</template>

<script>
import PollCreateUpdateForm from "./PollCreateUpdateForm.vue"
import NewPost from "../blog/NewPost.vue"
import Polls from "@models/Polls"

export default {
	components: {NewPost, PollCreateUpdateForm},
    props: {
        pollItem: {
            type: Object,
            required: true
        }
    },
    data() {
        return {
            isActive: null
        }
    },
    mounted() {
        this.$eventHub.$on('polls-open', (poll) => {
            if (poll.id !== this.pollItem.id) {
                this.isActive = false
            }
        })
		console.info(this.pollItem)
    },
    methods: {
        closeOptionsDropdown() {
            this.$refs.pollItemDropdown.close()
        },
        openPollInfo() {
            if(!this.isActive) {
                this.isActive = true
                this.$eventHub.$emit('polls-open', this.pollItem)
            }
        },
		pollEdit() {
			this.$refs.editPollModal.openModal()
		},
		pollArchive(){
			Polls.api().updatePollTemplate({ poll_template_id: this.pollItem.id, is_archived: true })
				.then((res) => {
					this.$flash("Poll ' " + this.pollItem.question + " ' archived", 'success')
					this.$eventHub.$emit("poll-template:update")
				})
				.catch((error) => {
					this.loading = false
					this.$flash("Failed to archive poll: " + error.message, 'error')
				})
		},
		pollDelete() {
			Polls.api().deletePollTemplate({ poll_template_id: this.pollItem.id, is_archived: false })
				.then((res) => {
					console.log("Poll deleted successfully")
					this.$flash(`Poll '${this.pollItem.question}' was deleted successfully`, "success")
					this.$eventHub.$emit("poll-template:update")
				})
				.catch((error) => {
					console.log("Error:", error)
					this.loading = false
					this.$flash("Failed to delete poll: " + error.message, "error")
					this.$eventHub.$emit("poll-template:update")
				})

		},
		closeEditPollModal() {
			this.$refs.editPollModal.closeModal()
		}
    }
}
</script>

<style>

</style>