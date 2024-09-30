<template>
    <div
        v-if="room"
        :class="{'cm__tools__wrapper__ipad' : $device.ipad()}"
        class="cm__tools__wrapper">
        <div
            v-if="$device.mobile()"
            class="cm__tools__wrapper__row">
            <div class="display__flex">
                <div class="cm__tools__mobile">
                    <m-icon
                        ref="mobileOption"
                        :class="{'cm__tools__mobile__icon__active': mobileOption}"
                        :name="'GlobalIcon-dots-3'"
                        class="cm__tools__mobile__icon"
                        size="0"
                        @click="toggleMobileOption" />
                    <select-options
                        v-show="settings"
                        v-click-outside="checkTargetOptions"
                        :class="{'cm__tools__mobile__list' : $device.mobile()}"
                        :mobile="$device.mobile()"
                        :room="room"
                        :room-info="roomInfo"
                        :settings="settings"
                        @closeSettings="closeSettings"
                        @deviceUpdated="deviceUpdated" />
                    <div
                        v-if="mobileOption"
                        v-click-outside="checkMobileOption"
                        :class="{'cm__tools__mobile__select' : $device.mobile(), 'cm__tools__mobile__select__presenter' : isPresenter}"
                        class="cm__tools__select">
                        <div
                            ref="selectOptions"
                            :class="{'cm__tools__select__active': settings}"
                            class="cm__tools__select__item cm__tools__select__item__specific"
                            @click="() => { participantsSelect(); toggleSettings(); }">
                            {{ $t('frontend.app.components.video_client.tools.settings') }}
                            <m-icon
                                v-if="settings"
                                class="cm__tools__select__active__icon"
                                size="16">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            v-if="isPresenter"
                            :class="{'cm__tools__select__active': more.manage}"
                            class="cm__tools__select__item cm__tools__select__item__specific"
                            @click="() => { participantsSelect(); toggleManage(); }">
                            {{ $t('frontend.app.components.video_client.tools.manage_participants') }}
                            <m-icon
                                v-if="more.manage"
                                class="cm__tools__select__active__icon"
                                size="16">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            v-if="isPresenter"
                            :class="{'cm__tools__select__active': more.invite}"
                            class="cm__tools__select__item cm__tools__select__item__specific"
                            @click="() => { participantsSelect(); toggleInvite(); }">
                            {{ $t('frontend.app.components.video_client.tools.invite_participants') }}
                            <m-icon
                                v-if="more.invite"
                                class="cm__tools__select__active__icon"
                                size="16">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            v-else
                            :class="{'cm__tools__select__active': more.manage}"
                            class="cm__tools__select__item cm__tools__select__item__specific"
                            @click="() => { participantsSelect(); toggleManage(); }">
                            {{ $t('frontend.app.components.video_client.tools.participants') }}
                            <m-icon
                                v-if="more.manage"
                                class="cm__tools__select__active__icon"
                                size="16">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            :class="{'cm__tools__select__active': more.polls}"
                            class="cm__tools__select__item cm__tools__select__item__specific"
                            @click="openCreatePolls">
                            Polls
                        </div>
                        <div
                            v-if="isPresenter"
                            class="cm__tools__select__item cm__tools__select__item__specific">
                            {{ $t('frontend.app.components.video_client.tools.participants_screen_share') }}
                            <m-toggle
                                :value="roomInfo && roomInfo.is_screen_share_available"
                                @change="toggleShareForAll" />
                        </div>
                        <div
                            v-if="isSharePresenterAvailable"
                            class="cm__tools__select__item"
                            @click="() => { shareScreenSelect(); enableShare(); }">
                            {{ shareScreen ? $t('frontend.app.components.video_client.tools.stop_share') : $t('frontend.app.components.video_client.tools.start_share') }}
                        </div>
                    </div>
                </div>
                <!-- <div class="cm__tools__mobile">
          <m-icon ref="selectOptions" @click="toggleSettings()" size="0" v-tooltip="'A/V Settings'"
                  class="cm__tools__mobile__icon"
                  :class="{'cm__tools__mobile__icon__active' : settings}">GlobalIcon-settings</m-icon>

        </div> -->
            </div>
            <div class="display__flex">
                <div class="cm__tools__mobile">
                    <m-icon
                        v-tooltip="videoMuted ? $t('frontend.app.components.video_client.tools.tooltips.camera_off') : $t('frontend.app.components.video_client.tools.tooltips.camera_on')"
                        :class="{'cm__tools__mobile__icon__active': !videoMuted}"
                        :name="!videoMuted ? 'GlobalIcon-stream-video':'GlobalIcon-video-off'"
                        class="cm__tools__mobile__icon"
                        size="0"
                        @click="toggleVideoMute" />
                </div>
                <div class="cm__tools__mobile">
                    <m-icon
                        v-tooltip="audioMuted ? $t('frontend.app.components.video_client.tools.tooltips.mic_off') : $t('frontend.app.components.video_client.tools.tooltips.mic_on')"
                        :class="{'cm__tools__mobile__icon__active': !audioMuted}"
                        :name="!audioMuted ? 'GlobalIcon-mic':'GlobalIcon-mic-off'"
                        class="cm__tools__mobile__icon cm__tools__icon__mic"
                        size="0"
                        @click="toggleAudioMute" />
                </div>
                <div class="cm__tools__mobile">
                    <div
                        v-if="isChatAllowed"
                        v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.chat')"
                        class="cm__tools__icon__message">
                        <div
                            v-show="newMessages > 0"
                            class="cm__tools__icon__message__new" />
                        <m-icon
                            :class="{'cm__tools__mobile__icon__active' : more.chat}"
                            class="cm__tools__mobile__icon"
                            size="0"
                            @click="toggleChat">
                            GlobalIcon-message-square
                        </m-icon>
                    </div>
                </div>
            </div>
            <div class="display__flex">
                <div class="cm__tools__mobile">
                    <div
                        v-if="layoutSelect"
                        v-click-outside="checkTargetLayout"
                        :class="{'cm__tools__mobile__sidebar__pin' : isPresenterPins}"
                        class="cm__tools__select cm__tools__mobile__sidebar">
                        <div
                            v-if="!isPresenterPins"
                            :class="{'cm__tools__select__active': layoutPanels.grid}"
                            class="cm__tools__select__item"
                            @click="toggleGrid()">
                            <m-icon class="cm__tools__select__icon">
                                GlobalIcon-Grid
                            </m-icon>
                            {{ $t('frontend.app.components.video_client.tools.layouts.grid') }}
                            <m-icon
                                v-if="layoutPanels.grid"
                                class="cm__tools__select__check"
                                size="0">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            v-if="!$device.mobile()"
                            :class="{'cm__tools__select__active': layoutPanels.vertical}"
                            class="cm__tools__select__item"
                            @click="toggleVertical()">
                            <m-icon class="cm__tools__select__icon">
                                GlobalIcon-sidebar
                            </m-icon>
                            {{ $t('frontend.app.components.video_client.tools.layouts.vertical') }}
                            <m-icon
                                v-if="layoutPanels.vertical"
                                class="cm__tools__select__check"
                                size="0">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            :class="{'cm__tools__select__active': layoutPanels.horizontal}"
                            class="cm__tools__select__item"
                            @click="toggleHorizontal()">
                            <m-icon class="cm__tools__select__icon cm__tools__select__horizontal">
                                GlobalIcon-sidebar
                            </m-icon>
                            {{ $t('frontend.app.components.video_client.tools.layouts.horizontal') }}
                            <m-icon
                                v-if="layoutPanels.horizontal"
                                class="cm__tools__select__check"
                                size="0">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                        <div
                            v-if="!$device.mobile()"
                            :class="{'cm__tools__select__active': layoutPanels.presenterOnly}"
                            class="cm__tools__select__item"
                            @click="togglePresenterOnly()">
                            <m-icon class="cm__tools__select__icon">
                                GlobalIcon-square
                            </m-icon>
                            {{ $t('frontend.app.components.video_client.tools.layouts.presenter_only') }}
                            <m-icon
                                v-if="layoutPanels.presenterOnly"
                                class="cm__tools__select__check"
                                size="0">
                                GlobalIcon-check
                            </m-icon>
                        </div>
                    </div>
                    <m-icon
                        v-if="!isLivestream"
                        ref="selectLayout"
                        v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.layout')"
                        :class="{'cm__tools__icon__active' : layoutSelect,
                                 'GlobalIcon-sidebar': layoutPanels.vertical,
                                 'GlobalIcon-Grid': layoutPanels.grid,
                                 'cm__tools__select__horizontal GlobalIcon-sidebar': layoutPanels.horizontal,
                                 'GlobalIcon-square': layoutPanels.presenterOnly}"
                        class="cm__tools__mobile__icon cm__tools__icon__sidebar"
                        size="0"
                        @click="toggleLayoutSelect()" />
                </div>
                <div
                    v-if="$device.os != 'ios'"
                    class="cm__tools__mobile">
                    <m-icon
                        v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.full_screen')"
                        :class="{'cm__tools__mobile__icon__active' : isFullScreen}"
                        class="cm__tools__mobile__icon"
                        size="0"
                        @click="toggleFullScreen()">
                        GlobalIcon-fullScreen
                    </m-icon>
                </div>
                <div class="cm__tools__mobile">
                    <m-icon
                        v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.exit')"
                        class="cm__tools__mobile__icon"
                        size="0"
                        @click="exit">
                        GlobalIcon-exit
                    </m-icon>
                </div>
            </div>
        </div>
        <div
            v-else
            class="cm__tools__wrapper__row">
            <div class="display__flex">
                <div
                    v-tooltip="videoMuted ? $t('frontend.app.components.video_client.tools.tooltips.camera_off') : $t('frontend.app.components.video_client.tools.tooltips.camera_on')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active': !videoMuted}"
                        :name="!videoMuted ? 'GlobalIcon-stream-video':'GlobalIcon-video-off'"
                        class="cm__tools__icon cm__tools__double"
                        size="0"
                        @click="toggleVideoMute" />
                    <m-icon
                        ref="videoSelect"
                        :class="{'cm__tools__angle__active' : vidSettings}"
                        class="cm__tools__angle"
                        @click="toggleSettings(false, true)">
                        GlobalIcon-angle-down
                    </m-icon>
                </div>
                <div
                    v-tooltip="audioMuted ? $t('frontend.app.components.video_client.tools.tooltips.mic_off'): $t('frontend.app.components.video_client.tools.tooltips.mic_on')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active': !audioMuted}"
                        :name="!audioMuted ? 'GlobalIcon-mic':'GlobalIcon-mic-off'"
                        class="cm__tools__icon cm__tools__double cm__tools__icon__mic"
                        size="0"
                        @click="toggleAudioMute" />
                    <m-icon
                        ref="audioSelect"
                        :class="{'cm__tools__angle__active' : micSettings}"
                        class="cm__tools__angle"
                        @click="toggleSettings(true, false)">
                        GlobalIcon-angle-down
                    </m-icon>
                </div>
            </div>
            <select-options
                v-show="settings"
                v-click-outside="micSettings ? checkAudioTarget : checkVideoTarget"
                :mic-settings="micSettings"
                :mobile="$device.mobile()"
                :room="room"
                :room-info="roomInfo"
                :settings="settings"
                :vid-settings="vidSettings"
                @closeSettings="closeSettings"
                @deviceUpdated="deviceUpdated" />
            <div class="display__flex">
                <div
                    v-if="participants && isPresenter"
                    v-click-outside="checkTargetParticipants"
                    class="cm__tools__select">
                    <div
                        v-if="isPresenter"
                        :class="{'cm__tools__select__active': more.manage}"
                        class="cm__tools__select__item cm__tools__select__item__specific"
                        @click="() => { participantsSelect(); toggleManage(); }">
                        {{ $t('frontend.app.components.video_client.tools.manage_participants') }}
                        <m-icon
                            v-if="more.manage"
                            class="cm__tools__select__active__icon"
                            size="16">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                    <div
                        v-if="isPresenter"
                        :class="{'cm__tools__select__active': more.invite}"
                        class="cm__tools__select__item cm__tools__select__item__specific"
                        @click="() => { participantsSelect(); toggleInvite(); }">
                        {{ $t('frontend.app.components.video_client.tools.invite_participants') }}
                        <m-icon
                            v-if="more.invite"
                            class="cm__tools__select__active__icon"
                            size="16">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                </div>
                <div
                    v-if="isPresenter"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.participants')"
                    class="cm__tools">
                    <m-icon
                        ref="selectParticipants"
                        :class="{'cm__tools__icon__active' : participants}"
                        class="cm__tools__icon"
                        size="0"
                        @click="participantsSelect()">
                        GlobalIcon-users
                    </m-icon>
                </div>
                <div
                    v-else
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.participants')"
                    class="cm__tools">
                    <m-icon
                        ref="selectParticipants"
                        :class="{'cm__tools__icon__active' : participants}"
                        class="cm__tools__icon"
                        size="0"
                        @click="() => { participantsSelect(); toggleManage(); }">
                        GlobalIcon-users
                    </m-icon>
                </div>
                <div
                    v-if="!isPresenter && isShareAvailable"
                    v-tooltip="shareScreen ? $t('frontend.app.components.video_client.tools.tooltips.stop_share') : $t('frontend.app.components.video_client.tools.tooltips.start_share')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active active' : shareScreen}"
                        class="cm__tools__icon"
                        size="0"
                        @click="checkAvailable()">
                        GlobalIcon-screen-share
                    </m-icon>
                </div>
                <div
                    v-if="!isPresenter && !isShareAvailable && shareScreen"
                    v-tooltip="shareScreen ? $t('frontend.app.components.video_client.tools.tooltips.stop_share') : $t('frontend.app.components.video_client.tools.tooltips.start_share')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active active' : shareScreen}"
                        class="cm__tools__icon"
                        size="0"
                        @click="checkAvailable()">
                        GlobalIcon-screen-share
                    </m-icon>
                </div>
                <div
                    v-if="isPresenter"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.start_share')"
                    class="cm__tools">
                    <m-icon
                        ref="selectShare"
                        :class="{'cm__tools__icon__active active' : shareScreen}"
                        class="cm__tools__icon"
                        size="0"
                        @click="shareScreenSelect()">
                        GlobalIcon-screen-share
                    </m-icon>
                </div>
                <div
                    v-if="!isPresenter && !isShareAvailable && !shareScreen"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.share_unavailable')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active active' : shareScreen}"
                        class="cm__tools__icon"
                        size="0">
                        GlobalIcon-screen-share
                    </m-icon>
                </div>
                <div
                    v-if="shareScreenMenu"
                    v-click-outside="checkTargetShare"
                    class="cm__tools__select cm__tools__select__share">
                    <div class="cm__tools__select__item cm__tools__select__item__specific">
                        {{ $t('frontend.app.components.video_client.tools.participants_screen_share') }}
                        <m-toggle
                            :value="roomInfo && roomInfo.is_screen_share_available"
                            @change="toggleShareForAll" />
                    </div>
                    <div
                        v-if="isSharePresenterAvailable"
                        class="cm__tools__select__item"
                        @click="() => { shareScreenSelect(); enableShare(); }">
                        {{ shareScreen ? $t('frontend.app.components.video_client.tools.stop_share') : $t('frontend.app.components.video_client.tools.start_share') }}
                    </div>
                </div>
                <!-- <m-icon @click="studioSelect()" size="0"  v-tooltip="'Studio'"
          class="cm__tools__icon"
          :class="{'cm__tools__icon__active' : studio}" v-if="isPresenter">GlobalIcon-message-square</m-icon>
        <div @click="studioSelect()" class="channelFilters__icons__options__cover" v-show="studio" />
        <div v-if="studio" class="cm__tools__select">
          <div @click="() => { studioSelect(); }" class="cm__tools__select__item">Products</div>
          <div @click="() => { studioSelect(); }" class="cm__tools__select__item">Polls</div>
          <div @click="() => { studioSelect(); }" class="cm__tools__select__item">Donations</div>
        </div> -->
                <div
                    v-if="isChatAllowed"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.chat')"
                    class="cm__tools">
                    <div
                        v-show="newMessages > 0"
                        class="cm__tools__icon__message__new" />
                    <m-icon
                        :class="{'cm__tools__icon__active' : more.chat}"
                        class="cm__tools__icon"
                        size="0"
                        @click="toggleChat">
                        GlobalIcon-message-square
                    </m-icon>
                </div>
                <div
                    v-tooltip="'Polls'"
                    class="cm__tools">
                    <m-icon
                        :class="{'active' : more.polls}"
                        class="cm__tools__icon"
                        size="0"
                        @click="openCreatePolls">
                        poll-icon
                    </m-icon>
                </div>
                <div
                    v-if="isVBSupported"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.video_background')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active' : more.virtualBackground}"
                        class="cm__tools__icon"
                        size="0"
                        @click="toggleVideoBackground">
                        GlobalIcon-settings
                    </m-icon>
                </div>
                <!-- <div
                    class="cm__tools">
                    <m-dropdown
                        ref="settingsDropdown"
                        class="cm__tools__icon">
                        <m-option
                            :class="{'cm__tools__select__active': more.virtualBackground}"
                            @click="toggleVideoBackground">
                            {{ $t('frontend.app.components.video_client.tools.tooltips.video_background') }}
                            <m-icon
                                v-if="more.virtualBackground"
                                class="cm__tools__select__active__icon"
                                size="16">
                                GlobalIcon-check
                            </m-icon>
                        </m-option>
                        <m-option
                            :class="{'cm__tools__icon__active' : more.polls}"
                            @click="openCreatePolls">
                            {{ $t('frontend.app.components.video_client.tools.tooltips.create_polls') }}
                        </m-option>
                    </m-dropdown>
                </div> -->
                <!-- <div class="cm__tools">
          <m-icon @click="toggleMobileOption" ref="mobileOption" size="0" :name="'GlobalIcon-dots-3'"
          class="cm__tools__mobile__icon cm__tools__dotsH" :class="{'cm__tools__mobile__icon__active': mobileOption}" />
        </div> -->
            </div>
            <div class="display__flex">
                <div
                    v-if="layoutSelect"
                    v-click-outside="checkTargetLayout"
                    :class="{'cm__tools__select__ipad' : $device.ipad()}"
                    class="cm__tools__select">
                    <div
                        v-if="!isPresenterPins || (isPresenterPins && isSelfShare)"
                        :class="{'cm__tools__select__active': layoutPanels.grid}"
                        class="cm__tools__select__item"
                        @click="toggleGrid()">
                        <m-icon class="cm__tools__select__icon">
                            GlobalIcon-Grid
                        </m-icon>
                        {{ $t('frontend.app.components.video_client.tools.layouts.grid') }}
                        <m-icon
                            v-if="layoutPanels.grid"
                            class="cm__tools__select__check"
                            size="0">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                    <div
                        v-if="!isSelfShare && !$device.mobile()"
                        :class="{'cm__tools__select__active': layoutPanels.vertical}"
                        class="cm__tools__select__item"
                        @click="toggleVertical()">
                        <m-icon class="cm__tools__select__icon">
                            GlobalIcon-sidebar
                        </m-icon>
                        {{ $t('frontend.app.components.video_client.tools.layouts.vertical') }}
                        <m-icon
                            v-if="layoutPanels.vertical"
                            class="cm__tools__select__check"
                            size="0">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                    <div
                        v-if="!isSelfShare"
                        :class="{'cm__tools__select__active': layoutPanels.horizontal}"
                        class="cm__tools__select__item"
                        @click="toggleHorizontal()">
                        <m-icon class="cm__tools__select__icon cm__tools__select__horizontal">
                            GlobalIcon-sidebar
                        </m-icon>
                        {{ $t('frontend.app.components.video_client.tools.layouts.horizontal') }}
                        <m-icon
                            v-if="layoutPanels.horizontal"
                            class="cm__tools__select__check"
                            size="0">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                    <div
                        v-if="!isSelfShare && !$device.mobile()"
                        :class="{'cm__tools__select__active': layoutPanels.presenterOnly}"
                        class="cm__tools__select__item"
                        @click="togglePresenterOnly()">
                        <m-icon class="cm__tools__select__icon">
                            GlobalIcon-square
                        </m-icon>
                        {{ $t('frontend.app.components.video_client.tools.layouts.presenter_only') }}
                        <m-icon
                            v-if="layoutPanels.presenterOnly"
                            class="cm__tools__select__check"
                            size="0">
                            GlobalIcon-check
                        </m-icon>
                    </div>
                </div>
                <div
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.layout')"
                    class="cm__tools "
                    @click="toggleLayoutSelect()">
                    <m-icon
                        v-if="!isLivestream"
                        ref="selectLayout"
                        :class="{'cm__tools__icon__active' : layoutSelect,
                                 'GlobalIcon-sidebar': layoutPanels.vertical,
                                 'GlobalIcon-Grid': layoutPanels.grid,
                                 'cm__tools__select__horizontal GlobalIcon-sidebar': layoutPanels.horizontal,
                                 'GlobalIcon-square': layoutPanels.presenterOnly}"
                        class="cm__tools__icon cm__tools__double cm__tools__icon__sidebar"
                        size="0" />
                    <m-icon
                        ref="selectLayoutArrow"
                        :class="{'cm__tools__angle__active' : layoutSelect}"
                        class="cm__tools__angle">
                        GlobalIcon-angle-down
                    </m-icon>
                </div>
                <div
                    v-if="$device.os != 'ios'"
                    v-tooltip="$t('frontend.app.components.video_client.tools.tooltips.full_screen')"
                    class="cm__tools">
                    <m-icon
                        :class="{'cm__tools__icon__active' : isFullScreen}"
                        class="cm__tools__icon"
                        size="0"
                        @click="toggleFullScreen()">
                        GlobalIcon-fullScreen
                    </m-icon>
                </div>
                <div class="cm__tools__exit">
                    <a
                        class="btn btn btn__bordered"
                        type="bordered"
                        @click="exit">{{ $t('frontend.app.components.video_client.tools.leave') }}</a>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import CreatePoll from '@components/polls/CreatePoll.vue'
