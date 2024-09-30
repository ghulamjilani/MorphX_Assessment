
<template>
    <div class="chatGroup__body">
        <div class="chatDialog">
            <div
                v-if="showPollVisibilityMessage && activePoll"
                class="chatDialog__flesh pollVisibilityMessage"
                @click="scrollToPoll">
				<div>
					<div class="pollVisibilityMessage__text">
						Poll
					</div>
					<div class="pollVisibilityMessage__title">
						{{ activePoll.poll.question }}
					</div>
				</div>
               <div
                    class="btn btn-m btn__secondary"
                    @click.stop="openPolls">
				   View all
			   </div>
            </div>
            <div
                ref="messages"
                class="chatDialog__body smallScrolls">
                <p
                    v-if="messages.length == 0 && initLoader && isLive"
                    class="history__body__no-results">
                    There are no messages at the moment. You can be the first one to write a message!
                </p>
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
                <template v-for="msg in messages">
                    <conversation-message
                        v-if="!msg.isPoll"
                        :key="msg.id"
                        :message="msg" />
                    <poll
                        v-if="msg.isPoll"
                        :key="msg.id"
                        :poll="msg.poll"
                        :is-creator="isPresenter" />
                </template>
            </div>
            <div
                v-if="currentConversation && !currentConversation.closed && !replay"
                class="chatDialog__footer">
                <m-form
                    v-if="(currentUser || isGuest || currentGuest)
                        && currentConversation && currentConversation.can_create_message"
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
                <div
                    v-else-if="currentConversation && !currentConversation.closed && !guestNameMode"
                    class="chatDialog__footer__buttons">
                    <m-btn
                        v-if="canGuest"
                        type="secondary"
                        @click="guestNameMode = true">
                        {{ $t('frontend.app.components.pageparts.chat.chat_wrapper.guest') }}
                    </m-btn>
                    <m-btn
                        v-if="!canGuest"
                        @click="openLogin">
                        {{ $t('frontend.app.components.pageparts.chat.chat_wrapper.sign_in') }}
                    </m-btn>
                </div>
                <div
                    v-else-if="currentConversation && !currentConversation.closed && guestNameMode"
                    class="chatDialog__footer__buttons">
                    <m-input
                        v-model="guestName"
                        :errors="false"
                        label="Enter name"
                        @enter="init(false)" />
                    <m-btn
                        type="secondary"
                        @click="init(false)">
                        {{ $t('frontend.app.components.pageparts.chat.chat_wrapper.enter') }}
                    </m-btn>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import ClickOutside from "vue-click-outside"
    import InfiniteLoading from "vue-infinite-loading"

    import User from '@models/User'
    import ImConversations from '@models/ImConversations'
    import ImConversationMessages from '@models/ImConversationMessages'
    import Polls from '@models/Polls'
    import Session from '@models/Session'

    import ConversationMessage from './ConversationMessage.vue'
    import { getCookie, setCookie } from '@utils/cookies'
    import Poll from '@components/polls/Poll.vue'

    export default {
        directives: { ClickOutside },
        components: { ConversationMessage, InfiniteLoading, Poll },
        props: {
            sessionId: {
                type: [String, Number]
            },
            replay: {
                type: Boolean,
                default: false
            },
            roomInfo: Object
        },
        data() {
            return {
                message: {
                    body: ""
                },
                showEmoji: false,
                disable: false,
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
                limit: 50,
                guestName: "",
                guestNameMode: false,
                isGuest: false,
                playerCurrentTime: 0, // for reactive update by player time
                pollsChannel: null,
				showPollVisibilityMessage: false
            }
        },
        computed: {
            currentUser() {
                return this.$store.getters["Users/currentUser"]
            },
            currentGuest() {
                return this.$store.getters["Users/currentGuest"]
            },
            roomMember() {
                return this.$store.getters["VideoClient/roomMember"]
            },
            isPresenter() {
                if(window.Immerss?.session?.organizer_id) {
                    return this.currentUser?.id == window.Immerss?.session?.organizer_id
                }
                else if(this.roomInfo) {
                    return this.roomInfo?.presenter_user?.id === this.currentUser?.id
                }
                return false
            },
            currentConversation() {
                return ImConversations.query().where('conversationable_id', this.getSessionId).first()
            },
            allMessages() {
                return ImConversationMessages.query()
                            .where('conversation_id', this.currentConversation.id)
                            .orderBy('created_at', 'asc').get()
            },
            messages() {
                if(!this.currentConversation) return []
                if(this.replay || window?.Immerss?.replay?.cropped_start_at) {
                    let offset = new Date(window?.Immerss?.replay?.cropped_start_at).getTime() + (this.playerCurrentTime * 1000)
                    if(window?.player?.ads?.playing) offset = 0

                    return ImConversationMessages.query()
                        .where('conversation_id', this.currentConversation.id)
                        .where('created_at', (value) => value <= offset)
                        .orderBy('created_at', 'asc').get()
                }
                else {
                     return ImConversationMessages.query()
                            .where('conversation_id', this.currentConversation.id)
                            .orderBy('created_at', 'asc').get()
                }
            },
            getSessionId() {
                if(this.sessionId) return this.sessionId.toString()
                else if(window.Immerss?.session?.id) return window.Immerss.session.id.toString()
                else return "-1"
            },
            canGuest() {
                if(window.spaMode == "embed") {
                    return this.$railsConfig.global?.instant_messaging?.conversations?.sessions?.guests?.embed
                }
                else {
                    return this.$railsConfig.global?.instant_messaging?.conversations?.sessions?.guests?.regular
                }
            },
            activePoll() {
                return this.messages.find(m => m.isPoll && m.poll.enabled && !m.poll.is_voted)
            },
            isLive() {
                return window.Immerss && window.Immerss.session && !window.Immerss.replay
            }
        },
        watch: {
            currentUser(val, oldVal) {
                if(oldVal == null && val) this.init()
            },
            messages(val, oldVal) {
                if(this.replay || window?.Immerss?.replay?.cropped_start_at) {
                    if(val.length != oldVal.length) this.scrollToBottom()
                }
            }
        },
        mounted() {
            if(window.player) {
                setInterval(() => {
                    if(window.player) this.playerCurrentTime = window.player.currentTime
                }, 1000)
            }

            window.addEventListener("message", (e) => {
                if(e?.data?.type == "playerTime") {
                    this.playerCurrentTime = e?.data?.data
                }
            })


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
                    if(this.currentConversation?.id == id) {
                        if(this.checkToBottom() < 250) {
                            this.scrollToBottom()
                        }
                        this.newMessages++
                        this.$eventHub.$emit("tw-chatNewMessagesCount", this.newMessages)
                    }
                })
            })

            this.$eventHub.$on("conversation-polls", (polls) => {
                polls.forEach(poll => {
                    ImConversationMessages.insert({ data: {
                        conversation_id: this.currentConversation?.id,
                        id: "poll" + poll.id,
                        created_at: new Date(poll.created_at).getTime(),
                        isPoll: true,
                        poll: poll
                    } })
                })
            })

            this.$eventHub.$on("tw-toggleChat", () => {
                this.newMessages = 0
                this.$eventHub.$emit("tw-chatNewMessagesCount", this.newMessages)
            })

            this.$eventHub.$on("webRTC-toggleChat", () => {
                this.newMessages = 0
                this.$eventHub.$emit("tw-chatNewMessagesCount", this.newMessages)
            })

            this.$eventHub.$on("chat:update-conversations", () => {
                this.init(false)
            })

            this.init(true)

            if(window.spaMode == "monolith") {
                this.getPolls()
            }
			this.setupIntersectionObserver()
        },
        methods: {
            init(initCheck = false) {
                this.checkForGuest(initCheck).then(() => {
                    ImConversations.api().getSessionConversations({session_id: this.getSessionId}).then(() => {
                        this.getConversationMessages()
                        this.cabelConversation()
                        this.initPollsChannel()
                    })
                }).catch(() => {
                    ImConversations.api().getSessionConversations({session_id: this.getSessionId}).then(() => {
                        this.getConversationMessages()
                        this.cabelConversation()
                        this.initPollsChannel()
                    })
                })
            },
            openLogin() {
                this.$eventHub.$emit("open-modal:auth", "login")
            },
            cabelConversation(){
                let channel = initImConversationsChannel(this.currentConversation?.id)
                channel.bind(imConversationsChannelEvents.newMessage, (data) => {
                    let message = { ...data.message }
                    // message.conversation_id = this.currentConversation.id
                    message.abstract_user = data.message.conversation_participant.abstract_user
                    message.created_at = new Date(data.message.created_at).getTime()
                    ImConversationMessages.insert({ data: message })
                    // this.addNewMessage(message, conversation.channel.title)
                    this.$eventHub.$emit("conversation-newMessage", data.message.conversation_id)

                    this.$eventHub.$emit("tw-chatNewMessage", data.message)
                })
            },
            initPollsChannel() {
                this.pollsChannel = initPollsChannel()
                // this.pollsChannel.bind(pollsChannelEvents.addPoll, (data) => {
                //     console.log("*** addPoll ***", data);
                //     this.$eventHub.$emit(pollsChannelEvents.addPoll, data)
                // })
                this.pollsChannel.bind(pollsChannelEvents.startPoll, (data) => {
                    console.log("*** startPoll ***", data)
                    if(this.sessionId == data.model_id) {
                       this.updatePoll(data.poll_id)
                    }
                    this.$eventHub.$emit("tw-chatNewMessage", {
                        body: `New poll was started`,
                        id: "poll" + data.poll_id,
                        created_at: new Date().getTime()
                    })
                    this.$eventHub.$emit(pollsChannelEvents.startPoll, data)
                    this.scrollToBottom()
                })
                this.pollsChannel.bind(pollsChannelEvents.stopPoll, (data) => {
                    console.log("*** stopPoll ***", data)
                    if(this.sessionId == data.model_id) {
                       this.updatePoll(data.poll_id)
                    }
                    this.$eventHub.$emit(pollsChannelEvents.stopPoll, data)
                })
            },
            toggleEmoji(setEmoji = null) {
                if(setEmoji == null) this.showEmoji = !this.showEmoji
                else this.showEmoji = setEmoji

                this.lastEmojiPos = -1
            },
            getConversationMessages(loaderState = null){
                if(!this.currentConversation) return
                // created_at_from, created_at_to
                ImConversationMessages.api().getAllConversationMessages({
                    id: this.currentConversation.id,
                    limit: this.limit,
                    offset: this.allMessages.length,
                    order: "asc"
                    // created_at_from: new Date(window.Immerss.replay.cropped_start_at).getTime(),
                    // created_at_to: new Date(window.Immerss.replay.cropped_start_at).getTime() + (60 * 60 *1000)
                }).then((res) => {
                    if(loaderState) loaderState.complete()

                    if(!this.initLoader) {
                        this.initLoader = true
                        this.scrollToBottom()
                    }
                    if(res.response.data.pagination.total_pages > res.response.data.pagination.current_page) {
                        setTimeout(() => {
                            this.getConversationMessages()
                        }, 2000)
                    }
					this.$nextTick(() => {
						this.setupIntersectionObserver()
					})
                    // if(loaderState && res.response.data.pagination.total_pages <= res.response.data.pagination.current_page) {
                    //     loaderState.complete()
                    // }
                    // else if(loaderState) {
                    //     loaderState.loaded()
                    // }
                })
            },
            checkMobile() {
              return this.$device.mobile()
            },
            sendComment() {
                if (this.message.body.length && this.message.body.trim().length > 0) {
                    ImConversationMessages.api().createMessage({id: this.currentConversation?.id, message: this.message}).then(() => {
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
                this.toggleEmoji()
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
            },
            // guest
            checkForGuest(initCheck = false) {
                return new Promise((resolve, reject) => {
                    if(this.currentUser) { // not guest
                        resolve()
                    }
                    else if(!this.canGuest) {
                        resolve()
                        return
                    }
                    else if(getCookie('_guest_jwt')) { // guest and not expired
                        this.isGuest = true
                        resolve()
                    }
                    else if(getCookie('_guest_jwt_refresh')) { // guest and can refresh
                        User.api().refreshGuestJwt().then(res => {
                            setCookie('current_guest_id', res.response.data.response.guest.id, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie('current_guest_name', res.response.data.response.guest.public_display_name, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie('_guest_jwt', res.response.data.response.jwt_token, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie('_guest_jwt_refresh', res.response.data.response.jwt_token_refresh, new Date(res.response.data.response.refresh_jwt_exp).getTime())
                            setCookie('_cable_jwt', res.response.data.response.jwt_token, new Date(res.response.data.response.jwt_exp).getTime(), location.hostname)
                            this.$store.dispatch('Users/setCurrentGuest', res.response.data.response.guest)
                            this.isGuest = true
                            this.$eventHub.$emit("updateJwt")
                            resolve()
                        }).catch(error => {
                            reject()
                        })
                    }
                    else if((!initCheck && this.guestName != "") || (this.roomMember && this.roomMember.guest)) { // guest and expired
                        if(this.roomMember) {
                            this.guestName = this.roomMember.display_name
                        }
                        let visitor_id = getCookie("visitor_id")
                        // TODO: interactive guest name
                        User.api().createGuestJwt({visitor_id, public_display_name: this.guestName}).then(res => {
                            setCookie("current_guest_id", res.response.data.current_guest_id, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie("current_guest_name", this.guestName, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie("_guest_jwt", res.response.data.response.jwt_token, new Date(res.response.data.response.jwt_exp).getTime())
                            setCookie("_cable_jwt", res.response.data.response.jwt_token, new Date(res.response.data.response.jwt_exp).getTime(), location.hostname)
                            setCookie("_guest_jwt_refresh", res.response.data.response.jwt_token_refresh, new Date(res.response.data.response.refresh_jwt_exp).getTime())
                            this.$store.dispatch('Users/setCurrentGuest', res.response.data.response.guest)
                            this.isGuest = true
                            this.$eventHub.$emit("updateJwt")
                            resolve()
                        }).catch(() => {
                            reject()
                        })
                    }
                    else {
                        reject()
                    }
                })
            },
            // polls
            updatePoll(poll_id) {
                Polls.api().fetchPoll({id: poll_id}).then((res) => {
                    let poll = res.response.data
                    ImConversationMessages.insert({ data: {
                        conversation_id: this.currentConversation?.id,
                        id: "poll" + poll.id,
                        created_at: new Date(poll.created_at).getTime(),
                        isPoll: true,
                        poll: poll
                    } })
                    this.getPolls()
					this.$nextTick(() => {
						this.setupIntersectionObserver()
					})
                })
            },
            getPolls() {
                Session.api().getSessionById({id: this.sessionId}).then(res => {
                    setTimeout(() => {
                        this.$eventHub.$emit("conversation-polls", res.response.data.response.session.polls)
                    }, 1000)
                })
            },
			setupIntersectionObserver() {
				console.log("setupIntersectionObserver")
				const observer = new IntersectionObserver(
					(entries) => {
						entries.forEach((entry) => {
							if (this.activePoll?.poll && entry.target.classList.contains(`poll-${this.activePoll.poll.id}`)) {
								console.log("poll", entry.target)
								if (!entry.isIntersecting) {
									this.showPollVisibilityMessage = true
									console.log("showPollVisibilityMessage", true)
								} else {
									this.showPollVisibilityMessage = false
									console.log("showPollVisibilityMessage", false)
								}
							}
						})
					},
					{
						root: this.$refs.messages,
						threshold: 0
					}
				)

				// Add all poll elements to the observer
				const polls = this.$refs.messages ? this.$refs.messages.querySelectorAll(".poll") : []
				polls.forEach((poll) => {
					observer.observe(poll)
				})
			},
			scrollToPoll() {
                document.querySelector(".chatDialog__body").scrollTo({
                    top: document.querySelector(".poll-" + this.activePoll.poll.id).offsetTop - 100,
                    left: 0,
                    behavior: "smooth"
                })
            },
            openPolls() {
                if(document.querySelector(".mobileFooterNav div[data-target='polls']")) {
                    document.querySelector(".mobileFooterNav div[data-target='polls']").click()
                    this.$eventHub.$emit('poll-template:open', "Recent Polls")
                }
                else {
                    this.$eventHub.$emit('poll-template:open', "Recent Polls")
                }
            }
		}
    }
</script>