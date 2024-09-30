<template>
    <div
        v-if="pollTemplate"
        class="pollsResult">
        <div class="pollsResult__title">
            {{ pollTemplate.question }}
        </div>

        <div
            v-if="pollTemplate"
            class="pollsResult__polls">
            <div
                v-for="poll in polls"
                :key="poll.id"
                class="pollsResult__poll">
                <a
					:href="poll.model.url"
					target="_blank"
					class="pollsResult__poll__session">
                    <div class="pollsResult__poll__session__img">
                        <img
                            :src="poll.model.image_url">
                    </div>
                    <div class="pollsResult__poll__session__details">
                        <div>{{ poll.model.title }}</div>
                        <div>Channel: {{ poll.model.channel.title }}</div>
                        <div>Host: {{ poll.model.user.name }}</div>
                    </div>
                </a>
                <poll
                    :poll="poll"
                    :dashboard="true" />
            </div>
        </div>
        <div v-if="polls && polls.length == 0">
            <p>
                At this moment,
                this voting template has not been used yet.
                Once it's used and results are available,
                you'll be able to view them here.
            </p>
        </div>
    </div>
	
    <div v-else>
        <div class="pollsResult__title text__center">
            <p>Select Poll template to see statistic</p>
        </div>
    </div>
</template>

<script>
import Polls from '@models/Polls'

import Poll from '@components/polls/Poll.vue'

export default {
    components: {
        Poll
    },
    data() {
        return {
            pollTemplate: null,
            polls: []
        }
    },
    mounted() {
        this.$eventHub.$on('polls-open', (poll) => {
            this.pollTemplate = poll
            this.fetchPolls()
        })
    },
    methods: {
        fetchPolls() {
            this.polls = []
            Polls.api().fetchPolls({poll_template_id: this.pollTemplate.id}).then((res) => {
                this.polls = res.response.data.map((item) => {
                    item.options_attributes = item.options
                    return item
                })
            })
        }
    }
}
</script>

<style>

</style>