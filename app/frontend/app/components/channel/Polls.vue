<template>
    <div class="videoComments">
        <div
            v-if="!tabs"
            class="review__label">
            Polls
        </div>
        <div
            v-if="!polls || polls.length == 0"
            class="videoComments__empty">
            No polls yet...
        </div>
        <poll
            v-for="poll in polls"
            :key="poll.id"
            :poll="poll"
            :is-creator="isPresenter" />
    </div>
</template>

<script>
import Session from "@models/Session"
import Polls from "@models/Polls"

import Poll from '@components/polls/Poll.vue'

export default {
    components: {Poll},
    props: {
        model: Object,
        tabs: Boolean
    },
    data() {
        return {
            polls: [],
            pollsChannel: null,
            session: null
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCreator() {
            return this.currentUser && this.currentUser.id == this.session?.presenter_user?.id
        },
        isPresenter() {
            return this.currentUser?.id == Immerss?.session?.organizer_id
        }
    },
    mounted() {
      this.initPollsChannel()

      this.getPolls()

      this.$eventHub.$on("conversation-polls", (polls) => {
        // this.polls = polls
        polls.forEach(poll => {
            let pollIndex = this.polls.findIndex(p => p.id == poll.id)
            if(pollIndex == -1) {
                this.polls.push(poll)
            }
            else {
                this.polls[pollIndex] = poll
            }
        })
        this.polls.sort((a, b) => {
            return new Date(a.created_at).getTime() > new Date(b.created_at).getTime() ? -1 : 1
        })
      })
    },
    methods: {
        getPolls() {
          Session.api().getSessionById({id: this.model.id}).then(res => {
              if(res.response.data.response.session.polls) {
                this.polls = res.response.data.response.session.polls
                this.polls.sort((a, b) => {
                    return new Date(a.created_at).getTime() > new Date(b.created_at).getTime() ? -1 : 1
                })
              }
          })
        },
        initPollsChannel() {
          this.pollsChannel = initPollsChannel()
          this.pollsChannel.bind(pollsChannelEvents.startPoll, (data) => {
              console.log("*** startPoll ***", data);
              if(this.model.id == data.model_id) {
                  this.updatePoll(data.poll_id)
              }
              this.$eventHub.$emit(pollsChannelEvents.startPoll, data)
          })
          this.pollsChannel.bind(pollsChannelEvents.stopPoll, (data) => {
              console.log("*** stopPoll ***", data);
              if(this.model.id == data.model_id) {
                  this.updatePoll(data.poll_id)
              }
              this.$eventHub.$emit(pollsChannelEvents.stopPoll, data)
          })
      },
    updatePoll(poll_id) {
            Polls.api().fetchPoll({id: poll_id}).then((res) => {
            let poll = res.response.data
            this.$eventHub.$emit("conversation-polls", [poll])
        })
    }
    }
}
</script>

