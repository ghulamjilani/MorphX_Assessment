<template>
    <m-modal
        ref="ownerModal"
        class="ownerModal"
        :backdrop="!booking"
        :class="showFooter ? '' : 'ownerModal__margin'">
        <template #header>
            <OwnerHeaderTemplate
                :count="followersCount"
                :follows_count="followsCount"
                :owner="model"
                :owner_id="model.id"
                :token="token" />
        </template>
        <transition
            mode="out-in"
            name="slide">
            <message-creator
                v-if="message && selfFollows && !currentFollow()"
                :monolit="monolit"
                :recipient="model"
                @cancel="message = false" />
            <FollowSection
                v-else-if="followersExists"
                :count="followersCount"
                :follows="follows"
                :follows_count="followsCount"
                :integer="integer"
                :organization_id="organization_id ? organization_id : organizationId"
                :owner="model"
                :owner_id="model.id"
                :token="token"
                :user-follow="userFollow(follows)" />
            <book-user
                v-else-if="booking"
                :owner="model" />
            <AboutOwner
                v-else
                :limit="4"
                :owner="model" />
        </transition>
        <template #black_footer>
            <OwnerCreatorFooterTemplate
                :owner="model"
                class="ownerModal__footer"
                @close="close()" />
        </template>
    </m-modal>
</template>

<script>
import OwnerCreatorFooterTemplate from './template/OwnerCreatorFooterTemplate'
import OwnerHeaderTemplate from './template/OwnerHeaderTemplate'
import AboutOwner from './template/AboutOwner'
import FollowSection from './template/FollowSection'
import SelfFollows from "@models/SelfFollows"
import UserFollowers from "@models/UserFollowers"
import UserFollows from "@models/UserFollows"
import User from "@models/User"
import MessageCreator from './template/MessageCreator.vue'
import BookUser from './template/BookUser.vue'

export default {
    components: {OwnerCreatorFooterTemplate, OwnerHeaderTemplate, AboutOwner, FollowSection, MessageCreator, BookUser},
    props: {
        monolit: {
            type: Boolean,
            default: false
        },
        channels: {
            type: Array
        },
        token: {},
        organization_id: Number,
        owner: {}
    },
    data() {
        return {
            model: null,
            followerOn: false,
            follows: false,
            integer: 0,
            organizationId: null,
            message: false,
            booking: false
        }
    },
    computed: {
        showFooter(){
            return this.model && (this.model.channels_as_invited_presenter || this.model.channels_as_owner) && (this.model.channels_as_invited_presenter.length || this.model.channels_as_owner.length)
        },
        selfFollows() {
            return SelfFollows.query().where('id', this.model.id).exists()
        },
        userFollowers() {
            return UserFollowers.query().get()
        },
        userFollows() {
            return UserFollows.query().get()
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
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
            this.booking = false
        })
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
        this.$eventHub.$on("open-modal:userinfo", (data) => {
            this.model = data.model
            // this.organization_id = data.organization_id // immutable if it in props
            this.organizationId = data.organization_id
            if (data && data.notFull) {
                User.api().getCreatorInfo({id: data.model.id}).then(res => {
                    this.model = res.response.data.response
                    this.updateFollows()
                })
            }
            this.open()
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
        open() {
            this.$refs.ownerModal?.openModal()
            this.booking = false
            if (this.token) {
                SelfFollows.api().getFollows({followable_type: "User"})
                SelfFollows.api().getFollows({followable_type: "Organization"})
                SelfFollows.api().getFollows({followable_type: "Channel"})
            }
        },
        close() {
            if (this.$refs.ownerModal)
                this.$refs.ownerModal.closeModal()
        },
        userFollow(follows) {
            if (follows) {
                return this.userFollows
            } else {
                return this.userFollowers
            }
        },
        updateFollows() {
            if (!this.model) return
            UserFollows.deleteAll()
            UserFollowers.deleteAll()
            UserFollows.api().getFollows({followable_type: "user", followable_id: this.model.id})
            UserFollowers.api().getFollowers({followable_type: "user", followable_id: this.model.id})
        }
    }
}
</script>