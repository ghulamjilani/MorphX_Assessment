<template>
    <m-modal
        ref="aboutBusinessModal"
        class="ownerModal">
        <template #header>
            <OwnerHeaderTemplate
                :count="followersCount"
                :organization="organization"
                :owner_id="owner.id"
                :token="token" />
        </template>
        <transition
            mode="out-in"
            name="slide">
            <FollowSection
                v-if="followersExists"
                :company-followers="organizationFollowers"
                :count="followersCount"
                :integer="integer"
                :organization_id="organization.id"
                :owner="owner"
                :token="token" />
            <div
                v-else-if="organization.description || organization.website_url || (organization.social_links && organization.social_links.length)"
                class="ownerModal__body">
                <div class="ownerModal__title ownerModal__title__border">
                    <div class="ownerModal__label">
                        About
                    </div>
                    <div class="ownerModal__social__wrapper">
                        <a
                            v-if="organization && organization.website_url"
                            :href="organization.website_url"
                            class="ownerModal__social"
                            target="_blank">
                            <m-icon size="1.6rem">GlobalIcon-website</m-icon>
                        </a>
                        <a
                            v-for="social in organization.social_links"
                            :key="social.id"
                            :href="social.url"
                            class="ownerModal__social"
                            target="_blank">
                            <m-icon size="1.6rem">GlobalIcon-{{ social.provider }}</m-icon>
                        </a>
                    </div>
                </div>
                <div
                    class="ownerModal__description"
                    v-html="description" />
                <div class="ownerModal__title">
                    <button
                        v-if="organization.description && organization.description.length > cropReadMore"
                        class="btn__reset ownerModal__readMore"
                        @click="toggleReadMore">
                        {{ readMore ? ' Read less' : ' Read more' }}
                    </button>
                </div>
            </div>
        </transition>
        <template #black_footer>
            <ChannelsFooterTemplate
                :channels="channels"
                class="ownerModal__footer"
                @close="close()" />
        </template>
    </m-modal>
</template>

<script>
import ChannelsFooterTemplate from './template/ChannelsFooterTemplate'
import OwnerHeaderTemplate from './template/OwnerHeaderTemplate'
import FollowSection from './template/FollowSection'
import SelfFollows from "@models/SelfFollows"
import CompanyFollowers from "@models/CompanyFollowers"

export default {
    components: {ChannelsFooterTemplate, OwnerHeaderTemplate, FollowSection},
    props: {
        organization: {
            type: Object
        },
        channels: {
            type: Array
        },
        token: {},
        owner: {}
    },
    data() {
        return {
            followerOn: false,
            cropReadMore: 500,
            readMore: false,
            integer: 0
        }
    },
    computed: {
        description() {
            if (this.organization.description?.length <= this.cropReadMore) this.readMore = true
            return this.readMore ? this.organization.description : this.organization.description?.slice(0, this.cropReadMore) + "..."
        },
        organizationFollowers() {
            return CompanyFollowers.query().get()
        },
        followersCount() {
            if (CompanyFollowers.query().get().length) {
                return CompanyFollowers.query().first().count
            } else {
                return 0
            }
        },
        followersExists() {
            this.followerOn
            if (this.organizationFollowers.length && this.followerOn) {
                return true
            } else {
                this.followerOn = false
                return false
            }
        }
    },
    watch: {
        organization(val) {
            if (val) {
                CompanyFollowers.api().getFollowers({
                    followable_type: "Organization",
                    followable_id: this.organization.id,
                    type: "Organization",
                    limit: 50
                })
            }
        }
    },
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        }),
            this.$eventHub.$on("open-follow-company", () => {
                this.followerOn = true
            }),
            this.$eventHub.$on("close-follow-company", () => {
                this.followerOn = false
            })
    },
    methods: {
        open() {
            this.$refs.aboutBusinessModal.openModal()
            if (this.token) {
                SelfFollows.api().getFollows({followable_type: "Organization"})
            }
        },
        close() {
            if (this.$refs.aboutBusinessModal) this.$refs.aboutBusinessModal.closeModal()
        },
        toggleReadMore() {
            this.readMore = !this.readMore
        }
    }
}
</script>