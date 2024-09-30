<template>
    <div class="mChannel__banner__wrapper">
        <div class="mChannel__banner mChannel__section mChannel__section__full">
            <div
                :style="{backgroundPositionY: (((positionY1 + 16) / - 9) + 'rem'), backgroundImage: posterUrl ? 'url(' + (posterUrl) + ')': ''}"
                class="mChannel__banner__img">
                <div
                    v-if="organization.website_url || showSocialLinks"
                    class="mChannel__banner__social">
                    <a
                        v-if="organization.website_url && organization.website_url !== ''"
                        :href="organization.website_url"
                        target="_blank">
                        <m-icon size="1.6rem">GlobalIcon-website</m-icon>
                    </a>
                    <a
                        v-for="social in organization.social_links"
                        :key="social.id"
                        :href="social.url"
                        target="_blank">
                        <m-icon size="1.6rem">GlobalIcon-{{ social.provider }}</m-icon>
                    </a>
                </div>
                <business-modal
                    ref="businessModal"
                    :channels="channels"
                    :organization="organization"
                    :owner="owner"
                    :token="token" />
                <m-btn
                    v-if="isBlog && prevRoute"
                    :disabled="disabled"
                    class="mChannel__banner__back"
                    type="secondary"
                    @click="back">
                    {{ $t('channel_page.back_to_channel') }}
                </m-btn>
            </div>
        </div>
        <div class="mChannel__head mChannel__section mChannel__section__full">
            <div class="mChannel__head__topLine">
                <div class="mChannel__orgInfo">
                    <div
                        :style="organization.logo_url ? `background-image: url('${organization.logo_url}')` : ''"
                        class="mChannel__orgInfo__logo"
                        @click="openAboutBusiness" />
                    <div class="mChannel__orgInfo__content">
                        <div class="mChannel__orgInfo__description">
                            <div class="mChannel__orgInfo__name">
                                {{ organization.name }}
                            </div>

                            <div
                                v-if="getChannelDescription"
                                class="mChannel__orgInfo__description">
                                <!--if lese then 64 characters in description-->
                                <div v-if="getChannelDescription.length < 64">
                                    {{ getChannelDescription }}
                                </div>
                                <!--if more then 64 characters in description-->
                                <div v-else>
                                    {{ getChannelDescription.substring(0,64) }}
                                    <span @click="openAboutBusiness">
                                        ...
                                        read more
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div
                            v-if="channels.length > 1"
                            class="channel__select">
                            <button
                                class="btn__reset"
                                :style="channelsDropdown ? ' z-index: 100001;' : ''"
                                @click="toggleChannels">
                                {{ $t('channel_page.part_of') }}
                                <i
                                    :style="channelsDropdown ? ' transform: rotate(180deg) translateY(50%);' : ''"
                                    class=" GlobalIcon-angle-down" />
                            </button>
                            <div
                                v-show="channelsDropdown"
                                class="channel__select__content">
                                <div class="channel__select__cover" />
                                <div class="channel__select__label">
                                    {{ $t('channel_page.channels_by') }} {{ organization.name }}
                                </div>
                                <div class="channel__select__wrapp animatedScroll">
                                    <!--if !blog-->
                                    <router-link
                                        v-for="ch in channels"
                                        v-show="!isBlog"
                                        :key="ch.id"
                                        :to="{ name: 'channel-slug',
                                               params: { id: ch.relative_path.split('/')[2], slug: ch.relative_path.split('/')[3] }}">
                                        <div
                                            class="channel__select__item"
                                            @click="toggleChannels">
                                            <div
                                                :style="`background-image: url('${ch.image_gallery_url}')`"
                                                class="channel__select__img" />
                                            <div class="channel__select__title">
                                                {{ ch.title }}
                                            </div>
                                            <div
                                                v-if="ch.plans && getStartedPlan(ch)"
                                                class="channel__select__subscribe">
                                                {{ $t('channel_page.subscription_plan_from') }} {{ getStartedPlan(ch) }}
                                            </div>
                                        </div>
                                    </router-link>
                                    <!--if blog-->
                                    <div
                                        v-show="isBlog"
                                        class="channel__select__item"
                                        @click="filterChannel('all')">
                                        <div
                                            :style="`background-image: url('${organization.poster_url}')`"
                                            class="channel__select__img" />
                                        <div class="channel__select__title">
                                            {{ $t('channel_page.all') }}
                                        </div>
                                    </div>

                                    <div
                                        v-for="ch in channels"
                                        v-show="isBlog"
                                        :key="'ch'+ch.id"
                                        @click="filterChannel(ch.id)">
                                        <div class="channel__select__item">
                                            <div
                                                :style="`background-image: url('${ch.image_gallery_url}')`"
                                                class="channel__select__img" />
                                            <div class="channel__select__title">
                                                {{ ch.title }}
                                            </div>
                                        </div>
                                    </div>
                                    <!--/if-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="mChannel__head__bottomLine">
                <div
                    class="mChannel__head__name">
                    <div class="mChannel__head__name__label">
                        {{ isBlog && (!channel || !channel.title) ? organization.name : channel.title }}
                    </div>
                </div>
                <div class="mChannel__head__avatarS">
                    <div
                        class="avatarBlock"
                        @mouseleave="avatarsouseLeave">
                        <div
                            v-if="members.length > showCountCreators"
                            class="avatarBlock__item avatarBlock__item__more"
                            @click="openCreators">
                            <div class="avatarBlock__item__img openMore">
                                <i class="GlobalIcon-dots-3" />
                            </div>
                        </div>
                        <creators-modal
                            ref="creatorsModal"
                            :members="members"
                            :name="organization.name"
                            :owner_id="owner.id"
                            :token="token" />
                        <div
                            v-if="!creators.length || membersLoading"
                            class="avatarBlock__item active placeholder">
                            <div class="avatarBlock__item__img" />
                            <div class="avatarBlock__item__content">
                                <div class="avatarBlock__item__content__owner" />
                                <div class="avatarBlock__item__content__name" />
                            </div>
                        </div>
                        <div
                            v-for="creator in creators"
                            v-show="!membersLoading"
                            :key="creator.id"
                            :class="{'active': creator.active}"
                            class="avatarBlock__item"
                            @mouseenter="creatorMouseEnter(creator)">
                            <a
                                target="_blank"
                                @click="creatorModal(creator)">
                                <m-avatar
                                    class="avatarBlock__item__img"
                                    size="l"
                                    star-size="s"
                                    :src="creator.avatar_url"
                                    :can-book="creator.has_booking_slots" />
                                <!-- <div
                                    :style="`background-image: url('${creator.avatar_url}')`"
                                    class="avatarBlock__item__img" /> -->
                            </a>
                            <div class="avatarBlock__item__content">
                                <div
                                    v-if="creator.owner && currentFollow(creator)"
                                    class="avatarBlock__item__content__owner">
                                    {{ $t('channel_page.owner') }}
                                </div>
                                <div class="avatarBlock__item__content__name">
                                    {{ creator.public_display_name }}
                                </div>
                                <m-btn
                                    v-show="!selfFollows(creator) && !currentFollow(creator) && !ownerFollow(creator)"
                                    class="avatarBlock__item__content__follow"
                                    size="xs"
                                    type="bordered"
                                    @click="follow(creator)">
                                    {{ $t('channel_page.follow') }}
                                </m-btn>
                                <m-btn
                                    v-show="selfFollows(creator) && !currentFollow(creator) && !ownerFollow(creator)"
                                    class="avatarBlock__item__content__following"
                                    size="xs"
                                    type="bordered"
                                    @click="unFollow(creator)"
                                    @mouseover.native="handleHover($event, creator.id)"
                                    @mouseleave.native="handleBlur($event, creator.id)">
                                    {{ $t('channel_page.following') }}
                                </m-btn>
                                <m-btn
                                    v-show="!selfFollows(creator) && !currentFollow(creator) && ownerFollow(creator)"
                                    class="avatarBlock__item__content__follow"
                                    size="xs"
                                    type="bordered"
                                    @click="follow(creator)">
                                    {{ $t('channel_page.follow_owner') }}
                                </m-btn>
                                <m-btn
                                    v-show="selfFollows(creator) && !currentFollow(creator) && ownerFollow(creator)"
                                    class="avatarBlock__item__content__following avatarBlock__item__content__following__owner"
                                    size="xs"
                                    type="bordered"
                                    @click="unFollow(creator)"
                                    @mouseover.native="handleHover($event, creator.id)"
                                    @mouseleave.native="handleBlur($event, creator.id)">
                                    {{ $t('channel_page.following_owner') }}
                                </m-btn>
                            </div>
                        </div>
                    </div>
                </div>

                <div
                    v-if="!isBlog && !currentFollowChannel && !loading"
                    :class="{'oneChannel': channels.length < 2}"
                    class="text__right mChannel__head__buttonsS">
                    <m-btn
                        v-show="!selfFollowChannel && !currentFollowChannel"
                        class="avatarBlock__item__content__follow"
                        size="m"
                        type="bordered"
                        @click="followChannel(channel)">
                        {{ $t('channel_page.follow_channel') }}
                    </m-btn>
                    <m-btn
                        v-show="selfFollowChannel && !currentFollowChannel"
                        class="avatarBlock__item__content__following avatarBlock__item__content__following__channel"
                        size="m"
                        type="bordered"
                        @click="unFollowChannel(channel)"
                        @mouseover.native="handleChannelHover($event)"
                        @mouseleave.native="handleChannelBlur($event)">
                        {{ $t('channel_page.following_channel') }}
                    </m-btn>
                    <m-btn
                        v-if="subscription && !subscription.can_be_subscribed && !selfSubscriptions"
                        :disabled="true"
                        class="margin-l__10"
                        size="m"
                        type="main">
                        {{ $t('channel_page.subscribe') }} {{ getStartedPlan(channel) }}
                    </m-btn>
                    <m-btn
                        v-else-if="subscription && subscription.can_be_subscribed && subscription.plans && +getStartedPlan(channel) !== 0 && !selfSubscriptions"
                        class="margin-l__10"
                        size="m"
                        type="main"
                        @click="openSubsPlans">
                        {{ $t('channel_page.subscribe') }} {{ getStartedPlan(channel) }}
                    </m-btn>
                    <m-btn
                        v-if="selfSubscriptions"
                        class="margin-l__10"
                        size="m"
                        type="secondary">
                        {{ $t('channel_page.subscribed') }}
                    </m-btn>
                </div>
                <div
                    v-else
                    class="text__right mChannel__head__buttonsS" />
            </div>
        </div>
    </div>
