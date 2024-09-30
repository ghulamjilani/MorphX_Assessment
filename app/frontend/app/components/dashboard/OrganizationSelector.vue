<template>
    <div>
        <div
            v-show="orgSelect"
            class="channelFilters__icons__options__cover"
            @click="toggleOrgSelect()" />
        <div
            v-if="organizations && organizations.length > 1"
            class="dashboardMK2__organizations">
            <div
                v-if="currentOrganization"
                class="dashboardMK2__organizations__organization"
                @click="toggleOrgSelect()">
                <div
                    :style="`background-image: url('${getOrganizationLogo}')`"
                    class="dashboardMK2__organizations__image" />
                <div class="header__organization__name">
                    {{ currentOrganization.name }}
                </div>
                <m-icon
                    :class="{'dashboardMK2__organizations__icon__active' : orgSelect}"
                    class="dashboardMK2__organizations__icon"
                    size="0">
                    GlobalIcon-angle-down
                </m-icon>
            </div>
            <div
                v-show="orgSelect"
                class="dashboardMK2__organizations__list">
                <div
                    v-for="organization in organizations"
                    :key="organization.id">
                    <div
                        v-if="currentOrganization.id != organization.id"
                        class="dashboardMK2__organizations__item"
                        @click="setCurrentOrganization(organization); toggleOrgSelect()">
                        <div class="dashboardMK2__organizations__organization">
                            <div
                                :style="`background-image: url('${organization.logo_url}')`"
                                class="dashboardMK2__organizations__image" />
                            <div class="header__organization__name">
                                {{ organization.name }}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div
            v-else-if="currentOrganization"
            class="dashboardMK2__organizations">
            <div class="dashboardMK2__organizations__organization dashboardMK2__organizations__organization__normal">
                <div
                    :style="`background-image: url('${getOrganizationLogo}')`"
                    class="dashboardMK2__organizations__image" />
                <div class="header__organization__name">
                    {{ currentOrganization.name }}
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import Organization from '@models/Organization'

export default {
    name: 'DashboardOrganizationSelector',
    data() {
        return {
            orgSelect: false
        }
    },
    computed: {
        getOrganizationLogo() {
            if (!this.currentOrganization) return null
            return this.currentOrganization.logo_url
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        organizations() {
            return this.$store.getters["Users/organizations"]
        }
    },
    methods: {
        toggleOrgSelect() {
            this.orgSelect = !this.orgSelect
        },
        setCurrentOrganization(company) {
            let result = confirm("Your current organization will be changed?")
            if (result) {
                Organization.api().setCurrentOrganization({id: company.id}).then(() => {
                    if(company.user_id != this.currentUser?.id) {
                        location.href = location.origin + company.relative_path
                    }
                    else {
                        location.reload()
                    }
                }).catch(error => {
                    console.log(error);
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else{
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }
        }
    }
}
</script>