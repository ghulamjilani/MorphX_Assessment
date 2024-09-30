<template>
    <m-modal
        ref="shareModal"
        :class="className">
        <div class="unobtrusive-flash-container" />
        <template #header>
            <div
                v-show="model"
                class="shareModalMK2__header">
                <div class="shareModalMK2__share">
                    <h3 class="shareModalMK2__share__title">
                        {{ $t('frontend.app.components.modals.share_modal.share') }}
                    </h3>
                    <div class="shareModalMK2__share__social">
                        <a
                            v-for="social in socials"
                            :key="social.id"
                            :href="social.url"
                            class="shareModalMK2__share__social__icon"
                            target="_blank">
                            <m-icon size="1.6rem">GlobalIcon-{{ social.provider }}</m-icon>
                        </a>
                        <a
                            class="shareModalMK2__share__social__icon"
                            @click="openEmailModal">
                            <m-icon size="16px">GlobalIcon-message</m-icon>
                        </a>
                        <share-email-modal
                            ref="shareEmailModal"
                            :model_id="model.id"
                            :model_type="type" />
                    </div>
                    <div>
                        <span class="fs__13">{{ $t('frontend.app.components.modals.share_modal.full_permalink') }}</span>
                        <div class="shareModalMK2__share__link">
                            <span>{{ relativeLink() }}</span>
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(relativeLink())">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                    </div>
                    <div v-if="shortLink">
                        <span class="fs__13">{{ $t('frontend.app.components.modals.share_modal.short_permalink') }}</span>
                        <div class="shareModalMK2__share__link">
                            <span>{{ shortLink }}</span>
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(shortLink)">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                    </div>
                    <div v-if="referralLink">
                        <span class="fs__13">{{ $t('frontend.app.components.modals.share_modal.referral_permalink') }}</span>
                        <div class="shareModalMK2__share__link">
                            <span>{{ referralLink }}</span>
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(referralLink)">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                    </div>
                    <div
                        v-for="interactiveAccessToken in interactiveAccessTokens"
                        :key="interactiveAccessToken.interactive_access_token.id">
                        <span class="fs__13">{{ interactiveAccessToken.interactive_access_token.title }}</span>
                        <div class="shareModalMK2__share__link">
                            <span>{{ interactiveAccessToken.interactive_access_token.absolute_url }}</span>
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(interactiveAccessToken.interactive_access_token.absolute_url)">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                    </div>
                    <div
                        v-if="type !== 'Channel'"
                        class="shareModalMK2__share__embed">
                        {{ $t('frontend.app.components.modals.share_modal.embed') }}
                        <!-- <m-checkbox v-model="embed"/> -->
                        <m-toggle v-model="embed" />
                    </div>
                </div>
                <div
                    v-if="embed"
                    class="shareModalMK2__embed">
                    <div class="shareModalMK2__embed__options">
                        <div class="shareModalMK2__embed__options__title">
                            EMBED OPTIONS
                        </div>
                        <m-checkbox
                            v-model="options"
                            :disabled="!optionRules('live')"
                            val="live"
                            @click="updateOptions('live')">
                            Show live
                        </m-checkbox>
                        <m-checkbox
                            v-model="options"
                            :disabled="!optionRules('chat')"
                            val="chat">
                            Show chat
                        </m-checkbox>
                        <m-checkbox
                            v-model="options"
                            :disabled="!optionRules('product')"
                            val="product">
                            Show product list
                        </m-checkbox>
                        <m-checkbox
                            v-model="options"
                            :disabled="!optionRules('external_playlist')"
                            val="external_playlist">
                            Show playlist
                        </m-checkbox>
                        <m-checkbox
                            v-model="options"
                            :disabled="!optionRules('single_item')"
                            val="single_item"
                            @click="updateOptions('single_item')">
                            Show single item
                        </m-checkbox>
                    </div>
                    <div class="shareModalMK2__embed__code">
                        <div class="shareModalMK2__embed__options__title">
                            CODE
                        </div>
                        <div class="shareModalMK2__embed__code__iframe">
                            <textarea
                                id=""
                                v-model="embedText"
                                class="shareModalMK2__embed__code__textarea"
                                name=""
                                rows="6" />
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(embedText)">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                        <div
                            v-if="showEmbedV2"
                            class="shareModalMK2__embed__options__title">
                            SINGLE FRAME CODE
                        </div>
                        <div
                            v-if="showEmbedV2"
                            class="shareModalMK2__embed__code__iframe">
                            <textarea
                                id=""
                                v-model="embedText2"
                                class="shareModalMK2__embed__code__textarea"
                                name=""
                                rows="6" />
                            <m-btn
                                size="s"
                                type="bordered"
                                @click="copy(embedText2)">
                                {{ $t('frontend.app.components.modals.share_modal.copy') }}
                            </m-btn>
                        </div>
                    </div>
                </div>
            </div>
        </template>
        <div
            v-if="embed"
            id="embedBlock"
            class="shareModal__embedBlock" />
    </m-modal>
