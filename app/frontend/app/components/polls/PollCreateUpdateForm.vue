<template>
    <div class="createUpdatePoll">
        <m-form v-if="poll">
            <section>
                <m-input
                    v-model="poll.question"
                    type="text"
                    label="Your Question"
                    :max-counter="80"
                    :maxlength="80" />
                <div class="createUpdatePoll__options">
                    <draggable
                        v-model="poll.options"
                        draggable=".item"
                        @input="handleOptionOrderChange">
                        <template v-for="(element, index) in poll.options">
                            <div
                                v-show="!element._destroy"
                                :key="index"
                                class="item createUpdatePoll__options__item">
                                <m-icon>
                                    GlobalIcon-list
                                </m-icon>
                                <!--TODO show max-counter-->
                                <div class="createUpdatePoll__options__item__input">
                                    <m-input
                                        v-model="element.title"
                                        type="text"
                                        placeholder="Option"
                                        :max-counter="40"
                                        :maxlength="40"
                                        :pure="true"
                                        :errors="false" />
                                </div>
                                <m-icon
                                    class="createUpdatePoll__options__item__remove"
                                    @click="removeOption(index)">
                                    GlobalIcon-clear
                                </m-icon>
                            </div>
                        </template>
                    </draggable>
                    <div
                        v-if="poll.options.length < maxOptions"
                        slot="footer"
                        class="createUpdatePoll__options__add"
                        @click="addOption">
                        <m-icon> GlobalIcon-plus-circle </m-icon>
                        Add Option
                    </div>
                    <div v-else>
                        <p class="createUpdatePoll__options__add__error">
                            You can add up to 10 options
                        </p>
                    </div>
                </div>
            </section>

            <section v-if="isSettings">
                <div
                    class="createUpdatePoll__settings">
                    <div
                        class="createUpdatePoll__settings__row">
                        <span>Multiple Answers</span>
                        <m-toggle
                            v-model="multiselect" />
                    </div>
                    <div class="createUpdatePoll__settings__row">
                        <m-select
                            v-model="duration"
                            label="Choose Duration"
                            :options="durationOptions" />
                    </div>
                    <div class="createUpdatePoll__settings__row">
                        <m-select
													v-model="hidden_results"
													label="Show results"
													:options="showResultsOptions" />
                    </div>
                </div>
            </section>
            <!-- if poll create-->
            <div class="text__right">
                <m-btn
                    v-if="isPollCreate"
                    :disabled="disabled"
                    :loading="loading"
                    class=""
                    type="main"
                    @click="createTemplate()">
                    Create Poll
                </m-btn>
                <!-- if poll update-->
                <m-btn
                    v-else
                    :disabled="disabled"
                    :loading="loading"
                    class=""
                    type="main"
                    @click="updateTemplate()">
                    Update Poll
                </m-btn>
            </div>
            <!-- if close-->
        </m-form>
    </div>
</template>

<script>
import Draggable from "vuedraggable"
import Polls from "@models/Polls"

export default {
	components: {
		Draggable
	},
	props: {
		isPollCreate: {
			type: Boolean,
			default: true
		},
		isSettings:{
			type: Boolean,
			default: false
		},
		modelId: Number,
		modelType: String,
		pollItem: Object // Adding a new prop to pass survey data to the component
	},
	data () {
		return {
			poll: {
				name: '',
				question: '',
				options: [
					{key: 1, title: '', _destroy: false, position: 0},
					{key: 2, title: '', _destroy: false, position: 1},
					{key: 3, title: '', _destroy: false, position: 2}
				],
				multiselect: false
			},
			defaultPoll: {
				name: '',
				question: '',
				options: [
					{key: 1, title: '', _destroy: false, position: 0},
					{key: 2, title: '', _destroy: false, position: 1},
					{key: 3, title: '', _destroy: false, position: 2}
				],
				multiselect: false
			},
			maxOptions: 10,
			// create new poll
			loading: false,

			// settings
			multiselect: false,
			duration: "manual",
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
			hidden_results: false
		}
	},
	computed: {
		filteredOptions() {
			return this.poll.options.filter(option => !option._destroy)
		},
		disabled() {
			return this.poll.question === '' || this.filteredOptions.length < 2 || this.filteredOptions.filter((item) => {
				return item.title !== ''
			}).length < 2
		}
	},
	mounted() {
		if (!this.isPollCreate && this.pollItem) {
			this.poll = JSON.parse(JSON.stringify(this.pollItem))
			this.poll.options.forEach((item, index) => {
				item.position = index
				item._destroy = false
			})
			console.log(this.poll)
		} else {
			this.createNewPollTemplate()
		}
	},
	methods: {
		addOption() {
			this.poll.options.push({key: new Date().getTime(), value: '', position: this.poll.options.length, _destroy: false})
		},
		removeOption(index) {
			const optionToDelete = this.poll.options[index]
			if (optionToDelete.id) {
				// If the option already exists in the database, mark it for deletion
				optionToDelete._destroy = true
				// Update the array for Vue
				this.poll.options = this.poll.options.map((item) => {
					if (item.id === optionToDelete.id) {
						return optionToDelete
					}
					return item
				})
			} else {
				// If the option is new (does not exist in the database), remove it from the array
				this.poll.options.splice(index, 1)
			}
		},
		handleOptionOrderChange(newOptions) {
			// Update the order of options in an array
			this.poll.options = newOptions
		},
		createNewPollTemplate() {
			this.poll = JSON.parse(JSON.stringify(this.defaultPoll))
		},
		createTemplate() {
			this.loading = true
			this.poll.options.forEach((item, index) => {
				item.position = index
			})
			this.poll.options_attributes = this.poll.options.filter((item) => {
				return item.title !== ''
			})

			Polls.api().createTemplate({poll_template: this.poll})
				.then((res) => {
				this.loading = false
				this.$flash("Poll ' " + this.poll.question + " ' was created", 'success')
				this.createNewPollTemplate()
				this.$eventHub.$emit("poll-template:create")
				this.$emit("pollTemplateCreared", {
						pollTemplate: res.response.data,
						multiselect: this.multiselect,
						duration: this.duration,
						hidden_results: this.hidden_results
					})
				})
				.catch((error) => {
					this.loading = false
					this.$flash("Failed to create poll: " + error.message, 'error')
				})
		},
		updateTemplate() {
			this.loading = true
			this.poll.options.forEach((item, index) => {
				item.position = index
			})
			this.poll.options_attributes = this.poll.options.filter((item) => {
				return item.title !== ''
			})

			Polls.api().updatePollTemplate({ poll_template: this.poll, poll_template_id: this.poll.id })
				.then((res) => {
					this.loading = false
					this.$flash("Poll '" + this.poll.question + "' was updated", 'success')
					this.$eventHub.$emit("poll-template:update")
					this.$emit("close")
				})
				.catch((error) => {
					this.loading = false
					this.$flash("Failed to update poll: " + error.message, 'error')
				})
		}
	}
}
</script>