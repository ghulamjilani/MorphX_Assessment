
<template>
    <div>
        <div class="chatGroup__header">
            <span>{{ currentConversation.channel.title }}</span>
            <m-icon
                size="0"
                class="chatGroup__header__back"
                @click="$emit('toggleChat', false)">
                GlobalIcon-angle-left
            </m-icon>
            <m-icon
                size="0"
                class="chatGroup__header__close"
                @click="$emit('closeChat')">
                GlobalIcon-clear
            </m-icon>
        </div>
        <div class="chatGroup__body">
            <div class="chatDialog">
                <div
                    ref="messages"
                    class="chatDialog__body smallScrolls">
                    <infinite-loading
                        v-if="initLoader"
                        ref="InfiniteLoading"
                        spinner="waveDots"
                        direction="top"
                        @infinite="infiniteHandler">
                        <div slot="no-more" />
                        <div
                            slot="no-results"
                            class="history__body__no-results" />
                    </infinite-loading>
                    <conversation-message
                        v-for="msg in messages"
                        :key="msg.id"
                        :message="msg" />
                </div>
                <div
                    class="chatDialog__footer">
                    <m-form
                        ref="form"
                        v-click-outside="() => { toggleEmoji(false)}"
                        @onSubmit="sendComment"
                        @enterPressed="sendComment">
                        <m-input
                            ref="message"
                            v-model="message.body"
                            :smile="!checkMobile()"
                            :max-counter="200"
                            :borderless="true"
                            :pure="true"
                            placeholder="Type your comment..."
                            :maxlength="200"
                            field-id="chatDialog__footer__input"
                            autocomplete="off"
                            @smileClicked="toggleEmoji()"
                            @click="lastEmojiPos = -1"
                            @focus="lastEmojiPos = -1">
                            <template #icon>
                                <m-icon
                                    class="chatDialog__footer__icon"
                                    size="1.8rem"
                                    @click="sendComment">
                                    GlobalIcon-send
                                </m-icon>
                            </template>
                        </m-input>
                        <div
                            v-if="showEmoji"
                            class="chatDialog__footer__emoji">
                            <VEmojiPicker
                                :emojis-by-row="8"
                                @select="selectEmoji" />
                        </div>
                    </m-form>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import ClickOutside from "vue-click-outside"
    import InfiniteLoading from "vue-infinite-loading"

    import ImConversations from '@models/ImConversations'
    import ImConversationMessages from '@models/ImConversationMessages'

    import ConversationMessage from './ConversationMessage.vue'

    export default {
        directives: { ClickOutside },
        components: { ConversationMessage, InfiniteLoading },
        props: {
            conversationId: {
                type: [String, Boolean],
                default: false
            }
        },
        data() {
            return {
                message: {
                    body: ""
                },
                showEmoji: false,
                disable: false,
                currentChannel: null,
                options: {
                    historyLimit: 50
                },
                lastEmojiPos: -1,
                loading: false,
                isChatOpened: false,
                newMessages: 0,
                firstEnter: true,
                initLoader: false,
                offset: 0,
                limit: 10
            }
        },
        computed: {
            currentUser() {
                return this.$store.getters["Users/currentUser"]
            },
            currentConversation() {
                return ImConversations.query().whereId(this.conversationId).first()
            },
            messages() {
                return ImConversationMessages.query().where('conversation_id', this.currentConversation.id).orderBy('created_at', 'asc').get()
            }
        },
        watch: {
            conversationId: {
                handler(val){
                    if(val){
                        this.getConversationMessages()
                    }
                },
                immediate: true,
                deep: true
            }
        },
        mounted() {
            document.addEventListener("keyup", (event) => {
                if (event.keyCode === 13) {
                    event.preventDefault()
                    if (this.showEmoji) {
                        this.sendComment()
                    }
                }
            })

            this.$eventHub.$on("conversation-newMessage", (id) => {
                this.$nextTick(() => {
                    if(this.conversationId == id) {
                        if(this.checkToBottom() < 250) {
                            this.scrollToBottom()
                        }
                    }
                })
            })
        },
        methods: {
            toggleEmoji(setEmoji = null) {
                if(setEmoji == null) this.showEmoji = !this.showEmoji
                else this.showEmoji = setEmoji

                this.lastEmojiPos = -1
            },
            getConversationMessages(loaderState = null){
                ImConversationMessages.api().getAllConversationMessages({
                    id: this.conversationId,
                    limit: this.limit,
                    offset: this.messages.length
                }).then((res) => {
                    if(!this.initLoader) {
                        this.initLoader = true
                        this.scrollToBottom()
                    }
                    if(loaderState && res.response.data.pagination.total_pages <= res.response.data.pagination.current_page) {
                        loaderState.complete()
                    }
                    else if(loaderState) {
                        loaderState.loaded()
                    }
                })
            },
            checkMobile() {
              return this.$device.mobile()
            },
            sendComment() {
                if (this.message.body.length && this.message.body.trim().length > 0) {
                    ImConversationMessages.api().createMessage({id: this.conversationId, message: this.message}).then(() => {
                        this.scrollToBottom()
                    })
                }
                this.message.body = ""
                this.showEmoji = false
            },
            selectEmoji(emoji) {
                let el = this.$refs.message.$refs.input
                let startPos = el.selectionStart,
                    endPos = el.selectionEnd,
                    tmpStr = el.value
                if (this.lastEmojiPos !== -1) {
                    startPos = this.lastEmojiPos
                    endPos = this.lastEmojiPos
                }
                this.message.body = tmpStr.substring(0, startPos) + emoji.data + tmpStr.substring(endPos, tmpStr.length)
                this.lastEmojiPos = startPos + emoji.data.length
            },
            scrollToBottom() {
                setTimeout(() => {
                    this.calculateToBottom()
                }, 500)
                this.calculateToBottom()
            },
            checkToBottom() {
                return this.$refs.messages.scrollHeight - (this.$refs.messages.scrollTop + this.$refs.messages.clientHeight)
            },
            calculateToBottom() {
                const maxScrollTop = this.$refs.messages.scrollHeight - this.$refs.messages.clientHeight + 50
                return this.$refs.messages.scrollTop = maxScrollTop > 0 ? maxScrollTop : 0
            },
            infiniteHandler($state) {
                this.getConversationMessages($state)
            }
        }
    }
</script>