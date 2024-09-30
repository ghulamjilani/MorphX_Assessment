<template>
    <div class="mChannel">
        <banner
            v-show="channel.id"
            :channel="channel"
            :channels="channels"
            :channels-plans="channelsPlans"
            :organization="organization"
            :owner="owner"
            :priority="1"
            :subscription="subscription"
            :token="token" />

        <tiles
            v-show="channel.id"
            :channel="channel"
            :channels="channels"
            :members="members"
            :organization_relative_path="organization.relative_path"
            :owner="owner"
            :posts-count="postsCount"
            :priority="2"
            :subscription_features="organization.subscription_features" />

        <!-- <div
            v-if="channel.id"
            v-show="postsCount > 0"
            id="anchorSection__blog"
            class="mChannel__blog mChannel__section anchorSection">
            <div class="mChannel__label">
                {{ $t('frontend.app.components.channel.page.most_resent_posts') }}
            </div>
            <articles-wrapper :channel-id="channel.id" />
        </div> -->

        <BookingUsersRow
            :users="[owner].concat(members)" />

        <div
            v-if="$railsConfig.global.is_document_management_enabled && channel.id && documents.length > 0"
            id="anchorSection__documents"
            class="mChannel__documents">
            <div class="channel__list__wrapp mChannel__section">
                <div class="mChannel__label">
                    {{ $t('frontend.app.components.channel.page.documents') }}
                </div>
                <documents-cards-collection
                    :channel="channel"
                    :loadIterationLimit="5" />
            </div>
        </div>

        <reviews
            v-if="channel.show_reviews && reviews.length"
            :model="{id: channel.id, type: 'Channel', show_reviews: channel.show_reviews}" />

        <blog
            v-show="channel.id && isCommunityAvailable"
            :can-create="canCreatePost"
            :channel="channel"
            :organization="organization"
            :priority="[4,5]"
            @postsCount="getPostsCount" />

        <products
            v-if="channel && channel.id"
            class="mChannel__section"
            :channel="channel" />

        <info
            v-show="channel.id"
            :channel="channel"
            :channels="channels"
            :organization="organization"
            :owner="owner"
            :priority="6"
            :token="token" />

        <channels
            v-show="channel.id && channels.length > 1"
            :channels="channels"
            :channels-plans="channelsPlans"
            :name="organization.name"
            :organization_id="organization.id"
            :subscription="subscription"
            :current-channel-id="currentChannelId" />

        <user-info-modal
            :channels="channels"
            :organization_id="organization.id"
            :owner="owner"
            :token="token" />
        <booking-payment />

        <!-- <subs-plans-template
            ref="subsPlans"
            :subscription="subscription" /> -->
    </div>
</template>

<script>
import Banner from "@components/channel/Banner"
import Tiles from "@components/channel/Tiles"
import Reviews from "@components/channel/Reviews"
import Info from "@components/channel/Info"
import Channels from "@components/channel/Channels"
import Blog from "@components/channel/Blog"
import Products from "@components/channel/Products"
import UserInfoModal from "@components/modals/UserInfoModal"
import BookingUsersRow from "@components/booking/BookingUsersRow"

import Channel from "@models/Channel"
import Members from "@models/Members"
import SelfSubscription from "@models/SelfSubscription"
import SelfFreeSubscription from "@models/SelfFreeSubscription"
import Document from "@models/Document"
import Pagination from '@models/Pagination'
import {getCookie} from "../../utils/cookies"
import DocumentsCardsCollection from "../documents/CardsCollection"
import SubsPlansTemplate from '../modals/SubscriptionPlans'
// import ArticlesWrapper from "@components/main-page/ArticlesWrapper.vue"
import BookingPayment from "@components/booking/bookModal/BookingPayment.vue"

