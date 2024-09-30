<template>
    <div class="cardMK2__tile-body">
        <div
            class="fs__16 text__bold display-block cursor-pointer cardMK2__tile-body__title"
            @click="goTo(model.relative_path)"
            @click.middle="goTo(model.relative_path, true)">
            {{ model.title }}
        </div>
        <div
            v-if="homePage || searchPage"
            class="fs__14 display-block cursor-pointer">
            <div class="orgSection">
                <a
                    :href="defaultChannelPath"
                    class="orgSection__img"
                    :style="`background-image: url(${video.organization.logo_url})`">
                </a>
                <div class="orgSection__text">
                    <p @click="openUserModal()">
                        {{ $t('session_tile.by') }} {{ organizer.public_display_name }}
                    </p>
                    <a
                        :href="defaultChannelPath">
                        {{ video.organization.name }}
                    </a>
                </div>
            </div>
            <!-- <span v-if="isPurchased" class="statusPurchased">Purchased</span> -->
        </div>
        <div
            v-else
            class="fs__14 display-block cursor-pointer"
            href="#"
            @click="goTo('/users' + organizer.relative_path)"
            @click.middle="goTo('/users' + organizer.relative_path, true)">
            {{ $t('replay_tile.by') }} {{ organizer.public_display_name }}
            <!-- <span v-if="isPurchased" class="statusPurchased">Purchased</span> -->
        </div>
        <div class="fs__14 cardMK2__ratingAndViews">
            <!-- <m-rating
                :show-text="false"
                :value="model.rating"
                class="fs__12 star_ratingWrapper__span" />
            <div class="cardMK2__ratingAndViews__ratingsCount">
                ({{ model.raters_count }})
            </div> -->
            <timeago
                class="margin-r__10"
                :auto-update="30"
                :datetime="formattedDate" />

            <!--show viewer count if user not log in or not member of this organization or user can_use_debug_area-->
            <v-popover
                v-if="(currentUser && currentOrganization && currentOrganization.id === video.organization.id && video.type === 'video') || (currentUser && currentUser.can_use_debug_area)"
                trigger="hover"
                placement="bottom-center">
                <span class="tooltip-target">
                    <m-icon size="1.6rem">GlobalIcon-eye-2</m-icon>
                    {{ (model.views_count || 0) + (abstract.views_count || 0) }}
                </span>
                <template slot="popover">
                    <div class="fs__16">
                        <div class="display__flex flex__justify__space-between padding-b__5">
                            {{ $t('replay_tile.views_count_popover.live_steams_views') }}:<span class="margin-l__10">{{ abstract.views_count || 0 }}</span>
                        </div>
                        <div class="display__flex flex__justify__space-between">
                            {{ $t('replay_tile.views_count_popover.replay_views') }}:<span class="margin-l__10">{{ model.views_count || 0 }}</span>
                        </div>
                    </div>
                </template>
            </v-popover>
            <span
                v-else
                class="tooltip-target">
                <m-icon size="1.6rem">GlobalIcon-eye-2</m-icon>
                {{ (model.views_count || 0) + (abstract.views_count || 0) }}
            </span>
            <!--!!!!!END!!!!! show viewer count if user not log in or not member of this organization or user platform owner !!!!!END!!!!!-->

            <div
                v-if="currentUser"
                class="cardMK2__ratingAndViews__status">
                <div
                    v-if="abstract.opt_out_as_recorded_member"
                    class="statusPurchased">
                    {{ $t('replay_tile.purchased') }}
                </div>
                <div
                    v-else-if="!isOwner && abstract.access_replay_as_subscriber"
                    class="statusSubscription">
                    {{ $t('replay_tile.subscription') }}
                </div>
                <div
                    v-if="isPurchased"
                    class="statusPurchased">
                    {{ $t('replay_tile.purchased') }}
                </div>
            </div>
        </div>
        <!-- <div>
            <timeago
                :auto-update="30"
                :datetime="formattedDate" />
            <span
                class="fs__14">{{ $t('replay_tile.streamed') }}: {{ formattedDate }}</span>
        </div> -->
        <div
            v-if="currentUser"
            class="cardMK2__tile-body__status">
            <div
                v-if="abstract.opt_out_as_recorded_member"
                class="statusPurchased">
                {{ $t('replay_tile.purchased') }}
            </div>
            <div
                v-else-if="!isOwner && abstract.access_replay_as_subscriber"
                class="statusSubscription">
                {{ $t('replay_tile.subscription') }}
            </div>
            <div
                v-if="isPurchased"
                class="statusPurchased">
                {{ $t('replay_tile.purchased') }}
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        video: {},
        homePage: Boolean,
        searchPage: Boolean
    },
    computed: {
        model() {
            return this.video.video || this.video
        },
        formattedDate(timeOnly = false, dayName = true) {
            // this.video.session.start_at
            let dt = this.abstract.start_at
            let date = this.currentUser && this.currentUser.timezone ?
                moment(dt).tz(this.currentUser.timezone) : moment(dt)
            // let format = ''
            // format = 'ddd, '
            // format += this.currentUser && this.currentUser.am_format ? 'MMM D h:mm A' : 'MMM D H:mm'
            return date//.format(format)
        },
        organization() {
            return this.video?.organization
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization(){
            return this.$store.getters["Users/currentOrganization"]
        },
        organizer() {
            return this.video.user || this.video.presenter_user
        },
        isOwner() {
            return this.currentUser?.id == this.organizer?.id
        },
        abstract() {
            return this.video.abstract_session
        },
        isPurchased() {
            if (this.abstract?.is_purchased) {
                return this.abstract?.is_purchased
            } else if (this.model?.is_purchased) {
                return this.model?.is_purchased
            } else {
                return false
            }
        },
        defaultChannelPath(){
            return location.origin + this.video?.channel?.relative_path
        }
    },
    methods: {
        openUserModal() {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: this.organizer
            })
        }
    }
}
</script>