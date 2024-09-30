<template>
    <m-modal
        ref="newRoleUser"
        class="newRoleUser"
        @modalClosed="resetData">
        <transition
            mode="out-in"
            name="slide">
            <div
                v-if="checkType()"
                class="newRoleUser__form__wrapper">
                <h4>New User</h4>
                <div class="newRoleUser__form">
                    <m-form
                        ref="form"
                        :form="user"
                        @onSubmit="invite">
                        <m-input
                            v-model="user.first_name"
                            :maxlength="50"
                            :pure="true"
                            :rules="nameRules"
                            field-id="su_fname"
                            name="first_name"
                            placeholder="First Name*" />
                        <m-input
                            v-model="user.last_name"
                            :maxlength="50"
                            :pure="true"
                            :rules="nameRules"
                            field-id="su_lname"
                            name="last_name"
                            placeholder="Last Name*" />
                        <m-input
                            v-model="user.email"
                            :maxlength="128"
                            :pure="true"
                            :validation-debounce="400"
                            field-id="su_email"
                            placeholder="Email*"
                            autocomplete="username"
                            rules="required|email|server_canUseEmail"
                            type="email" />
                        <div class="newRoleUser__form__csv">
                            <div class="newRoleUser__form__csv__title">
                                Or select CSV-file to upload new user
                                <br>
                                <div :class="{'input__field__bottom__errors': UploadFile.error}">
                                    Upload file: <b v-text="UploadFile.name"></b>
                                </div>
                            </div>
                            <label class="btn btn__bordered btn__normal">
                                <input
                                    accept=".csv"
                                    class="inputfile hidden"
                                    type="file"
                                    @change="change">
                                Select file
                            </label>
                        </div>
                    </m-form>
                </div>
                <h4>Or find existing user</h4>
                <div class="newRoleUser__search">
                    <m-search
                        v-slot="data"
                        v-model="selectedUserFromSearch"
                        placeholder="Search by email"
                        response-payload-path="data.response.users"
                        search-url="/api/v1/user/user_search">
                        {{ data.option.user.public_display_name }}
                    </m-search>
                </div>
            </div>
            <user-info-head
                v-else
                :member="member" />
        </transition>
        <user-table
            :is-roles-valid="isRolesValid"
            :member="member"
            :organization-membership-id="user_member_id"
            :user-groups-ids="groupsIds" />
        <div class="newRoleUser__buttons">
            <m-btn
                v-if="newUser"
                size="s"
                type="secondary"
                @click="close()">
                Cancel
            </m-btn>
            <m-btn
                v-if="checkType() || selectedUserFromSearch"
                :disabled="!(isRolesValid && (isUserValid || selectedUserFromSearch || isUploadFile))"
                size="s"
                tag-type="submit"
                type="save"
                @click="submit()">
                Invite
            </m-btn>
            <m-btn
                v-if="!newUser"
                size="s"
                type="save"
                @click="close()">
                Close
            </m-btn>
        </div>
    </m-modal>
</template>