</template>

<script>
import Share from "@models/Share"
import Session from "@models/Session"
import {getCookie} from "../../utils/cookies"
import ShareEmailModal from "./ShareEmailModal"

export default {
    components: {ShareEmailModal},
    data() {
        return {
            model: null,
            type: "",
            socials: [
                {id: 1, url: '', provider: 'facebook'},
                {id: 2, url: '', provider: 'twitter'},
                {id: 3, url: '', provider: 'linkedin'},
                {id: 4, url: '', provider: 'tumblr'},
                {id: 5, url: '', provider: 'pinterest'},
                {id: 6, url: '', provider: 'reddit'}
            ],
            options: ['live', 'chat', 'product', 'external_playlist'],
            embed: false,
            embedText: "",
            embedText2: "",
            showEmbedV2: false,
            shortLink: "",
            referralLink: "",
            interactiveAccessTokens: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        className() {
            if (this.embed) return "shareModalMK2"
            else return "shareModalMK2 shareModalMK2Small"
        },
        token() {
            return getCookie('_unite_session_jwt')
        }
    },
    watch: {
        model(val) {
            if (val) {
                this.getInteractiveToken()
            }
        },
        options(val) {
            this.generateShare()
            this.generateShare2()
        },
        embed(val) {
            setTimeout(() => {
                this.generateShare()
                this.generateShare2()
            }, 500)
        }
    },
    mounted() {
        // this.embedText = "lorem".repeat(200);
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })

        this.$eventHub.$on("open-modal:share", ({model, type}) => {
            this.type = type
            this.model = model
            if (type !== "Channel") {
                if (model.video) this.model = model.video
                else if (model.session) this.model = model.session
                else if (model.recording) this.model = model.recording
                this.getInteractiveToken()
                this.generateShare()
                this.generateShare2()
            }

            switch (type) {
                case 'Session':
                    this.options = ['live', 'chat', 'product', 'external_playlist']
                    break
                case 'Recording':
                    this.options = ['product']
                    break
                case 'Video':
                    this.options = ['product', 'external_playlist']
                    break
                default:
                    this.options = []
                    break
            }
            this.embedText = ""
            this.embed = false
            this.open()
            Share.api().fetch({
                model_type: this.type,
                model_id: this.model.id
            }).then(res => {
                this.shortLink = res.response.data.response.model.short_permalink
                this.referralLink = res.response.data.response.model.referral_permalink
                this.socials.forEach(e => {
                    e.url = res.response.data.response.model[e.provider + "_url"]
                })
            })
        })
    },
    methods: {
        getInteractiveToken() {
            this.interactiveAccessTokens = null
            if (this.currentUser && this.model?.status != "done" && this.model?.service_type == 'webrtcservice') {
                Session.api().getInteractiveToken({session_id: this.model.id}).then((res) => {
                    if (res.response.data.response.interactive_access_tokens.length) {
                        this.interactiveAccessTokens = res.response.data.response.interactive_access_tokens
                    }
                })
            }
        },
        openEmailModal() {
            if (this.currentUser) {
                this.$refs.shareEmailModal.open()
            } else {
                this.$flash("You need to login")
                this.$eventHub.$emit("open-modal:auth", "login")
            }
        },
        relativeLink() {
            return location.origin + this.model.relative_path
        },
        directLink() {
            if (this.type == 'Session') {
                return location.origin + this.model.join_interactive_url
            }
        },
        open() {
            this.$refs.shareModal.openModal()
        },
        close() {
            if (this.$refs.shareModal) this.$refs.shareModal.closeModal()
        },
        copy(value) {
            this.$clipboard(value)
            this.$flash("Сopied!", "success")
        },
        findOpt(opt) {
            return this.options.find(e => e === opt)
        },
        optionRules(opt) {
            let flag = true
            switch (opt) {
                case 'chat':
                    flag = this.findOpt('live')
                    if (flag) flag = this.type !== "Recording"
                    break
                case 'live':
                    flag = !this.findOpt('single_item') || this.type == 'Session'
                    if (flag) flag = this.type !== "Recording"
                    break
                case 'external_playlist':
                    flag = !this.findOpt('single_item')
                    if (flag) flag = this.type !== "Recording"
                    break
                case 'single_item':
                    flag = this.type !== "Recording"
                    break
            }
            return !!flag
        },
        updateOptions(type) {
            let blackList = ['chat', 'external_playlist']
            if(this.type != 'Session') blackList.push('live')

            if (type == 'single_item') {
                this.options = this.options.filter(e => !blackList.find(b => b === e))
            }
            if (type == 'live') {
                this.options = this.options.filter(e => e !== 'chat')
            }
        },
        generateShare2() {
            if (!this.model) return
            let id = this.model.id
            let type = this.type.toLowerCase()

            // small video with right blocks and without products
            let styles = `
                    display: block !important;
                    position: relative !important;
                    padding-top: calc(49.25% + 102px) !important;
                `
            this.showEmbedV2 = false

            // current !!!
            // big video without right blocks and products
            if (!["chat", "single_item", "external_playlist", "product"].some(e => this.options.includes(e))) {
                // height = "780px"
                styles = `
                        display: block !important;
                        position: relative !important;
                        padding-top: calc(56.25% + 102px) !important;
                    `
                this.showEmbedV2 = true
            }
            // small video with right blocks and with products
            if (this.options.includes("product") && ["chat", "single_item", "external_playlist"].some(e => this.options.includes(e))) {
                // height = "1220px"
                styles = `
                        display: block !important;
                        position: relative !important;
                        padding-top: calc(56.25% + 102px) !important;
                    `
            }
            // big video without right blocks and with products
            if (this.options.includes("product") && !["chat", "single_item", "external_playlist"].some(e => this.options.includes(e))) {
                // height = "1550px"
            }

            this.embedText2 = `
                <script>setTimeout(() => {if(document.querySelector("#morphx__embed iframe").name == '') { document.querySelector("#morphx__embed").innerHTML = "<b>Showing this video is not available on this domain<\/b><br\/>" +document.querySelector("#morphx__embed").innerHTML}}, 2000)<\/script>
                <div class="morphx__embed" id="morphx__embed" style="${styles}">
                <iframe class="morphx__embed__iframe"
                    style="display: block !important;width: 100% !important;height: 100% !important;position: absolute  !important;left: 0 !important;top: 0 !important;" allow="encrypted-media" allowfullscreen=""
                    frameborder="0" name="" src="${location.origin}/widgets/${id}/${type}/embedv2?options=${this.options.join(',')}"></iframe>
                </div>
                `
        },
        generateShare() {
            let find = (opt) => {
                return this.options.find(e => e === opt)
            }
            if (!this.model) return
            let id = this.model.id
            let type = this.type.toLowerCase()

            let videoPartParams = `${this.options.length > 0 ? '?' : ''}${find('external_playlist') ? 'external_playlist=true&' : ''}${find('live') ? 'live=true&' : ''}${find('single_item') ? 'single_item=true' : ''}`
            let videoPart = `<iframe allow="encrypted-media" allowfullscreen="" data-role="vplayer"
            frameborder="0" name="" src="${location.origin}/widgets/${id}/${type}/player${videoPartParams}" data-name="${type}${id}"></iframe>`

            let additionalPartParams = `${this.options.length > 0 ? '?' : ''}${find('external_playlist') ? 'external_playlist=true&' : ''}${find('chat') ? 'chat=true&' : ''}${find('single_item') ? 'single_item=true' : ''}`
            let additionalPart = `<div class="mio_embed unite_embed_additionsIframeWrapp">
        <iframe data-role="additions" id="unite_embed_additions" name="" src="${location.origin}/widgets/${id}/${type}/additions${additionalPartParams}" data-name="${type}${id}"></iframe>
      </div>`

            let productPart = `<div class="mio_embed unite_embed_shopIframeWrapp"><iframe allowfullscreen="" data-role="shop" frameborder="0"
      id="unite_embed_shop" name="" src="${location.origin}/widgets/${id}/${type}/shop" data-name="${type}${id}"></iframe></div>`

            this.embedText = `<div ${find('product') ? 'class="full mio_embed"' : 'class="mio_embed"'} id="unite_embed" style="display: block">
        <div class="mio_embed unite_embed_videoIframeWrapp active" id="unite_embed_videoWrapp">
          <div class="mio_embed" id="unite_embed_video" style="display: block;">${videoPart}</div>
          <link rel="stylesheet" media="screen" href="${this.$railsConfig.global.asset_host}/assets/widgets/template_V${find('product') ? '_P' : ''}${(find('external_playlist') || find('chat') || find('single_item')) ? '_L' : ''}.css">
        </div>
        ${(find('external_playlist') || find('chat') || find('single_item')) ? additionalPart : ''}
        ${find('product') ? productPart : ''}
      </div>
      <script src="${this.$railsConfig?.global?.asset_host}/assets/embeds/channel.js" defer><\/script>
      <script>setTimeout(() => {if(document.querySelector("#unite_embed_video iframe").name == '') { document.querySelector("#unite_embed_video").innerHTML = "<b>Showing this video is not available on this domain<\/b><br\/>" +document.querySelector("#unite_embed_video").innerHTML}}, 2000) <\/script>`
            if (document.getElementById("embedBlock"))
                document.getElementById("embedBlock").innerHTML = this.embedText
        }
    }
}
</script>