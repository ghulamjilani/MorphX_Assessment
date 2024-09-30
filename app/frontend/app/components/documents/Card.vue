<template>
    <div class="DocumentsCard">
        <div class="DocumentsCard__topWrap">
            <svg viewBox="0 0 48 64">
                <path d="M14 28C13.4696 28 12.9609 28.2107 12.5858 28.5858C12.2107 28.9609 12 29.4696 12 30C12 30.5304 12.2107 31.0391 12.5858 31.4142C12.9609 31.7893 13.4696 32 14 32H34C34.5304 32 35.0391 31.7893 35.4142 31.4142C35.7893 31.0391 36 30.5304 36 30C36 29.4696 35.7893 28.9609 35.4142 28.5858C35.0391 28.2107 34.5304 28 34 28H14ZM12 38C12 37.4696 12.2107 36.9609 12.5858 36.5858C12.9609 36.2107 13.4696 36 14 36H34C34.5304 36 35.0391 36.2107 35.4142 36.5858C35.7893 36.9609 36 37.4696 36 38C36 38.5304 35.7893 39.0391 35.4142 39.4142C35.0391 39.7893 34.5304 40 34 40H14C13.4696 40 12.9609 39.7893 12.5858 39.4142C12.2107 39.0391 12 38.5304 12 38ZM12 46C12 45.4696 12.2107 44.9609 12.5858 44.5858C12.9609 44.2107 13.4696 44 14 44H22C22.5304 44 23.0391 44.2107 23.4142 44.5858C23.7893 44.9609 24 45.4696 24 46C24 46.5304 23.7893 47.0391 23.4142 47.4142C23.0391 47.7893 22.5304 48 22 48H14C13.4696 48 12.9609 47.7893 12.5858 47.4142C12.2107 47.0391 12 46.5304 12 46Z"/>
                <path d="M30 0H8C5.87827 0 3.84344 0.842855 2.34315 2.34315C0.842854 3.84344 0 5.87827 0 8V56C0 58.1217 0.842854 60.1566 2.34315 61.6569C3.84344 63.1571 5.87827 64 8 64H40C42.1217 64 44.1566 63.1571 45.6569 61.6569C47.1571 60.1566 48 58.1217 48 56V18L30 0ZM30 4V12C30 13.5913 30.6321 15.1174 31.7574 16.2426C32.8826 17.3679 34.4087 18 36 18H44V56C44 57.0609 43.5786 58.0783 42.8284 58.8284C42.0783 59.5786 41.0609 60 40 60H8C6.93913 60 5.92172 59.5786 5.17157 58.8284C4.42143 58.0783 4 57.0609 4 56V8C4 6.93913 4.42143 5.92172 5.17157 5.17157C5.92172 4.42143 6.93913 4 8 4H30Z"/>
            </svg>
            <document-thumbnail
                :document="document"
                @openDocumentPreviewModal="openDocumentPreviewModal" />
            <div
                :class="[`DocumentsCard__topWrap__${mode}`, {'mobile' : mobile}]"
                @click="openDocumentPreviewModal">
                <m-btn
                    v-if="mode === 'consumer' || mode === 'feed'"
                    type="tetriary">
                    {{ $t('frontend.app.components.documents.card.open_document') }}
                </m-btn>
            </div>
            <div
                v-if="mode !== 'dashboard'"
                class="labels">
                <!-- v-if="(!isFree && !isPPV && !isForMember) ||
                    (!isFree && isPPV && !isForMember) ||
                    (!isFree && isForMember && selfSubscriptions)" -->
                <!-- <div
                    class="label transparent"> -->
                <!-- <m-chips
                        v-tooltip="'$' + ((+document.purchase_price * 100)/100).toFixed(2)"
                        :buy="priceInCents" /> -->
                <div
                    v-if="isFree && !membershipFrom"
                    class="label">
                    <span>{{ $t('frontend.app.components.documents.card.free') }}</span>
                </div>
                <m-chips
                    v-else
                    :just-slot="true">
                    <div
                        v-if="(!isFree && !isPPV && !isForMember) ||
                            (!isFree && isPPV && !isForMember) ||
                            (!isFree && isForMember && selfSubscriptions)"
                        class="chips__dollar">
                        $
                    </div>
                    <div
                        v-if="membershipFrom && !(!isFree && isForMember && selfSubscriptions)"
                        class="chips__label chips__label__margin0 memberLevel">
                        Member
                    </div>
                    <div
                        class="sessionCost-tooltip fs-12"
                        :class="{'sessionCost-tooltip__long': subscribeFrom && membershipFrom}">
                        <div class="chips__dollar__price">
                            <div
                                v-if="!isFree"
                                class="chips__dollar__price__row">
                                {{ $t('frontend.app.components.card_templates.session_top.buy') }}: <span>${{ ((+document.purchase_price * 100)/100).toFixed(2) }}</span>
                            </div>
                            <div
                                v-if="membershipFrom"
                                class="chips__dollar__price__row">
                                Membership from: <span>{{ subscribeFrom }}</span>
                            </div>
                        </div>
                    </div>
                </m-chips>
                <!-- </div> -->

                <!-- <div
                    v-if="membershipFrom && !(!isFree && isForMember && selfSubscriptions)"
                    class="label member">
                    <span>{{ $t('frontend.app.components.documents.card.member') }}</span>
                </div> -->
            </div>
        </div>
        <div class="DocumentsCard__bottomWrap">
            <div
                v-tooltip="document.filename"
                class="DocumentsCard__bottomWrap__title"
                @click="openDocumentPreviewModal">
                {{ document.filename }}
            </div>
            <div
                class="DocumentsCard__bottomWrap__description">
                {{ document.description }}
            </div>
            <div v-if="mode === 'feed'">
                <div class="orgSection">
                    <a
                        :href="defaultChannelPath"
                        class="orgSection__img"
                        :style="`background-image: url(${document.organization.logo_url})`" />
                    <div class="orgSection__text">
                        <p
                            v-if="document.presenter"
                            @click="openUserModal()">
                            {{ $t('session_tile.by') }} {{ document.presenter.public_display_name }}
                        </p>
                        <a
                            :href="defaultChannelPath">
                            {{ document.organization.name }}
                        </a>
                    </div>
                </div>
            </div>
            <div class="DocumentsCard__bottomWrap__published">
                {{ $t('frontend.app.components.documents.card.published') }}: {{ document.formattedCreatedAt }}
            </div>
            <div class="DocumentsCard__bottomWrap__size">
                <div>{{ $t('frontend.app.components.documents.card.size') }}</div>
                <span>{{ size }}</span>
            </div>
            <div class="DocumentsCard__bottomWrap__date">
                <div>{{ $t('frontend.app.components.documents.card.date') }}</div>
                <span>{{ document.formattedDate }}</span>
            </div>
            <div
                v-if="mode === 'dashboard'"
                class="DocumentsCard__bottomWrap__icons">
                <i
                    :class="'GlobalIcon-eye' + (document.hidden ? '-off' : '')"
                    @click="toggleHide" />
                <!-- <i class="GlobalIcon-link" /> -->
                <i
                    class="GlobalIcon-settings"
                    @click="openSettingsModal" />
                <documents-options-dropdown
                    v-if="canManageDocuments"
                    :document="document" />
            </div>
            <documents-preview-modal
                v-if="showPreview"
                :document="document"
                @modalClosed="showPreview = false" />
        </div>
    </div>
