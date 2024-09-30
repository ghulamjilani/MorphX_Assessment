<template>
    <div
        id="anchorSection__about"
        class="mChannel__info anchorSection">
        <div class="channel__info__wrapp mChannel__section">
            <div class="channel__info__left">
                <div class="channel__info__left__content">
                    <div class="mChannel__label">
                        {{ $t('channel_page.about') }}
                    </div>
                    <div
                        class="mChannel__info__description"
                        v-html="description" />
                    <div>
                        <button
                            v-if="channel.description && channel.description.length > cropReadMore"
                            class="btn__reset channel__info__left__readMore"
                            @click="toggleReadMore">
                            {{ readMore ? $t('channel_page.read_less') : $t('channel_page.read_more') }}
                        </button>
                    </div>
                </div>
                <div class="channel__info__left__footer">
                    <div>
                        <div>{{ $t('channel_page.category') }}:</div>
                        <span>{{ channel.category_name }}</span>
                    </div>
                    <div>
                        <div>{{ $t('channel_page.channel') }}:</div>
                        <span>{{ $t('channel_page.since') }} {{ year }}</span>
                    </div>
                    <div>
                        <div>{{ $t('channel_page.streams') }}:</div>
                        <span>{{ channel.past_sessions_count }}</span>
                    </div>
                    <div>
                        <div>{{ $t('channel_page.language') }}:</div>
                        <span>{{
                            buetifyLanguage[channel.language] ? buetifyLanguage[channel.language] : channel.language
                        }}</span>
                    </div>
                </div>
            </div>
            <div class="channel__info__right">
                <div class="channel__info__right__label">
                    {{ $t('channel_page.channel_owner') }}
                </div>
                <div class="channel__info__right__owner">
                    <m-avatar
                        size="xl"
                        :src="owner.avatar_url"
                        :can-book="owner.has_booking_slots"
                        @click="creatorModal(owner)" />
                    <!-- <div
                        class="logo__xl bookingLabel__wrapper"
                        @click="creatorModal(owner)">
                        <i
                            v-tooltip="'This Creator available for Booking'"
                            class="bookingLabel bookingLabel__l GlobalIcon-star" />
                        <img
                            :src="owner.avatar_url"
                            alt="">
                    </div> -->
                    <div>
                        <div
                            class="channel__info__right__owner__name"
                            @click="creatorModal(owner)">
                            {{ owner.public_display_name }}
                        </div>
                        <button
                            class="btn__reset"
                            @click="creatorModal(owner)">
                            {{ $t('channel_page.followers') }}: <span>{{ followersCount }}</span>
                        </button>
                        <button
                            class="btn__reset"
                            @click="creatorModal(owner)">
                            {{ $t('channel_page.following') }}: <span>{{ followingCount }}</span>
                        </button>
                    </div>
                </div>
                <div
                    v-show="creators.length > 0"
                    class="channel__info__right__creator">
                    <div class="channel__info__right__creator__label">
                        {{ $t('dictionary.creators_upper') }}
                        <button
                            v-show="members.length > 4"
                            class="btn__reset text__uppercase"
                            @click="openCreators">
                            {{ $t('channel_page.view_all') }}
                        </button>
                        <creators-modal
                            ref="creatorsModal"
                            :members="members"
                            :name="organization.name"
                            :owner_id="owner.id"
                            :token="token" />
                    </div>
                    <div
                        v-for="creator in creators"
                        :key="creator.id"
                        class="channel__info__right__block">
                        <a @click="memberModal(creator)">
                            <m-avatar
                                size="l"
                                star-size="s"
                                :src="creator.avatar_url"
                                :can-book="creator.has_booking_slots" />
                        </a>
                        <a @click="memberModal(creator)">{{ creator.public_display_name }}</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import CreatorsModal from '../modals/CreatorsModal'
import Members from "@models/Members"
import UserFollows from "@models/UserFollows"
import UserFollowers from "@models/UserFollowers"

export default {
    components: {CreatorsModal},
    props: {
        channel: {
            type: Object
        },
        channels: {
            type: Array
        },
        organization: {
            type: Object
        },
        owner: {
            type: Object
        },
        token: {},
        priority: {
            type: Number,
            default: null
        }
    },
    data() {
        return {
            buetifyLanguage: {
                "en": "English"
            },
            cropReadMore: 1700,
            readMore: false,
            followingCount: 0,
            followersCount: 0
        }
    },
    computed: {
        members() {
            return Members.query().get()
        },
        creators() {
            return this.members.length > 0 ? this.members.slice(0, 4) : []
        },
        year() {
            return this.channel ? new Date(this.channel.created_at).getFullYear() : 1800
        },
        description() {
            if (this.channel.description?.length <= this.cropReadMore) this.readMore = true
            return this.readMore ? this.channel.description : this.channel.description?.slice(0, this.cropReadMore) + "..."
        }
    },
    watch: {
        owner(val) {
            UserFollows.api().getFollows({
                followable_type: "User",
                followable_id: this.owner.id,
                limit: 1
            }).then(res => {
                this.followingCount = res.response.data.pagination?.count
            })
            UserFollowers.api().getFollowers({
                followable_type: "User",
                followable_id: this.owner.id,
                limit: 1
            }).then(res => {
                this.followersCount = res.response.data.pagination?.count
            })
        }
    },
    mounted() {
        this.$eventHub.$on('priority', (val) => {
            if (this.priority == val) {
                this.getAllFollow()
            }

        })
        this.$eventHub.$on("updateFollow", (followersCount, followingCount) => {
            if (followingCount !== false) this.followingCount = followingCount
            if (followersCount !== false) this.followersCount = followersCount
        })
    },
    methods: {
        getAllFollow() {
            this.getUserFollows().then(() => {
                this.getUserFollowers().then(() => {
                    this.$eventHub.$emit('check-priority', 2)
                })
            })
        },
        getUserFollows() {
            return new Promise((resolve, reject) => {
                UserFollows.api().getFollows({
                    followable_type: "User",
                    followable_id: this.owner.id,
                    limit: 1
                }).then(res => {
                    this.followingCount = res.response.data.pagination?.count
                    resolve()
                })
            })
        },
        getUserFollowers() {
            return new Promise((resolve, reject) => {
                UserFollowers.api().getFollowers({
                    followable_type: "User",
                    followable_id: this.owner.id,
                    limit: 1
                }).then(res => {
                    this.followersCount = res.response.data.pagination?.count
                    resolve()
                })
            })
        },
        creatorModal(creator) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: creator
            })
        },
        openCreators() {
            this.$refs.creatorsModal.open()
        },
        toggleReadMore() {
            this.readMore = !this.readMore
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