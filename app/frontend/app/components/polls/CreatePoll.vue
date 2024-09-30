<template>
    <div
        v-show="!hided"
        class="createPoll">
        <div
            class="createPoll__activator"
            @click="open">
            <slot />
        </div>
        <m-modal
            ref="createPollModal"
            :backdrop="false"
            @modalClosed="$eventHub.$emit('tw-pollsStatus', false)">
            <div
                class="createPoll__body"
                :class="{'oneTab' : !canCreate}">
                <m-tabs
                    ref="tabs">
                    <m-tab
                        v-if="canCreate"
                        title="Сhoose Existing Poll">
                        <div
                            v-if="pollTemplatesList && pollTemplatesList.length > 0"
                            class="choosePoll__list">
                            <div
                                v-for="pollTemplate in pollTemplatesList"
                                :key="pollTemplate.value"
                                class="choosePoll__list__item"
                                :class="{'active': pollPreview == pollTemplate.value}">
                                <div
                                    class="choosePoll__list__item__top"
                                    @click="choosePoll(pollTemplate.value)">
                                    <div class="choosePoll__list__item__name">
                                        {{ pollTemplate.name }}
                                    </div>
                                    <div class="choosePoll__list__item__settings">
                                        <div
                                            v-if="enabledCurrentPoll && enabledCurrentPoll.enabled && enabledCurrentPoll.poll_template_id == pollTemplate.value"
                                            class="choosePoll__list__item__startOrStop"
                                            @click="stopPoll($event)">
                                            <div>
                                                <svg
                                                    class="stop-circle"
                                                    width="24"
                                                    height="24"
                                                    viewBox="0 0 24 24"
                                                    fill="none"
                                                    xmlns="http://www.w3.org/2000/svg">
                                                    <path
                                                        d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22Z"
                                                        stroke="#F23535"
                                                        stroke-width="2"
                                                        stroke-linecap="round"
                                                        stroke-linejoin="round" />
                                                    <path
                                                        d="M15 9H9V15H15V9Z"
                                                        stroke="#F23535"
                                                        stroke-width="2"
                                                        stroke-linecap="round"
                                                        stroke-linejoin="round" />
                                                </svg>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div
                                    v-if="pollPreview == pollTemplate.value"
                                    class="choosePoll__list__item__bottom">
                                    <div class="choosePoll__list__item__bottom__left">
                                        <span class="choosePoll__list__item__bottom__left__label">Preview</span>
                                        <poll
                                            :only-show="true"
                                            :poll="previewPoll" />
                                    </div>
                                    <div class="choosePoll__list__item__bottom__right">
                                        <span class="choosePoll__list__item__bottom__left__label">Settings options</span>
                                        <div
                                            class="createUpdatePoll__settings__row">
                                            <span>Multiple Answers</span>
                                            <m-toggle
                                                v-model="multiselect" />
                                        </div>
                                        <div
                                            v-if="poll"
                                            class="createPoll__settings__row">
                                            <m-select
                                                v-model="duration"
                                                label="Choose Duration"
                                                :options="durationOptions" />
                                        </div>
                                        <div
                                            v-if="poll"
                                            class="createPoll__settings__row">
                                            <m-select
                                                v-model="hidden_results"
                                                label="Show results"
                                                :options="showResultsOptions" />
                                        </div>
                                        <div class="text__right">
                                            <m-btn
                                                :disabled="disabled"
                                                :loading="loading"
                                                class=""
                                                type="main"
                                                @click="createPoll()">
                                                Start Poll
                                            </m-btn>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div
                            v-else
                            class="videoComments__empty">
                            No templates yet...
                        </div>
                    </m-tab>

                    <m-tab
                        v-if="canCreate"
                        title="Create New Poll">
                        <div>
                            <PollCreateForm
                                :is-settings="true"
                                :is-poll-create="true"
                                @pollTemplateCreared="pollTemplateCreared" />
                        </div>
                    </m-tab>

                    <m-tab title="Recent Polls">
                        <div class="pollsHistory">
                            <div
                                v-if="!currentPolls || currentPolls.length == 0"
                                class="videoComments__empty">
                                There are no active polls at the moment. As soon as they appear, you will be able to see both the active polls and the results here.
                            </div>
                            <poll
                                v-for="(p) in currentPolls"
                                :key="p.id"
                                :poll="p" />
                        </div>
                    </m-tab>
                </m-tabs>
            </div>
            <template #black_footer>
                <div class="createPoll__buttons">
                    <m-btn
                        class=""
                        type="secondary"
                        @click="closeModal()">
                        Cancel
                    </m-btn>
                </div>
            </template>
        </m-modal>
    </div>
</template>

<script>
import Polls from "@models/Polls"
import Poll from "@components/polls/Poll.vue"
import PollCreateForm from '@components/polls/PollCreateUpdateForm.vue'

