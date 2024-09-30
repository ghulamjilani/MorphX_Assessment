<template>
    <div
        class="poll"
        :class="dashboard ? 'dashboard': '' + `poll-${poll.id}`">
        <div
            v-if="!dashboard"
            class="poll__question">
            {{ poll.question }}
        </div>
        <div
            v-if="!dashboard && isCreator && poll.enabled"
            class="poll__stop"
            @click="stopPoll">
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
        <div
            v-if="!dashboard"
            class="poll__hr" />

        <div
            v-for="(option, index) in poll.options"
            :key="index"
            class="poll__option">
            <m-radio
                v-if="!poll.multiselect && canVote"
                v-model="answer"
                :val="option.id"
                :disabled="onlyShow || dashboard">
                <div class="poll__option__answer">
                    {{ option.title }}
                    <span
                        class="poll__option__answer__resultForCreator"
                        v-if="!onlyShow && isCreator">
                        {{calculatePercent(option)}}%
                    </span>
                </div>
            </m-radio>
            <m-checkbox
                v-if="poll.multiselect && canVote"
                v-model="answers"
                :val="option.id"
                :disabled="onlyShow || dashboard"
                class="">
                <div class="poll__option__answer">
                    {{ option.title }}
                    <span
                        class="poll__option__answer__resultForCreator"
                        v-if="!onlyShow && isCreator">
                        {{calculatePercent(option)}}%
                    </span>
                </div>
            </m-checkbox>

            <div
                v-if="!onlyShow && showResult"
                class="poll__option__result">
                {{ option.title }}
                <span>{{ calculatePercent(option) }}%</span>
            </div>
            <div
                v-if="!onlyShow && !canVote && !showResult"
                class="poll__option__result">
                {{ option.title }}
            </div>

            <div
                v-if="!onlyShow && (showResult || isCreator)"
                class="poll__progress">
                <div class="poll__progress__background" />
                <div
                    :style="`width: ${calculatePercent(option)}%;`"
                    class="poll__progress__bar"
                    :class="{'userAnswer': option.is_voted}" />
            </div>
        </div>

        <div class="poll__hr" />

        <div class="poll__bottom">
            <div
                v-if="!onlyShow || dashboard"
                class="poll__statistic">
                <div class="poll__text">
                    {{ votesCount }} {{ votesCount === 1 ? 'vote' : 'votes' }}
                </div>

                <div
                    v-if="poll.duration && timeLeft > 0"
                    class="poll__statistic__shape" />

                <div
                    v-if="poll.enabled && poll.duration && timeLeft > 0"
                    class="poll__statistic__text">
                    {{ timeLeft }} min left
                </div>
                <div
                    v-if="dashboard"
                    class="poll__statistic__shape" />

                <div
                    v-if="dashboard"
                    class="poll__statistic__text">
                    {{ poll.created_at | formattedDate }}
                </div>
            </div>

            <m-btn
                v-if="canVote && (answer !== '' || answers.length > 0)"
                @click="vote">
                Vote
            </m-btn>

            <m-btn
                v-if="!currentUser && !onlyShow && !poll.is_voted && !dashboard && (answer !== '' || answers.length > 0)"
                @click="login">
                Login to vote
            </m-btn>
        </div>
    </div>
</template>
<script>
import MCheckbox from '../../uikit/MCheckbox.vue'
import Polls from "@models/Polls"
import utils from '@helpers/utils'

export default {
  components: {MCheckbox},
  props: {
    onlyShow: {
      type: Boolean,
      default: false
    },
    dashboard: {
      type: Boolean,
      default: false
    },
    theme: {
        type: String,
        default: 'system'
    },
    poll: {
      type: Object,
      required: true
    },
    isCreator: {
      type: Boolean,
      default: false
    },
  },
  data() {
    return {
        answer: "",
        answers: [],
        currentTime: 0,
        pollsChannel: null,
        optionsInfo: null,
        votesCountUpdated: 0
    }
  },
  computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    },
    answersCount() {
        if(!this.optionsInfo) return 0
        return this.optionsInfo.reduce((sum, el) => sum + +el?.votes_count, 0) || 0
    },
    votesCount() {
        if(this.votesCountUpdated > this.poll.votes_count) {
            return this.votesCountUpdated
        }
        return this.poll.votes_count
    },
    timeLeft() {
        let leftTime = 1
        if(this.poll.duration) {
            leftTime = window.moment(this.poll.end_at).diff(this.currentTime, 'minutes') + 1
        }
        return leftTime < 0 ? 0 : leftTime
    },
    canVote() {
        return this.onlyShow || this.currentUser && !this.poll.is_voted && !this.dashboard && this.poll.enabled && (this.duration === null || this.timeLeft > 0)
    },
    showResult() {
        return this.dashboard ||
                (!this.poll.hidden_results && this.poll.is_voted) ||
                !this.poll.enabled

        // return this.poll.is_voted || this.dashboard || !this.poll.enabled || ((this.poll.duration != null && this.timeLeft <= 0))
    },
    options() {
        let options = this.poll.options
        return options.sort((a,b) => {
				return a.position - b.position
			})
    }
  },
    watch: {
        poll: {
            handler(val) {
                this.optionsInfo = val.options
            },
            deep: true
        }
    },
  mounted() {
    this.currentTime = window.moment()
    setInterval(() => {
        this.currentTime = window.moment()
    }, 1000)

    this.optionsInfo = this.poll.options

    this.pollsChannel = initPollsChannel({test: Math.random()})
    this.pollsChannel.bind(pollsChannelEvents.votePoll, (data) => {
        console.log("*** votePoll ***", data);
        if(this.poll?.id && data.poll_id == this.poll.id) {
            this.optionsInfo = JSON.parse(data.options)
            this.votesCountUpdated = data.votes_count

            if(this.canVote && this.isCreator) {
                this.updatePoll()
            }
        }
    })
  },
  methods: {
    calculatePercent(option) {
        if(this.answersCount === 0) return 0
        let vc = +this.optionsInfo.find(el => el.id === option.id)?.votes_count
        return ((vc / this.answersCount) * 100).toFixed(1)
    },
    vote() {
        let option_ids = this.poll.multiselect ? this.answers : [this.answer]
        if(option_ids.length === 0) {
            return
        }

        Polls.api().vote({
            poll_template_id: this.poll.poll_template_id,
            poll_id: this.poll.id,
            option_ids
        }).then(res => {
            console.log("*** voted", res.response.data);
            this.$eventHub.$emit("conversation-polls", [res.response.data])
        })
    },
    login() {
        this.$eventHub.$emit("open-modal:auth", "login")
    },
    stopPoll() {
        if(confirm("Are you sure?")) {
            Polls.api().stopPoll({poll_template_id: this.poll.poll_template_id, poll_id: this.poll.id, enabled: false}).then((res) => {
                this.$flash("Poll stopped", "success")
            })
        }
    },
    updatePoll: utils.debounce(function () {
            Polls.api().fetchPoll({id: this.poll.id}).then((res) => {
            let poll = res.response.data
            this.$eventHub.$emit("conversation-polls", [poll])
        })
    }, 5000)
  }
}
</script>