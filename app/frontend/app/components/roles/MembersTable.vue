<template>
    <div class="membersTable">
        <div class="membersTable__searchSection">
            <m-input
                v-model.trim="fetchOptions.q"
                :maxlength="60"
                :pure="true"
                placeholder="Search by name or email"
                @input="search()">
                <template #icon>
                    <m-icon
                        size="1.6rem"
                        @click="search()">
                        GlobalIcon-search
                    </m-icon>
                    <m-icon
                        v-if="fetchOptions.q.length"
                        size="1.6rem"
                        @click="clearSearch()">
                        GlobalIcon-clear
                    </m-icon>
                </template>
            </m-input>
            <div
                v-if="members.length && !loading"
                class="customPaginate">
                <p class="customPaginate__text">
                    {{ paginationData.from }}-{{ paginationData.to }} from {{ paginationData.total }}
                </p>
                <a
                    :class="{'customPaginate__disable' : paginationData.from < paginationData.perPage + 1}"
                    class="customPaginate__arrow"
                    @click="fetch({prevPage: true})">
                    <m-icon size="1.2rem"> GlobalIcon-angle-left</m-icon>
                </a>
                <a
                    :class="{'customPaginate__disable' : paginationData.to == paginationData.total}"
                    class="customPaginate__arrow"
                    @click="fetch({nextPage: true})">
                    <m-icon size="1.2rem"> GlobalIcon-angle-right</m-icon>
                </a>
            </div>
        </div>
        <div
            v-if="members.length == 0 && !loading"
            class="emptyTable">
            There are no Users
        </div>
        <div v-if="loading">
            <div class="membersTable__spinner">
                <div class="spinnerSlider">
                    <div class="bounceS1" />
                    <div class="bounceS2" />
                    <div class="bounceS3" />
                </div>
            </div>
        </div>
        <m-table
            v-if="!members.length == 0 && !loading"
            :column-width-proportion="[35, 55, 10]">
            <thead>
                <tr>
                    <th>NAME</th>
                    <th>ROLES & CHANNELS</th>
                    <th>STATUS</th>
                </tr>
            </thead>
            <tbody>
                <tr
                    v-for="member in members"
                    :key="member.id">
                    <td>
                        <div
                            v-if="member.id"
                            class="logo__m membersTable__UserAvatar"
                            @click="openUserInfo(member.id)">
                            <img :src="member.user ? member.user.avatar_url : ''">
                        </div>
                        <div class="membersTable__UserNameEmail">
                            <div class="fs__12">
                                {{ member.user.public_display_name }}
                            </div>
                            <div class="color__secondary fs__12">
                                {{ member.user.email }}
                            </div>
                        </div>
                    </td>
                    <td>
                        <div
                            v-for="groups_member in member.groups_members"
                            :key="groups_member.id"
                            class="newRoleUser__table__RolesAndChannels">
                            <div class="newRoleUser__table__RolesAndChannels__wrapper">
                                <span
                                    :style="`background-color: ${groups_member.color}`"
                                    class="newRoleUser__table__Role roleName">
                                    {{ groups_member.name }}
                                    <!-- <m-icon size="1rem"> GlobalIcon-clear </m-icon> -->
                                </span>
                            </div>
                            <m-select
                                v-if="groups_member.code != 'super_admin' && groups_member.code != 'user_admin' && groups_member.is_for_channel && selectedChannels[member.id] && selectedChannels[member.id][groups_member.id]"
                                v-model="selectedChannels[member.id][groups_member.id]"
                                :disabled="!isCanAddGroup(member)"
                                :mutiselect="true"
                                :options="channels"
                                :with-image="true"
                                class="newRoleUser__table__channels__item"
                                placeholder="Select"
                                :updateble="updateble"
                                @change="updateble.isUpdating = true, saveSelectedChannelsToServer($event, groups_member)" />
                        </div>
                        <span
                            v-if="isCanAddGroup(member)"
                            class="addRole"
                            @click="openGroupsModal(member.id)"><m-btn
                                size="xs"
                                type="bordered"> + Add Role</m-btn></span>
                    </td>
                    <td class="color__secondary fs__12">
                        <div class="membersTable__status">
                            {{ $t(`components.roles.members_table.invite_status.${member.status}`) }}
                            <m-dropdown>
                                <m-option
                                    v-if="['cancelled', 'pending'].includes(member.status.toLowerCase())"
                                    @click="updateStatus(member, 'resend')">
                                    Resend Invite
                                </m-option>
                                <m-option
                                    v-if="['pending'].includes(member.status.toLowerCase())"
                                    @click="updateStatus(member, 'cancel')">
                                    Cancel Invite
                                </m-option>
                                <m-option
                                    v-if="['active'].includes(member.status.toLowerCase())"
                                    @click="updateStatus(member, 'suspend')">
                                    Suspend
                                </m-option>
                                <m-option
                                    v-if="['active'].includes(member.status.toLowerCase())"
                                    @click="resetPassword(member)">
                                    Reset Password
                                </m-option>
                                <m-option
                                    v-if="['suspended'].includes(member.status.toLowerCase())"
                                    @click="updateStatus(member, 'activate')">
                                    Activate
                                </m-option>
                            </m-dropdown>
                        </div>
                    </td>
                </tr>
            </tbody>
        </m-table>
    </div>