<script>
import UserInfoHead from './UserInfoHead.vue'
import UserTable from './UserTable.vue'
import Groups from "@models/Groups"
import OrganizationMemberships from "@models/OrganizationMemberships"
import GroupsMembers from "@models/GroupsMembers"
export default {
    components: {UserInfoHead, UserTable},
    props: {
        newUser: Boolean,
        user_member_id: Number
    },
    data() {
        return {
            nameRules: {required: true, min: 2, regex: /^[A-Za-zА-Яа-я][A-Za-zА-Яа-я0-9\\s.\'\"\`\-]+$/},
            user: {
                user_id: "",
                first_name: "",
                last_name: "",
                email: ""
            },
            newGroups: [],
            infoUser: false,
            searchUdserQuery: '',
            selectedUserFromSearch: null,
            channelsForGroups: {},
            UploadFile: {
                file: "",
                name: "",
                error: false
            },
        }
    },
    computed: {
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        member() {
            if (this.user_member_id) return OrganizationMemberships.query().whereId(this.user_member_id).first()
            if (this.selectedUserFromSearch) {
                return {
                    status: 'pending',
                    user: {
                        avatar_url: this.selectedUserFromSearch.user.avatar_url,
                        public_display_name: this.selectedUserFromSearch.user.public_display_name
                    }
                }
            } else {
                return null
            }
        },
        groupsIds() {
            return this.newUser ? this.newGroups : this.member?.groups_members?.map(gm => gm.group_id)
        },
        isRolesValid() {
            return this.groupsIds?.length > 0
        },
        isUserValid() {
            return this.user.first_name.length > 0 && this.user.last_name.length > 0 && this.user.email.length > 0
        },
        isUploadFile() {
            return this.UploadFile.name?.length > 0
        }
    },
    watch: {
        selectedUserFromSearch(val) {
            if (val) {
                this.user = {
                    user_id: val.user.id,
                    first_name: "",
                    last_name: "",
                    email: val.user.email
                }
                this.infoUser = true
            }
        }
    },
    mounted() {
        this.$eventHub.$on('groups:new-user-change-groups', (data) => {
            if (data.organizationMembershipId) {
                this.newGroups = data.selectedGroups.map(gm => gm.group_id)
            } else {
                this.newGroups = data.selectedGroups.map(gm => gm.id)
            }
        })
        this.$eventHub.$on('groups:set-channels-for-groups', (data) => {
            this.channelsForGroups = data.channelsForGroups
        })
    },
    methods: {
        checkType() {
            if (this.infoUser) return false
            return this.newUser
        },
        open() {
            if (this.$railsConfig.global.enterprise) {
                let memberGroupId = Groups.query().where('code', 'member').first()?.id
                if (memberGroupId) {
                    this.newGroups.push(memberGroupId)
                }
            }
            this.$refs.newRoleUser.openModal()
        },
        close() {
            this.$refs.newRoleUser.closeModal()
        },
        resetData() {
            this.user = {
                user_id: "",
                first_name: "",
                last_name: "",
                email: ""
            },
                this.newGroups = [],
                this.infoUser = false,
                this.searchUdserQuery = '',
                this.selectedUserFromSearch = null
        },
        change(event) {
            let file = event.target.files[0]
            if (file) {
                let regexp = /\.csv$/;
                if (regexp.test(file.name)) {
                    this.UploadFile.file = file
                    this.UploadFile.name = file.name
                    this.UploadFile.error = false
                }
                else {
                    this.UploadFile.name = "invalid file format",
                    this.UploadFile.error = true
                }
            }
        },
        submit() {
            if (this.selectedUserFromSearch) {
                this.invite()
            } else {
                this.$refs.form.onSubmit()
            }
        },
        inviteSuccess() {
            this.$flash("Invitation taken for processing. Refresh the page after a few minutes to see the result.", "success")
            this.$eventHub.$emit('groups:updateUserCount')
            this.close()
        },
        inviteError(error) {
            console.log(error)
            if (error?.response?.data?.status === 422) {
                // this.$flash('Has already been taken')
                this.$flash(error.response.data.message)
            } else {
                this.$flash('Something went wrong. Please try again later')
            }
        },
        groupsMembersUpdate(assignedGroups) {
            assignedGroups.forEach((assignedGroup) => {
                let channelsToAssign = this.channelsForGroups[assignedGroup.group_id]
                if (channelsToAssign) {
                    let params = {
                        group_id: assignedGroup.id,
                        channel_ids: channelsToAssign.map(i => i.value),
                        organization_id: this.currentOrganization.id
                    }
                    GroupsMembers.api().update(params)
                }
            })
        },
        invite() {
            if (this.isUploadFile) {
                this.importUserFromCSV()
            } else {
                OrganizationMemberships.api().createOrganizationMembership({
                    id: this.currentOrganization.id,
                    user_id: this.user.user_id,
                    email: this.user.email,
                    first_name: this.user.first_name,
                    last_name: this.user.last_name,
                    groups: Object.entries(this.channelsForGroups).map(([key, value]) => { return { group_id: key, channel_ids: value.filter(e => e.id > 0).map(e => e.id)} })
                }).then((res) => {
                    let assignedGroups = res?.response?.data?.response?.organization_membership?.groups_members
                    if (assignedGroups) {
                        this.groupsMembersUpdate(assignedGroups)
                    }
                    this.inviteSuccess()
                }).catch(error => {
                    this.inviteError(error)
                })
            }
        },
        importUserFromCSV() {
            OrganizationMemberships.api().importOrganizationMembershipFromCSV({
                file: this.UploadFile.file,
                id: this.currentOrganization.id,
                groups: Object.entries(this.channelsForGroups).map(([key, value]) => { return { group_id: key, channel_ids: value.filter(e => e.id > 0).map(e => e.id)} })
            }).then((res) => {
                let assignedGroups = res?.response?.data?.response?.organization_membership?.groups_members
                if (assignedGroups) {
                    this.groupsMembersUpdate(assignedGroups)
                }
                this.inviteSuccess()
                Object.assign(this.$data.UploadFile, this.$options.data().UploadFile)
            }).catch(error => {
                this.inviteError(error)
            })
        }
    }
}
</script>