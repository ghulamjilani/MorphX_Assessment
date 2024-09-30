<template>
    <div class="inviteParticipant">
        <div class="inviteParticipant__header">
            <div class="inviteParticipant__header__title">
                Invite Participants
            </div>
            <div
                class="inviteParticipant__header__close"
                @click="$emit('close')">
                <m-icon size="1.8rem">
                    GlobalIcon-clear
                </m-icon>
            </div>
        </div>
        <div class="inviteParticipant__email">
            <m-input
                v-model="email"
                :disabled="inviteEmailLoading"
                :pure="true"
                field-id="inviteParticipant__email__input"
                placeholder="Invite by Email..."
                type="email"
                @enter="inviteEmail()">
                <template #icon>
                    <m-icon
                        class="inviteParticipant__email__icon"
                        size="1.4rem"
                        @click="inviteEmail()">
                        GlobalIcon-send
                    </m-icon>
                </template>
            </m-input>
        </div>
        <div class="inviteParticipant__contacts">
            <div class="inviteParticipant__contacts__title">
                My contacts <span>({{ usersCount }})</span>
            </div>
            <div class="inviteParticipant__contacts__search">
                <m-input
                    v-model="search"
                    :pure="true"
                    field-id="inviteParticipant__contacts__search__input"
                    placeholder="Search contacts"
                    @input="contactSearch()">
                    <template #icon>
                        <m-icon
                            size="1.8rem"
                            @click="contactSearch()">
                            GlobalIcon-search
                        </m-icon>
                    </template>
                </m-input>
            </div>
        </div>
        <div
            :class="{'inviteParticipant__contacts__wrapper__mobile' : $device.mobile(), 'IpCam__cs__contacts' : ip_cam_or_rtmp}"
            class="inviteParticipant__contacts__wrapper smallScrolls">
            <div
                v-if="loading"
                class="cm__loader">
                <div class="spinnerSlider">
                    <div class="bounceS1" />
                    <div class="bounceS2" />
                    <div class="bounceS3" />
                </div>
            </div>

            <div v-if="showUsers.length">
                <contact
                    v-for="user in showUsers"
                    :key="user.id"
                    :invited-participants-list="invitedParticipantsList"
                    :room-info="roomInfo"
                    :user="user"
                    :participantship="user.participantship"
                    @invited="invited" />
            </div>
            <div
                v-if="!showUsers.length && search !== ''"
                class="text__center">
                Not found
            </div>
            <template v-if="search === ''">
                <contact
                    v-for="user in invitedParticipantsList"
                    :key="user.id"
                    :invited-participants-list="invitedParticipantsList"
                    :room-info="roomInfo"
                    :user="user.participantship.user"
                    :participantship="user.participantship"
                    @invited="invited" />
            </template>

            <m-btn
                v-if="users.length < count"
                :class="{'IpCam__cs__showMore' : ip_cam_or_rtmp}"
                :disabled="showMoreLoading"
                class="inviteParticipant__showMore"
                type="secondary"
                @click="fetchUsers">
                Show more
            </m-btn>
        </div>
    </div>
</template>

<script>
import Contact from './Contact.vue'
import Contacts from "@models/Contacts"
import Room from "@models/Room"
import utils from '@helpers/utils'

export default {
    components: {Contact},
    props: {
        roomInfo: Object,
        ip_cam_or_rtmp: {
            type: Boolean,
            default: false
        },
        isWebrtc: {
            type: Boolean,
            default: false
        },

    },
    data() {
        return {
            email: "",
            search: "",
            users: [],
            searchUsers: [],
            offset: 0,
            limit: 25,
            loading: false,
            showMoreLoading: false,
            inviteEmailLoading: false,
            invitedParticipantsList: [],
            count: 0,
            total: null,
            int: 0
        }
    },
    computed: {
        showUsers() {
            return this.search !== '' ? this.searchUsers : this.users.filter(e => {
                return !this.invitedParticipantsList.find(user => e.contact_user_id === user.participantship.user.id)
            })
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            if (!this.currentUser || !this.roomInfo) return false
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        usersCount() {
            return this.search !== '' ? this.showUsers.length : this.count + this.invitedParticipantsList.length
        }
    },
    created() {
        if (this.users.length === 0) {
            this.loading = true
            this.fetchUsers()
        }
        this.$eventHub.$on("tw-toggleInvite", flag => {
            if (flag && this.users.length === 0) {
                this.fetchUsers()
            }
        })

        let SessionsChannel = initSessionsChannel()
        SessionsChannel.bind(sessionsChannelEvents.totalParticipantsCountUpdated, (data) => {
            if(data.session_id == this.roomInfo.abstract_session_id) {
                this.updateInvitedList()
            }
        })
    },
    methods: {
        contactSearch() {
            this.loading = true
            this.fetchUsers()
        },
        fetchUsers: utils.debounce(function () {
            if (!this.isPresenter) return

            this.$eventHub.$emit("tw-updateParticipantslist")
            this.showMoreLoading = true
            let params = {
                limit: this.limit,
                offset: this.offset
            }
            if (this.search !== '') {
                params['q'] = this.search
                params['offset'] = 0
            }
            Contacts.api().fetch(params).then(res => {
                this.total = this.int === 0 ? res.response.data.pagination?.count - 1 : this.total
                this.int++
                this.count = res.response.data.pagination?.count
                this.loading = false
                this.showMoreLoading = false
                let users = res.response.data.response.filter((item) => item.contact_user_id !== this.currentUser.id)
                if (this.search !== '') {
                    this.searchUsers = users
                    let current_user = res.response.data.response.find((item) => item.contact_user_id === this.currentUser.id)
                    this.count = current_user ? res.response.data.pagination?.count - 1 : res.response.data.pagination?.count
                } else {
                    this.users = this.users.concat(users)
                    this.offset += this.limit
                    this.count = this.total === -1 ? 0 : this.total
                }
                this.updateInvitedList()
            })
        }, 500),
        updateInvitedList() {
            if (!this.roomInfo) return
            if(this.ip_cam_or_rtmp || this.isWebrtc) {
                Room.api().getInvitedLivestreamParticipant({room_id: this.roomInfo.id}).then(res => {
                    let users = res.response.data.response.participantships
                    this.invitedParticipantsList = users
                })
            }
            else {
                Room.api().getInvitedImmersiveParticipant({room_id: this.roomInfo.id}).then(res => {
                    let users = res.response.data.response.participantships
                    this.invitedParticipantsList = users
                })
            }
        },
        invited(user) {
            this.invitedParticipantsList.unshift(user)
            this.count -= 1
            this.updateInvitedList()
        },
        inviteEmail() {
            this.inviteEmailLoading = true
            Room.api().inviteParticipant({
                    room_id: this.roomInfo.id,
                    email: this.email.trim()
                }, this.roomInfo?.abstract_session?.service_type).then(res => {
                this.$flash("Invited", "success")
                this.inviteEmailLoading = false
                this.email = ""
                this.invited(res.response.data.response)
                this.updateInvitedList()
            }).catch(error => {
                this.inviteEmailLoading = false
                if (error.response.data.message.message) {
                    this.$flash(error.response.data.message.message)
                } else {
                    this.$flash(error.response.data.message.slice(19))
                }
            })
        }
    }
}
</script>