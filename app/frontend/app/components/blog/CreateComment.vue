<template>
    <div class="cardMK2__post__comment__forPost">
        <m-form
            ref="form"
            v-click-outside="() => { showEmoji = false }"
            @onSubmit="sendComment">
            <div
                :class="{'ownerModal__message__quill__wrapper__error' : false}"
                class="cardMK2__post__comment__forPost__quill__wrapper">
                <vue-editor
                    ref="quilleditor"
                    v-model="message"
                    :editor-options="editorSettings"
                    placeholder="Type your comment..."
                    @text-change="textChange" />
                <m-icon
                    :class="{'cardMK2__post__comment__forPost__disable' : disable}"
                    class="cardMK2__post__comment__forPost__icon"
                    size="1.8rem"
                    @click="sendComment">
                    GlobalIcon-send
                </m-icon>
                <div class="ownerModal__message__bottom">
                    <div class="mTextArea__bottom__counter">
                        {{ textLength }}/600
                    </div>
                </div>
            </div>
            <!-- <div class="cardMK2__post__comment__emoji" v-if="showEmoji">
        <VEmojiPicker @select="selectEmoji" :emojisByRow="8" />
      </div> -->
        </m-form>
        <!-- <link-preview :link="linkPreview" :editable="true" @close="removePreview"
          v-if="linkPreview" :manage="manage" /> -->
    </div>
</template>

<script>
import ClickOutside from "vue-click-outside"
import BlogComments from "@models/BlogComments"
import Blog from "@models/Blog"
import User from "@models/User"
import Comments from "@models/Comments"
import utils from '@helpers/utils'
import {Quill, VueEditor} from "vue2-editor"
import Emoji from "./../../assets/js/quill-emoji"
import "quill-emoji/dist/quill-emoji.css"
import "quill-mention"

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

