<template>
    <div
        v-if="session"
        class="activeSession container">
        <div class="homePage__title__wrapper">
            <h3
                class="homePage__title">
                {{ title }}
            </h3>
        </div>
        <div class="TileSlider__Wrapper">
            <div
                class="morphx__embed"
                style="display: block !important;
                    position: relative !important;
                    padding-top: calc(56.25% + 102px) !important;
            ">
                <iframe
                    class="morphx__embed__iframe"
                    style="display: block !important;width: 100% !important;height: 100% !important;position: absolute  !important;left: 0 !important;top: 0 !important;" allow="encrypted-media" allowfullscreen=""
                    frameborder="0" :src="linkToSession"/>
            </div>
        </div>
    </div>
</template>

<script>
import Search from "@models/Search"

export default {
    props: {
        title: {
            type: String,
            default: ""
        }
    },
    data() {
        return {
            session: null
        }
    },
    computed: {
        linkToSession() {
            if(!this.session) return ""
            return `${location.origin}/widgets/${this.session.id}/session/embedv2?options=live`
        }
    },
  mounted() {
    this.loadSession()
  },
  methods: {
      loadSession() {
          Search.api().searchApi({
              show_on_home: true,
              limit: 1,
              order_by: "start_at",
              searchable_type: "Session"
          }).then((res) => {
            this.session = res.response.data.response.documents[0]?.searchable_model?.session
          })
      }
  }
}
</script>

<style>

</style>