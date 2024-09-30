<template>
    <div class="mops-channel">
        <div
            class="mops-channel__info"
            @click="openMopsList">
            <div
                class="mops-channel__info__logo"
                :style="'background-image: url(' + channel.image_url + ')'" />
            <div class="mops-channel__info__name">
                {{ channel.title }}
            </div>
            <div
                class="mops-channel__info__arrow"
                :class="{active: isOpen}">
                <m-icon size="1.5rem">
                    GlobalIcon-angle-down
                </m-icon>
            </div>
        </div>
        <div
            v-if="isOpen"
            class="mops-channel__listSection">
            <div class="mops-channel__listSection__separateLine" />
            <div class="mops-channel__listSection__mopsList">
                <div
                    v-tooltip="'Add new'"
                    class="mops-channel__mops mops-channel__mops__addNew"
                    @click="addNewMops">
                    <m-icon size="2rem">
                        GlobalIcon-Plus
                    </m-icon>
                </div>
                <!-- v-tooltip="mops.description" -->
                <div
                    v-for="mops in mopsList"
                    :key="mops.id"
                    class="mops-channel__mops">
                    {{ mops.title }}
                    <m-dropdown
                        :close-by-self-click="true"
                        class="mops-channel__mops__menu">
                        <m-option @click="editMops(mops)"> Edit </m-option>
                        <m-option @click="showMops(mops)"> Show </m-option>
                        <m-option @click="removeMops(mops)"> Remove </m-option>
                    </m-dropdown>
                    <m-icon
                        class="mops-channel__mops__status"
                        :class="{active: mops.active}">
                        GlobalIcon-recording
                    </m-icon>
                    <div class="mops-channel__mops__statistics">
                        <m-icon>GlobalIcon-eye-2</m-icon>
                        {{ mops.views_count }}
                        <m-icon>GlobalIcon-upload</m-icon>
                        {{ mops.submits_count }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import OptIn from "@models/OptIn"

export default {
  props: {
    channel: Object,
    allMopsList: Array
  },
  data() {
    return {
      isOpen: false
    }
  },
  computed: {
    mopsList() {
        return this.allMopsList.filter(mops => mops.channel_uuid === this.channel.uuid)
    }
  },
  methods: {
    openMopsList() {
        this.isOpen = !this.isOpen
    },
    addNewMops() {
        this.$eventHub.$emit("mops-settings:new", this.channel)
    },
    editMops(mops) {
        this.$eventHub.$emit("mops-settings:edit", mops)
    },
    showMops(mops) {
        this.$eventHub.$emit("mops-modal:show", mops)
    },
    removeMops(mops) {
        OptIn.api().removeOptInModals({id: mops.id}).then(() => {
            this.$emit("removed", mops)
            this.$flash(`OptIn "${mops.title}" removed successfully`, "success")
        })
    }
  }
}
</script>

<style>

</style>