<template>
    <div class="componentSettings">
        <m-modal ref="settingsModal">
            <template #header>
                <h3> {{ $t('frontend.app.uikit.components_manager.component_settings_modal.title') }} </h3>
            </template>

            <m-form
                v-if="settings">
                <m-select
                    v-model="settings.type"
                    :options="optionsType"
                    label="Choose Type"
                    :without-error="true" />
                <!-- <m-checkbox
                    v-if="settings.props.useStandartTitle !== undefined"
                    v-model="settings.props.useStandartTitle">
                    Use standart Title
                </m-checkbox> -->
                <m-input
                    v-if="settings.props.title !== undefined"
                    v-model="settings.props.title"
                    field-id="title"
                    label="Title"
                    :errors="false" />
                <m-input
                    v-if="settings.props.areaId !== undefined"
                    v-model="settings.props.areaId"
                    field-id="areaId"
                    label="Area Id"
                    :errors="false" />
                <m-input
                    v-if="settings.props.accountId !== undefined"
                    v-model="settings.props.accountId"
                    field-id="accountId"
                    label="Account Id"
                    :errors="false" />
                <m-select
                    v-model="settings.props.showFor"
                    :options="optionsShowFor"
                    label="Show For"
                    :without-error="true" />
                <m-select
                    v-if="settings.props.orderBy !== undefined"
                    v-model="settings.props.orderBy"
                    :options="optionsOrderByByType"
                    label="Choose OrderBy"
                    :without-error="true" />
                <m-select
                    v-if="settings.props.order !== undefined"
                    v-model="settings.props.order"
                    :options="optionsOrder"
                    label="Choose Order"
                    :without-error="true" />
                <m-checkbox
                    v-if="settings.props.isScrollable !== undefined"
                    v-model="settings.props.isScrollable"
                    class="">
                    {{ $t('frontend.app.uikit.components_manager.component_settings_modal.is_scrollable') }}
                </m-checkbox>
                <div
                    v-if="(settings.props.isScrollable === undefined && settings.props.itemsCount !== undefined) ||
                        (settings.props.isScrollable !== undefined && settings.props.isScrollable === true)"
                    class="componentSettings__flexInput">
                    <label class="fs__16">{{ $t('frontend.app.uikit.components_manager.component_settings_modal.count') }}: </label>
                    <m-input
                        v-model="settings.props.itemsCount"
                        :pure="true"
                        type="number"
                        :errors="false" />
                </div>
                <div class="componentSettings__checkmarks">
                    <m-radio
                        v-if="(settings.props.isScrollable === undefined && settings.props.loadCount !== undefined) ||
                            (settings.props.isScrollable !== undefined && settings.props.isScrollable === false)"
                        v-model="settings.props.loadCount"
                        :val="4">
                        4 {{ $t('frontend.app.uikit.components_manager.component_settings_modal.tiles') }}
                    </m-radio>
                    <m-radio
                        v-if="(settings.props.isScrollable === undefined && settings.props.loadCount !== undefined) ||
                            (settings.props.isScrollable !== undefined && settings.props.isScrollable === false)"
                        v-model="settings.props.loadCount"
                        :val="8">
                        8 {{ $t('frontend.app.uikit.components_manager.component_settings_modal.tiles') }}
                    </m-radio>
                    <m-checkbox
                        v-if="(settings.props.isScrollable === undefined && settings.props.showMore !== undefined) ||
                            (settings.props.isScrollable !== undefined && settings.props.isScrollable === false)"
                        v-model="settings.props.showMore">
                        {{ $t('frontend.app.uikit.components_manager.component_settings_modal.show_more') }}
                    </m-checkbox>
                    <m-checkbox
                        v-if="settings.props.promoWeight !== undefined"
                        v-model="settings.props.promoWeight">
                        {{ $t('frontend.app.uikit.components_manager.component_settings_modal.use_promo_weight') }}
                    </m-checkbox>
                    <m-checkbox
                        v-if="settings.props.onlyShowOnHome !== undefined"
                        v-model="settings.props.onlyShowOnHome">
                        {{ $t('frontend.app.uikit.components_manager.component_settings_modal.show_on_homepage') }}
                    </m-checkbox>
                    <m-checkbox
                        v-if="settings.props.hideOnHome !== undefined"
                        v-model="settings.props.hideOnHome">
                        {{ $t('frontend.app.uikit.components_manager.component_settings_modal.hide_on_home') }}
                    </m-checkbox>
                </div>

                <m-input
                    v-if="settings.props.background !== undefined"
                    v-model="settings.props.background"
                    label="Background color"
                    :errors="false" />
                <div
                    v-if="settings.props.rawHtml !== undefined"
                    class="componentSettings__hint">
                    <m-icon
                        size="1.8rem"
                        @click="hint = !hint">
                        GlobalIcon-info
                    </m-icon>
                    <div v-show="hint">
                        <strong>{host}</strong> - {{ $t('frontend.app.uikit.components_manager.component_settings_modal.hints.host') }} (<i>https://{host}/terms-of-use</i>)
                    </div>
                </div>
                <vue-editor
                    v-if="settings.props.rawHtml !== undefined"
                    ref="editor"
                    v-model="settings.props.rawHtml"
                    :editor-options="editorSettings" />

                <m-input
                    v-if="settings.props.bannerLabel !== undefined"
                    v-model="settings.props.bannerLabel"
                    label="Banner Label"
                    :errors="false" />

                <textarea
                    v-if="settings.props.bannerContent !== undefined"
                    v-model="settings.props.bannerContent"
                    placeholder="Banner Content"
                    class="mTextArea" />

                <form-manager
                    v-if="settings.props.form !== undefined"
                    :form="settings.props.form"
                    :editing="true"
                    @formChanged="onFormChanged" />

                <div
                    v-if="settings.type === 'customizable-banner'"
                    class="componentSettings__buttonSettings">
                    <m-select
                        v-if="settings.props.buttonType !== undefined"
                        v-model="settings.props.buttonType"
                        :options="buttonTypes"
                        label="Button Type"
                        :without-error="true" />

                    <m-input
                        v-if="settings.props.buttonText !== undefined && settings.props.buttonType !== 'buttonless'"
                        v-model="settings.props.buttonText"
                        label="Button Text"
                        :errors="false" />

                    <m-select
                        v-if="settings.props.buttonAction !== undefined && settings.props.buttonType !== 'buttonless'"
                        v-model="settings.props.buttonAction"
                        :options="buttonActions"
                        label="Button Action"
                        :without-error="true" />
                </div>

                <m-input
                    v-if="settings.props.buttonLink !== undefined && settings.props.buttonAction === 'link' && settings.props.buttonType !== 'buttonless'"
                    v-model="settings.props.buttonLink"
                    label="Button Link"
                    :errors="false" />

                <m-tabs
                    v-if="settings.props.backgroundImage !== undefined && settings.props.backgroundVideoLink !== undefined"
                    class="componentSettings__crop">
                    <m-tab title="Image Background">
                        <p>
                            Video background has more priority than image background
                        </p>
                        <m-crop-image
                            v-model="settings.props.backgroundImage"
                            :aspect-ratio="4.25" />
                    </m-tab>
                    <m-tab title="Video Background">
                        <p>
                            Video background has more priority than image background
                        </p>
                        <m-input
                            v-model="settings.props.backgroundVideoLink"
                            class="margin-t__30 margin-b__30"
                            label="Video Link"
                            :errors="false" />
                        <div
                            class="videoBanner"
                            style="max-height: 300px">
                            <video
                                ref="video"
                                autoplay="true"
                                loop="true"
                                muted="muted"
                                playsinline
                                :src="settings.props.backgroundVideoLink"
                                type="video/mp4" />
                        </div>
                    </m-tab>
                </m-tabs>
                <m-select
                    v-if="settings.props.imageSize !== undefined"
                    v-model="settings.props.imageSize"
                    :options="optionsImageSize"
                    label="Image Size"
                    :without-error="true" />

                <template v-if="settings.props.imageSize !== undefined && settings.type!='ad-butler'">
                    <h3 v-if="settings.props.imageSize != 'custom' && settings.props.imageSize != 'full'">
                        Leave empty or override defaul settings:
                    </h3>
                    <h3 v-else>
                        Please don't forget to setup width/height:
                    </h3>
                    <p v-if="settings.props.imageSize == 'custom'"> For CUSTOM - required 'Custom Image Width' and Height or Padding-Bottom </p>
                    <p v-if="settings.props.imageSize == 'full'">For FULL - required 'Padding-Bottom' </p>
                    <m-input
                        v-model="settings.props.imageWidth"
                        field-id="imageWidth"
                        label="Custom Image Width (px/rem/%)"
                        :errors="false"/>
                    <m-input
                        v-model="settings.props.imageHeight"
                        field-id="imageHeight"
                        label="Custom Image Height (px/rem/%)"
                        :errors="false" />
                    <m-input
                        v-model="settings.props.paddingBottom"
                        field-id="paddingBottom"
                        label="Padding-Bottom settings like: 'calc(100% / 4)'"
                        :errors="false" />
                </template>

                <template v-if="settings.props.imageSize !== undefined && settings.type=='ad-butler'">
                    <h3>Ad Butler Ads Keys:</h3>
                    <m-input
                        v-for="(ad, index) in settings.props.ads"
                        :key="'ad' + index"
                        v-model="settings.props.ads[index]"
                        :field-id="'ad' + index"
                        :label="'Ad Butler Key ' + (index + 1)"
                        :errors="false"/>
                </template>
            </m-form>

            <template #footer>
                <m-btn
                    :loading="saving"
                    :disabled="saving"
                    @click="save">
                    {{ $t('frontend.app.uikit.components_manager.component_settings_modal.save') }}
                </m-btn>
            </template>
        </m-modal>
    </div>
</template>

<script>
import {VueEditor} from "vue2-editor"
import FormManager from "./Components/FormManager.vue"
import Files from "@models/Files"
import imageHelper from "@utils/images"

import Quill from 'quill'
import htmlEditButton from "quill-html-edit-button"

if(!Quill.imports["modules/htmlEditButton"]) Quill.register("modules/htmlEditButton", htmlEditButton)

export default {
  components: { VueEditor, FormManager },
  data() {
    return {
      hint: false,
      saving: false,
      settings: {
        type: null,
        props: {
          showFor: "all" // logined, guest
        }
      },
      new: false,
      group: null,
      // --- default settings
      defaultSettings: {
        type: null,
        props: {
          showFor: "all" // logined, guest
        }
      },
      // Дополнительные спецефичные настройки
      defaulByType: {
        "banner-announcement": {
          bannerLabel: "",
          bannerContent: ""
        },
        "active-session": {
          title: ""
        },
        "replays-uploads-without-scroll": {
          loadCount: 8,
          showMore: false,
          orderBy: "views_count",
          order: "desc",
          title: "",
          promoWeight: false,
          onlyShowOnHome: true,
          hideOnHome: false
        },
        "live-sessions": {
          title: "",
          order: "asc",
          promoWeight: false,
          orderBy: "start_at",
          onlyShowOnHome: true,
          itemsCount: 12,
          hideOnHome: false
        },
        "h-p-channels": {
          title: "",
          promoWeight: false,
          orderBy: "listed_at",
          order: "desc",
          onlyShowOnHome: true,
          itemsCount: 12,
          hideOnHome: false
        },
        "creators-list": {
          title: "",
          order: "desc",
          promoWeight: false,
          orderBy: "views_count",
          onlyShowOnHome: true,
          itemsCount: 12,
          hideOnHome: false
        },
        "organization-tiles": {
          title: "",
          promoWeight: false,
          onlyShowOnHome: true,
          itemsCount: 12,
          isScrollable: true,
          loadCount: 8,
          showMore: false,
          orderBy: "listed_at",
          order: "desc",
          hideOnHome: false
        },
        "articles-wrapper": {
          title: "",
          promoWeight: false,
          orderBy: "views_count",
          order: "desc",
          onlyShowOnHome: true,
          itemsCount: 12,
          hideOnHome: false
        },
        "raw-html": {
          rawHtml: "",
          background: "var(--bg__content__secondary)"
        },
        "form-manager": {
          form: null
        },
        "feed-channels-list": {
          title: ""
        },
        "booking-users": {
          title: "",
          hideOnHome: false,
          order: "asc",
          promoWeight: false,
          onlyShowOnHome: true
        },
        'customizable-banner': {
          rawHtml: "",
          buttonText: "",
          buttonType: "buttonless",
          buttonAction: "signUp",
          buttonLink: "",
          backgroundImage: "",
          backgroundVideoLink: ""
        },
        "feed-recordings": {
          loadCount: 4,
          showMore: true,
          orderBy: "listed_at",
          order: "desc",
          title: "",
          // promoWeight: false,
          // onlyShowOnHome: true,
          // hideOnHome: false
        },
        "feed-replays": {
          loadCount: 4,
          showMore: true,
          orderBy: "listed_at",
          order: "desc",
          title: "",
          // promoWeight: false,
          // onlyShowOnHome: true,
          // hideOnHome: false
        },
        "feed-documents": {
          loadCount: 4,
          showMore: true,
          orderBy: "listed_at",
          order: "desc",
          title: ""
          // promoWeight: false,
          // onlyShowOnHome: true,
          // hideOnHome: false
        },
        "feed-sessions": {
          title: "",
          order: "asc",
          promoWeight: false,
          orderBy: "start_at",
          // onlyShowOnHome: true,
          loadCount: 4
          // hideOnHome: false
        },
        "banner-advertisement": {
          title: "",
          areaId: "",
          imageSize: "full", // full | large | medium | custom
          imageWidth: "",
          imageHeight: "",
          paddingBottom: ""
        },
        "ad-butler": {
          title: "",
          accountId: "",
          imageSize: "full", // full | large | medium | custom
          ads: []
          //imageWidth: "",
          //imageHeight: "",
          //paddingBottom: ""
        }
      },
      // --- options
      optionsType: [
        {name: "Header Banner", value: "banner-wrapper"},
        {name: "Customizable Banner", value: "customizable-banner"},
        {name: "AdButler", value: "ad-butler"},
        {name: "Banner Advertisement", value: "banner-advertisement"},
        {name: "Active Session", value: "active-session"},
        {name: "Banner Announcement", value: "banner-announcement"},
        {name: "Live", value: "live-sessions"},
        {name: "Replays/Uploads", value: "replays-uploads-without-scroll"},
        {name: "Channels", value: "h-p-channels"},
        {name: "Creators", value: "creators-list"},
        {name: "Organizations List", value: "organization-tiles"},
        {name: this.$t('frontend.app.components.channel.blog.community'), value: "articles-wrapper"},
        {name: "Footer Banner", value: "footer-banner"},
        {name: "Raw Text", value: "raw-html"},
        {name: "Form Manager", value: "form-manager"},
        {name: "My Library - Channels List", value: "feed-channels-list"},
        {name: "My Library - Sessions List", value: "feed-sessions"},
        {name: "My Library - Uploads List", value: "feed-recordings"},
        {name: "My Library - Replays List", value: "feed-replays"},
        {name: "My Library - Documents List", value: "feed-documents"},
        // {name: "Booking Users", value: "booking-users"}
      ],
      optionsOrderBy: [
        {name: "Views Count", value: "views_count",
          for: ["creators-list", "replays-uploads-without-scroll", "articles-wrapper", "organization-tiles",
          "feed-recordings", "feed-replays", "feed-documents"]},
        {name: "Created At", value: "model_created_at",
          for: ["h-p-channels", "creators-list", "articles-wrapper", "organization-tiles"]},
        {name: "Listed At", value: "listed_at",
          for: ["replays-uploads-without-scroll", "h-p-channels",
          "feed-recordings", "feed-replays", "feed-documents"]},
        {name: "Start At", value: "start_at",
          for: ["live-sessions", "feed-sessions"]}
      ],
      optionsShowFor: [
        {name: "All", value: "all"},
        {name: "Authorized", value: "logined"},
        {name: "Guest", value: "guest"},
        {name: "Not organization members", value: "not_organization"},
        {name: "Only organization members", value: "only_organization"}
      ],
      optionsForOrder: [
        {name: "Newest", value: "desc", default: true},
        {name: "Oldest", value: "asc", default: true},
        {name: "More views", value: "desc", for: "views_count"},
        {name: "Less views", value: "asc", for: "views_count"},
        {name: "Newest", value: "desc", for: "start_at"},
        {name: "Oldest", value: "asc", for: "start_at"}
      ],
      buttonTypes: [
        {name: "Without Button", value: "buttonless"},
        {name: "Primary", value: "main"},
        {name: "Secondary", value: "secondary"},
        // {name: "Tetriary", value: "tetriary"},
        // {name: "Bordered", value: "bordered"}
      ],
      buttonActions: [
        {name: "Sign Up", value: "signUp"},
        {name: "Login", value: "login"},
        {name: "Link", value: "link"}
      ],
      optionsImageSize: [
        {name: "Full", value: "full"},
        {name: "Large", value: "large"},
        {name: "Medium", value: "medium"},
        {name: "Custom", value: "custom"}
      ],
      // --- quill editor
       editorSettings: {
        modules: {
            toolbar: {
                container: [
                    [{header: [1, 2, 3, 4, 5, 6, false]}],
                    [
                        {align: ""},
                        {align: "center"},
                        {align: "right"},
                        {align: "justify"}
                    ],
                    ["bold", "italic", "underline", "strike"],
                    ["link"],
                    // ["emoji"],
                    // ["image", "link"],
                    // [{list: "ordered"}, {list: "bullet"}],
                    // ["blockquote", "code-block"],
                    // [{ size: ["small", false, "large"] }],
                    // [{ direction: [] }],
                    // ["align"]
                    // ["clean"],
                    // [{ header: 1 }, { header: 2 }],
                    // [{ script: "sub" }, { script: "super" }],
                    // [{ indent: "-1" }, { indent: "+1" }],
                    // [{ color: [] }, { background: [] }],
                    ['clean']
                ]
            },
            htmlEditButton: {
              okText: "Save"
              // syntax: true // need highlight.js
            }
          }
      },
      // ---
      editLoaded: false // overriding by change type
    }
  },
  computed: {
    optionsOrder() {
      let list = this.optionsForOrder.filter(e => e.for === this.settings.props.orderBy)
      if(list.length > 0) return list
      else return this.optionsForOrder.filter(e => e.default)
    },
    optionsOrderByByType() {
      let list = this.optionsOrderBy.filter(e => e.for.includes(this.settings.type))
      return list
    }
  },
  watch: {
    "settings.type": {
      handler(val) {
        this.hint = false
        if(this.editLoaded) { // overriding by change type
          this.editLoaded = false
        }
        else {
          if(val && this.defaulByType[val]) {
            this.settings.props = {...this.settings.props, ...this.defaulByType[val]}
          }
          this.clearFields()
        }
      }
    },
    'settings.props.imageSize': {
        handler(val) {
          let adsOld = this.settings.props.ads
          if(val === 'full') {
            this.settings.props.ads = ['']
          }
          else if(val === 'large') {
            this.settings.props.ads = ['', '', '']
          }
          else if(val === 'medium') {
            this.settings.props.ads = ['', '', '', '', '']
          }
          this.settings.props.ads.forEach((ad, index) => {
            if(adsOld[index]) this.settings.props.ads[index] = adsOld[index]
          })
      }
    }
  },
  mounted() {
    this.$eventHub.$on("open-modal:componentSettings", (group, settings) => {
      this.group = group
      if(settings === null) {
        this.new = true
        this.editLoaded = false
        this.settings = JSON.parse(JSON.stringify(this.defaultSettings)) // deep copy
      }
      else {
        this.new = false
        this.editLoaded = true
        this.settings = JSON.parse(JSON.stringify(settings))
        this.checkFields()
      }
      this.openModal()
    })
  },
  methods: {
    openModal(){
      this.$refs.settingsModal.openModal()
    },
    closeModal(){
      this.$refs.settingsModal.closeModal()
    },
    clearFields() {
      if(!this.settings) return

      Object.keys(this.settings.props).forEach(key => {
        if(!(Object.keys(this.defaultSettings.props).includes(key) ||
            (this.defaulByType[this.settings.type] &&
            Object.keys(this.defaulByType[this.settings.type]).includes(key)))) {
              delete this.settings.props[key]
        }
      })
    },
    checkFields() { // check new fields in old settings
      if(!this.settings) return

      Object.keys(this.defaultSettings.props).forEach(key => {
        if(!Object.keys(this.settings.props).includes(key)) {
          this.settings.props[key] = this.defaultSettings.props[key]
        }
      })
      if(this.defaulByType[this.settings.type]){
        Object.keys(this.defaulByType[this.settings.type]).forEach(key => {
          if(!Object.keys(this.settings.props).includes(key)) {
            this.settings.props[key] = this.defaulByType[this.settings.type][key]
          }
        })
      }
    },
    save() {
        this.saving = true
        this.clearFields()

        this.fileSave().then(() => {
            if(this.new) {
                this.$eventHub.$emit("componentSettings:add", this.group, this.settings)
            }
            else {
                this.$eventHub.$emit("componentSettings:change", this.group, this.settings)
            }

            this.saving = false
            this.closeModal()
        })
    },
    onFormChanged(val) {
      this.settings.props.form = val
    },
    fileSave() {
        return new Promise((resolve, reject) => {
            if(this.settings.props.backgroundImage && this.settings.props.backgroundImage.includes("data:image")) {
                let file = imageHelper.DataURIToBlob(this.settings.props.backgroundImage)
                const formData = new FormData();
                formData.append('file', file)
                Files.api().saveHomeBannerImage(formData).then(res => {
                    this.settings.props.backgroundImage = res.response.data.url
                    resolve()
                })
            }
            else resolve()
        })
    }
  }
}
</script>

<style>

</style>