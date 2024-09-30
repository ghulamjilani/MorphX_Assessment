<template>
    <div
        class="newPost"
        :class="{'editPost': editPost}">
        <div class="newPost__info">
            <m-form
                ref="form"
                v-model="disabled">
                <div class="newPost__form">
                    <div class="newPost__settings__wrapper">
                        <div class="newPost__settings">
                            <div
                                class="newPost__settings__header"
                                @click="toggleSettings()">
                                <div class="newPost__settings__title">
                                    {{ $t('views.blog_posts.additional_settings') }}
                                </div>
                                <m-icon
                                    :class="{'newPost__settings__arrow__active' : settings}"
                                    class="newPost__settings__arrow"
                                    size="1rem">
                                    GlobalIcon-angle-down
                                </m-icon>
                            </div>
                            <div
                                v-show="settings"
                                class="newPost__settings__body">
                                <m-checkbox
                                    v-model="isHidden"
                                    class="newPost__settings__checkbox">
                                    {{ $t('views.blog_posts.hide_post') }}
                                </m-checkbox>
                                <m-checkbox
                                    v-model="post.hide_author"
                                    class="newPost__settings__checkbox">
                                    {{ $t('views.blog_posts.show_author_name') }}
                                </m-checkbox>
                                <div class="newPost__settings__prompt">
                                    {{ $t('views.blog_posts.prompt') }}
                                </div>
                            </div>
                        </div>
                    </div>
                    <m-select
                        v-model="post.channel_id"
                        :options="options"
                        class="newPost__info__select"
                        label="Channel *"
                        placeholder="Select Channel"
                        rules="required"
                        type="default" />
                    <m-input
                        v-model="post.title"
                        class="newPost__info__input"
                        field-id="title"
                        label="Post title *"
                        rules="required|min-length:6|max-length:80" />
                    <div
                        v-if="loaded"
                        class="newPost__info__tags">
                        <blog-tags
                            ref="tags"
                            v-model="post.tag_list" />
                    </div>
                    <div class="newPost__editor">
                        <vue-editor
                            ref="editor"
                            v-model="post.body"
                            :editor-options="editorSettings"
                            use-custom-image-handler
                            @imageAdded="handleImageAdded"
                            @image-added="handleImageAdded" />
                        <m-modal
                            ref="linkModal"
                            class="linkModal"
                            @modalClosed="embedLink = ''">
                            <m-input
                                v-model="embedLink"
                                class="newPost__info__input"
                                field-id="embedLink"
                                label="Link" />
                            <m-btn
                                tag="div"
                                :full="true"
                                @click="addEmbedLink">
                                Add
                            </m-btn>
                        </m-modal>
                    </div>
                    <link-preview
                        v-if="linkPreview"
                        :editable="true"
                        :link="linkPreview"
                        :manage="false"
                        @close="removePreview" />
                </div>
            </m-form>
        </div>
        <crop-image
            ref="crop"
            v-model="post.post_cover"
            :post="editPost"
            @validate="validateImage" />

        <!-- <img :src="post.post_cover" alt=""> -->

        <div
            v-if="!editPost || (editPost && editPost.status === 'draft')"
            class="newPost__info__checkboxWrapper">
            <m-checkbox
                v-model="isDraft"
                class="newPost__info__checkbox draft">
                Save as draft
            </m-checkbox>
        </div>

        <div class="newPost__buttons">
            <m-btn
                :disabled="loading"
                type="secondary"
                @click="cancel">
                Cancel
            </m-btn>
            <m-btn
                v-if="editPost"
                :disabled="loading || disabled || isDisabled || !validImage"
                type="save"
                @click="update">
                {{
                    isDraft ? 'Save as Draft' : isHidden ? 'Save' : editPost.status === 'draft' || editPost.status ===
                        'hidden' ? 'Publish' : 'Update'
                }}
            </m-btn>
            <m-btn
                v-else
                :disabled="loading || disabled || isDisabled || !validImage"
                type="save"
                @click="create">
                {{ isDraft ? 'Save as Draft' : isHidden ? 'Save' : 'Publish' }}
            </m-btn>
        </div>
    </div>
