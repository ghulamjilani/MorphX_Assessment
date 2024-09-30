<template>
    <div class="manageParticipant">
        <!-- <div class="manageParticipant__presenter">
      <div class="manageParticipant__presenter__title">
        Presenter
      </div>
      <div class="manageParticipant__presenter__title">
      </div>
    </div> -->
        <div class="manageParticipant__participants">
            <div class="manageParticipant__participants__header">
                <div class="manageParticipant__participants__header__title">
                    {{ headerTitle }} ({{ total }})
                </div>
                <div
                    class="manageParticipant__participants__header__close"
                    @click="$emit('close')">
                    <m-icon size="1.8rem">
                        GlobalIcon-clear
                    </m-icon>
                </div>
            </div>
            <div
                v-if="total > 0"
                class="manageParticipant__participants__body smallScrolls">
                <participant
                    v-for="p in participantsList"
                    :key="'mp' + p.id"
                    :participant="p"
                    @banUser="openBanReason" />
            </div>
            <div
                v-else
                class="text__center">
                <!-- Not found -->
            </div>
        </div>

        <m-modal
            ref="banReasonsModal"
            class="banReasonsModal"
            @modalClosed="banModalClosed">
            <template #header>
                <span class="banTitle">Ban Reason</span>
            </template>
            <m-select
                v-model="banReason"
                :options="banOptions"
                label="Ban Reason" />
            <template #footer>
                <m-btn
                    :disabled="!banReason"
                    @click="ban">
                    Ban
                </m-btn>
            </template>
        </m-modal>
    </div>
</template>

<script>
import Participant from './Participant.vue'
import Room from "@models/Room"
import MModal from '../../../uikit/MModal.vue'

import {mapActions, mapGetters} from "vuex"

export default {
    components: {Participant, MModal},
    props: {},
    data() {
        return {
            total: 0,
            banReason: null,
            banUser: null
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "roomMember",
            "roomInfo",
            "banList"
        ]),
        headerTitle() {
            return this.isPresenter ? 'Manage Participants' : 'Participants'
        },
        banOptions() {
            return this.banList.map(e => {
                return {
                    name: e.name,
                    value: e.id
                }
            })
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        participantsList() {
            if (!this.$store.getters["VideoClient/participantsList"]) {
                return []
            } else {
                return this.$store.getters["VideoClient/participantsList"]
            }
        }
    },
    watch: {
        participantsList: {
            handler(val) {
                this.total = this.isPresenter ? val.length - 1 : val.length
            },
            deep: true,
            immediate: true
        }
    },
    created() {
        if (this.isPresenter && this.banList.length === 0) {
            Room.api().getBanReasons().then(res => {
                this.setBanList(res.response.data.response.ban_reasons)
            })
        }
    },
    methods: {
        ...mapActions("VideoClient", [
            "setBanList"
        ]),
        openBanReason(user) {
            this.$refs.banReasonsModal.openModal()
            this.banUser = user.id
        },
        banModalClosed() {
            this.banUser = null
            this.banReason = null
        },
        ban() {
            if (!this.banUser) {
                this.$flash("Error, please try again")
            }
            Room.api().banRoomMember({
                room_id: this.roomInfo.id,
                id: this.banUser,
                banned: true,
                ban_reason_id: this.banReason
            }).then(res => {
                this.banUser = null
                this.banReason = null
                this.$eventHub.$emit("tw-updateParticipantslist")
                this.$refs.banReasonsModal.closeModal()
            }).catch(error => {
                this.$flash(error?.response?.data?.message)
            })
        }
    }
}
</script>