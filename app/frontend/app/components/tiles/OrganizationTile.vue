<template>
    <div
        id="organizations"
        class="OrganizationTile">
        <a
            class="OrganizationTile__img"
            :href="organization.relative_path">
            <div
                class="OrganizationTile__img__container"
                :style="backgroundImage" />
            <div
                class="OrganizationTile__img__organization"
                :style="OrganizationImage" />
        </a>
        <moderate-tiles
            :item="organization"
            type="Organization"
            :use-promo-weight="usePromoWeight" />
        <div class="OrganizationTile__body">
            <a
                class="OrganizationTile__body__name"
                :href="organization.relative_path">
                {{ organization.name }}
            </a>
            <div
                class="OrganizationTile__body__owner"
                @click="openUserModal">
                <a> {{ organization.user.public_display_name }}</a>
            </div>
            <div class="OrganizationTile__body__since">
                {{ $t('frontend.app.components.tiles.organization_tile.channels', {count: organization.channels_count}) }}
                <div class="OrganizationTile__body__since__dot" />
                {{ $t('frontend.app.components.tiles.organization_tile.creators', {count: organization.creators_count}) }}
            </div>
        </div>
    </div>
</template>

<script>


export default {
    props: {
        organization: Object,
        usePromoWeight: Boolean
    },
    data() {
        return {

        }
    },
    computed: {
        backgroundImage() {
            return {backgroundImage: `url(${this.organization.poster_url})`}
        },
        OrganizationImage() {
           return {backgroundImage: `url(${this.organization.logo_url})`}
        }
    },
    methods: {
        openUserModal() {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: this.organization.user
            })
        }
    }
}
</script>