</template>

<script>
import Tags from "./Tags"
import CropImage from "./CropImage"
import LinkPreview from "./LinkPreview"
import {Quill, VueEditor} from "vue2-editor"
import Emoji from "./../../assets/js/quill-emoji"
import "quill-emoji/dist/quill-emoji.css"
import ImageResize from 'quill-image-resize-vue'
import {ImageDrop} from 'quill-image-drop-module'
import Blog from "@models/Blog"
import User from "@models/User"

import imageHelper from "@utils/images"
import utils from '@helpers/utils'

import "quill-mention"
import "quill-mention/dist/quill.mention.css"

import MediaBlot from "@plugins/quill/insertEmbed"
Quill.register("modules/MediaBlot", MediaBlot)
import RegularMediaBlot from "@plugins/quill/insertRegularEmbed"
Quill.register("modules/RegularMediaBlot", RegularMediaBlot)
import insertEmbedController from "@plugins/quill/insertEmbedController"

if(!Quill.imports["modules/quill-emoji"]) Quill.register("modules/quill-emoji", Emoji)
Quill.register(
    {
        "formats/emoji": Emoji.EmojiBlot,
        "modules/short_name_emoji": Emoji.ShortNameEmoji,
        "modules/toolbar_emoji": Emoji.ToolbarEmoji,
        "modules/textarea_emoji": Emoji.TextAreaEmoji
    },
    true
)
var Font = Quill.import('formats/font')
Font.whitelist = ['Roboto']
Quill.register(Font, true)

Quill.register("modules/imageDrop", ImageDrop)
Quill.register("modules/imageResize", ImageResize)
var BaseImageFormat = Quill.import('formats/image')

var icons = Quill.import("ui/icons"); // fill="var(--tp__icons)"
    icons["customEmbed"] = `<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"><path fill="var(--tp__icons)" d="M21 3H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h5v1c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-1h5c1.1 0 1.99-.9 1.99-2L23 5a2 2 0 0 0-2-2zm-1 14H4c-.55 0-1-.45-1-1V6c0-.55.45-1 1-1h16c.55 0 1 .45 1 1v10c0 .55-.45 1-1 1zm-5.52-5.13l-3.98 2.28c-.67.38-1.5-.11-1.5-.87V8.72c0-.77.83-1.25 1.5-.87l3.98 2.28c.67.39.67 1.35 0 1.74z"></path></svg>`;

const ImageFormatAttributesList = [
    'alt',
    'height',
    'width',
    'style'
]

class ImageFormat extends BaseImageFormat {
    static formats(domNode) {
        return ImageFormatAttributesList.reduce(function (formats, attribute) {
            if (domNode.hasAttribute(attribute)) {
                formats[attribute] = domNode.getAttribute(attribute)
            }
            return formats
        }, {})
    }

    format(name, value) {
        if (ImageFormatAttributesList.indexOf(name) > -1) {
            if (value) {
                this.domNode.setAttribute(name, value)
            } else {
                this.domNode.removeAttribute(name)
            }
        } else {
            super.format(name, value)
        }
    }
}

Quill.register(ImageFormat, true)