export default {
    directives: {
        ClickOutside
    },
    components: {VueEditor},
    props: {
        type: {
            type: String,
            default: 'blog'
        },
        model: Object,
        post: {},
        replyComment: {
            type: Object,
            default: null
        },
        manage: Boolean,
        editing: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            message: "",
            showEmoji: false,
            links: [],
            cancelledLinks: [],
            linkPreview: null,
            LinkPreviewsChannel: null,
            comment: null,
            disable: false,
            oldText: '',
            sended: false,
            textLength: 0,
            editorSettings: {
                modules: {
                    toolbar: {
                        container: [
                            ["emoji"]
                        ]

                    },
                    toolbar_emoji: true,
                    short_name_emoji: true,
                    textarea_emoji: false,
                    "emoji-shortname": true,
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
                        source: async (searchTerm, renderList, mentionChar) => {
                            let quillList = []
                            if (this.isBlog) {
                                quillList.push({
                                    id: "-1",
                                    value: "Recommended users",
                                    disabled: true
                                })
                                if (this.post && this.post.user) {
                                    quillList.push({
                                        id: this.post.user.id,
                                        value: this.post.user.slug
                                    })
                                }
                                if (this.replyComment && this.replyComment?.user?.id !== this.post?.user?.id) {
                                    quillList.push({
                                        id: this.replyComment?.user?.id,
                                        value: this.replyComment?.user?.slug
                                    })
                                }
                            } else if (this.isVideo) {
                                if (this.replyComment) {
                                    quillList.push({
                                        id: "-1",
                                        value: "Recommended users",
                                        disabled: true
                                    })
                                    quillList.push({
                                        id: this.replyComment?.user?.id,
                                        value: this.replyComment?.user?.slug
                                    })
                                } else {
                                    quillList.push({
                                        id: "-1",
                                        value: "Please write more than 2 symbols",
                                        disabled: true
                                    })
                                }
                            }
                            if (searchTerm.length > 2) {
                                let list = await User.api().mentionSuggestions({
                                    query: searchTerm
                                })
                                quillList = list?.response?.data?.response?.mention_suggestions.map(e => {
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
                                renderList(quillList, searchTerm)
                            }
                        }
                    },
                    keyboard: {
                        bindings: {
                            tab: false,
                            handleEnter: {
                                key: 13,
                                handler: () => {
                                    this.sendComment()
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    computed: {
        isBlog() {
            return this.type === 'blog'
        },
        isVideo() {
            let arr = ['Recording', 'Video', 'Session']
            return arr.includes(this.type)
        }
    },
    watch: {
        "message": {
            handler(val) {
                // var expression = /(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})/gi
                // let text = val.replaceAll("<p>", " ").replaceAll("</p>", " ")
                // const array = [...text.matchAll(expression)]
                // this.links = this.links.concat(array.map(e => e[0])).unique()
                // this.checkLinks()
            }
        }
    },
    methods: {
        sendComment() {
            this.showEmoji = false
            if (this.disable) return
            if (this.message.trim() === "") return
            if (this.editing) {
                this.updateComment()
                return
            }
            this.disable = true
            if (this.isBlog) {
                BlogComments.api().sendComment({
                    post_id: this.post.id,
                    comment: {
                        body: this.message.trim(),
                        commentable_type: `Blog::${this.replyComment ? 'Comment' : 'Post'}`,
                        commentable_id: this.replyComment ? this.replyComment.id : this.post.id
                        // link_previews_id: this.linkPreview ? [this.linkPreview.id] : []
                    }
                }).then(res => {
                    this.$emit("commented", res.response.data.response.comment)
                    this.message = ""
                    this.links = []
                    this.linkPreview = null
                    this.$refs.form.observerReset()
                    this.disable = false
                    this.clearText()
                    this.$nextTick(() => {
                        this.sended = true
                    })
                }).catch(error => {
                    this.disable = false
                    this.$flash(error.response.data.message)
                })
            } else if (this.isVideo) {
                Comments.api().sendComment({
                    body: this.message.trim(),
                    commentable_type: `${this.replyComment ? 'Comment' : this.type}`,
                    commentable_id: this.replyComment ? this.replyComment.id : this.model.id
                }).then(res => {
                    this.$emit("commented", res.response.data.response.comment)
                    this.message = ""
                    this.links = []
                    this.linkPreview = null
                    this.$refs.form.observerReset()
                    this.disable = false
                    this.clearText()
                    this.$nextTick(() => {
                        this.sended = true
                    })
                }).catch(error => {
                    this.disable = false
                    this.$flash(error.response.data.message)
                })
            }
        },
        updateComment() {
            if (this.message.trim() === "") return
            if (this.isBlog) {
                BlogComments.api().updateComment({
                    comment: {
                        id: this.comment.id,
                        body: this.message.trim(),
                        commentable_type: this.comment.commentable_type,
                        commentable_id: this.comment.commentable_id
                        // link_previews_id: this.linkPreview ? [this.linkPreview.id] : []
                    }
                }).then(res => {
                    this.$emit("commented", res.response.data.response.comment)
                    this.comment.edited_at = res.response.data.response.comment.edited_at
                    this.message = ""
                    this.links = []
                    this.linkPreview = null
                    this.$refs.form.observerReset()
                    this.clearText()
                    this.$nextTick(() => {
                        this.sended = true
                    })
                }).catch(error => this.$flash(error.response.data.message))
            } else if (this.isVideo) {
                Comments.api().updateComment({
                    id: this.comment.id,
                    body: this.message.trim(),
                    commentable_type: this.comment.commentable_type,
                    commentable_id: this.comment.commentable_id
                }).then(res => {
                    this.$emit("commented", res.response.data.response.comment)
                    this.comment.edited_at = res.response.data.response.comment.edited_at
                    this.message = ""
                    this.links = []
                    this.linkPreview = null
                    this.$refs.form.observerReset()
                    this.clearText()
                    this.$nextTick(() => {
                        this.sended = true
                    })
                }).catch(error => this.$flash(error.response.data.message))
            }
        },
        selectEmoji(emoji) {
            let el = this.$refs.message.$refs.input
            let startPos = el.selectionStart,
                endPos = el.selectionEnd,
                tmpStr = el.value
            this.message = tmpStr.substring(0, startPos) + emoji.data + tmpStr.substring(endPos, tmpStr.length)
            this.showEmoji = false
        },
        removePreview(link = "") {
            this.cancelledLinks.push(link)
            this.linkPreview = null
            this.checkLinks()
        },
        checkLinks() {
            return
            let arr = this.links.filter(e => !this.cancelledLinks.includes(e))
            if (arr.length > 0) {
                this.disable = true
                let link = arr[arr.length - 1]
                Blog.api().parseLink({url: link}).then(res => {
                    if (res.response.data.response.link_preview.status === 'done') {
                        this.linkPreview = res.response.data.response.link_preview
                    } else {
                        let id = res.response.data.response.link_preview.id
                        this.LinkPreviewsChannel = initLinkPreviewsChannel(id)
                        this.LinkPreviewsChannel.bind(linkPreviewsChannelEvents.linkParsed, (data) => {
                            if (data && data.title) {
                                data.id = id
                                this.linkPreview = data
                            } else {
                                this.removePreview(link)
                            }
                        })
                        this.LinkPreviewsChannel.bind("link_parse_failed", (data) => {
                            this.removePreview(link)
                        })
                    }
                    this.disable = false
                })
            }
        },
        editComment(comment) {
            this.message = comment.body
            this.comment = comment
        },

        textChange() {
            let quill = this.$refs.quilleditor.quill
            this.textLength = quill.getLength() - 1
            this.sended = false
            window.quill = quill
            if (quill.getLength() > 600) {
                quill.deleteText(600, quill.getLength())
                this.flashMessage()
            }
        },
        flashMessage: utils.debounce(function () {
            this.$flash('Maximum comment length could not be more then 600 symbols.')
        }, 200),
        clearText() {
            this.message = ""
            this.$refs.quilleditor.quill.container.children[0].innerText = ""
        },
        validateRequired() {
            return this.oldText && (this.textLength < 1) && !this.sended
        },
        focus() {
            // this.quilleditor
        },
        insertMention() {
            // if(this.message.length === 0) {
            //   this.$refs.quilleditor.quill.getModule('mention').insertItem({
            //     denotationChar: '@',
            //     id: this.replyComment?.user?.id,
            //     value: this.replyComment.user.public_display_name
            //   },true)
            // }
        }
    },
    mounted() {
        function checkEmoji() {
            let windowH = document.documentElement.clientHeight
            let elem = document.getElementById('emoji-palette')
            let rect = elem.getBoundingClientRect()
            if (windowH < rect.bottom) {
                elem.classList.add('goTop')
            }
        }

        setTimeout(() => {
            let openEmojiButton = document.querySelectorAll('button.ql-emoji')
            openEmojiButton.forEach(el => {
                el.addEventListener('click', checkEmoji)
            })
        }, 1000) // wait for quill
    }
}
</script>