<template>
    <div class="channel__info__owner">
        <a
            :href="link"
            target="_blank">
            <m-avatar
                :class="classAvatar()"
                size="xl"
                :src="srcLogo()"
                :can-book="owner && owner.has_booking_slots" />
        </a>
        <div>
            <div class="channel__info__owner__name">
                {{ name() }}
            </div>
            <div class="channel__info__owner__follow">
                <button
                    class="btn__reset"
                    @click="openFollowers()">
                    {{ $t('channel_page.followers') }}: <span class="channel__info__owner__count">{{ count }}</span>
                </button>
                <button
                    v-if="owner"
                    class="btn__reset"
                    @click="openFollows()">
                    {{ $t('channel_page.following') }}: <span
                        class="channel__info__owner__count">{{ follows_count }}</span>
                </button>
            </div>
        </div>
        <div class="channel__info__owner__button">
            <m-btn
                v-show="!selfFollows && !currentFollow()"
                type="bordered"
                @click="follow()">
                {{ $t('channel_page.follow') }}
            </m-btn>
            <m-btn
                v-show="selfFollows && !currentFollow()"
                type="secondary"
                @click="unFollow()"
                @mouseover.native="handleHover($event)"
                @mouseleave.native="handleBlur($event)">
                {{ $t('channel_page.following') }}
            </m-btn>
            <m-btn
                v-show="!selfFollows && !currentFollow() && owner"
                v-tooltip.bottom="{content: 'You need to follow user first', classes: 'channel__info__owner__tooltip'}"
                class="channel__info__owner__message channel__info__owner__message__hide"
                type="bordered">
                {{ $t('channel_page.message') }}
            </m-btn>
            <m-btn
                v-show="selfFollows && !currentFollow() && owner"
                class="channel__info__owner__message"
                type="bordered"
                @click="toggleMessage()">
                {{ $t('channel_page.message') }}
            </m-btn>
            <m-btn
                v-if="owner && $railsConfig.global.booking && $railsConfig.global.booking.enabled"
                class="channel__info__owner__message"
                type="bordered"
                :disabled="!owner.id || !owner.has_booking_slots || !owner.booking_available"
                @click="toggleBooking()">
                {{ $t('channel_page.book_me') }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import User from "@models/User"
import SelfFollows from "@models/SelfFollows"
import UserFollowers from "@models/UserFollowers"
import CompanyFollowers from "@models/CompanyFollowers"
import UserFollows from "@models/UserFollows"

export default {
    props: {
        owner_id: Number,
        organization: {
            type: Object
        },
        owner: {
            type: Object
        },
        follows_count: {
            type: Number,
            default: 0
        },
        token: {},
        count: {
            type: Number,
            default: 0
        }
    },
    computed: {
        selfFollows() {
            if (this.owner) {
                if(this.owner.following !== undefined) return this.owner.following
                return SelfFollows.query().where('id', this.owner.id).exists()
            } else {
                return SelfFollows.query().where('id', this.organization.id).exists()
            }
        },
        link() {
            if (this.owner) {
                return location.origin + "/users" + this.owner.relative_path
            } else {
                return location.origin + this.organization.relative_path
            }
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        followingCount() {
            return UserFollows.query().get().length
        }
    },
    methods: {
        toggleMessage() {
            this.$eventHub.$emit('toggle-message', true)
        },
        toggleBooking() {
            if(!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login", {action: "close"})
                return
            }
            this.$eventHub.$emit('toggle-booking', true)
        },
        openFollows() {
            if (this.owner) {
                this.$eventHub.$emit('open-follow', true, this.owner.id, false)
            } else {
                this.$eventHub.$emit('open-follow-company')
            }
        },
        openFollowers() {
            if (this.owner) {
                this.$eventHub.$emit('open-follow', false, this.owner.id, false)
            } else {
                this.$eventHub.$emit('open-follow-company')
            }
        },
        handleHover(event) {
            event.target.innerText = this.$t('channel_page.unfollow')
        },
        handleBlur(event) {
            event.target.innerText = this.$t('channel_page.following')
        },
        currentFollow() {
            if (this.owner) {
                if (this.currentUser && this.currentUser.id === this.owner.id) {
                    return true
                } else {
                    return false
                }
            }
        },
        srcLogo() {
            if (this.organization) {
                return this.organization.logo_url
            } else {
                return this.owner.avatar_url
            }
        },
		classAvatar() {
            if (this.organization) {
                return "channel__info__owner__companyLogo"
            } else {
                return ""
            }
        },
        name() {
            if (this.organization) {
                return this.organization.name
            } else {
                return this.owner.public_display_name
            }
        },
        countFollows() {
            return this.userFollows.length
        },
        follow() {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                if (this.organization) {
                    User.api().userFollow({
                        followable_type: "Organization",
                        followable_id: this.organization.id
                    }).then((res) => {
                        SelfFollows.api().getFollows({followable_type: "Organization"})
                        if (this.currentUser.id === this.owner_id) {
                            UserFollows.api().getFollows({
                                followable_type: "User",
                                followable_id: this.owner_id
                            }).then((res) => {
                                this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                            })
                        }
                        CompanyFollowers.api().getFollowers({
                            followable_type: "Organization",
                            followable_id: this.organization.id,
                            type: "Organization"
                        })
                    })
                } else {
                    User.api().userFollow({followable_type: "User", followable_id: this.owner.id}).then((res) => {
                        if (this.currentUser.id === this.owner_id) {
                            UserFollows.api().getFollows({
                                followable_type: "User",
                                followable_id: this.owner_id
                            }).then((res) => {
                                this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                            })
                        }
                        this.owner.following = true
                        SelfFollows.api().getFollows({followable_type: "User"})
                        UserFollowers.api().getFollowers({
                            followable_type: "User",
                            followable_id: this.owner.id,
                            type: "User"
                        })
                        UserFollows.api().getFollows({followable_type: "User", followable_id: this.owner.id})
                    })
                }
            }
        },
        unFollow() {
            if (this.organization) {
                User.api().userUnFollow({
                    followable_type: "Organization",
                    followable_id: this.organization.id
                }).then((res) => {
                    SelfFollows.delete(this.organization.id)
                    CompanyFollowers.delete(this.currentUser.id)
                    CompanyFollowers.api().getFollowers({
                        followable_type: "Organization",
                        followable_id: this.organization.id,
                        type: "Organization"
                    })
                    if (this.currentUser.id === this.owner_id) {
                        UserFollows.delete(this.organization.id)
                    }
                })
            } else {
                this.$eventHub.$emit('toggle-message', false)
                User.api().userUnFollow({followable_type: "User", followable_id: this.owner.id}).then((res) => {
                    if (this.currentUser.id === this.owner_id) {
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner_id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    }
                    this.owner.following = false
                    SelfFollows.delete(this.owner.id)
                    UserFollowers.api().getFollowers({
                        followable_type: "User",
                        followable_id: this.owner.id,
                        type: "User"
                    })
                    UserFollows.api().getFollows({followable_type: "User", followable_id: this.owner.id})
                })
            }
        }
    }
}
</script>