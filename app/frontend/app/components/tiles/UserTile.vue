<template>
    <div
        :id="`creator_tile_${user.id}`"
        :data-id="user.id"
        class="UserTile"
        data-type="creator">
        <a
            :href="user.short_url"
            class="UserTile__img">
            <m-avatar
                :src="user.avatar_url"
                :alt="user.public_display_name"
                size="xxl"
                :can-book="user.has_booking_slots" />
            <!-- <div
                :style="backgroundImage"
                class="UserTile__img__circle" /> -->
        </a>
        <moderate-tiles
            :item="user"
            type="User"
            :use-promo-weight="usePromoWeight" />
        <div class="UserTile__body">
            <a
                :href="user.short_url"
                class="UserTile__body__name">
                {{ user.public_display_name }}
            </a>
            <!--<div class="Country" v-if="user.country">Country: {{ user.country }}</div>-->
            <!--<div class="Language"><span>Language:</span> {{ user.language }}</div>-->
            <div class="UserTile__body__follows">
                <div>{{ $t('creator_tile.followers_count') }} <span>{{ user.followers }}</span></div>
                <div>{{ $t('creator_tile.following_count') }} <span>{{ user.following }}</span></div>
            </div>
            <m-btn
                v-show="!selfFollows && !currentFollow && !ownerFollow"
                class="avatarBlock__item__content__follow"
                size="s"
                type="bordered"
                @click="follow(user)">
                {{ $t('creator_tile.follow') }}
            </m-btn>
            <m-btn
                v-show="selfFollows && !currentFollow && !ownerFollow"
                class="avatarBlock__item__content__following"
                size="s"
                type="secondary"
                @click="unFollow(user)"
                @mouseover.native="handleHover($event, user.id)"
                @mouseleave.native="handleBlur($event, user.id)">
                {{ $t('creator_tile.following') }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import User from "@models/User"
import UserFollowers from "@models/UserFollowers"
import SelfFollows from "@models/SelfFollows"

export default {
    props: {
        existUser: Object,
        itemId: Number,
        search: Boolean,
        usePromoWeight: Boolean
    },
    computed: {
        selfFollows() {
            return SelfFollows.query().where('id', this.user.id).exists()
        },
        currentFollow() {
            return this.currentUser?.id === this.user?.id
        },
        ownerFollow() {
            return this.owner?.id === this.user?.id
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        user() {
            if (this.existUser) return this.existUser
            else return User.query().whereId(this.itemId).first()
        },
        backgroundImage() {
            return {backgroundImage: `url(${this.user.avatar_url})`}
        }
    },
    methods: {
        follow(user) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                User.api().userFollow({followable_type: "User", followable_id: user.id}).then((res) => {
                    SelfFollows.api().getFollows({followable_type: "User"})
                    UserFollowers.api().getFollowers({
                        followable_type: "User",
                        followable_id: user.id,
                        type: "User"
                    })
                })
            }
        },
        unFollow(user) {
            User.api().userUnFollow({followable_type: "User", followable_id: user.id}).then((res) => {
                SelfFollows.delete(user.id)
                UserFollowers.delete(this.currentUser.id)
            })
        },
        handleHover(event, id) {
            event.target.innerText = this.$t('creator_tile.unfollow')
        },
        handleBlur(event, id) {
            event.target.innerText = this.$t('creator_tile.following')
        }
    }
}
</script>
