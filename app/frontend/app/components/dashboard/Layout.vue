<template>
    <div class="dashboardMK2__wrapper">
        <div class="dashboardMK2__title">
            <div class="dashboardMK2__title__content">
                <h2>{{ activeName }}</h2>
                <organization-selector />
            </div>
        </div>
        <div class="dashboardMK2">
            <div class="dashboardMK2__main">
                <side-bar :active-menu-item="activeName" />
                <div class="dashboardMK2__main__content">
                    <slot name="beforeTabs" />
                    <slot name="tabs" />
                    <transition
                        mode="out-in"
                        name="slide">
                        <router-view />
                    </transition>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import SideBar from './SideBar.vue'
import OrganizationSelector from './OrganizationSelector.vue'

export default {
    name: 'DashboardLayout',
    components: {SideBar, OrganizationSelector},
    props: {
        activeName: {
            type: String,
            default: ''
        }
    },
    data() {
        return {
            orgSelect: false
        }
    }
}
</script>