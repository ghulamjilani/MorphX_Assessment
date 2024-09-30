<template>
    <div
        class="componentManager"
        :class="{'componentManager__editing': editing}">
        <component
            :is="componentData.type"
            v-if="isShowing"
            :dont-hide="editing"
            :group="group"
            v-bind="componentData.props" />

        <div
            v-if="editing"
            class="componentManager__editingButtons">
            <m-btn
                v-tooltip="'move line up'"
                :reset="true"
                type="custom"
                @click="orderUp">
                <m-icon
                    class="rotate__180"
                    size="1.2rem">
                    GlobalIcon-angle-down
                </m-icon>
            </m-btn>
            <m-btn
                v-tooltip="'move line down'"
                :reset="true"
                type="pushRight"
                @click="orderDown">
                <m-icon
                    size="1.2rem">
                    GlobalIcon-angle-down
                </m-icon>
            </m-btn>
            <m-btn
                v-tooltip="'edit line'"
                :reset="true"
                type="custom"
                @click="edit">
                <m-icon
                    size="1.2rem">
                    GlobalIcon-Pensil2
                </m-icon>
            </m-btn>
            <m-btn
                v-tooltip="'remove line'"
                :reset="true"
                type="custom"
                @click="remove">
                <m-icon
                    size="1.2rem">
                    GlobalIcon-trash
                </m-icon>
            </m-btn>
        </div>
    </div>
</template>

<script>
import BannerWrapper from "@components/main-page/banners/BannerWrapper"
import BannerAnnouncement from "@components/main-page/banners/BannerAnnouncement/BannerAnnouncement"
import LiveSessions from "@components/main-page/liveSessions"
import HPChannels from "@components/main-page/HPChannels"
import CreatorsList from "@components/main-page/CreatorsList"
import FooterBanner from "@components/main-page/FooterBanner"
import ReplaysUploadsWithoutScroll from "@components/main-page/ReplaysUploadsWithoutScroll"
import OrganizationTiles from "@components/main-page/OrganizationTiles"
import ArticlesWrapper from "@components/main-page/ArticlesWrapper"
import RawHtml from "@uikit/ComponentsManager/Components/RawHtml.vue"
import FormManager from "@uikit/ComponentsManager/Components/FormManager.vue"
import ActiveSession from "@components/main-page/ActiveSession"
import BookingUsers from "@components/main-page/BookingUsers"
import CustomizableBanner from "@components/main-page/CustomizableBanner"
import BannerAdvertisement from "@components/main-page/BannerAdvertisement"
import AdButler from "@components/main-page/AdButler"
import FeedChannelsList from "@components/main-page/feed/FeedChannelsList"
import FeedRecordings from "@components/main-page/feed/FeedRecordings"
import FeedReplays from "@components/main-page/feed/FeedReplays"
import FeedDocuments from "@components/main-page/feed/FeedDocuments"
import FeedSessions from "@components/main-page/feed/FeedSessions"

export default {
  components: {
    BannerWrapper,
    BannerAnnouncement,
    LiveSessions,
    HPChannels,
    ReplaysUploadsWithoutScroll,
    FooterBanner,
    CreatorsList,
    OrganizationTiles,
    RawHtml,
    ArticlesWrapper,
    FeedChannelsList,
    FormManager,
    ActiveSession,
    BookingUsers,
    CustomizableBanner,
    FeedRecordings,
    FeedReplays,
    FeedDocuments,
    FeedSessions,
    BannerAdvertisement,
    AdButler
  },
  props: {
    componentData: Object,
    group: String,
    editing: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    isShowing() {
      if(!this.componentData?.props?.showFor || this.editing) { // old, edit and null
        return true
      }
      else {
        switch(this.componentData?.props?.showFor) {
          case "all": return true
          case "logined": return this.currentUser
          case "guest": return !this.currentUser
          case "not_organization": return this.currentUser && this.currentUser.can_become_a_creator
          case "only_organization": return this.currentUser && !this.currentUser.can_become_a_creator
          default: return true
        }
      }
    },
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    }
  },
  watch: {
      componentData: {
          handler(val) {
              if (val) {
                this.componentDataLocales()
              }
          },
          deep: true,
          immediate: true
      }
  },
  methods: {
    componentDataLocales() {
      if (this.componentData.props?.href == 'creators') {
        this.componentData.props.href = this.$t('dictionary.creators')
      }
      if (this.componentData.props?.title == 'Creators') {
        this.componentData.props.title = this.$t('dictionary.creators_upper')
      }
    },
    orderUp() {
      this.$emit("orderChange", -1)
    },
    orderDown() {
      this.$emit("orderChange", 1)
    },
    edit() {
      this.$eventHub.$emit("open-modal:componentSettings", this.group, this.componentData)
    },
    remove() {
      this.$emit("remove")
    }
  }
}
</script>
