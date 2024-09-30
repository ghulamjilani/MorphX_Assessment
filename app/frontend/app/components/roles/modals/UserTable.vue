<template>
    <div class="newRoleUser__table">
        <m-table table-collapse="none">
            <thead>
                <tr>
                    <th
                        :class="{newRoleUser__table__invalid_header: !isRolesValid}"
                        title="Role is required">
                        ROLES & CHANNELS*
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <div>
                            <div
                                v-for="group in groups"
                                :key="group.id"
                                class="newRoleUser__table__RolesAndChannels">
                                <div class="newRoleUser__table__RolesAndChannels__wrapper">
                                    <span
                                        :style="`background-color: ${group.color}`"
                                        class="newRoleUser__table__Role roleName">
                                        {{ group.name }}
                                    </span>
                                </div>
                                <m-select
                                    v-if="group.is_for_channel && group.code != 'super_admin' && group.code != 'user_admin'"
                                    v-model="channelsForGroups[group.id]"
                                    :data-group="group.id"
                                    :disabled="!canManageGroups()"
                                    :mutiselect="true"
                                    :options="channels"
                                    :pure="true"
                                    :with-image="true"
                                    class="newRoleUser__table__channels__item"
                                    placeholder="Select"
                                    @change="saveSelectedChannelsToServer($event, group)" />
                            </div>
                            <span
                                v-if="canManageGroups()"
                                class="addRole"
                                @click="openGroupsModal()">
                                <m-btn
                                    size="xs"
                                    type="bordered">
                                    + Add Role
                                </m-btn>
                            </span>
                        </div>
                    </td>
                </tr>
            </tbody>
        </m-table>
    </div>
</template>

<script>
import Groups from "@models/Groups"
import Channel from "@models/Channel"
import GroupsMembers from "@models/GroupsMembers"
import utils from '@helpers/utils'

export default {
    props: {
        userGroupsIds: Array,
        organizationMembershipId: Number,
        member: Object,
        isRolesValid: Boolean
    },
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
            channelsForGroups: {}
        }
    },
    computed: {
        groups() {
            if (this.member?.groups_members) {
                return Groups.query().whereIdIn(this.member.groups_members.map(gm => gm.group_id)).get()
            } else {
                return Groups.query().whereIdIn(this.userGroupsIds).get()
            }
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    watch: {
        currentOrganization: {
            handler(val) {
                if (val) {
                    this.getChannels()
                }
            },
            deep: true,
            immediate: true
        },
        groups: {
            handler(val) {
                if (val) {
                    this.updateChannelsForGroups(val)
                }
            },
            deep: true,
            immediate: true
        },
        channelsForGroups: {
            handler(val) {
                if (val && !this.member?.groups_members) {
                    this.$eventHub.$emit('groups:set-channels-for-groups', {channelsForGroups: val})
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.$eventHub.$on('groups:add', (data) => {
            this.$eventHub.$emit('groups:new-user-change-groups', data)
            this.$eventHub.$emit("groups:closeGroupsModal")
        })
    },
    beforeDestroy() {
        this.$eventHub.$off('groups:add')
    },
    methods: {
        canManageGroups() {
            if (this.currentUser && this.member) {
                let isSuperAdmin = this.member?.groups_members?.some(gm => {
                    // andrey todo: fix this check;
                    // dasha todo: add type to groups_member to detect master role
                    return gm.name == 'Super Admin'
                })
                return (this.currentUser.id != this.member.user.id && !isSuperAdmin)
                    || (isSuperAdmin && this.currentOrganization.user_id == this.currentUser.id)
            } else {
                return true
            }
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
                this.updateChannelsForGroups()
            })
        },
        openGroupsModal() {
            this.$eventHub.$emit("groups:openGroupsModal", {
                eventUid: 'user-table',
                organizationMembershipId: this.organizationMembershipId,
                selectedGroupsIds: this.groups.map(r => r.id)
            })
        },
        updateChannelsForGroups(groups = []) {
            if (this.member?.groups_members) {
                this.member?.groups_members.forEach(gm => {
                    this.channelsForGroups[gm.group_id] = this.channels.reduce((resultChannels, channel) => {
                        if (gm.channels.some(ch => ch.id === channel.value)) {
                            let channelCopy = {...channel} // deep copy channel
                            channelCopy.selected = true
                            resultChannels.push(channelCopy)
                        }
                        return resultChannels
                    }, [])
                    if (!this.channelsForGroups[gm.group_id].length) {
                        let allChannelOptionCopy = {...this.allChannelOption}
                        allChannelOptionCopy.selected = true
                        this.channelsForGroups[gm.group_id].push(allChannelOptionCopy)
                    }
                })
            } else {
                this.channelsForGroups = {}
                groups.forEach(group => {
                    if (!this.channelsForGroups[group.id]?.length) {
                        let allChannelOptionCopy = {...this.allChannelOption}
                        allChannelOptionCopy.selected = true
                        this.channelsForGroups[group.id] = [allChannelOptionCopy]
                        this.$eventHub.$emit("m-selec-update", group.id)
                    }
                })
            }
        },
        saveSelectedChannelsToServer: utils.debounce(function (selectedChannels, group) {
            let assignedGroup = this.member?.groups_members?.find(gm => gm.group_id == group.id)
            if (assignedGroup) {
                let params = {
                    group_id: assignedGroup.id,
                    channel_ids: selectedChannels.filter(i => i.value != 'all').map(i => i.value),
                    organization_id: this.currentOrganization.id
                }
                GroupsMembers.api().update(params)
            }
        }, 500),
    }
}
</script>
