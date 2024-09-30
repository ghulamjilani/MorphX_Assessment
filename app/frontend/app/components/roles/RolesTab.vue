<template>
    <div>
        <div class="roles__rolesList">
            <div class="roles__rolesList__top">
                <div class="roles__rolesList__top__text">
                    Roles allow your team members to manage certain aspects of your organization.
                    You can opt for predefined roles, or create custom member roles that best suit your needs.
                </div>
                <m-btn
                    v-if="credentialsAbility && credentialsAbility.can_manage_roles"
                    size="s"
                    @click="newGroup()">
                    Create new role
                </m-btn>
            </div>
            <div
                v-if="systemGroups.length"
                class="roles__rolesList__bottom">
                <role-item
                    v-for="group in systemGroups"
                    :key="group.id"
                    :group="group" />
            </div>
        </div>
        <div v-if="customGroups.length">
            <div class="roles__customRolesList__title">
                Custom Roles
            </div>
            <div class="roles__customRolesList">
                <role-item
                    v-for="group in customGroups"
                    :key="group.id"
                    :group="group"
                    :mode="'custom'" />
            </div>
        </div>
    </div>
</template>

<script>
import RoleItem from "./RoleItem"
import Groups from "@models/Groups"

export default {
    name: 'RolesRolesTab',
    components: {RoleItem},
    computed: {
        systemGroups() {
            return Groups.query().where('system', true).get()
        },
        customGroups() {
            return Groups.query().where('system', false).get()
        },
        credentialsAbility() {
            if (this.currentUser) return this.currentUser.credentialsAbility
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    methods: {
        newGroup() {
            this.$router.push({name: 'roles_new'})
        }
    }
}
</script>