export default {
    components: {
        "blog-tags": Tags,
        CropImage,
        VueEditor,
        LinkPreview
    },
    props: {
        editPost: Object,
        channelId: {
            type: Number,
            default: null
        }
    },
    data() {
        return {
            settings: false,
            loaded: false,
            loading: false,
            disabled: false,
            options: [],
            channels: [],
            isDraft: true,
            isHidden: false,
            post: {
                channel_id: this.channelId,
                title: "",
                body: "",
                tag_list: [],
                post_cover: "",
                image_id: [],
                link_preview_id: [],
                hide_author: false
            },
            // links
            links: [],
            cancelledLinks: [],
            linkPreview: null,
            LinkPreviewsChannel: null,
            waitForLink: 0,
            //images
            validImage: true,
            embedLink: '',
            quillLastCaretPosition: 0,
            // editor
            editorSettings: {
                modules: {
                    toolbar: {
                        container: [
                            // [{ font: [] }],
                            [{header: [1, 2, 3, 4, 5, 6, false]}],
                            [
                                {align: ""},
                                {align: "center"},
                                {align: "right"},
                                {align: "justify"}
                            ],
                            ["bold", "italic", "underline", "strike"],
                            ["emoji"],
                            ["image", "link"],
                            [{list: "ordered"}, {list: "bullet"}],
                            ["blockquote", "code-block"],
                            // [{ size: ["small", false, "large"] }],
                            // [{ direction: [] }],
                            // ["align"]
                            // [{ header: 1 }, { header: 2 }],
                            // [{ script: "sub" }, { script: "super" }],
                            [{ indent: "-1" }, { indent: "+1" }],
                            // [{ color: [] }, { background: [] }],
                            ["clean"],
                            ["customEmbed"]
                        ],
                        handlers: {
                          customEmbed: () => {
                            this.quillLastCaretPosition = this.$refs.editor.quill.getSelection().index
                            this.$refs.linkModal.openModal()
                            setTimeout(() => {
                                document.getElementById('embedLink').focus()
                            }, 500)
                          }
                        }
                    },
                    toolbar_emoji: true,
                    short_name_emoji: true,
                    textarea_emoji: false,
                    "emoji-shortname": true,
                    imageDrop: true,
                    // MediaBlot: true,
                    imageResize: {},
                    mention: {
                        // allowedChars: /^[A-Za-z\sÅÄÖåäö]*$/,
                        mentionDenotationChars: ["@"],
                        renderItem: (data) => {
                            if (data.disabled) {
                                return `<div class="quillSeparator">${data.value}</div>`
                            }
                            return data.value
                        },
                        renderLoading: () => {
                            return "Loading..."
                        },
                        source: async function (searchTerm, renderList, mentionChar) {
                            if (searchTerm.length > 2) {
                                let list = await User.api().mentionSuggestions({
                                    query: searchTerm
                                })
                                let quillList = list?.response?.data?.response?.mention_suggestions.map(e => {
                                    return {
                                        id: e.user.id,
                                        value: e.user.slug
                                    }
                                })
                                if (quillList.length === 0) {
                                    quillList.push({
                                        id: "-1",
                                        value: "Not found",
                                        disabled: true
                                    })
                                }
                                renderList(quillList, searchTerm)
                            } else {
                                renderList([], searchTerm)
                            }
                        }
                    }
                }
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        isDisabled() {
            return !(this.post?.tag_list?.length > 0 && this.post?.channel_id && this.post?.channel_id >= 0)
        },
        isCanManagePost() {
            return this.currentUser?.credentialsAbility?.can_manage_blog_post && this.editPost?.channel.can_create_post && this.currentUser.id === this.editPost.user.id
        },
        isCanModerateBlogPost() {
            return this.currentUser?.credentialsAbility?.can_moderate_blog_post
        }
    },
    watch: {
        "post.body": {
            handler(val) {
                if (!val) return
                var expression = /(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})/gi
                let text = val.replaceAll("<p>", " ").replaceAll("</p>", " ").replaceAll("</a>", " ").replaceAll("\"", " ").replaceAll("\'", " ")
                    .replaceAll("</span>", " ").replaceAll("<span>", " ").replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"')
                const array = [...text.matchAll(expression)].map(e => e[0]).unique()
                if (!this.links.equals(array)) {
                    this.links = array // this.links.concat(array).unique()
                    this.checkLinks()
                }
            }
        },
        isHidden: {
            handler(val) {
                if (val) {
                    this.isDraft = false
                }
            }
        },
        isDraft: {
            handler(val) {
                if (val) {
                    this.isHidden = false
                }
            }
        }
    },
    mounted() {
        let inputTest = document.querySelector('.ql-tooltip input')
        if (inputTest) {
            inputTest.addEventListener('input', (event) => {
                this.validateLinks(event)
            })
            inputTest.addEventListener('focus', (event) => {
                this.validateLinks(event)
            })
            inputTest.addEventListener('blur', (event) => {
                this.clearLinks(event)
            })
        }
        this.$eventHub.$on('clearData-post', () => {
            this.clearData()
        })
        if (this.editPost && this.editPost.id) {
            this.post = {
                channel_id: this.editPost.channel_id,
                title: this.editPost.title,
                body: this.editPost.body,
                tag_list: this.editPost.tag_list,
                post_cover: "",
                hide_author: this.editPost.hide_author,
                published_at: this.editPost.published_at
            }
            this.isDraft = this.editPost.status === "draft"
            this.isHidden = this.editPost.status === "hidden"
            this.$nextTick(() => {
                if (this.$refs.crop && this.$refs.crop.changeImage)
                    this.$refs.crop.changeImage(this.editPost.cover_url)
            })
            Blog.api().getPost({slug: this.editPost.slug}).then(res => {
                let postBody = res.response.data.response.post.body
                this.post.tag_list = res.response.data.response.post.tag_list
                this.$nextTick(() => {
                    let delta = this.$refs.editor.quill.clipboard.convert(postBody)
                    this.$refs.editor.quill.setContents(delta, "user")
                })
                this.linkPreview = res.response.data.response.post.featured_link_preview
                this.isDraft = res.response.data.response.post.status === "draft"
                setTimeout(() => {
                    this.linkPreview = res.response.data.response.post.featured_link_preview
                }, 1000)
                if (this.$refs.crop && this.$refs.crop.changeImage)
                    this.$refs.crop.changeImage(this.editPost.cover_url)
            })
        }
        setTimeout(() => {
            this.updateChannelsList()
            this.loaded = true
        }, 200)

        this.LinkPreviewsChannel = initLinkPreviewsChannel(0)
        this.LinkPreviewsChannel.bind(linkPreviewsChannelEvents.linkParsed, (data) => {
            if (data && data.status === "done") {
                if (data.id === this.waitForLink) {
                    this.linkPreview = data
                }
            }
        })

        this.$refs.editor.quill.on('text-change', (delta, oldDelta, source) => {
            let QDelta = this.$refs.editor.quill.editor.delta
            QDelta.ops.forEach(d => {
                if(d?.insert?.regularEmbed && !d.insert.regularEmbed.innerHTML.includes("morphx__embed")) {
                    let embed = d.insert.regularEmbed.innerText
                    let embedData = embed
                    let index = QDelta.ops.indexOf(d)
                    QDelta.ops[index].insert = embedData
                    this.$refs.editor.quill.setContents(QDelta)
                }
            })
        });
    },
    methods: {
        toggleSettings() {
            this.settings = !this.settings
        },
        clearData() {
            this.post = {
                channel_id: null,
                title: "",
                body: "",
                tag_list: [],
                post_cover: "",
                image_id: [],
                hide_author: false
            }
            this.links = []
            if (this.$refs.tags) this.$refs.tags.clear()
            if (this.$refs.crop) this.$refs.crop.clear()
            if (this.$refs.form) this.$refs.form.observerReset()
        },
        checkStatus() {
            if (this.isDraft) return "draft"
            if (this.isHidden) return "hidden"
            return "published"
        },
        checkTitle() {
            if (!this.title?.length) {
                this.upTitle = false
            }
        },
        removePreview(link = "") {
            this.cancelledLinks.push(link)
            this.linkPreview = null
            this.checkLinks()
        },
        updateChannelsList() {
            if (this.editPost) {
                if (this.isCanManagePost) {
                    User.api().accessManagment({permission_code: 'manage_blog_post'}).then(res => {
                        let channels = res.response.data.response = res.response.data.response
                        this.options = channels.map((e) => {
                            return {
                                name: e.title,
                                value: e.id
                            }
                        })
                        if (this.options?.length === 1) {
                            this.post.channel_id = this.options[0].value
                        }
                    })
                        .catch(error => {
                            this.$flash(error.response.message)
                        })
                } else {
                    User.api().accessManagment({permission_code: 'moderate_blog_post'}).then(res => {
                        let channels = res.response.data.response = res.response.data.response
                        this.options = channels.map((e) => {
                            return {
                                name: e.title,
                                value: e.id
                            }
                        })
                        if (this.options?.length === 1) {
                            this.post.channel_id = this.options[0].value
                        }
                    })
                        .catch(error => {
                            this.$flash(error.response.message)
                        })
                }
            } else {
                User.api().accessManagment({permission_code: 'manage_blog_post'}).then(res => {
                    let channels = res.response.data.response = res.response.data.response
                    this.options = channels.map((e) => {
                        return {
                            name: e.title,
                            value: e.id
                        }
                    })
                    if (this.options?.length === 1) {
                        this.post.channel_id = this.options[0].value
                    }
                })
                    .catch(error => {
                        this.$flash(error.response.message)
                    })
            }
        },
        create() {
            this.checkVisitUrlValidation()
            this.loading = true
            let data = {
                channel_id: this.post.channel_id,
                title: this.post.title.trim(),
                body: this.post.body,
                status: this.checkStatus(),
                tag_list: this.post.tag_list.join(","),
                post_cover: this.post.post_cover ? imageHelper.DataURIToBlob(this.post.post_cover) : null,
                image_id: this.post.image_id,
                hide_author: this.post.hide_author,
                published_at: this.checkStatus() == 'published' && !this.post.published_at ? utils.dateToTimeZone(moment(), true).format() : this.post.published_at
            }
            if (this.linkPreview)
                data["featured_link_preview_id"] = this.linkPreview.id

            let mentions = []
            document.querySelectorAll(".mention").forEach(e => {
                mentions.push(e.dataset.id)
            })
            data["mention_ids"] = mentions

            Blog.api().create(data).then(res => {
                this.loading = false
                let post = res.response.data.response.post
                if (post) {
                    if (this.isDraft || this.isHidden) {
                        this.$flash("Post successfully saved!", "success")
                    } else {
                        this.$flash("Post successfully published!", "success")
                    }
                    this.$emit("created", post)
                    if (this.$router.history.current.name === 'create-post') {
                        this.$router.push({name: 'manage-blog'})
                    }
                    this.cancel()
                }
            })
                .catch(error => {
                    this.loading = false
                    this.$flash(error.response.data.message)
                })
        },
        update() {
            if (confirm("Are you sure to edit this post?")) {
                this.checkVisitUrlValidation()
                this.loading = true
                let data = {
                    id: this.editPost.id,
                    channel_id: this.post.channel_id,
                    title: this.post.title.trim(),
                    body: this.post.body,
                    tag_list: this.post.tag_list.join(","),
                    image_id: this.post.image_id,
                    status: this.checkStatus(),
                    hide_author: this.post.hide_author,
                    published_at: this.checkStatus() == 'published' && !this.post.published_at ? utils.dateToTimeZone(moment(), true).format() : this.post.published_at
                }
                if (this.post.post_cover && this.post.post_cover !== "") {
                    data["post_cover"] = imageHelper.DataURIToBlob(this.post.post_cover)
                }
                if (this.linkPreview) {
                    data["featured_link_preview_id"] = this.linkPreview.id
                } else {
                    data["featured_link_preview_id"] = ''
                }

                let mentions = []
                document.querySelectorAll(".mention").forEach(e => {
                    mentions.push(e.dataset.id)
                })
                data["mention_ids"] = mentions

                Blog.api().update(data).then(res => {
                    this.loading = false
                    let post = res.response.data.response.post
                    if (post) {
                        this.$flash("Post successfully updated!", "success")
                        this.$emit("update", post)
                        this.$emit("close", true)
                    }
                })
                    .catch(error => {
                        this.loading = false
                        this.$flash(error.response.data.message)
                    })
            }
        },
        cancel() {
            this.clearData()
            this.$emit("close")
        },
        handleImageAdded(file, Editor, cursorLocation, resetUploader) {
            var formData = new FormData()
            formData.append("image", file)
            let organization_id = -1
            if (this.currentOrganization) organization_id = this.currentOrganization.id
            else {
                let selectedChannel = this.channels.find(e => e.id == this.post.channel_id)
                organization_id = selectedChannel.organization_id
            }
            formData.append("organization_id", organization_id)
            if (this.editPost)
                formData.append("blog_post_id", this.editPost.id)

            Blog.api().sendImage(formData)
                .then((res) => {
                    let url = res.response.data.response.image.large_url // Get url from response
                    Editor.insertEmbed(cursorLocation, "image", url)
                    resetUploader()
                    this.post.image_id.push(res.response.data.response.image.id)
                })
                .catch((err) => {
                    if (err.response.status == 422) {
                        this.$flash("This Image could not be processed")
                    } else {
                        this.$flash("Something went wrong please try again later")
                    }
                })
        },
        validateImage(val) {
            this.validImage = val
        },
        checkLinks: utils.debounce(function () {
            let arr = this.links.filter(e => !this.cancelledLinks.includes(e))
            if (arr?.length > 0) {
                let link = arr[arr?.length - 1]
                Blog.api().parseLink({url: link}).then(res => {
                    let lp = res.response.data.response.link_preview
                    if (lp.status === 'done' && (lp.description && lp.description !== '' && lp.title && lp.title !== '')) {
                        this.linkPreview = res.response.data.response.link_preview
                        if (this.linkPreview && this.linkPreview.title) {

                        } else {
                            this.removePreview(link)
                        }
                    } else {
                        let id = res.response.data.response.link_preview.id
                        this.waitForLink = id
                        this.LinkPreviewsChannel.bind("link_parse_failed", (data) => {
                            this.removePreview(link)
                        })
                    }
                })
            }
        }, 500),
        validateLinks(element) {
            var RegExp = /^((ftp|http|https):\/\/)?(www\.)?([A-Za-zА-Яа-я0-9]{1}[A-Za-zА-Яа-я0-9\-]*\.?)*\.{1}[A-Za-zА-Яа-я0-9-]{2,8}(\/([\w#!:.?+=&%@!\-\/])*)?/
            if (RegExp.test(element.target.value)) {
                element.target.nextElementSibling.classList.remove('disabled')
                element.target.classList.remove('error')
                document.querySelector('.ql-tooltip').classList.remove('error')
            } else {
                element.target.nextElementSibling.classList.add('disabled')
                document.querySelector('.ql-tooltip').classList.add('error')
                element.target.classList.add('error')
            }
        },
        clearLinks(element) {
            setTimeout(() => {
                if (element.target.parentElement.classList.contains('ql-hidden')) {
                    element.target.value = ''
                    element.target.nextElementSibling.classList.remove('disabled')
                    element.target.classList.remove('error')
                    document.querySelector('.ql-tooltip').classList.remove('error')
                }
            }, 200)
        },
        checkVisitUrlValidation() {
            let delta = this.$refs.editor.quill.editor.delta
            let changed = false
            delta.ops.forEach(el => {
                if(el?.attributes?.link) {
                    if(!(el.attributes.link.includes("https://") || el.attributes.link.includes("http://"))) {
                        el.attributes.link = "https://" + el.attributes.link
                        changed = true
                    }
                }
            })
            if(changed)  {
                this.$refs.editor.quill.setContents(delta)
            }
        },

        addEmbedLink() {
            insertEmbedController.insertEmbedLink(this.$refs.editor.quill, this.quillLastCaretPosition, this.embedLink).then(() => {
                this.embedLink = ''
                this.$refs.linkModal.closeModal()
            })
        }
    }
}
</script>