</template>

<script>
import OrganizationMemberships from "@models/OrganizationMemberships"
import Channel from "@models/Channel"
import GroupsMembers from "@models/GroupsMembers"
import User from "@models/User"
import utils from '@helpers/utils'

export default {
    data() {
        return {
            allChannelOption: {
                id: 0,
                name: 'All Channels',
                value: 'all',
                selected: false,
                excluded: true,
                unlisted: true,
                selectText: 'All Channels'
            },
            channels: [
                {...this.allChannelOption}
            ],
            selectedChannels: {},
            paginationData: {
                to: 20,
                from: 1,
                total: 0,
                perPage: 20
            },
            fetchOptions: {
                id: null,
                q: '',
                offset: 0,
                limit: 20
            },
            loading: true,
            updateble: {
                value: true,
                isUpdating: false
            }
        }
    },
    computed: {
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        members() {
            return OrganizationMemberships.query().get()
        }
    },
    watch: {
        currentOrganization: {
            handler(val) {
                if (val) {
                    this.getChannels()
                    this.fetchOptions.id = this.currentOrganization.id
                    this.fetch()
                }
            },
            deep: true,
            immediate: true
        },
        members: {
            handler(newVal, oldVal) {
                if (newVal.length) {
                    this.updateSelectedChannels(newVal)
                }
                if (newVal.length != oldVal?.length) {
                    this.allOrganizationMemberships()
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.$eventHub.$on('groups:add', (data) => {
            if (data.eventUid === 'member-table') {
                OrganizationMemberships.api().updateOrganizationMembership({
                    id: data.organizationMembershipId,
                    group_ids: data.selectedGroups.map(r => r.id),
                    organizationId: this.currentOrganization.id
                }).then(() => {
                    this.$flash("User roles have been updated", "success")
                    this.$eventHub.$emit("groups:closeGroupsModal")
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
        })
    },
    beforeDestroy() {
        this.$eventHub.$off('groups:add')
    },
    methods: {
        clearSearch() {
            this.fetchOptions.q = ''
            this.fetch()
        },
        isCanAddGroup(member) {
            var superAdmin
            member.groups_members.some(gm => {
                return superAdmin = gm.name == 'Super Admin'
            })
            let flag = true
            if (this.currentUser?.id == member.user.id) flag = false
            if (this.currentUser?.id != this.currentOrganization?.user_id && superAdmin) flag = false
            return flag
        },
        allOrganizationMemberships() {
            OrganizationMemberships.api().allOrganizationMemberships(this.fetchOptions).then((data) => {
                this.updatePagination(data.response?.data)
                this.$eventHub.$emit('groups:update-all-members-count', {count: data.response.data.pagination.count})
                this.loading = false
            })
        },
        search: utils.debounce(function () {
            this.fetch()
        }, 500),
        updatePagination(data) {
            this.paginationData.total = data.pagination.count
            this.paginationData.from = data.pagination.offset + 1
            this.paginationData.to = data.pagination.offset + data.response.organization_memberships.length
        },
        fetch(options = {}) {
            this.loading = true
            if (options.nextPage) {
                this.fetchOptions.offset = this.fetchOptions.offset + this.paginationData.perPage
            }
            if (options.prevPage) {
                this.fetchOptions.offset = this.fetchOptions.offset - this.paginationData.perPage
            }
            this.allOrganizationMemberships()
            this.isSelectAll = false
        },
        openUserInfo(id) {
            this.$eventHub.$emit("groups:openUserModal", {newUser: false, id: id})
        },
        openGroupsModal(id) {
            this.$eventHub.$emit("groups:openGroupsModal", {
                eventUid: 'member-table',
                organizationMembershipId: id,
                selectedGroupsIds: OrganizationMemberships.query().whereId(id).first().groups_members.map(gm => gm.group_id)
            })
        },
        getChannels() {
            Channel.api().getChannels({organization_id: this.currentOrganization.id}).then((res) => {
                this.channels = [
                    ...[this.allChannelOption],
                    ...res.response.data.response.channels.map(c => {
                        return {
                            id: c.id,
                            name: c.title,
                            value: c.id,
                            image: c.image_gallery_url,
                            selected: false
                        }
                    })
                ]
                this.updateSelectedChannels(this.members)
            })
        },
        updateSelectedChannels(members) {
            members.forEach((member) => {
                this.selectedChannels[member.id] = {}
                member.groups_members.forEach((gm) => {
                    this.selectedChannels[member.id][gm.id] = this.channels.reduce((resultChannels, channel) => {
                        if (gm.channels.some(ch => ch.id === channel.value)) {
                            let channelCopy = {...channel} // deep copy channel
                            channelCopy.selected = true
                            resultChannels.push(channelCopy)
                        }
                        return resultChannels
                    }, [])
                    if (!this.selectedChannels[member.id][gm.id].length) {
                        let allChannelOptionCopy = {...this.allChannelOption}
                        allChannelOptionCopy.selected = true
                        this.selectedChannels[member.id][gm.id].push(allChannelOptionCopy)
                    }
                })
            })
        },
        saveSelectedChannelsToServer: utils.debounce(function (selectedChannels, assignedGroup) {
            let params = {
                group_id: assignedGroup.id,
                channel_ids: selectedChannels.filter(i => i.value != 'all').map(i => i.value),
                organization_id: this.currentOrganization.id
            }
            GroupsMembers.api().update(params)
            .then(res => {
                this.updateble.isUpdating = false
            }).catch(error => {
              if (error?.response?.data?.message) {
                this.$flash(error.response.data.message)
              } else {
                this.$flash('Something went wrong please try again later')
              }
              this.updateble.isUpdating = false
            })
        }, 500),
        updateStatus(member, type) {
            let status = ""
            switch (type) { // pending/active/cancelled/suspended
                case 'resend':
                    status = 'pending'
                    break
                case 'cancel':
                    status = 'cancelled'
                    break
                case 'suspend':
                    status = 'suspended'
                    break
                case 'activate':
                    status = 'active'
                    break
            }
            OrganizationMemberships.api().updateOrganizationMembershipStatus({
                id: member.id,
                status,
                organization_id: this.currentOrganization.id
            }).then(res => {
                this.$eventHub.$emit("m-dropdown:closeAll")
                this.$flash("Status successfully changed", "success")
            }).catch(error => {
              if (error?.response?.data?.message) {
                this.$flash(error.response.data.message)
              } else {
                this.$flash('Something went wrong please try again later')
              }
            })
        },
        resetPassword(member) {
            User.api().rememberPassword({
                user: {email: member.user.email}
            }).then(res => {
                this.$eventHub.$emit("m-dropdown:closeAll")
                this.$flash("Password reset instructions sent successfully", "success")
            })
        }
    }
}
</script>
