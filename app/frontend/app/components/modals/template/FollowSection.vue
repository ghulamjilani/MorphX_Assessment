<template>
    <transition
        mode="out-in"
        name="slide">
        <div
            :key="integer"
            class="ownerModal__followers">
            <div class="ownerModal__followers__title">
                <h4 v-if="follows">
                    Following({{ follows_count }})
                </h4>
                <h4 v-else>
                    Followers({{ count }})
                </h4>
                <span
                    class="GlobalIcon-clear MK2-modal__close"
                    @click="close()" />
            </div>
            <div class="ownerModal__followers__body smallScrolls">
                <div
                    v-for="follower in items()"
                    :key="follower.id"
                    class="ownerModal__followers__follower">
                    <div>
                        <a
                            :href="link(follower)"
                            target="_blank">
                            <m-avatar
                                v-if="follower.type === 'Organization' || follower.type === 'Channel'"
                                size="l"
                                star-size="s"
                                class="ownerModal__followers__avatar channel__info__owner__companyLogo"
                                :src="follower.avatar_url"
                                :can-book="follower.has_booking_slots" />
                            <m-avatar
                                v-else
                                size="l"
                                star-size="s"
                                class="ownerModal__followers__avatar"
                                :src="follower.avatar_url"
                                :can-book="follower.has_booking_slots" />
                        </a>
                    </div>
                    <div class="ownerModal__followers__displayName">
                        <a
                            :href="link(follower)"
                            target="_blank">
                            {{ follower.public_display_name }}
                        </a>
                    </div>
                    <div class="ownerModal__followers__button">
                        <m-btn
                            v-show="follower.type !== 'Channel' && !isFollowing(follower.id) && !currentFollow(follower.id)"
                            type="bordered"
                            @click="follow(follower.id, follower.type)">
                            Follow
                        </m-btn>
                        <m-btn
                            v-show="follower.type !== 'Channel' && isFollowing(follower.id) && !currentFollow(follower.id)"
                            type="secondary"
                            @click="unFollow(follower.id, follower.type)"
                            @mouseover.native="handleHover($event)"
                            @mouseleave.native="handleBlur($event)">
                            Following
                        </m-btn>
                        <m-btn
                            v-show="follower.type === 'Channel' && !isFollowing(follower.id) && !currentFollow(follower.id)"
                            class="ownerModal__followers__button__channel"
                            type="bordered"
                            @click="follow(follower.id, follower.type)">
                            Follow Channel
                        </m-btn>
                        <m-btn
                            v-show="follower.type === 'Channel' && isFollowing(follower.id) && !currentFollow(follower.id)"
                            class="ownerModal__followers__button__channel"
                            type="secondary"
                            @click="unFollow(follower.id, follower.type)"
                            @mouseover.native="handleChannelHover($event)"
                            @mouseleave.native="handleChannelBlur($event)">
                            Following Channel
                        </m-btn>
                    </div>
                </div>
                <infinite-loading
                    ref="InfiniteLoading"
                    spinner="waveDots"
                    @infinite="infiniteHandler">
                    <div slot="no-more" />
                    <div
                        slot="no-results"
                        class="history__body__no-results" />
                </infinite-loading>
            </div>
        </div>
    </transition>
</template>

<script>
import User from "@models/User"
import SelfFollows from "@models/SelfFollows"
import UserFollows from "@models/UserFollows"
import UserFollowers from "@models/UserFollowers"
import CompanyFollowers from "@models/CompanyFollowers"
import InfiniteLoading from "vue-infinite-loading"

