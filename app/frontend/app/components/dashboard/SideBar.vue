<template>
    <div
        v-if="currentUser"
        class="dashboardMK2__main__sideBar">
        <div
            class="dashboardMK2__main__sideBar__mobile"
            @click="toggleNav">
            Dashboard nav
            <m-icon
                :class="{'dashboardMK2__main__sideBar__mobile__icon__show': showNav }"
                class="dashboardMK2__main__sideBar__mobile__icon"
                size=".8rem">
                GlobalIcon-angle-down
            </m-icon>
        </div>
        <div
            v-if="showNav"
            class="dashboardMK2__main__sideBar__nav">
            <div>
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('My Library', ['/dashboard/my_library'])}"
                    :to="{name: 'my_library'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.my_feed') }}
                </router-link>
            </div>
            <div v-if="isCompanyAvailable && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Company', ['/dashboard/company'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/company">
                    {{ $t('frontend.app.components.dashboard.sidebar.company') }}
                </a>
            </div>
            <div v-if="isBusinessSubscriptionAvailable && $railsConfig.global.service_subscriptions.enabled">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Business Subscription', ['/dashboard/business_plan'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/business_plan">
                    {{ $t('frontend.app.components.dashboard.sidebar.business_subscription') }}
                </a>
            </div>
            <div v-if="isCurrentUserExist && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Channels', ['/dashboard/sessions_'], true)}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/sessions_presents">
                    <!-- participant_nav -->
                    {{ $t('frontend.app.components.dashboard.sidebar.channels') }}
                </a>
            </div>
            <div v-if="isCurrentUserExist && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Videos', ['/dashboard/replays', '/dashboard/uploads'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/replays">
                    <!-- participant_nav -->
                    {{ $t('frontend.app.components.dashboard.sidebar.videos') }}
                </a>
            </div>
            <div v-if="is_document_management_enabled && isCurrentOrganizationHasSubscriptionOrRevenue && credentialsAbility.can_manage_documents">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Documents', ['/documents'])}"
                    :to="{name: 'documents'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.documents') }}
                </router-link>
            </div>
            <div
                v-if="isCurrentUserExist && credentialsAbility && isSubscriptionsAvailable && credentialsAbility.can_manage_channel_subscription && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Subscriptions', ['/subscriptions'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/subscriptions">
                    {{ $t('frontend.app.components.dashboard.sidebar.subscriptions') }}
                </a>
            </div>
            <div
                v-else-if="!isSubscriptionsAvailable && presenter"
                v-tooltip="'Not allowed by your Business plan'"
                class="dashboardMK2__main__sideBar__wrap_disabled">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Subscriptions')}"
                    class="dashboardMK2__main__sideBar__links"
                    @click.prevent>
                    {{ $t('frontend.app.components.dashboard.sidebar.subscriptions') }}
                </a>
            </div>
            <div v-if="(isCurrentOrganizationOwner || credentialsAbility.can_manage_channel_subscription) && isCurrentOrganizationHasFreeSubscriptions">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Free Subscriptions', ['/dashboard/free_subscriptions'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/free_subscriptions">
                    {{ $t('frontend.app.components.dashboard.sidebar.free_subscriptions') }}
                </a>
            </div>
            <div v-if="isManagementAvailable && credentialsAbility && credentialsAbility.can_manage_team">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('User Management')}"
                    :to="{name: 'users'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.user_management') }}
                </router-link>
            </div>
            <div v-else-if="isManagementAvailable && credentialsAbility && credentialsAbility.can_manage_roles">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('User Management')}"
                    :to="{name: 'roles'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.user_management') }}
                </router-link>
            </div>
            <!-- <div
                v-else-if="!isManagementAvailable && presenter"
                v-tooltip="'Not allowed by your Business plan'"
                class="dashboardMK2__main__sideBar__wrap_disabled">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('User Management')}"
                    class="dashboardMK2__main__sideBar__links"
                    @click.prevent>
                    {{ $t('frontend.app.components.dashboard.sidebar.user_management') }}
                </a>
            </div> -->
            <div v-if="isContactsAndMailingAvailable">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Contacts & Mailing')}"
                    :to="{name: 'contacts'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.contacts_mailing') }}
                </router-link>
            </div>
            <div v-else>
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Contacts')}"
                    :to="{name: 'contacts'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.contacts') }}
                </router-link>
            </div>
            <div v-if="isProductsAvailable && credentialsAbility && credentialsAbility.can_manage_product && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Product Lists', ['/lists'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/lists">
                    {{ $t('frontend.app.components.dashboard.sidebar.product_lists') }}
                </a>
            </div>
            <div
                v-else-if="!isProductsAvailable && presenter"
                v-tooltip="'Not allowed by your Business plan'"
                class="dashboardMK2__main__sideBar__wrap_disabled">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Product Lists')}"
                    class="dashboardMK2__main__sideBar__links"
                    @click.prevent>
                    {{ $t('frontend.app.components.dashboard.sidebar.product_lists') }}
                </a>
            </div>
            <div v-if="isMultiroomAvailable && isMultiroomCred">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Video Studios', ['/studios'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/studios">
                    {{ $t('frontend.app.components.dashboard.sidebar.studios') }}
                </a>
            </div>
            <!-- <div v-else v-tooltip="'Not allowed by your Business plan'" class="dashboardMK2__main__sideBar__wrap_disabled">
        <a @click.prevent class="dashboardMK2__main__sideBar__links"
        :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Video Studios')}">
          Studios
        </a>
      </div> -->
            <div v-if="isMultiroomAvailable && isMultiroomCred">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Video Sources', ['/video_sources'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/video_sources">
                    {{ $t('frontend.app.components.dashboard.sidebar.video_sources') }}
                </a>
            </div>
            <!-- <div v-else v-tooltip="'Not allowed by your Business plan'" class="dashboardMK2__main__sideBar__wrap_disabled">
        <a @click.prevent class="dashboardMK2__main__sideBar__links"
        :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Video Sources')}">
          Video Sources
        </a>
      </div> -->
            <div>
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Saved', ['/wishlist'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/wishlist">
                    <!-- participant_nav -->
                    {{ $t('frontend.app.components.dashboard.sidebar.saved') }}
                </a>
            </div>
            <div v-if="isCommunityAvailable && credentialsAbility && credentialsAbility.can_manage_blog_post">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Community', ['/community'])}"
                    :to="{name: 'create-post'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.community') }}
                </router-link>
            </div>
            <div
                v-else-if="isCommunityAvailable && credentialsAbility && (credentialsAbility.can_moderate_blog_post || credentialsAbility.can_manage_blog_post)">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Community', ['/community'])}"
                    :to="{name: 'manage-blog'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.community') }}
                </router-link>
            </div>
            <div
                v-else-if="!isCommunityAvailable && presenter"
                v-tooltip="'Not allowed by your Business plan'"
                class="dashboardMK2__main__sideBar__wrap_disabled">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Community', ['/community'])}"
                    class="dashboardMK2__main__sideBar__links"
                    @click.prevent>
                    {{ $t('frontend.app.components.dashboard.sidebar.community') }}
                </a>
            </div>
            <div v-if="isCurrentOrganizationHasSubscriptionOrRevenue && credentialsAbility.can_moderate_comments_and_reviews">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Reviews')}"
                    :to="{name: 'reviews'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.reviews') }}
                </router-link>
            </div>
            <div v-if="isCurrentOrganizationHasSubscriptionOrRevenue && credentialsAbility.can_moderate_comments_and_reviews">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Comments')}"
                    :to="{name: 'comments'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.comments') }}
                </router-link>
            </div>
            <div>
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Money', ['/money/earnings', '/money/payouts', '/money/purchases'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/money/earnings">
                    <!-- participant_nav -->
                    {{ $t('helpers.dashboard.my_money_dashboard_nav_title') }}
                </a>
            </div>
            <div v-if="history">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Browsing History', ['/dashboard/history'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/history">
                    <!-- participant_nav -->
                    {{ $t('frontend.app.components.dashboard.sidebar.browsing_history') }}
                </a>
            </div>
            <div v-if="statistics && isStatisticsCred">
                <div v-if="isStatisticsAvailable">
                    <a
                        :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Statistics', ['/dashboard/statistics'])}"
                        class="dashboardMK2__main__sideBar__links"
                        href="/dashboard/statistics">
                        {{ $t('frontend.app.components.dashboard.sidebar.statistics') }}
                    </a>
                </div>
                <!-- it was with rule: show 'Not allowed by your Business plan' for all productions  -->
                <!-- <div
                    v-else
                    v-tooltip="'Not allowed by your Business plan'"
                    class="dashboardMK2__main__sideBar__wrap_disabled">
                    <a
                        :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Statistics')}"
                        class="dashboardMK2__main__sideBar__links"
                        @click.prevent>
                        {{ $t('frontend.app.components.dashboard.sidebar.statistics') }}
                    </a>
                </div> -->
            </div>
            <div v-if="isCurrentUserExist && presenter">
                <a
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Referrals', ['/dashboard/edit_referral'])}"
                    class="dashboardMK2__main__sideBar__links"
                    href="/dashboard/edit_referral">
                    {{ $t('frontend.app.components.dashboard.sidebar.referrals') }}
                </a>
            </div>
            <div v-if="isCurrentOrganizationOwner">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Optin Manager', ['/dashboard/optin'])}"
                    :to="{name: 'OptinManager'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.optin') }}
                </router-link>
            </div>
            <div
                v-if="$railsConfig.global.booking && $railsConfig.global.booking.enabled && credentialsAbility.can_manage_booking">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Booking', ['/dashboard/booking'])}"
                    :to="{name: 'Booking'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.booking') }}
                </router-link>
            </div>
            <div
                v-if="credentialsAbility.can_manage_polls">
                <router-link
                    :class="{dashboardMK2__main__sideBar__links__active: isMenuItemActive('Polls', ['/dashboard/polls'])}"
                    :to="{name: 'Polls'}"
                    class="dashboardMK2__main__sideBar__links">
                    {{ $t('frontend.app.components.dashboard.sidebar.polls') }}
                </router-link>
            </div>


            <div
                v-if="userFollows.length"
                class="dashboardMK2__main__sideBar__followers">
                <div class="dashboardMK2__main__sideBar__followers__info">
                    <div>
                        Following <span class="dashboardMK2__main__sideBar__followers__count">{{ followsCount }}</span>
                    </div>
                    <a @click="creatorModal(currentUser)">See all</a>
                </div>
                <div class="dashboardMK2__main__sideBar__followers__links">
                    <a
                        v-for="follows in userFollows"
                        :key="follows.id"
                        :class="{'channel__info__owner__companyLogo' : follows.type != 'User'}"
                        :style="`background-image: url(${follows.avatar_url})`"
                        :title="follows.public_display_name"
                        class="logo__xs dashboardMK2__main__sideBar__followers__avatar"
                        @click="creatorModal(follows)" />
                </div>
            </div>
            <div
                v-if="userFollowers.length"
                class="dashboardMK2__main__sideBar__followers">
                <div class="dashboardMK2__main__sideBar__followers__info">
                    <div>
                        Followers <span
                            class="dashboardMK2__main__sideBar__followers__count">{{ followersCount }}</span>
                    </div>
                    <a @click="creatorModal(currentUser)">See all</a>
                </div>
                <div class="dashboardMK2__main__sideBar__followers__links">
                    <a
                        v-for="follower in userFollowers"
                        :key="follower.id"
                        :style="`background-image: url(${follower.avatar_url})`"
                        :title="follower.public_display_name"
                        class="logo__xs dashboardMK2__main__sideBar__followers__avatar"
                        @click="creatorModal(follower, true)" />
                </div>
            </div>
        </div>
        <user-info-modal
            :owner="currentUser"
            :token="token" />
        <share-modal />
        <booking-payment />
    </div>
