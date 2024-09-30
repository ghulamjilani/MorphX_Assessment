<template>
    <div class="roles__filters">
        <div class="roles__filters__top">
            <span class="color__main fs__16 text__bold">All Users ({{ allMembersCount }})</span>
            <div class="roles__filters__top__buttons">
                <m-btn
                    :disabled="loading"
                    type="bordered"
                    @click="openNewUser()">
                    + New User
                </m-btn>
                <!--<m-btn type="bordered" class="margin-r__15">Upload CSV</m-btn>-->
                <!--<m-btn type="bordered" @click="toggleFilters">Filters-->
                <!--<m-icon class="padding-l__10"> GlobalIcon-filters </m-icon>-->
                <!--</m-btn>-->
            </div>
        </div>
        <div
            v-if="showFilters"
            class="roles__filters__bottom">
            <div class="roles__filters__buttons">
                <m-btn
                    size="s"
                    type="save">
                    Apply
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    data() {
        return {
            showFilters: false,
            allMembersCount: 0,
            loading: false
        }
    },
    mounted() {
        this.$eventHub.$on('groups:update-all-members-count', (data) => {
            this.allMembersCount = data.count
        })
        this.loading = true
        setTimeout(() => {
            this.loading = false
        }, 2500)
    },
    methods: {
        toggleFilters() {
            this.showFilters = !this.showFilters
        },
        hide() {
            this.show = false
        },
        close() {
            this.$refs.newRoleUser.close()
        },
        openNewUser() {
            this.$eventHub.$emit("groups:openUserModal", {newUser: true, id: null})
        }
    }
}
</script>
