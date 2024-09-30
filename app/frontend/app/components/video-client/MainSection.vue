<template>
    <div
        v-touch:swipe.left="nextGrid"
        v-touch:swipe.right="prevGrid"
        :class="{
            'cm__fullScreen' : fullScreen,
            'cm__hl' : layoutPanels.vertical || layoutPanels.horizontal,
            'cm__sidebar__chat': sidebarPanels.chat,
            'cm__sidebar__invite': sidebarPanels.invite,
            'cm__sidebar__manage': sidebarPanels.manage,
            'cm__presenter__share': mainMode === 'share',
            'cm__presenter__camera': mainMode === 'presenter'
        }"
        class="cm">
        <transition
            mode="out-in"
            name="main">
            <div
                v-show="shareScreen && currentSharingRoomMemberName !== ''"
                class="cm__sharedBy">
                <span> Screen share: </span> {{ currentSharingRoomMemberName }}
            </div>
        </transition>
        <view-new-messages
            :room-info="roomInfo"
            :style="layoutPanels.vertical && !hideSidebar ? `right: ${widthChild + 15}px` : ''" />
        <notification :room-info="roomInfo" />

        <div
            v-if="presenterNotPresent"
            class="cm__presenterNotPresent">
            <div class="cm__presenterNotPresent__info">
                <m-icon>GlobalIcon-info</m-icon>
                {{ $t('components.video_client.main_section.if_creator_not_join_in_time', {creator: $t('dictionary.creator')}) }}
            </div>
            <div
                v-if="presenterNotPresentStopAt"
                class="cm__presenterNotPresent__counter">
                The session will exripe in <span>{{ presenterNotPresentStopAt | datetimeToSession(true) }}</span> minutes.
            </div>
        </div>

        <div
            v-if="roomInfo && roomMember"
            :class="{'cm__video__wrapper__grid': live, 'cm__video__wrapper__fullScreen' : fullScreen, 'cm__video__wrapper__sidebar': sidebar}"
            :style="{height: $device.mobile() ? `${bottomHeight}` : ''}"
            class="cm__video__wrapper">
            <div class="cm__loader">
                <div class="spinnerSlider">
                    <div class="bounceS1" />
                    <div class="bounceS2" />
                    <div class="bounceS3" />
                </div>
            </div>
            <!-- <div v-if="!live" class="cm__video__presenter">
        <span>Presenter</span>
        {{roomInfo.presenter_user.public_display_name}}
      </div> -->
            <div ref="presenterAudio" />

            <transition
                mode="out-in"
                name="main">
                <div
                    v-show="(live && (!isPinned || mainMode === 'share') && (layoutPanels.vertical || layoutPanels.horizontal || layoutPanels.presenterOnly)) || (live && fullScreen)"
                    :class="{'cm__h__video__wrapper' : layoutPanels.horizontal}"
                    class="cm__video">
                    <pinch-zoom
                        v-show="mainMode === 'share'"
                        ref="myPinch"
                        :background-color="false"
                        :disable-zoom-control="'disable'"
                        style="width: 100%; height: 100%;">
                        <div
                            id="shareVideo"
                            :key="0"
                            ref="shareVideo"
                            :class="{'cm__video__fullScreen' : fullScreen,
                                     'cm__video__share': mainMode === 'share',
                                     'cm__h__video': layoutPanels.horizontal}"
                            :style="mainMode === 'share' && $device.mobile() ? `height: ${bottomHeight}` : ''"
                            class="cm__video" />
                    </pinch-zoom>

                    <div
                        v-show="videoEnabled && mainMode === 'presenter'"
                        id="presenterVideo"
                        :key="0"
                        ref="presenterVideo"
                        :class="{'cm__video__fullScreen' : fullScreen,
                                 'cm__video__camera': mainMode === 'presenter',
                                 'cm__h__video': layoutPanels.horizontal}"
                        :style="$device.mobile() && $device.orientation === 'portrait' ? `height: ${bottomHeight}` : ''"
                        class="cm__video" />

                    <div
                        v-if="!videoEnabled && mainMode === 'presenter'"
                        :style="$device.mobile() ? `height: ${bottomHeight}` : ''"
                        class="cm__video mutedMain">
                        <img
                            v-if="getPresenter && getPresenter.avatar_url"
                            :src="getPresenter.avatar_url"
                            class="presenterVideo__avatar">
                        <svg
                            v-else
                            fill="none"
                            height="50%"
                            viewBox="0 0 60 60"
                            width="50%"
                            xmlns="http://www.w3.org/2000/svg">
                            <path
                                clip-rule="evenodd"
                                d="M17.5 17.5C17.5 10.5 23 5 30 5C37 5 42.5 10.5 42.5 17.5C42.5 24.5 37 30 30 30C23 30 17.5 24.5 17.5 17.5ZM52.5 47.5V52.5C52.5 54 51.5 55 50 55C48.5 55 47.5 54 47.5 52.5V47.5C47.5 43.25 44.25 40 40 40H20C15.75 40 12.5 43.25 12.5 47.5V52.5C12.5 54 11.5 55 10 55C8.5 55 7.5 54 7.5 52.5V47.5C7.5 40.5 13 35 20 35H40C47 35 52.5 40.5 52.5 47.5ZM30 25C25.75 25 22.5 21.75 22.5 17.5C22.5 13.25 25.75 10 30 10C34.25 10 37.5 13.25 37.5 17.5C37.5 21.75 34.25 25 30 25Z"
                                fill="#6F7073"
                                fill-rule="evenodd" />
                        </svg>
                    </div>
                </div>
            </transition>
            <transition
                mode="out-in"
                name="main">
                <div
                    v-show="live && isPinned && !layoutPanels.grid && mainMode === 'presenter'"
                    :key="1"
                    :class="{
                        'cm__grid' : mainMode === 'presenter',
                        'cm__pinned__h' : layoutPanels.horizontal && mainMode === 'presenter'}"
                    :style="{ right: mainMode === 'share' ? `${pinnedWidth}` : '',
                              height: $device.mobile() ? `${bottomHeight}` : ''}"
                    class="cm__video cm__pinned">
                    <pinned
                        :layout-panels="mainMode === 'presenter' ? {grid: true, horizontal: false} : {horizontal: true, grid: false}"
                        :max-width-sidebar="maxWidthSidebar"
                        :share="mainMode === 'share'"
                        :width="setWidth" />
                </div>
            </transition>

            <transition
                mode="out-in"
                name="main">
                <div
                    v-show="live"
                    :key="1"
                    :class="{
                        'cm__grid' : layoutPanels.grid,
                        'cm__h': layoutPanels.horizontal,
                        'cm__h__ipad': layoutPanels.horizontal && $device.ipad(),
                        'cs' : layoutPanels.vertical,
                        'presenterOnly' : layoutPanels.presenterOnly}"
                    :style="layoutPanels.horizontal && sidebarPanelsActive() ? `width: calc(100% - ${widthSidebar()})` : ''">
                    <participants
                        :layout-panels="layoutPanels"
                        :main-mode="mainMode"
                        :max-width-sidebar="maxWidthSidebar"
                        :width="setWidth"
                        :is-self-share="isSelfShare" />

                    <vue-resizable
                        v-if="layoutPanels.vertical && !$device.mobile() && !$device.ipad()"
                        ref="resizableComponent"
                        :active="['l']"
                        :disable-attributes="['w', 't', 'h']"
                        class="cs__drag"
                        drag-selector=".cs__drag"
                        style="position:absolute;"
                        @mount="setDefault"
                        @resize:start="eHandler"
                        @resize:move="eHandler"
                        @resize:end="eHandler" />
                </div>
            </transition>
            <div
                v-show="!live && !selfView"
                class="cm__video cm__video__empty">
                <div
                    ref="prevideo"
                    class="cm__video__text" />
            </div>
            <div
                v-if="!live && isPresenter && !isGoLiveNotShown && !selfView"
                class="cm__goLive__wrapper">
                <m-btn
                    :disabled="isGoLiveDisabled"
                    class="cm__goLive"
                    size="l"
                    type="save"
                    @click="goLive">
                    GO LIVE
                </m-btn>
            </div>
        </div>
        <transition
            mode="out-in"
            name="main">
            <tools
                v-show="!overlay"
                :class="{'cm__tools__wrapper__hide' : hideTools, 'cm__h__tools': layoutPanels.horizontal, 'cm__h__tools__ipad' : $device.ipad()}"
                :full-screen="fullScreen"
                :is-self-share="isSelfShare"
                :layout-panels="layoutPanels"
                :room="room"
                :room-info="roomInfo"
                :style="layoutPanels.vertical && !hideSidebar ? `width: calc(100% - ${widthChild}px)` : ''"
                @fullScreen="toggleFullScreen" />
        </transition>
    </div>