</template>

<script>
import Document from "@models/Document"
import DocumentThumbnail from "./Thumbnail"
import DocumentsPreviewModal from "./PreviewModal"
import DocumentsOptionsDropdown from "./OptionsDropdown"
import {mapActions} from 'vuex'
import SelfSubscription from "@models/SelfSubscription"
import SelfFreeSubscription from "@models/SelfFreeSubscription"

export default {
    name: 'DocumentsCard',
    components: {DocumentsOptionsDropdown, DocumentsPreviewModal, DocumentThumbnail },
    props: {
        mode: {
            type: String,
            default: 'consumer',
            validator: (value) => {
                return ['consumer', 'dashboard', "feed"].indexOf(value) !== -1
            }
        },
        document: {
            type: Object,
            default: () => {}
        },
        channel: {
            type: Object,
            default: () => {}
        },
        canManageDocuments: {
            type: Boolean,
            default: false
        },
        isunite: {
            type: Boolean,
            default: false
        }
    },
    data(){
        return {
            showPreview: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        mobile() {
            return this.$device.tablet() || this.$device.mobile()
        },
        size() {
            let fileSize = this.document.file_size / 1024
            let mb = 1024
            if( fileSize > mb ) {
                return Math.round(fileSize / 1024 * 100) / 100 + " MB"
            }
            else {
                return Math.round(fileSize * 100) / 100  + " kb"
            }
        },
        isForMember() {
            return this.document.only_subscription
        },
        isPPV() {
            return this.document.only_ppv
        },
        priceInCents() {
            return +this.document.purchase_price * 100
        },
        isFree() {
            return this.priceInCents === 0
        },
        membershipFrom() {
            return (this.isFree && !this.isPPV && this.isForMember) ||
                (!this.isFree && !this.isPPV && this.isForMember) ||
                (!this.isFree && this.isPPV && this.isForMember) || this.isForMember
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
        defaultChannelPath(){
            return location.origin + this.document?.channel?.relative_path
        },
        subscribeFrom() {
            if(this.channel?.subscription?.plans?.length > 0) {
                let minPrice = 10000000
                let str = ""
                this.channel.subscription.plans.forEach(e => {
                    if (minPrice > +e.amount) {
                        minPrice = +e.amount
                        str = e.formatted_price
                    }
                })
                return str
            }
            return null
        }
    },
    mounted() {
        this.$eventHub.$on('open-doc', (id) => {
            if(this.document.id == id) {
                this.openDocumentPreviewModal()
            }
        })
    },
    methods: {
        ...mapActions('Users', ['authenticate']),
        openDocumentPreviewModal() {
            this.authenticate({data: this.document.id, action: () => {
                if (this.document.downloadUrl){
                    this.showPreview = true
                }
                else if (!this.channel.can_purchase_content) {
                    this.$flash(this.$t('frontend.app.components.documents.card.purchases_temporarily_unavailable'))
                }

                else if(this.membershipFrom && !this.selfSubscriptions) {
                    this.$eventHub.$emit('open-modal:subscriptionPlans', this.channel.subscription, this.channel)
                }
                else if((!this.isFree && !this.isPPV && !this.isForMember) ||
                        (!this.isFree && this.isPPV && !this.isForMember) ||
                        (!this.isFree && this.isForMember && this.selfSubscriptions)) {
                    this.$eventHub.$emit('open-modal:documentPayment', this.document)
                }
                else {
                    console.log('document: no download url')
                }
            }})
        },
        openSettingsModal() {
            this.$eventHub.$emit('open-modal', {
                title: 'Document info',
                component: {
                    name: 'DocumentsSettings',
                    params: {document_id: this.document.id}
                }
            })
        },
        toggleHide() {
            const params = {id: this.document.id, hidden: !this.document.hidden}
            Document.api().update(params)
        },
        openUserModal() {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: this.document.presenter
            })
        }
    }
}
</script>