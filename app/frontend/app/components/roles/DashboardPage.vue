<template>
    <div class="rolesPage">
        <new-role-user
            ref="newRoleUser"
            :new-user="newUser"
            :user_member_id="user_member_id" />
        <select-roles
            ref="selectRoles"
            :group_member_id="group_member_id" />
        <dashboard-layout
            :active-name="'User Management'"
            class="roles__page">
            <template #beforeTabs>
                <roles-info-cards
                    v-if="pageName != 'roles_edit'"
                    :all-members-count="allMembersCount" />
            </template>
            <template
                v-if="pageName != 'roles_edit'"
                #tabs>
                <div class="dashboardMK2__main__content__tabs">
                    <router-link
                        v-if="credentialsAbility && credentialsAbility.can_manage_team"
                        :class="{'dashboardMK2__main__content__tabs__tab__active': pageName === 'users'}"
                        :to="{name: 'users'}"
                        class="dashboardMK2__main__content__tabs__tab">
                        Users
                    </router-link>
                    <div
                        v-else
                        class="dashboardMK2__main__content__tabs__tab dashboardMK2__main__content__tabs__tab__disable">
                        Users
                    </div>
                    <router-link
                        v-if="credentialsAbility && credentialsAbility.can_manage_roles"
                        :class="{'dashboardMK2__main__content__tabs__tab__active': pageName === 'roles'}"
                        :to="{name: 'roles'}"
                        class="dashboardMK2__main__content__tabs__tab">
                        Roles
                    </router-link>
                    <div
                        v-else
                        v-tooltip="'You don`t have permissions to create or modify roles'"
                        class="dashboardMK2__main__content__tabs__tab dashboardMK2__main__content__tabs__tab__disable">
                        Roles
                    </div>
                </div>
            </template>
        </dashboard-layout>
    </div>
</template>

<script>
import RolesInfoCards from "./RolesInfoCards"
import NewRoleUser from "./modals/NewRoleUser"
import SelectRoles from "./modals/SelectRoles"
import DashboardLayout from '../dashboard/Layout.vue'
import Groups from "@models/Groups"
import OrganizationMemberships from "@models/OrganizationMemberships"

export default {
    name: 'RolesDashboardPage',
    components: {RolesInfoCards, NewRoleUser, SelectRoles, DashboardLayout},
    beforeRouteEnter(to, from, next) {
        if (this) this.changeRoute(to)
        next()
    },
    beforeRouteUpdate(to, from, next) {
        if (this) this.changeRoute(to)
        next()
    },
    data() {
        return {
            pageName: '',
            newUser: false,
            user_member_id: null,
            group_member_id: null,
            allMembersCount: 0
        }
    },
    computed: {
        credentialsAbility() {
            if (this.currentUser) return this.currentUser.credentialsAbility
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        }
    },
    mounted() {
        this.allOrganizationMemberships()
        this.$eventHub.$on('groups:updateUserCount', () => {
            this.allOrganizationMemberships()
        })
        this.changeRoute(this.$router.history.current)
        this.getAllGroups()
        this.$eventHub.$on("groups:openUserModal", (data) => {
            this.newUser = data.newUser
            this.user_member_id = data.id
            this.$refs.newRoleUser.open()
        })
    },
    methods: {
        allOrganizationMemberships() {
            OrganizationMemberships.api().allOrganizationMemberships(
                {
                    id: this.currentOrganization.id,
                    q: '',
                    offset: 0,
                    limit: 20,
                    save: false
                }
            ).then((data) => {
                this.$eventHub.$emit('groups:update-all-members-count', {count: data.response.data.pagination.count})
                this.allMembersCount = data.response.data.pagination.count
            })
        },
        changeRoute(route) {
            if (route.name === 'user_management' || route.name === 'users') {
                this.pageName = 'users'
            } else if (route.name === 'roles') {
                this.pageName = 'roles'
            } else {
                this.pageName = 'roles_edit'
            }
            scrollTo(0, 0)
        },
        getAllGroups() {
            Groups.api().allGroups().catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        }
    }
}
</script>