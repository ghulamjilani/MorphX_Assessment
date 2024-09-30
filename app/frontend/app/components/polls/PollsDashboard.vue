<template>
    <div class="pollsDashboard">
        <div class="pollsDashboard__content">
            <div class="pollsDashboard__title" />
            <m-tabs>
                <m-tab title="Existing Polls">
                    <div
                        v-if="pollTemplates && pollTemplates.length > 0"
                        class="pollsDashboard__list">
                        <div
                            class="pollsDashboard__pollTemplates">
                            <dashboard-poll-template-item
                                v-for="poll in pollTemplates"
                                :key="poll.id"
                                :poll-item="poll" />
                        </div>
                        <div class="pollsDashboard__pollsResult">
                            <dashboard-polls-result />
                        </div>
                    </div>
                    <div v-else>
                        <div class="pollsDashboard__title text__center">
                            <p>There are no polls yet</p>
                        </div>
                    </div>
                </m-tab>

                <m-tab title="New Poll">
					<div class="createUpdatePoll__dashboard">
						<PollCreateForm :is-poll-create="true" />
					</div>
                </m-tab>
            </m-tabs>
        </div>
    </div>
</template>

<script>
import Polls from '@models/Polls'
import DashboardPollTemplateItem from './DashboardPollTemplateItem.vue'
import DashboardPollsResult from './DashboardPollsResult.vue'
import Mtabs from '@uikit/MTabs.vue'
import PollCreateForm from '@components/polls/PollCreateUpdateForm.vue'

export default {
    components: {
        DashboardPollTemplateItem,
        DashboardPollsResult,
		PollCreateForm,
		Mtabs
    },
    data() {
        return {
            pollTemplates: []
        }
    },
    mounted() {
        this.fetchPollTemplates()

        this.$eventHub.$on("poll-template:create", () => {
            this.fetchPollTemplates()
        })
		this.$eventHub.$on("poll-template:update", () => {
			this.fetchPollTemplates()
		})
    },
    methods: {
        fetchPollTemplates() {
            Polls.api().fetchPollTemplates().then((res) => {
                this.pollTemplates = res.response.data
                this.pollTemplates.forEach((item) => {
                    item.options.sort((a, b) => {
                        return a.position - b.position
                    })
                })
            })
        }
    }
}
</script>

<style>

</style>