export default {
    name: 'ChannelPage',
    components: {
        DocumentsCardsCollection, Banner, Reviews, Info, Channels, Tiles, UserInfoModal, Blog,
        SubsPlansTemplate, Products, BookingPayment, BookingUsersRow
    },
    beforeRouteUpdate(to, from, next) {
        if (to.params.slug) {
            let slug = to.fullPath.replace("/channels", "")
            this.priority = 0
            this.$eventHub.$emit("reset-priority")
            this.fetchData(slug, true)
        } else {
            this.priority = 0
            this.$eventHub.$emit("reset-priority")
            this.fetchData(to.params.id)
        }
        this.$eventHub.$emit("close-modal:all")
        scrollTo(0, 0)
        next()
    },
    data() {
        return {
            channel: {},
            organizer: {},
            organization: {},
            channels: [],
            owner: {},
            subscription: {},
            channelsPlans: [],
            priority: 0,
            reviews: [1],
            postsCount: 0,
            documentsPaginationId: `${this.$options.name}_${this._uid}_documents`,
            lastOpenedDocument: null
        }
    },
    computed: {
        token() {
            return getCookie('_unite_session_jwt')
        },
        members() {
            return Members.query().get()
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentChannelId() {
            return this.channel?.id > 0 ? this.channel.id : null
        },
        isCommunityAvailable() {
            return true
            // return this.channel?.can_create_post || this.channel?.display_empty_blog || this.channel?.posts?.count > 0
            // return this.organization?.subscription_features?.can_manage_blog
        },
        canCreatePost() {
            if(!this.currentUser?.subscriptionAbility?.can_manage_blog ||
                !this.currentUser?.credentialsAbility?.can_manage_blog_post) return false

            if (this.currentOrganization?.id !== this.organization?.id) return false
            return this.currentUser?.id === this.bannerInfo?.organization?.user?.id || this.currentUser?.subscriptionAbility?.can_manage_blog && this.currentUser?.credentialsAbility?.can_manage_blog_post
        },
        documents() {
            return Document.query()
                .where('channel_id', this.channel.id)
                .where('hidden', false)
                .orderBy('id', 'desc').get()
        },
        documentsPagination() {
            return Pagination.find(this.documentsPaginationId)
        },
        haveActiveSubscriptions() {
            return this.channel?.subscription?.plans?.find(plan => plan.active)
        }
    },
    mounted() {
        window.reLoadDocuments = this.reLoadDocuments
        // init documents pagination
        Pagination.insert({data: {id: this.documentsPaginationId}})
        this.$eventHub.$on('channel-review', (val) => {
            this.reviews = val
        })
        this.$eventHub.$on('priority', (val) => {
            this.priority = val
            if (val === 3) {
                this.fetchData()
            }
        })
        document.querySelector("body").classList.remove("overflow-hidden")
        this.priority = 0
        if (this.$route.params.slug) {
            let slug = this.$route.fullPath.replace("/channels", "")
            this.fetchData(slug, true)
        } else {
            this.fetchData(this.$route.params.id)
        }
        this.$eventHub.$on('ChannelPage:openSubscriptionsPlanModal', () => {
            this.$refs.subsPlans.open()
        })

        this.$eventHub.$on("SubscriptionsPlanModal:subscribed", () => {
            this.reLoadDocuments(this.lastOpenedDocument)
        })

        this.$eventHub.$on('open-doc-afterlogin', (id) => {
            this.lastOpenedDocument = id
            this.reLoadDocuments(id)
        })
    },
    beforeDestroy() {
        this.$eventHub.$emit('channel-page-channel-retrieved', {channelId: null})
    },
    destroyed() {
        this.$eventHub.$off('priority')
    },
    methods: {
        getCurrentOrganization() {
            return new Promise((resolve) => {
                Channel.api().getPublicOrganization({id: this.channel.organization_id}).then((res) => {
                    this.organization = res.response.data.response.organization
                    this.$store.dispatch("Users/setPageOrganization", this.organization)
                    resolve()
                })
            })
        },
        getChannels() {
            return new Promise((resolve) => {
                Channel.api().getChannels({organization_id: this.channel.organization_id}).then((res) => {
                    this.channels = res.response.data.response.channels
                    this.channels.forEach(ch => {
                        if (ch.subscription?.plans) {
                            let sorted = ch.subscription.plans.sort((a, b) => {
                                return a.amount - b.amount
                            })
                            this.channelsPlans.push({
                                id: ch.id,
                                plans: sorted
                            })
                            ch.plans = sorted
                        }
                    })
                    resolve()
                })
            })
        },
        getMembers() {
            return new Promise((resolve) => {
                Members.deleteAll()
                Members.api().getPublicChannelMembers({id: this.channel.id}).then(() => {
                    resolve()
                })
            })
        },
        getCreatorInfo() {
            return new Promise((resolve) => {
                Channel.api().getCreatorInfo({id: this.organizer.id}).then((res) => {
                    this.owner = res.response.data.response
                    resolve()
                })
            })
        },
        getPublicChannel(param) {
            return new Promise((resolve) => {
                Channel.api().getPublicChannel(param).then((res) => {
                    this.channel = res.response.data.response.channel
                    this.$eventHub.$emit('channel-page-channel-retrieved', {channelId: this.channel.id})
                    this.organizer = res.response.data.response.organizer
                    this.subscription = this.channel.subscription
                    if (this.subscription) {
                        this.subscription.plans = this.channel.subscription?.plans.sort((a, b) => {
                            return a.amount - b.amount
                        })
                    }
                    this.loadDocuments()
                    resolve()
                })
            })
        },
        getSelfSubscription() {
            return new Promise((resolve) => {
                if (this.currentUser) {
                    SelfSubscription.api().getSubscriptions().then(() => {
                        resolve()
                    })
                } else {
                    resolve()
                }
            })
        },
        getSelfFreeSubscription() {
            return new Promise((resolve) => {
                if (this.currentUser) {
                    SelfFreeSubscription.api().getSubscriptions().then(() => {
                        resolve()
                    })
                } else {
                    resolve()
                }
            })
        },
        fetchData(slug, isSlug = false) {
            let param = {}
            if (isSlug) param['slug'] = slug
            else param['id'] = slug
            if (this.priority === 0) {
                this.getPublicChannel(param).then(() => {
                    this.getCurrentOrganization().then(() => {
                        this.getChannels().then(() => {
                            this.getMembers().then(() => {
                                this.getSelfSubscription().then(() => {
                                    this.getSelfFreeSubscription().then(() => {
                                        this.$eventHub.$emit('check-priority', 5)
                                    })
                                })
                            })
                        })
                    })
                })
            }
            if (this.priority === 3) {
                this.getCreatorInfo().then(() => {
                    this.$eventHub.$emit('check-priority', 2)
                })
            }
        },
        getPostsCount(count) {
            this.postsCount = count
        },
        async loadDocuments(){
            Pagination.update({id: this.documentsPaginationId, loading: true})
            let request = await Document.api().fetch({
                channel_id: this.channel.id,
                hidden: false,
                ...this.documentsPagination.nextPageParams,
                limit: 4
            })
            Pagination.update({id: this.documentsPaginationId, ...request.response.data.pagination, loading: false})
        },
        async reLoadDocuments(id = null){
            // Pagination.update({id: this.documentsPaginationId, loading: true})
            let request = await Document.api().fetch({
                channel_id: this.channel.id,
                hidden: false,
                offset: 0,
                limit: this.documents.length
            })
            if(id != null) {
                this.$eventHub.$emit('open-doc', id)
            }
            // Pagination.update({id: this.documentsPaginationId, loading: false})
        }
    }
}
</script>

<style lang="scss">
.mChannel__documents{
    background-color: #E6EFF1;
}
</style>