</template>

<script>
import VueResizable from "vue-resizable"
import Participants from './participants/Participants'
import Pinned from './participants/Pinned'
import Tools from './Tools.vue'
import utils from '@helpers/utils'
import Room from "@models/Room"
import ViewNewMessages from '../../components/video-client/chat/ViewNewMessages.vue'

import {createLocalVideoTrack} from 'webrtcservice-video'
import Notification from './chat/Notification.vue'
import {mapGetters} from 'vuex'

export default {
    components: {Tools, VueResizable, Participants, Pinned, ViewNewMessages, Notification},
    props: {
        // roomInfo: Object,
        // room: Object,
        sidebar: Boolean,
        tracks: Array,
        selfView: Boolean
    },
    data() {
        return {
            widthChild: 230,
            width: 230,
            leftChild: 0,
            left: 0,
            maxWidth: 0,
            live: false,
            hideSidebar: false,
            // videoTrack: null,
            fullScreen: false,
            timer: null,
            hideTools: false,
            settings: false,
            millsFromStart: -1,
            // statusChecked: false,
            videoEnabled: true,
            layoutSelect: false,
            participants: false,
            studio: false,
            shareScreen: false,
            mainTracksSubscribed: [], // tracks subscribed in update
            mainMode: "presenter", // presenter; share; pins
            isSharing: false,
            overlay: false,
            layoutPanels: {
                grid: true,
                vertical: false,
                horizontal: false,
                presenterOnly: false
            },
            sidebarPanels: {
                chat: false,
                invite: false,
                manage: false
            },
            shared: null,
            currentSharingRoomMemberName: "",
            bottomHeight: '220px',
            greenRoom: false,
            currentSharingRoomMemberId: null,
            isSelfShare: false,
            presenterNotPresent: false,
            presenterNotPresentStopAt: null
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "isLocalPins",
            "isPresenterPins",
            "room",
            "roomInfo",
            "participantsList"
        ]),
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isAwaiting() {
            return this.roomInfo && this.roomInfo.status === "awaiting"
        },
        isPresenter() {
            return this.currentUser?.id === this.roomInfo?.presenter_user?.id
        },
        isGoLiveDisabled() {
            return this.millsFromStart < 0 || this.roomInfo?.abstract_session?.autostart
        },
        isGoLiveNotShown() {
            return this.roomInfo?.abstract_session?.autostart
        },
        setWidth() {
            if (this.layoutPanels.vertical) {
                if (this.isPinned) utils.debounce(this.recalculateLayout(), 400)
                return this.widthChild + 'px'
            } else {
                return '100%'
            }
        },
        maxWidthSidebar() {
            if (this.sidebarPanels.chat && this.layoutPanels.vertical) {
                return document.querySelector(".client").getBoundingClientRect().width - 1070 + "px"
            } else {
                return "100%"
            }
        },
        pinnedWidth() {
            if (this.layoutPanels.vertical && this.sidebarPanelsActive()) return this.widthChild + (parseFloat(this.widthSidebar()) * 10) + "px"
            if (this.layoutPanels.vertical && !this.sidebarPanelsActive()) return this.widthChild + "px"
            if (!this.layoutPanels.vertical && this.sidebarPanelsActive()) return (parseFloat(this.widthSidebar()) * 10) + "px"
        },
        getPresenter() {
            return this.roomInfo?.presenter_user
        },
        isPinned() {
            return this.isLocalPins || this.isPresenterPins
        }
    },
    watch: {
        mainMode: {
            handler(val) {
                if (!this.$device.mobile()) return
                this.callToggleFullScreen()
                // if(this.$device.ios()) {
                //   this.$nextTick(()=> {
                //     this.iosFullScreen(true);
                //   })
                // } else {
                //   this.$eventHub.$emit('tw-toggleFullScreen');
                // }
                // else if(this.shared){
                //   // if(this.$device.ios()) {
                //   //   this.$nextTick(()=> {
                //   //     this.iosFullScreen(false);
                //   //   })
                //   // } else {
                //   //   this.$eventHub.$emit('tw-toggleFullScreen');
                //   // }
                //   this.$eventHub.$emit('tw-toggleFullScreen');
                // }
            },
            deep: true,
            immediate: true
        },
        currentSharingRoomMemberId: {
            handler(val) {
                if (val === this.roomInfo?.current_room_member?.id) {
                    this.selfShare()
                    this.isSelfShare = true
                } else {
                    this.isSelfShare = false
                }
            },
            deep: true,
            immediate: true
        },
        fullScreen(val) {
            if (!val) {
                setTimeout(() => {
                    this.recalculateLayout()
                }, 600)
            }
        },
        layoutPanels: {
            handler(val) {
                if (val.grid) {
                    setTimeout(() => {
                        this.recalculateLayout()
                    }, 600)
                }
            },
            deep: true
        },
        roomInfo: {
            handler(val) {
                if (val) {
                    this.live = !this.isAwaiting
                    if (!this.live) {
                        createLocalVideoTrack().then((track) => {
                            if (!this.greenRoom) this.$refs.prevideo.appendChild(track.attach())
                            this.greenRoom = true
                        })
                    }
                    if(val.abstract_session.polls) {
                        this.$eventHub.$emit("conversation-polls", val.abstract_session.polls)
                    }
                }
            },
            deep: true,
            immediate: true
        },
        shareScreen(val) {
            if (!val) {
                this.recalculateLayout()
                setTimeout(() => {
                    this.recalculateLayout()
                }, 300)
            }
        },
        isLocalPins(val) {
            if (!val) {
                this.recalculateLayout()
                setTimeout(() => {
                    this.recalculateLayout()
                }, 300)
            }
        },
        isPresenterPins(val) {
            if (!val) {
                this.recalculateLayout()
                setTimeout(() => {
                    this.recalculateLayout()
                }, 300)
            }
        }
        // millsFromStart(val) {
        //   if(val > 2 && !this.statusChecked && !this.live) {
        //     this.statusChecked = true
        //     this.$eventHub.$emit("tw-updateRoomInfo")
        //   }
        // }
    },
    mounted() {
        this.$eventHub.$on("tw-roomCreated", () => {
            this.roomCreated()
        })

        window.onorientationchange = () => {
            this.resetTimer()
        }
        if (this.$device.mobile() && this.$device.orientation == 'landscape') {
            this.overlay = true
            this.$eventHub.$emit("mobileOverlay", true)
        }
        window.attachVideoTrack = this.attachVideoTrack

        this.$eventHub.$on("tw-enableVideo", flag => {
            this.videoEnabled = !flag
            if (this.isPresenter && this.shared) this.videoEnabled = true
        })
        this.$eventHub.$on("tw-toggleGrid", flag => {
            this.horizontalScroll()
            this.resetLayout()
            this.recalculateLayout()
            this.layoutPanels.grid = flag
        })
        this.$eventHub.$on("tw-toggleVertical", flag => {
            this.horizontalScroll()
            this.resetLayout()
            this.layoutPanels.vertical = flag
        })
        this.$eventHub.$on("tw-toggleHorizontal", flag => {
            this.resetLayout()
            this.layoutPanels.horizontal = flag
            this.$nextTick(() => {
                this.horizontalScroll()
            })
        })
        this.$eventHub.$on("tw-togglePresenterOnly", flag => {
            this.horizontalScroll()
            this.resetLayout()
            this.layoutPanels.presenterOnly = flag
        })
        this.$eventHub.$on("tw-layoutSelect", flag => {
            this.layoutSelect = flag
        })
        this.$eventHub.$on("tw-participantsSelect", flag => {
            this.participants = flag
        })
        this.$eventHub.$on("tw-studioSelect", flag => {
            this.studio = flag
        })
        this.$eventHub.$on("tw-shareScreenSelect", flag => {
            this.shareScreen = flag
            this.horizontalScroll()
        })
        this.$eventHub.$on('tw-hideSidebar', (hideSidebar) => {
            this.hideSidebar = hideSidebar
        })
        this.maxWidth = document.querySelector(".client").getBoundingClientRect().width * 0.54
        window.addEventListener("resize", () => {
            this.maxWidth = document.querySelector(".client").getBoundingClientRect().width * 0.54
        })
        this.$eventHub.$on("Settings", (settings) => {
            this.settings = settings
        })

        document.querySelector('html').classList.add('videoClient')
        this.listenTimer()

        const debouncedRecalculateLayout = utils.debounce(this.recalculateLayout, 400)

        window.addEventListener("resize", () => {
            if (this.$device.mobile()) {
                this.bottomHeightMath()
                if (this.sidebarPanels.chat && this.$device.orientation == 'landscape') {
                    document.querySelector('.client__header').style.zIndex = 1
                    document.querySelector('.client__header').style.position = 'unset'
                } else if (this.$device.orientation == 'portrait') {
                    document.querySelector('.client__header').style.position = 'fixed'
                    document.querySelector('.client__header').style.zIndex = 999
                } else {
                    document.querySelector('.client__header').style.zIndex = 999
                }
            }
            debouncedRecalculateLayout()
        })
        if (this.$device.mobile()) {
            this.bottomHeightMath()
            if (this.isPinned || this.mainMode === 'share') {
                this.$eventHub.$emit('tw-toggleHorizontal', true)
            } else {
                this.$eventHub.$emit('tw-toggleGrid', true)
            }
        }
        debouncedRecalculateLayout()

        this.$eventHub.$on("tw-toggleSidebar", flag => {
            setTimeout(() => {
                this.recalculateLayout()
            }, 500)
            if (flag && !this.shared) {
            } else {
                this.recalculateLayout()
            }
        })

        this.$eventHub.$on("tw-toggleChat", flag => {
            this.sidebarPanels.chat = flag
            if (this.sidebarPanels.chat && this.$device.mobile()) {
                this.$eventHub.$emit("tw-toggleInvite", false)
                this.$eventHub.$emit("tw-toggleManage", false)
            }
            if (this.sidebarPanels.chat && this.$device.mobile() && this.$device.orientation == 'landscape') {
                document.querySelector('.client__header').style.zIndex = 1
                document.querySelector('.client__header').style.position = 'unset'
            } else if (this.$device.mobile()) {
                document.querySelector('.client__header').style.position = 'fixed'
                document.querySelector('.client__header').style.zIndex = 999
            } else {
                document.querySelector('.client__header').style.zIndex = 999
            }
        })

        this.$eventHub.$on("tw-toggleInvite", flag => {
            this.sidebarPanels.invite = flag
        })
        this.$eventHub.$on("tw-toggleManage", flag => {
            this.sidebarPanels.manage = flag
        })

        this.$eventHub.$on("recalculateLayout", () => {
            this.recalculateLayout()
        })

        this.$eventHub.$on("tw-toggleToSidebarIfGrid", () => {
            if (this.layoutPanels.grid) {
                if (this.$device.mobile()) {
                    this.$eventHub.$emit('tw-toggleHorizontal', true)
                } else {
                    this.$eventHub.$emit('tw-toggleVertical', true)
                }
            }
        })

        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.pinnedUsers, (data) => {
            if (data?.pinned_members?.length > 0 && this.layoutPanels.grid) {
                if (this.$device.mobile() && this.mainMode !== 'share') {
                    this.$eventHub.$emit('tw-toggleHorizontal', true)
                } else if (this.mainMode !== 'share') {
                    this.$eventHub.$emit('tw-toggleVertical', true)
                }
            }
        })

        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.noPresenterStopScheduled, (data) => {
            this.presenterNotPresent = true
            this.presenterNotPresentStopAt = new Date(data.stop_at + "000").getTime()
        })
        this.$eventHub.$on(presenceImmersiveRoomsChannelEvents.presenterJoined, () => {
             this.presenterNotPresent = false
        })

        setInterval(() => {
            if (this.roomInfo)
                this.millsFromStart = new Date().getTime() - new Date(this.roomInfo.abstract_session.start_at).getTime()
        }, 500)

        this.$eventHub.$on("tw-goLive-event", () => {
            this.live = true
            this.recalculateLayout()
            let isGuest = this.roomMember.guest
            Room.api().getRoom({id: this.roomInfo.id, isGuest}).then((res) => {
                this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                this.$eventHub.$emit("tw-roomInfoLoaded", res.response.data.response.room)
                this.$store.dispatch("VideoClient/setRoomInfo", res.response.data.response.room)
                // if(!this.selfView){
                this.$eventHub.$emit("tw-openSelfView")
                // }
            })
        })

        this.$eventHub.$on("tw-selfShare:enable", () => {
          this.currentSharingRoomMemberId = this.roomMember.id
        })

        this.$eventHub.$on("tw-selfShare:disable", () => {
          this.currentSharingRoomMemberId = -1
        })

        // this.$eventHub.$on("tw-selfView-goLive", (tracks)=>{
        //   if(!this.greenRoom) this.$refs.prevideo.appendChild(track.attach())
        //   this.greenRoom = true;
        // })

        window.recalculateLayout = this.recalculateLayout
    },
    destroyed() {
        document.querySelector('html').classList.remove('videoClient')
    },
    methods: {
        // iosFullScreen(val){
        //   let elem = document.querySelector('.cm__video__share video');
        //   if(elem && val) elem.webkitEnterFullscreen();
        //   if(elem && !val) elem.webkitExitFullscreen();
        // },
        callToggleFullScreen: utils.debounce(function () {
            let elem = document.querySelector('.GlobalIcon-fullScreen')
            if (elem) elem.click()
        }, 500),
        selfShare() {
            this.$eventHub.$emit('tw-toggleGrid', true)
        },
        nextGrid() {
            this.$eventHub.$emit('tw-nextGrid')
        },
        prevGrid() {
            this.$eventHub.$emit('tw-prevGrid')
        },
        bottomHeightMath() {
            var tape = document.querySelectorAll('.cm__h__users')
            var tools = document.querySelector('.cm__tools__wrapper')
            var header = document.querySelector('.client__header')
            var padding
            if (this.$device.mobile() && this.$device.orientation === 'portrait' && this.layoutPanels.grid && tools && header) {
                this.bottomHeight = document.documentElement.clientHeight - header.getBoundingClientRect().height - tools.getBoundingClientRect().height - 10 + "px"
                return
            }
            if (this.$device.mobile() && this.$device.orientation === 'portrait' && this.mainMode === 'share' && tape[1] && tools && header) {
                padding = parseInt(window.getComputedStyle(tape[1], null)?.getPropertyValue('padding-top'))
                this.bottomHeight = document.documentElement.clientHeight - header.getBoundingClientRect().height - tape[1].getBoundingClientRect().height + padding - tools.getBoundingClientRect().height - 10 + "px"
                return
            }
            if (this.$device.mobile() && this.$device.orientation === 'portrait' && tape[0] && tools && header) {
                padding = parseInt(window.getComputedStyle(tape[0], null)?.getPropertyValue('padding-top'))
                this.bottomHeight = document.documentElement.clientHeight - header.getBoundingClientRect().height - tape[0].getBoundingClientRect().height + padding - tools.getBoundingClientRect().height - 10 + "px"
                return
            }
            if (this.$device.mobile() && this.$device.orientation === 'landscape' && header) {
                return this.bottomHeight = document.documentElement.clientHeight - header.getBoundingClientRect().height + "px"
            }
        },
        horizontalScroll() {
            function scroll(e) {
                if (!document.querySelector('.cm__h__users') || document.querySelector('.presenterOnly__participants')) return
                this.scrollLeft -= (e.wheelDelta / 5)
            }

            if (!document.querySelector('.cm__h__users')) return
            document.querySelector('.cm__h__users').addEventListener('mousewheel', scroll, false)
        },
        widthSidebar() {
            return '40rem'
        },
        sidebarPanelsActive() {
            if (this.sidebarPanels.invite || this.sidebarPanels.manage || this.sidebarPanels.chat) return true
            return false
        },
        resetLayout() {
            Object.keys(this.layoutPanels).forEach(key => {
                this.layoutPanels[key] = false
            })
        },
        setDefault(data) {
            this.leftChild = data.left
            this.left = data.left
            this.widthChild = this.width
        },
        eHandler(data) {
            if (this.left != data.left && this.maxWidth >= this.width + (this.leftChild - data.left) && this.width <= this.width + (this.leftChild - data.left)) {
                this.left = data.left
                this.calcWidth(data.left)
            }
        },
        calcWidth(data) {
            return this.widthChild = this.width + (this.leftChild - data)
        },
        listenTimer() {
            this.resetTimer()
            document.addEventListener('click', () => this.resetTimer())
            document.addEventListener('mousemove', () => this.resetTimer())
            document.addEventListener('mousedown', () => this.resetTimer())
            document.addEventListener('touchstart', () => this.resetTimer())
        },
        resetTimer() {
            this.$eventHub.$emit("mobileOverlay", false)
            this.overlay = false
            this.hideTools = false
            clearTimeout(this.timer)
            this.timer = setTimeout(() => {
                this.hiddenTools()
                if (this.$device.mobile() && this.$device.orientation == 'landscape' && !this.sidebarPanels.chat && !this.sidebarPanels.invite && !this.sidebarPanels.manage && !this.settings) {
                    this.overlay = true
                    this.$eventHub.$emit("mobileOverlay", true)
                }
            }, 3000)
        },
        hiddenTools() {
            if (!this.settings && !this.layoutSelect && !this.participants && !this.studio && !this.shareScreen) {
                this.hideTools = true
            }
        },
        toggleFullScreen() {
            this.fullScreen = !this.fullScreen
        },
        // ---------
        goLive() {
            this.$eventHub.$emit("tw-goLive-new", this.tracks)
            this.live = true
            this.recalculateLayout()
            Room.api().activateRoom({id: this.roomInfo.id}).then((res) => {
                this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
                this.$eventHub.$emit("tw-roomInfoLoaded", res.response.data.response.room)
                setTimeout(() => {
                    this.$eventHub.$emit("tw-roomCreated")
                }, 1000)
            })
        },
        getPresenterRM() {
            return this.roomInfo?.room_members.find(rm => rm.room_member.kind === "presenter")?.room_member
        },
        roomCreated() {
            window.findParticipant = this.findParticipant
            setTimeout(() => {
                this.subsribeToWebrtcserviceEvents()
                this.loadPresenterTrack()
                this.loadSharedTrack()
            }, 2000) // time to init
        },
        subsribeToWebrtcserviceEvents() {
            // added new track, catch if presenter or share
            this.room.on('trackPublished', (track, participant) => {
                if (track.kind === "audio") return

                if (track.trackName === "share") {
                    this.currentSharingRoomMemberId = JSON.parse(participant.identity)?.mid || -1
                    let sharedUser = this.participantsList.find(e => e.id === this.currentSharingRoomMemberId)
                    if (sharedUser) {
                        this.currentSharingRoomMemberName = sharedUser.user ? sharedUser.user.public_display_name : sharedUser.display_name
                    }
                    setTimeout(() => {
                        this.initSharing(track)
                    }, 1500) // time to init
                }

                let identity = JSON.parse(participant.identity)
                if (this.getPresenterRM().id === identity.mid && track.trackName !== "share") {
                    setTimeout(() => {
                        this.initTrack(track)
                    }, 1500)
                }
            })
            // delete track, catch if presenter or share
            this.room.on('trackUnpublished', (track, participant) => {
                if (track.kind === "audio") return

                if (track.trackName === "share") {
                    this.shareScreen = false
                    this.mainMode = "presenter"
                    this.currentSharingRoomMemberId = -1
                    this.currentSharingRoomMemberName = ""
                    this.$eventHub.$emit("tw-sharingStatus", false)

                    track?.track?.detach().forEach(function (element) {
                        element.srcObject = null
                        element.remove()
                    })

                    // remove when webrtcservice stable it
                    let el = document.querySelector(`#shareVideo video`)
                    if (el) {
                        el.srcObject = null
                        el.remove()
                    }
                }

                // Presenter track
                let identity = JSON.parse(participant.identity)
                if (this.getPresenterRM().id === identity.mid && track.trackName !== "share") {
                    track?.track?.detach().forEach(function (element) {
                        element.srcObject = null
                        element.remove()
                    })
                    // remove when webrtcservice stable it
                    let el = document.querySelector(`#presenterVideo video`)
                    if (el) { // remove if excists
                        el.srcObject = null
                        el.remove()
                    }
                }
            })

            // init presenter track if presenter connected
            this.room.on("participantConnected", (participant) => {
                let identity = JSON.parse(participant.identity)
                if (this.getPresenterRM().id === identity.mid) {
                    setTimeout(() => {
                        this.loadPresenterTrack()
                    }, 600)
                }
            })

            // Clear share and presenter if disconectd
            this.room.on("participantDisconnected", (participant) => {
                participant.videoTracks.forEach(track => {
                    if (track.trackName === "share") { // clear share tracks
                        this.shareScreen = false
                        this.mainMode = "presenter"
                        this.currentSharingRoomMemberId = -1
                        this.currentSharingRoomMemberName = ""
                        this.$eventHub.$emit("tw-sharingStatus", false)
                        // remove when webrtcservice stable it
                        let el = document.querySelector(`#shareVideo video`)
                        if (el) {
                            el.srcObject = null
                            el.remove()
                        }
                    } else { // clear presenter tracks
                        let identity = JSON.parse(participant.identity)
                        if (this.getPresenterRM().id === identity.mid) {
                            this.videoEnabled = false
                            // remove when webrtcservice stable it
                            let el = document.querySelector(`#presenterVideo video`)
                            if (el) { // remove if excists
                                el.srcObject = null
                                el.remove()
                            }
                        }
                    }
                })
            })

            let participant = this.findParticipant(this.getPresenterRM()?.id)
            if (!participant) return
            participant.on('trackPublished', track => {
                if (track.trackName !== "share" && track.kind !== "audio") {
                    this.initTrack(track)
                }
            })
        },
        loadPresenterTrack() {  // load page and show presenter track
            let participant = this.findParticipant(this.getPresenterRM()?.id)
            if (!participant) {
                this.videoEnabled = false
                return
            }
            participant.videoTracks.forEach(track => {
                if (track.track.name !== "share") {
                    this.initTrack(track)
                }
            })
        },
        loadSharedTrack() { // load page and have share
            let shareTrack = null
            this.room.participants.forEach(participant => {
                participant.videoTracks.forEach(track => {
                    if (track.trackName === "share") {
                        shareTrack = track
                        this.currentSharingRoomMemberId = JSON.parse(participant.identity)?.mid || -1
                        let sharedUser = this.participantsList.find(e => e.id === this.currentSharingRoomMemberId)
                        if (sharedUser) {
                            this.currentSharingRoomMemberName = sharedUser.user ? sharedUser.user.public_display_name : sharedUser.display_name
                        }
                    }
                })
            })
            this.room.localParticipant.videoTracks.forEach(track => {
                if (track.trackName === "share") {
                    shareTrack = track
                }
            })
            if (shareTrack) {
                this.initSharing(shareTrack)
            }
        },
        initTrack(t) { // init presenter track
            let track = t.track ? t.track : t

            let el = document.querySelector(`#presenterVideo video`)
            if (el) { // remove if excists
                el.srcObject = null
                el.remove()
            }

            let div = document.querySelector(`#presenterVideo`)
            div.appendChild(track.attach())

            this.videoEnabled = track.isEnabled

            track.on('disabled', () => { // subscribe to track events
                this.videoEnabled = false
            })
            track.on('enabled', () => {
                this.videoEnabled = true
            })
            track.on('trackDisabled', () => {
                this.videoEnabled = false
            })
            track.on('trackEnabled', () => {
                this.videoEnabled = true
            })
        },
        initSharing(t) { // init share track
            let track = t.track ? t.track : t

            if (track?.setPriority) track?.setPriority("high")

            let el = document.querySelector(`#shareVideo video`)
            if (el) {
                el.srcObject = null
                el.remove()
            }

            let div = document.querySelector(`#shareVideo`)
            div.appendChild(track.attach())

            this.shareScreen = true
            this.mainMode = "share"

            this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
            this.$eventHub.$emit("tw-sharingStatus", true)
        },
        findParticipant(id) {
            if (!id) return null
            let p = null
            if (this.isPresenter) {
                p = this.room.localParticipant
            } else {
                this.room.participants.forEach(participant => {
                    let identity = JSON.parse(participant.identity)
                    if (identity.mid === id) {
                        p = participant
                    }
                })
            }
            return p
        },
        recalculateLayout() {
            this.bottomHeightMath()
            if (this.layoutPanels.grid || this.isPinned) {
                const gallery = document.querySelector(".cm")
                if (!gallery) return
                let aspectRatio = 4 / 3
                let tilePadding
                if (this.$device.mobile() && this.$device.orientation == "portrait") {
                    aspectRatio = 3 / 4
                } else if (this.$device.mobile() && this.$device.orientation == "landscape") {
                    aspectRatio = 4 / 3
                }
                if (this.$device.mobile()) {
                    //mobile
                    tilePadding = 0
                } else {
                    //desktop
                    tilePadding = 10
                }
                let screenWidth = document.querySelector(".cm").getBoundingClientRect().width
                let screenHeight = document.querySelector(".cm").getBoundingClientRect().height
                if (this.$device.mobile()) {
                    if (document.querySelector(".cm__pinned")) {
                        screenWidth = document.querySelector(".cm__pinned").getBoundingClientRect().width
                    }
                    if (document.querySelector(".cm__video__wrapper__grid")) {
                        screenWidth = document.querySelector(".cm__video__wrapper__grid").getBoundingClientRect().width
                    }
                    screenHeight = this.bottomHeight.slice(0, -2)
                } else if (!this.layoutPanels.grid && this.isPinned) {
                    if (document.querySelector(".cm__pinned")) {
                        screenWidth = document.querySelector(".cm__pinned").getBoundingClientRect().width
                        screenHeight = document.querySelector(".cm__pinned").getBoundingClientRect().height
                    }
                }
                var videoCount = document.querySelectorAll(".grid__tile").length
                if (this.layoutPanels.grid && this.$device.mobile()) {
                    videoCount = document.querySelectorAll(".grid__tile__not_pinned").length - document.querySelectorAll(".participantsTile__notShow").length
                } else if (this.layoutPanels.grid && !this.$device.mobile()) {
                    videoCount = document.querySelectorAll(".grid__tile__not_pinned").length
                } else if (!this.layoutPanels.grid && this.isPinned) {
                    videoCount = document.querySelectorAll(".grid__tile__pinned").length
                }
                if(!this.selfShare) videoCount--

                const {width, height, cols, rows} = this.calculateLayout(
                    screenWidth,
                    screenHeight,
                    videoCount,
                    aspectRatio,
                    tilePadding
                )
                gallery?.style?.setProperty("--width", width - tilePadding + "px")
                gallery?.style?.setProperty("--height", height - tilePadding / aspectRatio + "px")
                gallery?.style?.setProperty("--cols", cols + "")
                gallery?.style?.setProperty("--rows", rows + "")
            }
        },
        calculateLayout(
            containerWidth,
            containerHeight,
            videoCount,
            aspectRatio,
            tilePadding
        ) {
            let bestLayout = {
                cols: 0,
                rows: 0,
                width: 0,
                height: 0
            }
            for (let cols = 1; cols <= videoCount; cols++) {
                var rows = Math.ceil(videoCount / cols)
                var containerRatio = containerWidth / containerHeight
                var gridRatio = aspectRatio * cols / rows
                if (containerRatio / gridRatio > 1) {
                    var height = containerHeight / rows
                    var width = height * aspectRatio
                } else {
                    var width = containerWidth / cols
                    var height = width / aspectRatio
                }

                if (width > bestLayout.width) {
                    bestLayout = {
                        width,
                        height,
                        rows,
                        cols
                    }
                } else {
                    break
                }
            }
            return bestLayout
        }
    }
}
</script>