</template>
<script>
import UserFollowers from "@models/UserFollowers"
import UserFollows from "@models/UserFollows"
import MIcon from '../../uikit/MIcon.vue'
import UserInfoModal from "@components/modals/UserInfoModal"
import ShareModal from '@components/modals/ShareModal.vue'
import {getCookie} from "../../utils/cookies"
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    name: 'DashboardSideBar',
    components: {MIcon, UserInfoModal, ShareModal, BookingPayment},
    props: [
        'activeMenuItem'
    ],
    data() {
        return {
            followers: [],
            showNav: true,
            userFollowers: [],
            userFollows: [],
            history: false,
            statistics: false,
            is_document_management_enabled: false
        }
    },
    computed: {
        credentialsAbility() {
            return this.currentUser?.credentialsAbility
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isCurrentUserExist() {
            return !!this.currentUser
        },
        token() {
            return getCookie('_unite_session_jwt')
        },
        followersCount() {
            if (this.userFollowers.length) {
                return this.userFollowers[0].count
            } else {
                return 0
            }
        },
        followsCount() {
            if (this.userFollows.length) {
                return this.userFollows[0].count
            } else {
                return 0
            }
        },
        isCompanyAvailable() {
            return this.currentOrganization || this.currentUser?.hasSubscription
        },
        isStatisticsAvailable() {
            return process.env.RAILS_ENV !== 'production'
        },
        isStatisticsCred() {
            return this.credentialsAbility?.can_view_statistics
        },
        isMultiroomAvailable() {
            return this.currentUser?.subscriptionAbility?.can_access_multiroom
        },
        isManagementAvailable() {
            return this.currentUser?.subscriptionAbility?.can_manage_team
        },
        isCommunityAvailable() {
            return this.currentUser?.subscriptionAbility?.can_manage_blog
        },
        isProductsAvailable() {
            return this.currentUser?.subscriptionAbility?.can_access_products
        },
        isSubscriptionsAvailable() {
            return this.currentUser?.subscriptionAbility?.can_monetize_content
        },
        isCurrentOrganizationHasSubscriptionOrRevenue() {
            return this.currentOrganization?.has_active_subscription_or_split_revenue
        },
        isBusinessSubscriptionAvailable() {
            return this.currentUser?.hasSubscription
        },
        isContactsAndMailingAvailable() {
            // return this.currentOrganization.has_active_subscription_or_split_revenue && this.currentUser?.subscriptionAbility?.can_manage_contacts_and_mailing
            return this.currentUser?.subscriptionAbility?.can_manage_contacts_and_mailing
        },
        isMultiroomCred() {
            return this.credentialsAbility.can_multiroom_config
        },
        presenter() {
            return this.currentUser?.current_role === 'presenter' && this.currentOrganization?.id > 0
        },
        isCurrentOrganizationOwner() {
            return this.currentUser?.id && this.currentOrganization?.user_id === this.currentUser?.id
        },
        isCurrentOrganizationHasFreeSubscriptions() {
            return this.currentOrganization?.enable_free_subscriptions
        }
    },
    watch: {
        currentUser(val) {
            if (val) {
                UserFollowers.api().getFollowers({
                    followable_type: "User",
                    followable_id: this.currentUser?.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollowers = UserFollowers.query().get()
                })
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.currentUser?.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollows = UserFollows.query().get()
                })
            }
        }
    },
    mounted() {
        this.mobile()
        this.getFollow()
        this.history = this.$railsConfig.frontend.dashboard.menu.history
        this.statistics = this.$railsConfig.frontend.dashboard.menu.statistics
        this.is_document_management_enabled = this.$railsConfig.global.is_document_management_enabled
    },
    methods: {
        toggleNav() {
            this.showNav = !this.showNav
        },
        mobile() {
            if (window.innerWidth < 640) this.showNav = false
        },
        creatorModal(creator, followers) {
            if (creator.type === "User" || creator.id === this.currentUser?.id || followers) {
                this.$eventHub.$emit("open-modal:userinfo", {
                    notFull: true,
                    model: creator
                })
            }
        },
        getFollow() {
            if (this.currentUser) {
                UserFollowers.api().getFollowers({
                    followable_type: "User",
                    followable_id: this.currentUser?.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollowers = UserFollowers.query().get()
                })
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.currentUser?.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollows = UserFollows.query().get()
                })
            }
        },
        isMenuItemActive(munuItem, links = null, defaultDashboard = false) {
            if(this.activeMenuItem == munuItem) {
                return true
            }
            else if(links) {
                return (defaultDashboard && location.pathname == "/dashboard")
                        || links.find(l => location.href.includes(l))
            }
            return false
        }
    }
}
</script>