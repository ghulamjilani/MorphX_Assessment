<template>
    <div
        v-if="group"
        class="roles__rolesList__bottom__item">
        <div class="roles__rolesList__bottom__item__wrapper">
            <div class="coloredSquare__wrapper">
                <div
                    :style="{background: group.color}"
                    class="coloredSquare" />
            </div>
            <div
                class="roleName__wrapper"
                @click="showGroup(group)">
                <div class="roleName">
                    {{ group.name }}
                </div>
            </div>
        </div>
        <div class="roles__rolesList__bottom__item__description">
            {{ group.description }}
        </div>
        <div class="roles__rolesList__bottom__item__icon">
            <m-icon
                v-if="isDefault && credentialsAbility && credentialsAbility.can_manage_roles"
                size="2rem"
                @click="editGroup(group)">
                GlobalIcon-copy2
            </m-icon>
            <m-icon
                v-if="isCustom && credentialsAbility && credentialsAbility.can_manage_roles"
                size="2rem"
                @click="updateGroup(group)">
                GlobalIcon-Pensil2
            </m-icon>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        group: Object,
        mode: {
            type: String,
            default: 'default' /*default, custom, mini(modal)*/
        }
    },
    computed: {
        isDefault() {
            return this.mode === 'default'
        },
        isCustom() {
            return this.mode === 'custom'
        },
        isMini() {
            return this.mode === 'mini'
        },
        credentialsAbility() {
            if (this.currentUser) return this.currentUser.credentialsAbility
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    methods: {
        editGroup(group) {
            this.$router.push({name: 'roles_duplicate', params: {id: group.id}})
        },
        showGroup(group) {
            this.$router.push({name: 'roles_show', params: {id: group.id}})
        },
        updateGroup(group) {
            this.$router.push({name: 'roles_update', params: {id: group.id}})
        }
    }
}
</script>