export default {
    components: {InfiniteLoading},
    props: {
        token: {},
        count: Number,
        userFollow: Array,
        companyFollowers: Array,
        follows: Boolean,
        integer: Number,
        organization_id: Number,
        follows_count: Number,
        owner: {},
        owner_id: Number
    },
    data() {
        return {
            indexParams: {
                limit: 50,
                offset: 0
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    methods: {
        close() {
            this.$eventHub.$emit('close-follow')
            this.$eventHub.$emit('close-follow-company')
        },
        link(follower) {
            if (follower.type === 'User') return location.origin + '/users' + follower.relative_path
            return location.origin + follower.relative_path
        },
        handleHover(event) {
            event.target.innerText = "Unfollow"
        },
        handleBlur(event) {
            event.target.innerText = "Following"
        },
        handleChannelHover(event) {
            event.target.innerText = "Unfollow Channel"
        },
        handleChannelBlur(event) {
            event.target.innerText = "Following Channel"
        },
        infiniteHandler($state) {
            if (this.companyFollowers) {
                CompanyFollowers.api()
                    .getFollowers({
                        followable_type: "Organization",
                        followable_id: this.organization_id,
                        type: "Organization", ...this.indexParams
                    })
                    .then((response) => {
                        if (this.companyFollowers.length === response.response.data.pagination?.count || this.indexParams.limit >= response.response.data.pagination?.count || this.indexParams.offset >= response.response.data.pagination?.count) {
                            $state.complete()
                        } else {
                            this.indexParams.offset = this.indexParams.offset + this.indexParams.limit
                            $state.loaded()
                            document.querySelector('.ownerModal__followers__body').scrollTop -= 91 * response.response.data.response.followerslength.length
                        }
                    })
            } else if (this.userFollow && this.follows) {
                UserFollows.api()
                    .getFollows({
                        followable_type: "User",
                        followable_id: this.owner.id,
                        type: "User", ...this.indexParams
                    })
                    .then((response) => {
                        if (this.userFollow.length === response.response.data.pagination?.count || this.indexParams.limit >= response.response.data.pagination?.count || this.indexParams.offset >= response.response.data.pagination?.count) {
                            $state.complete()
                        } else {
                            this.indexParams.offset = this.indexParams.offset + this.indexParams.limit
                            $state.loaded()
                            document.querySelector('.ownerModal__followers__body').scrollTop -= 91 * response.response.data.response.follows.length
                        }
                    })
            } else if (this.userFollow && !this.follows) {
                UserFollowers.api()
                    .getFollowers({
                        followable_type: "User",
                        followable_id: this.owner.id,
                        type: "User", ...this.indexParams
                    })
                    .then((response) => {
                        if (this.userFollow.length === response.response.data.pagination?.count || this.indexParams.limit >= response.response.data.pagination?.count || this.indexParams.offset >= response.response.data.pagination?.count) {
                            $state.complete()
                        } else {
                            this.indexParams.offset = this.indexParams.offset + this.indexParams.limit
                            $state.loaded()
                            document.querySelector('.ownerModal__followers__body').scrollTop -= 91 * response.response.data.response.followers.length
                        }
                    })
            }
        },
        items() {
            if (this.userFollow) {
                return this.userFollow
            } else {
                return this.companyFollowers
            }
        },
        currentFollow(id) {
            if (this.currentUser && this.currentUser.id === id) {
                return true
            } else {
                return false
            }
        },
        isFollowing(id) {
            return SelfFollows.query().where('id', id).exists()
        },
        follow(id, type) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                if (this.follows) {
                    User.api().userFollow({followable_type: type, followable_id: id}).then((res) => {
                        if (this.currentUser.id === this.owner_id) {
                            UserFollows.api().getFollows({
                                followable_type: "User",
                                followable_id: this.owner_id
                            }).then((res) => {
                                this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                            })
                        }
                        SelfFollows.api().getFollows({followable_type: "User"})
                        SelfFollows.api().getFollows({followable_type: "Channel"})
                        SelfFollows.api().getFollows({followable_type: "Organization"})
                        UserFollows.api().getFollows({followable_type: "User", followable_id: this.owner.id})
                    })
                } else {
                    User.api().userFollow({followable_type: "User", followable_id: id}).then((res) => {
                        SelfFollows.api().getFollows({followable_type: "User"})
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner.id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    })
                }
            }
        },
        unFollow(id, type) {
            if (this.follows) {
                User.api().userUnFollow({followable_type: type, followable_id: id}).then((res) => {
                    if (this.currentUser.id === this.owner_id) {
                        UserFollows.delete(id)
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner_id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    }
                    if (this.organization_id === id) {
                        CompanyFollowers.delete(this.currentUser.id)
                        CompanyFollowers.api().getFollowers({
                            followable_type: "Organization",
                            followable_id: this.organization_id,
                            type: "Organization"
                        })
                    }
                    SelfFollows.delete(id)
                    UserFollows.api().getFollows({followable_type: "User", followable_id: this.owner.id})
                })
            } else {
                User.api().userUnFollow({followable_type: "User", followable_id: id}).then((res) => {
                    SelfFollows.delete(id)
                    if (this.currentUser.id === this.owner_id) {
                        UserFollows.delete(id)
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner_id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    }
                })
            }
        }
    }
}
</script>