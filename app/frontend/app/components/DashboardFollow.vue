<template>
    <div>
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
                    Followers <span class="dashboardMK2__main__sideBar__followers__count">{{ followersCount }}</span>
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
        <user-info-modal
            :monolit="monolit"
            :owner="currentUser"
            :token="token" />
        <share-modal />
        <booking-payment />
    </div>
</template>

<script>
import UserFollowers from "@models/UserFollowers"
import UserFollows from "@models/UserFollows"
import UserInfoModal from "@components/modals/UserInfoModal"
import ShareModal from './modals/ShareModal.vue'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"
import {getCookie} from "@utils/cookies"

export default {
    components: {UserInfoModal, ShareModal, BookingPayment},
    props: {
        monolit: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            followers: [],
            showNav: true,
            userFollowers: [],
            userFollows: [],
            history: false,
            statistics: false
        }
    },
    computed: {
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
        }
    },
    watch: {
        currentUser(val) {
            if (val) {
                UserFollowers.api().getFollowers({
                    followable_type: "User",
                    followable_id: this.currentUser.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollowers = UserFollowers.query().get()
                })
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.currentUser.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollows = UserFollows.query().get()
                })
            }
        }
    },
    mounted() {
        this.getFollow()
    },
    methods: {
        creatorModal(creator, followers) {
            if (creator.type === "User" || creator.id === this.currentUser.id || followers) {
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
                    followable_id: this.currentUser.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollowers = UserFollowers.query().get()
                })
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.currentUser.id,
                    type: "User",
                    limit: 14
                }).then(() => {
                    this.userFollows = UserFollows.query().get()
                })
            }
        }
    }
}
</script>