<template>
    <div class="userPage">
        <share-modal />
        <booking-payment />
        <div class="userPage__wrapper">
            <owner-header-template
                :count="followersCount"
                :follows_count="followsCount"
                :owner="user"
                :owner_id="user.id"
                :token="token" />
            <transition
                mode="out-in"
                name="slide">
                <message-creator
                    v-if="message && selfFollows && !currentFollow()"
                    :recipient="user"
                    @cancel="message = false" />
                <follow-section
                    v-else-if="followersExists"
                    :count="followersCount"
                    :follows="follows"
                    :follows_count="followsCount"
                    :integer="integer"
                    :owner="user"
                    :owner_id="user.id"
                    :token="token"
                    :user-follow="userFollow(follows)" />
                <book-user
                    v-else-if="booking"
                    :owner="user" />
                <about-owner
                    v-else
                    :limit="6"
                    :owner="user"
                    :is-user-channel="isUserChannel" />
            </transition>
        </div>
        <owner-creator-footer-template :owner="user" />
    </div>
</template>

<script>
import AboutOwner from '../components/modals/template/AboutOwner.vue'
import OwnerCreatorFooterTemplate from '../components/modals/template/OwnerCreatorFooterTemplate.vue'
import OwnerHeaderTemplate from '../components/modals/template/OwnerHeaderTemplate.vue'
import MessageCreator from '../components/modals/template/MessageCreator.vue'
import FollowSection from '../components/modals/template/FollowSection.vue'
import ShareModal from '@components/modals/ShareModal'
import BookUser from '@components/modals//template/BookUser.vue'
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

import Channel from "@models/Channel"
import SelfFollows from "@models/SelfFollows"
import UserFollowers from "@models/UserFollowers"
import UserFollows from "@models/UserFollows"
import {getCookie} from "../utils/cookies"

export default {
    components: {
        OwnerHeaderTemplate,
        AboutOwner,
        OwnerCreatorFooterTemplate,
        MessageCreator,
        FollowSection,
        ShareModal,
        BookUser,
        BookingPayment
    },
    data() {
        return {
            user: {},
            followerOn: false,
            follows: false,
            integer: 0,
            organizationId: null,
            message: false,
            booking: false
        }
    },
    computed: {
        token() {
            return getCookie('_unite_session_jwt')
        },
        selfFollows() {
            return SelfFollows.query().where('id', this.user.id).exists()
        },
        userFollowers() {
            return UserFollowers.query().get()
        },
        userFollows() {
            return UserFollows.query().orderBy('created_at', 'desc').get()
        },
        followersExists() {
            this.followerOn
            if (this.userFollow(this.follows).length && this.followerOn) {
                return true
            } else {
                this.followerOn = false
                return false
            }
        },
        followersCount() {
            if (UserFollowers.query().get().length) {
                return UserFollowers.query().first().count
            } else {
                return 0
            }
        },
        followsCount() {
            if (UserFollows.query().get().length) {
                return UserFollows.query().first().count
            } else {
                return 0
            }
        },
        isUserChannel() {
            return this.user?.channels_as_owner?.length > 0
        }
    },
    watch: {
        user(val) {
            if (val) {
                UserFollowers.api().getFollowers({
                    followable_type: "User",
                    followable_id: this.user.id,
                    type: "User",
                    limit: 50
                })
                UserFollows.api().getFollows({followable_type: "User", followable_id: this.user.id, limit: 50})
            }
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
            this.booking = false
        })
        if (this.$route.params.slug) {
            this.getUserInfo(this.$route.params.slug)
        }
        this.$eventHub.$on("toggle-message", (val) => {
            if (!val) return this.message = false
            this.message = !this.message
            this.followerOn = false
            this.booking = false
        })
        this.$eventHub.$on("toggle-booking", (val) => {
            if (!val) return this.booking = false
            this.booking = !this.booking
            this.message = false
            this.followerOn = false
        })
        this.$eventHub.$on("open-follow", (follows) => {
            this.integer++
            this.follows = follows
            this.followerOn = true
            this.message = false
            this.booking = false
        })
        this.$eventHub.$on("close-follow", () => {
            this.followerOn = false
        })
    },
    methods: {
        currentFollow() {
            if (this.owner) {
                if (this.currentUser && this.currentUser.id === this.owner.id) {
                    return true
                } else {
                    return false
                }
            }
        },
        userFollow(follows) {
            if (follows) {
                return this.userFollows
            } else {
                return this.userFollowers
            }
        },
        getUserInfo(slug) {
            Channel.api().getCreatorInfo({id: slug, log_activity: 1}).then((res) => {
                this.user = res.response.data.response
            })
            if (this.token) {
                SelfFollows.api().getFollows({followable_type: "User"})
                SelfFollows.api().getFollows({followable_type: "Organization"})
                SelfFollows.api().getFollows({followable_type: "Channel"})
            }
        }
    }
}
</script>