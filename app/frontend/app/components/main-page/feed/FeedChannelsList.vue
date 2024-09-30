<template>
    <div class="feedContainer feedChannels container">
        <div
            v-if="subscriptions.length > 0"
            class="homePage__title__wrapper homePage__title__wrapper__creators">
            <h3
                class="homePage__title homePage__title__creators">
                {{ title }}
            </h3>
        </div>
        <feed-channel
            v-for="subscription in subscriptions"
            :key="subscription.channel.id"
            :subscription="subscription" />
    </div>
</template>

<script>
import FeedChannel from "./FeedChannel"
import Customer from "@models/Customer"

export default {
  components: { FeedChannel },
  props: {
    title: String
  },
  data() {
    return {
      channels: [],
      subscriptions: []
    }
  },
  mounted() {
    this.getChannels()
  },
  methods: {
    getChannels() {
      Customer.api().getSubscriptions().then(res => {
        this.subscriptions = this.subscriptions.concat(res.response.data.response.subscriptions)
        Customer.api().getFreeSubscriptions().then(res2 => {
          this.subscriptions = this.subscriptions.concat(res2.response.data.response.free_subscriptions)
        })
      })
    }
  }
}
</script>

<style>

</style>