export default {
    components: {
        Poll,
		PollCreateForm
    },
    props: {
        modelId: Number,
        modelType: String,
        canCreate: {
            type: Boolean,
            default: false
        }
    },
    data () {
        return {
            createNew: false,
            pollTemplates: [],
            poll: null,
			pollPreview: null,
            duration: "manual",
            multiselect: false,
            hidden_results: false,
            // create new template
            durationOptions: [
                {name: 'Manual Stop', value: 'manual'},
                // {name: 'DEV 1 min', value: '1'},
                {name: '10 min', value: '10'},
                {name: '15 min', value: '15'}
            ],
            showResultsOptions: [
                {name: 'After vote', value: false},
                {name: 'After poll ends', value: true}
            ],
            maxOptions: 10,
            // create new poll
            disabled: false,
            loading: false,
            currentPolls: [],
            hided: false
        }
    },
    computed: {
        pollTemplatesList() {
            return this.pollTemplates.map((item) => {
                return {
                    name: item.question,
                    value: item.id
                }
            })
        },
        previewPoll() {
            return this.poll
        },
        enabledCurrentPoll() {
            return this.currentPolls?.find((item) => {
                return item.enabled === true
            })
        }
    },
    watch: {
        duration(val) {
            if(val !== 'manual') {
                this.poll.duration = +val
            }
        },
        multiselect(val) {
            this.poll.multiselect = val
        }
    },
    mounted() {
        this.$eventHub.$on('poll-template:open', (title = null) => {
            this.open()
            this.hided = false
            if(title) {
                setTimeout(() => {
                    this.$refs?.tabs?.changeByName(title)
                }, 500)
            }
        })
        this.$eventHub.$on('poll-template:close', () => {
        //   this.closeModal()
            this.hided = true
        })

        this.$eventHub.$on("conversation-polls", (polls) => {
            // this.currentPolls = polls
            polls.forEach(poll => {
            let pollIndex = this.currentPolls.findIndex(p => p.id == poll.id)
            if(pollIndex == -1) {
                this.currentPolls.push(poll)
            }
            else {
                this.currentPolls[pollIndex] = poll
            }
        })
        this.currentPolls.sort((a, b) => {
            return new Date(a.created_at).getTime() > new Date(b.created_at).getTime() ? -1 : 1
        })
            // if(this.currentPolls) {
            //     this.currentPolls.sort((a, b) => {
            //         return new Date(a.created_at).getTime() > new Date(b.created_at).getTime() ? -1 : 1
            //     })
            // }
      })
    },
    methods: {
        open() {
            this.poll = null
            this.pollPreview = null
            this.fetchPollsTemplates()
            this.openModal()
        },
        openModal() {
            this.$refs.createPollModal.openModal()
        },
        closeModal() {
            this.$refs.createPollModal.closeModal()
            this.$eventHub.$emit("tw-pollsStatus", false)
        },
        addOption() {
            this.poll.options_attributes.push({key: new Date().getTime(), value: ''})
        },
        removeOption(item) {
            this.poll.options_attributes = this.poll.options_attributes.filter((element) => {
                return element.key !== item.key
            })
        },
        createPoll(id = null) {
            this.loading = true
            let pollInfo = {
                poll_template_id: id ? id : this.poll.id,
                model_id: this.modelId,
                model_type: this.modelType,
                multiselect: this.multiselect,
                hidden_results: this.hidden_results
            }
            if(this.duration !== 'manual') {
                pollInfo.duration = +this.duration
                pollInfo.manual_stop = false
            }
            else {
                pollInfo.manual_stop = true
            }
            Polls.api().createPoll({poll_template_id: pollInfo.poll_template_id, poll: pollInfo}).then((res) => {
                this.loading = false
                this.$emit('createPoll', res.response.data)
                this.closeModal()
                this.currentPolls.push(res.response.data)
            })
        },
        fetchPollsTemplates() {
            Polls.api().fetchPollTemplates().then((res) => {
                this.pollTemplates = res.response.data
            })
        },
        choosePoll(pollId) {
            this.multiselect = false
            this.duration = "manual"
            this.hidden_results = false

            if(this.poll?.id == pollId) {
                this.poll = null
                this.pollPreview = null
                return
            }
            else {
                let poll = this.pollTemplates.find((item) => {
                    item.options_attributes = item.options
                    return item.id === pollId
                })
                this.poll = JSON.parse(JSON.stringify(poll))
                this.pollPreview = pollId
            }
		},
        pollTemplateCreared(data) {
            this.multiselect = data.multiselect
            this.duration = data.duration
            this.createPoll(data.pollTemplate.id)
        },
        stopPoll(event) {
            event.stopPropagation()
            if(this.enabledCurrentPoll) {
                Polls.api().stopPoll({poll_template_id: this.enabledCurrentPoll.poll_template_id, poll_id: this.enabledCurrentPoll.id, enabled: false}).then((res) => {
                    this.$eventHub.$emit("conversation-polls", [res.response.data])
                })
            }
        }
    }
}
</script>

<style>

</style>