<template>
    <div class="videoBanner">
        <video
            ref="video"
            autoplay="true"
            loop="true"
            muted="muted"
            playsinline
            src="https://gmi-prod-assets.s3.us-west-2.amazonaws.com/video_banners/unite_user_video.mp4"
            type="video/mp4" />
        <div class="videoBanner__toggleSound">
            <m-icon
                size="2rem"
                :name="muted ? 'GlobalIcon-Sound-off':'GlobalIcon-Sound-on'"
                @click="toggleSound" />
        </div>
    </div>
</template>

<script>
export default {
  data() {
    return {
      muted: true
    }
  },
  methods: {
    toggleSound() {
      this.muted = !this.muted
      if(this.$refs.video) {
        this.$refs.video.muted = this.muted
      }
    }
  }
}
</script>