</template>

<script>
import MIcon from '../../uikit/MIcon.vue'
import BusinessModal from '../modals/BusinessModal'
import planInfo from '../modals/planInfo'
import CreatorsModal from '../modals/CreatorsModal'
import Channel from "@models/Channel"
import User from "@models/User"
import SelfFollows from "@models/SelfFollows"
import SelfSubscription from "@models/SelfSubscription"
import SelfFreeSubscription from "@models/SelfFreeSubscription"
import UserFollowers from "@models/UserFollowers"
import UserFollows from "@models/UserFollows"
import Members from "@models/Members"

export default {
    components: {MIcon, BusinessModal, planInfo, CreatorsModal},
    props: {
        channel: {
            type: Object,
            default: null
        },
        organization: {
            type: Object
        },
        channels: {
            type: Array
        },
        token: {},
        owner: {},
        subscription: {},
        channelsPlans: {},
        isBlog: {
            type: Boolean,
            default: false
        },
        priority: {
            type: Number,
            default: null
        }
    },
    data() {
        return {
            creators: [],
            loading: true,
            showCountCreators: 4,
            channelsDropdown: false,
            positionY1: -1.5,
            ratio: 0.33, //shift rate for paralax
            disabled: true,
            members: [],
            membersLoading: true,
            subscriptionPlansOpened: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentFollowChannel() {
            return this.currentUser?.id === this.owner.id
        },
        selfFollowChannel() {
            return SelfFollows.query().where('id', this.channel.id).exists()
        },
        showSocialLinks() {
            return this.organization?.social_links?.length
        },
        posterUrl() {
            if (this.isBlog && this.channel && this.channel.gallery) {
                return this.channel.gallery[0].img_src
            } else if (this.channel && this.channel.gallery) {
                return this.channel.gallery[0].img_src
            } else {
                return this.organization.poster_url
            }
        },
        prevRoute() {
            return this.$store.getters["Global/prevRoute"]
        },
        selfSubscriptions() {
            if (this.currentUser && this.channel) {
                if (SelfFreeSubscription.query().where('channel_id', this.channel.id).exists()) {
                    return true
                } else if (SelfSubscription.query().where('channel_id', this.channel.id).exists()) {
                    return SelfSubscription.query().where('channel_id', this.channel.id).where('status', (value) => value == "trialing" || value == "active").first() != null
                } else return false
            } else {
                return false
            }
        },
        getChannelDescription() {
            return this.organization?.description?.replace(/<[^>]*>?/gm, '').replace(/&nbsp;/g, ' ')
        }
    },
    watch: {
        channel(val) {
            if (val) {
                this.getChannelMembers()
            }
        },
        organization(val) {
            if (val) {
                this.getOrganizationMembers()
            }
        },
        owner(val) {
            this.loading = false
            if (val && this.members) {
                this.calculateCreators()
            }
        },
        subscription(val) {
            if(!this.subscriptionPlansOpened && val?.plans?.length) {
                if(location.hash === "#subscription_plans") {
                    this.subscriptionPlansOpened = true
                    this.openSubsPlans()
                }
            }
        }
    },
    mounted() {
        this.$eventHub.$on('blog-changeChannel', () => {
            setTimeout(() => {
                if (this.isBlog && ((this.channel && this.channel.id) || this.organization.id)) {
                    this.getChannelMembers()
                    this.getOrganizationMembers()
                }
            }, 1000)
        })
        this.$eventHub.$on('priority', (val) => {
            if (this.priority == val) {
                this.selfFollowsChannel()
            }
        })
        setTimeout(() => {
            this.disabled = false
        }, 3000)
        this.$eventHub.$on("close-modal:all", () => {
            this.channelsDropdown = false
        })
        if (this.$route.query.user_modal) this.openCreatorModal(this.$route.query.user_modal)
        window.addEventListener("scroll", this.handleScroll) //Create scroll listener, page scroll callback handleScroll method
    },
    methods: {
        getChannelMembers() {
            if(this.channel?.id) {
                Members.api().getPublicChannelMembers({id: this.channel.id}).then((res) => {
                    this.members = res.response.data.response.channel_members
                    this.membersLoading = false
                    this.calculateCreators()
                })
            }
        },
        getOrganizationMembers() {
            if(!this.channel?.id && this.organization?.id) {
                Members.api().getPublicOrganizationMembers({id: this.organization.id, scope: 'all'}).then((res) => {
                    this.members = res.response.data.response.organization_members
                    this.membersLoading = false
                    this.calculateCreators()
                })
            }
        },
        handleHover(event, id) {
            if (this.owner && this.owner.id === id) {
                event.target.innerText = this.$t('channel_page.unfollow_owner')
            } else {
                event.target.innerText = this.$t('channel_page.unfollow')
            }
        },
        handleBlur(event, id) {
            if (this.owner && this.owner.id === id) {
                event.target.innerText = this.$t('channel_page.following_owner')
            } else {
                event.target.innerText = this.$t('channel_page.following')
            }
        },
        handleChannelHover(event) {
            event.target.innerText = this.$t('channel_page.unfollow_channel')
        },
        handleChannelBlur(event) {
            event.target.innerText = this.$t('channel_page.following_channel')
        },
        creatorMouseEnter(creator) {
            this.creators.forEach(e => e.active = false)
            creator.active = true
        },
        avatarsouseLeave() {
            this.creators.forEach((e, i) => e.active = i === this.creators.length - 1)
        },
        openSubsPlans() {
            this.$eventHub.$emit("open-modal:subscriptionPlans", this.subscription, this.channel)
        },
        openAboutBusiness() {
            this.$refs.businessModal.open()
            this.$eventHub.$emit('close-follow')
            this.$eventHub.$emit('close-follow-company')
        },
        openCreators() {
            this.$refs.creatorsModal.open()
        },
        toggleChannels() {
            this.channelsDropdown = !this.channelsDropdown
            this.$eventHub.$emit("toggle-pageCover", this.channelsDropdown)
        },
        chooseChannel(ch) {
            this.$router.push({path: `/channel/${ch.id}`})
        },
        currentFollow(creator) {
            if (this.currentUser) {
                if (creator && this.currentUser.id === creator.id) {
                    return true
                } else {
                    return false
                }
            }
        },
        ownerFollow(creator) {
            if (this.owner) {
                if (creator && this.owner.id === creator.id) {
                    return true
                } else {
                    return false
                }
            }
        },
        selfFollows(creator) {
            if (this.currentUser && creator) {
                return SelfFollows.query().where('id', creator.id).exists()
            }
        },
        follow(creator) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                User.api().userFollow({followable_type: "User", followable_id: creator.id}).then(() => {
                    SelfFollows.api().getFollows({followable_type: "User"})
                    UserFollowers.api().getFollowers({
                        followable_type: "User",
                        followable_id: creator.id,
                        type: "User"
                    })

                    if (this.currentUser.id === this.owner.id) {
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner.id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    }
                })
            }
        },
        followChannel(channel) {
            if (!this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "login")
            } else {
                User.api().userFollow({followable_type: "Channel", followable_id: channel.id}).then(() => {
                    SelfFollows.api().getFollows({followable_type: "Channel"})
                    if (this.currentUser.id === this.owner.id) {
                        UserFollows.api().getFollows({
                            followable_type: "User",
                            followable_id: this.owner.id
                        }).then((res) => {
                            this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                        })
                    }
                })
            }
        },
        unFollow(creator) {
            User.api().userUnFollow({followable_type: "User", followable_id: creator.id}).then(() => {
                SelfFollows.delete(creator.id)
                UserFollowers.delete(this.currentUser.id)
                if (this.currentUser.id === this.owner.id) {
                    UserFollows.api().getFollows({
                        followable_type: "User",
                        followable_id: this.owner.id
                    }).then((res) => {
                        this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                    })
                }
            })
        },
        unFollowChannel(channel) {
            User.api().userUnFollow({followable_type: "Channel", followable_id: channel.id}).then(() => {
                SelfFollows.delete(channel.id)
                if (this.currentUser.id === this.owner.id) {
                    UserFollows.api().getFollows({
                        followable_type: "User",
                        followable_id: this.owner.id
                    }).then((res) => {
                        this.$eventHub.$emit("updateFollow", false, res.response.data.pagination?.count)
                    })
                }
            })
        },
        getStartedPlan(channel) {
            if(!channel.subscription?.can_be_subscribed) return null

            let chp = this.channelsPlans.find(e => e.id === channel.id)
            if (!chp || !chp.plans) return "0"
            let str = ""
            let minPrice = 10000000
            chp.plans.forEach(e => {
                if (minPrice > +e.amount) {
                    minPrice = +e.amount
                    str = e.formatted_price
                }
            })
            return str
        },
        calculateCreators() {
            if (this.members.length > 0) {
                let deepCopy = JSON.parse(JSON.stringify(this.members))
                this.creators = deepCopy
                    .filter(e => e.id !== this.owner.id)
                    .slice(0, this.showCountCreators - 1)
                    .map((e) => {
                        e.active = false
                        return e
                    })
                this.creators.push(this.owner)
                this.creators[this.creators.length - 1].active = true
                this.creators[this.creators.length - 1].owner = true
            } else {
                if (this.members.length === 0 && this.owner) {
                    this.creators = [this.owner]
                    this.creators[0].active = true
                    this.creators[0].owner = true
                } else {
                    this.creators = []
                }
            }
        },
        handleScroll() {
            let scrollTop =
                window.pageYOffset ||
                document.documentElement.scrollTop ||
                document.body.scrollTop
            this.positionY1 = 0 - scrollTop * this.ratio //Original height-scroll distance * parallax coefficient
        },
        creatorModal(creator) {
            if(!creator.id) return
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: creator
            })
            setTimeout(() => {
                this.creatorMouseEnter(creator)
            }, 200)
        },
        filterChannel(channel) {
            this.toggleChannels()
            this.$emit("filterChannel", channel)
        },
        getFolowsUser() {
            return new Promise((resolve) => {
                SelfFollows.api().getFollows({followable_type: "User"}).then(() => {
                    resolve()
                })
            })
        },
        getFolowsChannel() {
            return new Promise((resolve) => {
                SelfFollows.api().getFollows({followable_type: "Channel"}).then(() => {
                    resolve()
                })
            })
        },
        selfFollowsChannel() {
            if (this.currentUser) {
                this.getFolowsUser().then(() => {
                    this.getFolowsChannel().then(() => {
                        this.$eventHub.$emit('check-priority', 2)
                    })
                })
            } else {
                this.$eventHub.$emit('check-priority', 0)
            }
        },
        back() {
            this.$router.back()
        },
        openCreatorModal(id) {
            Channel.api().getCreatorInfo({id: id}).then((res) => {
                var creator = res.response.data.response
                this.creatorModal(creator)
            })
        }
    }
}
</script>