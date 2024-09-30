<template>
    <m-modal
        ref="creatorsModal"
        class="creatorsModal">
        <div class="creatorsModal__header">
            <h4 class="creatorsModal__title">
                {{ name }}
            </h4>
            <span class="creatorsModal__count">{{ members.length }} {{ $t('frontend.app.components.modals.creators_modal.creators') }}</span>
        </div>
        <div class="creatorsModal__search">
            <div class="creatorsModal__input">
                <m-icon size="1.6rem">
                    GlobalIcon-search
                </m-icon>
                <m-input
                    v-model.trim="query"
                    :errors="false"
                    :placeholder="$t('frontend.app.components.modals.creators_modal.search_by_name')"
                    borderless
                    pure
                    type="text" />
            </div>
        </div>
        <div class="creatorsModal__body smallScrolls">
            <div
                v-for="member in members"
                :key="member.id"
                class="creatorsModal__creators">
                <div>
                    <m-avatar
                        size="l"
                        star-size="s"
                        :src="member.avatar_url"
                        :can-book="member.has_booking_slots"
                        @click="memberModal(member)" />
                    <!-- <a
                        target="_blank"
                        @click="memberModal(member)">
                        <span
                            :style="`background-image: url('${member.avatar_url}')`"
                            class="creatorsModal__creators__avatar" />
                    </a> -->
                </div>
                <div class="creatorsModal__creators__displayName">
                    <a @click="memberModal(member)">
                        {{ member.public_display_name }}
                    </a>
                </div>
                <div class="creatorsModal__creators__button">
                    <m-btn
                        v-show="!isFollowing(member.id) && !currentFollow(member.id)"
                        type="bordered"
                        @click="follow(member.id)">
                        Follow
                    </m-btn>
                    <m-btn
                        v-show="isFollowing(member.id) && !currentFollow(member.id)"
                        type="secondary"
                        @click="unFollow(member.id)"
                        @mouseover.native="handleHover($event)"
                        @mouseleave.native="handleBlur($event)">
                        {{ $t('frontend.app.components.modals.creators_modal.following') }}
                    </m-btn>
                </div>
            </div>
        </div>
    </m-modal>
</template>

<script>
import User from "@models/User"
import SelfFollows from "@models/SelfFollows"
import UserFollows from "@models/UserFollows"
import Members from "@models/Members"

export default {
    props: {
        name: String,
        owner_id: Number,
        token: {}
    },
    data() {
        return {
            query: ''
        }
    },
    computed: {
        members() {
            if (!this.query.length) {
                return Members.query().get()
            } else {
                return Members.query().where('public_display_name', (value) => value.toLowerCase().includes(this.query.toLowerCase())).get()
            }
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })
    },
    methods: {
        handleHover(event) {
            event.target.innerText = this.$t('frontend.app.components.modals.creators_modal.unfollow')
        },
        handleBlur(event) {
            event.target.innerText = this.$t('frontend.app.components.modals.creators_modal.following')
        },
        currentFollow(id) {
            if (this.currentUser && this.currentUser.id === id) {
                return true
            } else {
                return false
            }
        },
        open() {
            this.$refs.creatorsModal.openModal()
            if (this.token) {
                SelfFollows.api().getFollows({followable_type: "User"})
            }
        },
        close() {
            if (this.$refs.creatorsModal) this.$refs.creatorsModal.closeModal()
        },
        isFollowing(id) {
            return SelfFollows.query().where('id', id).exists()
        },
        follow(id) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                User.api().userFollow({followable_type: "User", followable_id: id}).then((res) => {
                    SelfFollows.api().getFollows({followable_type: "User"})
                    UserFollows.api().getFollows({
                        followable_type: "User",
                        followable_id: this.owner_id
                    }).then((res) => {
                        this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                    })
                })
            }
        },
        unFollow(id) {
            User.api().userUnFollow({followable_type: "User", followable_id: id}).then((res) => {
                SelfFollows.delete(id)
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.owner_id
                }).then((res) => {
                    this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                })
            })
        },
        memberModal(user) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: user
            })
        }
    }
}
</script>