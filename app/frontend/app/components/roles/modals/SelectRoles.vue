<template>
    <m-modal
        ref="selectRoles"
        class="selectRolesModal">
        <div class="selectRolesModal__title">
            Select roles {{ displaydata.email ? "for " + displaydata.email : '' }}
        </div>
        <div class="selectRolesModal__role__wrapper">
            <div
                v-for="group in groups"
                :key="group.id"
                :class="{'selectRolesModal__role__disabled' : unavailable(group)}"
                class="selectRolesModal__role">
                <m-checkbox
                    v-model="selectedGroupsIds"
                    :val="group.id"
                    class="selectRolesModal__role__checkBox" />
                <div class="selectRolesModal__role__body">
                    <span
                        :style="`background-color: ${group.color}`"
                        class="selectRolesModal__role__name">{{ group.name }}</span>
                    <div class="selectRolesModal__role__description">
                        {{ group.description }}
                    </div>
                </div>
            </div>
        </div>
        <div class="newRoleUser__buttons">
            <m-btn
                size="s"
                type="secondary"
                @click="close()">
                Cancel
            </m-btn>
            <m-btn
                :disabled="!selectedGroups.length"
                size="s"
                type="save"
                @click="save()">
                Save
            </m-btn>
        </div>
    </m-modal>
</template>

<script>
import Groups from "@models/Groups"

export default {
    data() {
        return {
            eventUid: null,
            displaydata: {
                name: null,
                email: null
            },
            selectedGroupsIds: [],
            organizationMembershipId: null,
            enterprise: false
        }
    },
    computed: {
        groups() {
            return Groups.query().get()
        },
        selectedGroups() {
            return Groups.query().whereIdIn(this.selectedGroupsIds).get()
        },
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
    watch: {
        selectedGroups(newVal, oldVal) {
            if (oldVal && oldVal.length && !newVal?.length) {
                this.$flash("Minimum one role required")
            }
        }
    },
    mounted() {
        this.enterprise = this.$railsConfig.global.enterprise
        this.$eventHub.$on("groups:openGroupsModal", (data) => {
            this.eventUid = data.eventUid
            this.organizationMembershipId = data.organizationMembershipId
            this.selectedGroupsIds = data.selectedGroupsIds
            this.open()
        })
        this.$eventHub.$on("groups:closeGroupsModal", () => {
            this.close()
        })
    },
    methods: {
        unavailable(group) {
            if (!this.credentialsAbility) return false
            var ruleType = {
                admin: false,
                creator: false,
                member: false
            }
            group.credentials.some(rule => {
                return ruleType.admin = rule.type.name == 'Admin'
            })
            group.credentials.some(rule => {
                return ruleType.creator = rule.type.name == 'Creator'
            })
            group.credentials.some(rule => {
                return ruleType.member = rule.type.name == 'Member'
            })
            if (this.enterprise && group.code == 'member') return true
            if (this.currentUser && this.currentOrganization && this.currentUser.id != this.currentOrganization.user_id && group.code == 'super_admin') return true
            if (!this.credentialsAbility.can_manage_admin && !this.credentialsAbility.can_manage_creator && !this.credentialsAbility.can_manage_enterprise_member && ruleType.member) return true
            if (!this.credentialsAbility.can_manage_creator && ruleType.creator) return true
            if (!this.credentialsAbility.can_manage_admin && ruleType.admin) return true
        },
        open() {
            this.$refs.selectRoles.openModal()
        },
        close() {
            this.$refs.selectRoles.closeModal()
        },
        save() {
            if (this.selectedGroups.length) {
                let data = {
                    eventUid: this.eventUid,
                    organizationMembershipId: this.organizationMembershipId,
                    selectedGroups: this.selectedGroups
                }
                this.$eventHub.$emit('groups:add', (data))
            }
        }
    }
}
</script>