import {mapGetters} from 'vuex'
import SelectOptions from './SelectOptions.vue'
import Room from "@models/Room"
import ClickOutside from "vue-click-outside"
import { isSupported } from '@webrtcservice/video-processors'

export default {
    directives: {
        ClickOutside
    },
    components: {SelectOptions, CreatePoll},
    props: {
        room: Object,
        roomInfo: Object,
        fullScreen: Boolean,
        layoutPanels: Object,
        isSelfShare: Boolean
    },
    data() {
        return {
            audioMuted: false,
            videoMuted: false,
            shareScreen: false,
            shareScreenMenu: false,
            circle: false,
            message: false,
            newMessage: true,
            sidebar: false,
            hideSidebar: false,
            settings: false,
            users: false,
            filters: false,
            dots: false,
            layoutSelect: false,
            participants: false,
            studio: false,
            participantsScreenShare: false,
            more: {
                chat: false,
                invite: false,
                manage: false,
                virtualBackground: false,
                polls: false
            },
            devices: [],
            tracks: [],
            isFullScreen: false,
            newMessages: 0,
            canShare: true,
            shareStream: null,
            lastDevices: {
                video: null,
                audio: null
            },
            mobileOption: false,
            micSettings: false,
            vidSettings: false,
            canToggleCamera: true
        }
    },
    created() {
        navigator.mediaDevices.enumerateDevices().then((e) => {
            this.devices = e
        })
        this.$eventHub.$on("tw-muteVideo", () => {
            this.checkVideoMuted()
            this.disableVideo()
        })
        this.$eventHub.$on("tw-chatNewMessagesCount", count => {
            this.newMessages = this.more.chat ? 0 : count
        })
        this.$eventHub.$on("tw-muteAudio", () => {
            this.checkAudioMuted()
            this.mute()
        })
        this.$eventHub.$on("tw-toggleChat", flag => {
            this.more.chat = flag
            if(flag) this.newMessages = 0
            setTimeout(() => {
                this.$eventHub.$emit("recalculateLayout")
            }, 500)
        })
        this.$eventHub.$on("tw-toggleVirtualBackground", flag => {
            this.more.virtualBackground = flag
            setTimeout(() => {
                this.$eventHub.$emit("recalculateLayout")
            }, 500)
        })
        this.$eventHub.$on("tw-toggleInvite", flag => {
            this.more.invite = flag
        })
        this.$eventHub.$on("tw-toggleManage", flag => {
            this.more.manage = flag
            if (!this.isPresenter && !this.more.manage) this.participantsSelect(true)
        })
        this.$eventHub.$on("tw-roomCreated", () => {
            this.checkVideoMuted()
            this.checkAudioMuted()
        })

        setInterval(() => {
            this.checkVideoMuted()
            this.checkAudioMuted()
        }, 1000)
    },
    computed: {
        ...mapGetters("VideoClient", ["isLocalPins", "isPresenterPins"]),
        audioDeviceOptions() {
            return this.devices.filter(e => e.kind === 'audioinput').map(e => {
                return {
                    value: e.deviceId,
                    name: e.label
                }
            })
        },
        participantTitle() {
            return this.isPresenter ? 'Manage Participants' : 'Participants'
        },
        videoDeviceOptions() {
            return this.devices.filter(e => e.kind === 'videoinput').map(e => {
                return {
                    value: e.deviceId,
                    name: e.label
                }
            })
        },
        roomMember() {
            return this.$store.getters["VideoClient/roomMember"]
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        },
        isLivestream() {
            return this.roomInfo?.abstract_session.livestream
        },
        isChatAllowed() {
            return this.roomInfo?.abstract_session?.allow_chat
        },
        isMore() {
            return this.isPresenter
        },
        isShareAvailable() {
            return this.roomInfo?.is_screen_share_available && this.canShare && !this.$device.mobile() && !this.$device.ipad()  && !this.$device.tablet()
        },
        isSharePresenterAvailable() {
            return this.canShare && !this.$device.mobile() && !this.$device.ipad()  && !this.$device.tablet()
        },
        isPinned() {
            return this.isLocalPins || this.isPresenterPins
        },
        checkShared() {
            let flag = false
            this.room.participants.forEach(participant => {
                participant.videoTracks.forEach(track => {
                    if (track.trackName === "share") {
                        flag = true
                    }
                })
            })
            return flag
        },
        isVBSupported() {
            return isSupported
        }
    },
    watch: {
        isSelfShare(val) {
            if (!val && this.isPresenterPins) {
                this.$eventHub.$emit("tw-toggleToSidebarIfGrid")
            }
        }
    },
    mounted() {
        this.$eventHub.$on('tw-toggleFullScreen', () => {
            this.toggleFullScreen()
        })
        window.toggleFullScreen = this.toggleFullScreen
        this.$eventHub.$on('tw-mobileSelectOption', () => {
            this.micSettings = true
            this.vidSettings = true
        })
        this.$eventHub.$on('tw-changeSidebar', (sidebar) => {
            this.sidebar = sidebar
        })
        this.$eventHub.$on('tw-hideSidebar', (hideSidebar) => {
            this.hideSidebar = hideSidebar
        })
        this.$eventHub.$on("tw-sharingStatus", (flag) => {
            this.canShare = !flag
        })
        this.$eventHub.$on("tw-pollsStatus", (flag) => {
            this.more.polls = flag
        })

        this.$eventHub.$on("tw-shareDisabled", () => {
            this.canShare = true
        })
        this.$eventHub.$on("tw-unmute", (type) => {
            if (type === "audio") {
                this.unmute()
            } else if (type === "video") {
                this.enableVideo()
            }
        })

        this.$eventHub.$on("tw-askSourcesStatus", () => {
            this.$eventHub.$emit("tw-answerSourcesStatus", {
                audio: !this.audioMuted, video: !this.videoMuted
            })
        })

        /* Standard syntax */
        document.addEventListener("fullscreenchange", () => {
            this.isFullScreen = document.fullscreenElement
        })

        /* Firefox */
        document.addEventListener("mozfullscreenchange", () => {
            this.isFullScreen = document.mozFullScreen
        })

        /* Chrome, Safari and Opera */
        document.addEventListener("webkitfullscreenchange", () => {
            this.isFullScreen = document.webkitIsFullScreen
        })

        /* IE / Edge */
        document.addEventListener("msfullscreenchange", () => {
            this.isFullScreen = document.msFullscreenElement
        })

        document.addEventListener("keydown", (event) => {
            if (event.which == 122) {
                event.preventDefault()
                this.toggleFullScreen()
            }
        })
    },
    methods: {
        checkAudioTarget(event) {
            if (this.$refs.audioSelect && this.$refs.audioSelect.$el == event.target) return
            this.micSettings = false
            this.settings = false
            this.closeSettings()
        },
        checkVideoTarget(event) {
            if (this.$refs.videoSelect && this.$refs.videoSelect.$el == event.target) return
            this.vidSettings = false
            this.settings = false
            this.closeSettings()
        },
        toggleMobileOption() {
            this.mobileOption = !this.mobileOption
        },
        checkMobileOption(event) {
            if (this.$refs.mobileOption.$el == event.target) return
            this.mobileOption = false
        },
        checkTargetOptions(event) {
            if (this.$refs.selectOptions && this.$refs.selectOptions.$el == event.target) return
            this.settings = false
            this.closeSettings()
        },
        checkTargetParticipants(event) {
            if (this.$refs.selectParticipants.$el == event.target) return
            this.participantsSelect()
        },
        checkTargetShare(event) {
            if (this.$refs.selectShare.$el == event.target) return
            this.shareScreenSelect()
        },
        checkTargetLayout(event) {
            if ((this.$refs.selectLayout && this.$refs.selectLayout.$el == event.target) ||
                (this.$refs.selectLayoutArrow && this.$refs.selectLayoutArrow.$el == event.target)) return
            this.toggleLayoutSelect()
        },
        participantsSelect(flag = false) {
            if (flag) {
                this.participants = false
                this.mobileOption = false
            } else if (this.$device.mobile()) {
                this.mobileOption = !this.mobileOption
            } else {
                this.participants = !this.participants
            }
            this.$eventHub.$emit("tw-participantsSelect", this.participants)
        },
        studioSelect() {
            this.studio = !this.studio
            this.$eventHub.$emit("tw-studioSelect", this.studio)
        },
        shareScreenSelect() {
            this.shareScreenMenu = !this.shareScreenMenu
            this.$eventHub.$emit("tw-shareScreenSelect", this.shareScreenMenu)
        },
        toggleGrid() {
            this.toggleLayoutSelect()
            this.$eventHub.$emit('tw-toggleGrid', true)
            this.$eventHub.$emit('tw-toggleSidebar', false)
        },
        toggleVertical() {
            this.toggleLayoutSelect()
            this.$eventHub.$emit('tw-toggleVertical', true)
            this.$eventHub.$emit('tw-toggleSidebar', true)
        },
        toggleHorizontal() {
            this.toggleLayoutSelect()
            this.$eventHub.$emit('tw-toggleHorizontal', true)
            this.$eventHub.$emit('tw-toggleSidebar', true)
        },
        togglePresenterOnly() {
            this.toggleLayoutSelect()
            this.$eventHub.$emit('tw-togglePresenterOnly', true)
            this.$eventHub.$emit('tw-toggleSidebar', true)
        },
        toggleSettings(mic = false, vid = false) {
            if (mic) {
                this.micSettings = !this.micSettings
                this.vidSettings = false
            }
            if (vid) {
                this.vidSettings = !this.vidSettings
                this.micSettings = false
            }
            if (!mic && !vid) {
                this.micSettings = false
                this.vidSettings = false
            }
            this.settings = !this.settings
            if (this.micSettings || this.vidSettings) this.settings = true
            this.$eventHub.$emit("Settings", this.settings)
        },
        toggleLayoutSelect() {
            this.layoutSelect = !this.layoutSelect
            this.$eventHub.$emit("tw-layoutSelect", this.layoutSelect)
        },
        closeSettings() {
            this.settings = false
            this.micSettings = false
            this.vidSettings = false
            this.$eventHub.$emit("Settings", this.settings)
        },
        deviceUpdated() {
            if (this.videoMuted) {
                // this.disableVideo()
            }
        },
        // audio settings
        toggleAudioMute() {
            this.checkAudioMuted()
            if (this.audioMuted) {
                this.unmute()
                this.$eventHub.$emit("tw-audioMuted", this.audioMuted)
            } else {
                this.mute()
                this.$eventHub.$emit("tw-audioMuted", this.audioMuted)
            }
            this.checkAudioMuted()
        },
        checkAudioMuted() {
            let flag = false
            if (this.room && this.room.localParticipant)
                this.room.localParticipant.audioTracks.forEach(publication => {
                    flag = !publication.isTrackEnabled
                })
            if (this.room?.localParticipant?.audioTracks.size === 0) flag = true
            this.audioMuted = flag
        },
        mute() {
            if (this.room && this.room.localParticipant)
                this.room.localParticipant.audioTracks.forEach(publication => {
                    publication.track.disable()
                })
            this.checkAudioMuted()
        },
        unmute() {
            if (this.room && this.room.localParticipant)
                this.room.localParticipant.audioTracks.forEach(publication => {
                    publication.track.enable()
                })
            this.checkAudioMuted()
        },
        // video settings
        toggleVideoMute() {
            this.checkVideoMuted()
            if (this.videoMuted) {
                this.enableVideo()
            } else {
                this.disableVideo()
            }
            this.checkVideoMuted()
            if (this.isPresenter) this.$eventHub.$emit("tw-enableVideo", (this.videoMuted))
        },
        checkVideoMuted() {
            let flag = false
            if (this.room && this.room.localParticipant)
                this.room.localParticipant.videoTracks.forEach(publication => {
                    if (publication.track.name !== 'share')
                        flag = !publication.isTrackEnabled
                })
            if (this.room?.localParticipant?.videoTracks.size === 0) flag = true
            this.videoMuted = flag
        },
        disableVideo() {
            if (!this.canToggleCamera) return
            if (this.room && this.room.localParticipant)
                this.room.localParticipant.videoTracks.forEach(publication => {
                    if (publication.track.name !== 'share') {
                        let label = publication.track.mediaStreamTrack.label
                        let device = this.videoDeviceOptions.find(e => e.name === label)
                        if (device) {
                            this.lastDevices.video = device.value
                        }
                        publication.track.disable()
                        this.canToggleCamera = false
                        // this.$eventHub.$emit("tw-updatePresenter")
                        setTimeout(() => {
                            // publication.track.stop();
                            //   publication.unpublish();
                            setTimeout(() => {
                                console.log("+++++ track info:")
                                console.log("publication:", publication)
                                console.log("isEnabled:", publication.track.isEnabled)
                                console.log("isStarted:", publication.track.isStarted)
                                console.log("----- track info:")
                            }, 500)
                        }, 500)
                        setTimeout(() => {
                            this.room.localParticipant.videoTracks.forEach(pub => {
                                // pub.track.stop();
                            })
                        }, 1000)
                        setTimeout(() => {
                            this.room.localParticipant.videoTracks.forEach(pub => {
                                // pub.track.stop();
                                this.canToggleCamera = true
                            })
                        }, 1500)
                    }
                })
            this.checkVideoMuted()
        },
        enableVideo() {
            if (!this.canToggleCamera) return
            console.log("enableVideo")
            this.room.localParticipant.videoTracks.forEach(publication => {
                if (publication.track.name !== 'share') {
                    // publication.track.restart();
                    publication.track.enable()
                    // this.$eventHub.$emit("tw-updatePresenter")
                }
                // publication.publish();
            })
            this.checkVideoMuted()
        },
        checkAvailable() {
            if (this.isShareAvailable) {
                this.enableShare()
            } else if (!this.isShareAvailable && this.shareScreen) {
                this.enableShare()
            } else {
                this.$flash("Please ask Presenter to allow Screen Share")
            }
        },
        enableShare() {
            if (!this.shareScreen) {
                navigator.mediaDevices.getDisplayMedia().then(async (stream) => {

                    if (this.checkShared) {
                        Window.stre = stream.getVideoTracks()[0]
                        stream.getVideoTracks()[0].stop()
                        this.$flash("Already shared")
                        return
                    }

                    // this.disableVideo()
                    let track = await this.room.localParticipant.publishTrack(stream.getVideoTracks()[0], {
                        name: "share",
                        video: {frameRate: 24}
                    })
                    this.shareScreen = true
                    this.tracks.push({
                        id: this.tracks.length,
                        type: "share",
                        track
                    })
                    this.shareStream = stream
                    // this.$eventHub.$emit('showSidebar', true);
                    // this.$eventHub.$emit('tw-toggleSidebar', true);
                    // this.$eventHub.$emit('tw-changeSidebar', true);
                    this.$eventHub.$emit("tw-attachMainTrack", track.track, true)
                    this.$eventHub.$emit("tw-selfShare:enable", track.track)
                    this.$eventHub.$emit("tw-checkIfSharing")

                    this.$eventHub.$emit("tw-sharedBy",
                        this.roomMember.abstract_user?.public_display_name ? this.roomMember.abstract_user.public_display_name : this.roomMember.display_name, this.roomMember.id)

                    stream.getVideoTracks()[0].onended = () => {
                        this.monitor = false
                        this.shareScreen = false
                        track.track.disable()
                        setTimeout(() => {
                            this.shareStream = null
                            track.track.stop()
                            track.unpublish()
                            track.track.detach().forEach(function (element) {
                                element.srcObject = null
                                element.remove()
                            })
                            if (track.track._setEnabled) track.track._setEnabled(false)
                            if (track._setEnabled) track._setEnabled(false)
                            this.$eventHub.$emit("tw-selfShare:disable", track.track)
                            setTimeout(() => {
                                this.$eventHub.$emit("recalculateLayout")
                            }, 500)
                        }, 1000)
                    }
                }).catch((error) => {
                    console.log(error)
                })
            } else {
                this.room.localParticipant.videoTracks.forEach(track => {
                    if (track.trackName === 'share') {
                        this.monitor = false
                        this.shareScreen = false
                        track.track.disable()
                        setTimeout(() => {
                            this.shareStream = null
                            track.track.stop()
                            track.unpublish()
                            track.track.detach().forEach(function (element) {
                                element.srcObject = null
                                element.remove()
                            })
                            if (track.track._setEnabled) track.track._setEnabled(false)
                            if (track._setEnabled) track._setEnabled(false)
                            this.$eventHub.$emit("tw-selfShare:disable", track.track)
                            setTimeout(() => {
                                this.$eventHub.$emit("recalculateLayout")
                            }, 500)
                        }, 1000)
                    }
                })
            }
        },
        exit() {
            this.$eventHub.$emit('exit')
        },
        toggleFullScreen() {
            let elem = document.body
            // ## The below if statement seems to work better ## if ((document.fullScreenElement && document.fullScreenElement !== null) || (document.msfullscreenElement && document.msfullscreenElement !== null) || (!document.mozFullScreen && !document.webkitIsFullScreen)) {
            if ((document.fullScreenElement !== undefined && document.fullScreenElement === null) ||
                (document.msFullscreenElement !== undefined && document.msFullscreenElement === null) ||
                (document.mozFullScreen !== undefined && !document.mozFullScreen) ||
                (document.webkitIsFullScreen !== undefined && !document.webkitIsFullScreen)) {
                if (elem.requestFullScreen) {
                    elem.requestFullScreen()
                } else if (elem.mozRequestFullScreen) {
                    elem.mozRequestFullScreen()
                } else if (elem.webkitRequestFullScreen) {
                    elem.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)
                } else if (elem.msRequestFullscreen) {
                    elem.msRequestFullscreen()
                }
                this.isFullScreen = true
            } else {
                if (document.cancelFullScreen) {
                    document.cancelFullScreen()
                } else if (document.mozCancelFullScreen) {
                    document.mozCancelFullScreen()
                } else if (document.webkitCancelFullScreen) {
                    document.webkitCancelFullScreen()
                } else if (document.msExitFullscreen) {
                    document.msExitFullscreen()
                }
                this.isFullScreen = false
                this.$eventHub.$emit("recalculateLayout")
            }
        },
        closeMore() {
            this.dots = false
        },
        closeAllMore() {
            Object.keys(this.more).forEach(key => {
                this.more[key] = false
            })
        },
        toggleChat() {
            if (this.more.chat) {
                this.closeAllMore()
            } else {
                this.closeAllMore()
                this.more.chat = true
            }
            setTimeout(() => {
                this.$eventHub.$emit("recalculateLayout")
            }, 500)
            this.$eventHub.$emit("recalculateLayout")
            this.$eventHub.$emit("tw-toggleChat", this.more.chat)
            this.$eventHub.$emit("tw-toggleInvite", false)
            this.$eventHub.$emit("tw-toggleManage", false)
            this.$eventHub.$emit("tw-toggleVirtualBackground", false)
        },
        toggleInvite() {
            if (this.more.invite) {
                this.closeAllMore()
            } else {
                this.closeAllMore()
                this.more.invite = true
            }
            setTimeout(() => {
                this.$eventHub.$emit("recalculateLayout")
            }, 500)
            this.$eventHub.$emit("recalculateLayout")
            this.$eventHub.$emit("tw-toggleChat", false)
            this.$eventHub.$emit("tw-toggleInvite", this.more.invite)
            this.$eventHub.$emit("tw-toggleManage", false)
            this.$eventHub.$emit("tw-toggleVirtualBackground", false)
        },
        toggleManage() {
            if (this.more.manage) {
                this.closeAllMore()
            } else {
                this.closeAllMore()
                this.more.manage = true
                this.$eventHub.$emit("tw-updateParticipantslist")
            }
            setTimeout(() => {
                this.$eventHub.$emit("recalculateLayout")
            }, 500)
            this.$eventHub.$emit("recalculateLayout")
            this.$eventHub.$emit("tw-toggleChat", false)
            this.$eventHub.$emit("tw-toggleInvite", false)
            this.$eventHub.$emit("tw-toggleManage", this.more.manage)
            this.$eventHub.$emit("tw-toggleVirtualBackground", false)
        },
        toggleShareForAll() {
            Room.api().updateRoom({
                id: this.roomInfo.id,
                is_screen_share_available: !this.roomInfo?.is_screen_share_available
            }).then(res => {
                this.$store.dispatch("VideoClient/setRoomInfo", res.response.data.response.room)
                this.$eventHub.$emit("roomUpdated", res.response.data.response.room)
            })
        },
        toggleVideoBackground() {
            // this.$refs.settingsDropdown.close()
            this.more.virtualBackground = !this.more.virtualBackground
            this.$eventHub.$emit("tw-toggleVirtualBackground", this.more.virtualBackground)
            this.$eventHub.$emit("tw-toggleChat", false)
            this.$eventHub.$emit("tw-toggleInvite", false)
            this.$eventHub.$emit("tw-toggleManage", false)
        },
        openCreatePolls() {
            this.more.polls = true
            // this.$refs.settingsDropdown.close()
            this.$eventHub.$emit('poll-template:open')
        }
    }
}
</script>
