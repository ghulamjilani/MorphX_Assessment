<template>
    <div class="ip__contact__wrapper">
        <div class="ip__contact">
            <div class="ip__contact__avatar">
                <img
                    :src="userAvatar()"
                    class="ip__contact__avatar__image">
            </div>
            <div class="ip__contact__name">
                {{ user.contact_user ? user.contact_user.public_display_name : user.name || user.public_display_name }}
            </div>
            <div
                v-if="!getUser"
                class="ip__contact__invite">
                <m-btn
                    :disabled="loading"
                    class="ip__contact__invite__button"
                    @click="invite">
                    {{ $t('frontend.app.components.video_client.invite.contact.invite') }}
                </m-btn>
            </div>
            <div
                v-else-if="getParticipantship"
                class="ip__contact__invited">
                {{ getParticipantship.status }}
            </div>
            <div
                v-else
                class="ip__contact__invited">
                {{ $t('frontend.app.components.video_client.invite.contact.invited') }}
            </div>
        </div>
    </div>
</template>

<script>
import Room from "@models/Room"

export default {
    props: {
        user: Object,
        participantship: Object,
        roomInfo: Object,
        invitedParticipantsList: Array
    },
    data() {
        return {
            loading: false
        }
    },
    computed: {
        participantsList() {
            return this.$store.getters["VideoClient/participantsList"]
        },
        getParticipantship() {
            if (!this.roomInfo) return null
            let id = this.user.contact_user_id ? +this.user.contact_user_id : this.user.id
            if (id === this.roomInfo.presenter_user.id) {
                return this.roomInfo.presenter_user
            }
            let user = this.invitedParticipantsList.find(e => e.participantship.user.id === id)
            return user?.participantship
        },
        getUser() {
            if (!this.roomInfo) return null

            let id = this.user.contact_user_id ? +this.user.contact_user_id : this.user.id

            if (id === this.roomInfo.presenter_user.id) {
                return this.roomInfo.presenter_user
            }
            let user = this.participantsList?.find(e => e.user_id === id)
            if (user) return user
            else {
                let user2 = this.roomInfo.room_members.find(e => e.room_member.abstract_user_id === id && e.room_member.abstract_user_type === 'User' )
                if (user2) return user2.room_member
                else {
                    let user3 = this.invitedParticipantsList.find(e => e.participantship.user.id === id)
                    if (user3) return user3?.participantship?.user
                    else return null
                }
            }
        }
    },
    methods: {
        invite() {
            this.loading = true
            Room.api().inviteParticipant({
                room_id: this.roomInfo.id,
                user_id: this.user.contact_user_id
            }, this.roomInfo?.abstract_session?.service_type).then(res => {
                this.loading = false
                this.$emit("invited", res.response.data.response)
            })
        },
        userAvatar() {
            if (this.user) {
                if (this.user.avatar_url) {
                    return this.user.avatar_url
                } else if (this.user.contact_user?.avatar_url) {
                    return this.user.contact_user.avatar_url
                } else {
                    return this.$img['hidden_default']
                }
            }
        }
    }
}
</script>