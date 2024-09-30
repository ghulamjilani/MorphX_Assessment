<template>
    <div>
        <!-- TODO: Вынести в отдельный компонент список обязательных модалок vue & monolith -->
        <modal-form ref="cis" />
        <subs-plans-template />
        <plan-info />
        <component-settings-modal />
        <conversation-group v-if="currentUser && instant_messaging_globalConfig" /> <!--check if this currentUser and instant_messaging(global config enabled)-->
        <m-flash-message
            ref="flash"
            :block-message="true" />
        <auth-modal class="loginSignUPForgotPassModals" />
        <div
            v-show="isShowOnMonolithPage"
            class="header__container">
            <div class="unobtrusive-flash-container flash-container__header" />
            <header
                id="headerToggle"
                :class="{active: isMenuOpen}"
                class="header">
                <i
                    v-if="isMenuOpen && search.length > 0"
                    class="GlobalIcon-clear closeMenu fs-15"
                    @click="toggleMenu" />
                <div class="header__left">
                    <div
                        v-if="back_to_home"
                        v-tooltip="'Back to homepage'"
                        class="header__back"
                        @click="goToHome()">
                        <m-icon
                            class="header__back__icon"
                            size="0">
                            {{ $device.mobile() ? 'GlobalIcon-home': 'GlobalIcon-angle-left' }}
                        </m-icon>
                    </div>
                    <div :class="['header__logo', logoName]">
                        <a
                            v-if="!getOrganizationLogo2"
                            :href="getOrganizationLink"
                            class="display__flex">
                            <img
                                v-if="logo_size == 'logo_small'"
                                :class="['header__logo_medium', {active: isScrolled}]"
                                :src="$img['logo']"
                                alt>
                            <img
                                v-if="logo_size == 'logo_small'"
                                :class="['header__logo_small', {active: !isScrolled}]"
                                :src="$img['logo_small']"
                                alt>
                            <img
                                v-else
                                :src="$img['logo']"
                                alt
                                class="header__logo_medium active">
                        </a>
                        <a
                            v-if="getOrganizationLogo2"
                            :href="getOrganizationLink">
                            <img
                                :src="getOrganizationLogo2"
                                alt
                                class="active">
                        </a>
                    </div>
                    <div class="header__logo tabletLogo">
                        <a
                            v-if="!getOrganizationLogo2"
                            :href="getOrganizationLink">
                            <img
                                :src="$img[logo_size]"
                                alt
                                class="active">
                        </a>
                        <a
                            v-if="getOrganizationLogo2"
                            :href="getOrganizationLink">
                            <img
                                :src="getOrganizationLogo2"
                                alt
                                class="active">
                        </a>
                    </div>
                    <div
                        v-if="!enterprise"
                        :class="['header__search', {mouseover: focusSearch, notEmpty: search.length}]"
                        @mouseleave="toggleHoverSearch(false)"
                        @mouseenter="toggleHoverSearch(true)">
                        <!-- <m-form>
              <m-input :pure="true" placeholder="Search" />
            </m-form> -->
                        <input
                            v-model="search"
                            :placeholder="$t('frontend.app.components.pageparts.header.search')"
                            type="text"
                            @keypress.enter="onSearch">
                        <button
                            v-if="search.length > 0"
                            class="GlobalIcon-clear header__search__clearButton"
                            @click="search = ''" />
                        <button
                            class="GlobalIcon-Search header__search__searchButton"
                            @click="goToSearch()" />
                    </div>
                </div>
                <div
                    v-if="loading"
                    class="header__placeholder__wrapper">
                    <current-user-placeholder />
                    <!-- <guest-placeholder/> -->
                </div>
                <div
                    v-else-if="currentUser"
                    class="header__right">
                    <div
                        v-if="!isMenuOpen"
                        class="header__status">
                        <div
                            v-if="!currentUser.confirmed_at"
                            class="header__confirmEmail header__desctopConfirmEmail">
                            <span>{{ $t('frontend.app.components.pageparts.header.confirm_email') }}</span>
                            <m-btn
                                size="xs"
                                type="main"
                                @click="resendEmailConfirmation">
                                {{ $t('frontend.app.components.pageparts.header.rewrite_email') }}
                            </m-btn>
                        </div>
                        <!-- <template v-if="nearestSession">
            <m-btn v-if="millisecondsToSesions <= 0"
            @click="join"
            @click.middle="join"
            :class="{focusHeaderSearch: focusSearchDelayed || search.length}"
            type="main"
            size="s"
            class="btn header__joinButton menu_btn">
              {{$t('frontend.app.components.pageparts.header.join')}}
            </m-btn>
            <div v-else
            v-show="!isMenuOpen"
            class="header__status__next_session"
            :class="{focusHeaderSearch: focusSearchDelayed || search.length}">
              {{$t('frontend.app.components.pageparts.header.next')}} {{millisecondsToSesions | timeToSession}}
            </div>
          </template> -->
                        <join @toggle="sessionsListToggle" />
                        <template v-if="currentUser.can_become_a_creator && isWizardEnabled">
                            <a
                                :class="{focusHeaderSearch: focusSearchDelayed || search.length}"
                                :href="startCreatingLink"
                                class="header__wizardButton btn btn__main btn__normal text__uppercase margin-l__20">
                                {{ startCreatingName }}
                            </a>
                        </template>
                    </div>
                    <div class="header__navWrapper">
                        <div
                            :class="{'hideOnMobile': sessionsList}"
                            class="header__responsiveNav">
                            <div
                                v-if="credentialsAbility && (credentialsAbility.can_create_session || credentialsAbility.can_upload_recording)"
                                class="header__showDropdown">
                                <a
                                    class="header__link margin-r__0"
                                    href="#"
                                    @click="toggleNav">
                                    <i class="GlobalIcon-stream-video content__middle color__icons" />
                                    <i
                                        v-if="isMenuOpen"
                                        :class="{rotate__180: isNavOpen}"
                                        class="GlobalIcon-angle-down fs__10 content__middle color__icons" />
                                </a>
                                <div class="header__dropdown showDrop">
                                    <a
                                        v-if="currentUser.can_create_session && credentialsAbility && credentialsAbility.can_create_session"
                                        :href="newSessionLink"
                                        @click="goLive">{{
                                                            $t('frontend.app.components.pageparts.header.sessions_create.go_live')
                                                        }}
                                        <i class="GlobalIcon-stream-video" />
                                    </a>
                                    <a
                                        v-if="currentUser.can_create_session && credentialsAbility && credentialsAbility.can_start_session && credentialsAbility.can_create_session && subscriptionAbility.can_create_interactive_stream"

                                        @click="openCIS">{{
                                                             $t('frontend.app.components.pageparts.header.sessions_create.fast_interactive')
                                                         }}
                                        <i class="GlobalIcon-users" />
                                        <b
                                            class="GlobalIcon-info"
                                            v-tooltip="$t('frontend.app.components.pageparts.header.sessions_create.fast_interactive_tooltip')">
                                        </b>
                                    </a>
                                    <a
                                        v-if="credentialsAbility && credentialsAbility.can_upload_recording"
                                        href="/dashboard/uploads">{{
                                                                      $t('frontend.app.components.pageparts.header.sessions_create.upload')
                                                                  }}
                                        <i class="GlobalIcon-upload" />
                                    </a>
                                </div>
                            </div>
                            <div class="header__showDropdown">
                                <a
                                    :data-count="currentUser.new_notifications_count || false"
                                    class="header__counter header__link"
                                    href="/notifications">
                                    <i class="GlobalIcon-notification color__icons" />
                                </a>
                                <div class="infoDR showDrop">
                                    <div class="infoDR__head">
                                        <b> <span class="fs__24">{{ currentUser.new_notifications_count || '' }}</span>
                                            {{
                                                $t('frontend.app.components.pageparts.header.notifications.latest_notifications')
                                            }}</b>
                                        <div class="infoDR__buttons">
                                            <button @click="markNotificationsAsRead">
                                                {{ $t('frontend.app.components.pageparts.header.notifications.mark_all') }}
                                            </button>
                                            <button @click="clearAll">
                                                {{ $t('frontend.app.components.pageparts.header.notifications.clear_all') }}
                                            </button>
                                        </div>
                                    </div>
                                    <div class="infoDR__body">
                                        <div
                                            v-for="notification in notifications"
                                            :key="notification.id">
                                            <notification-tile :notification="notification" />
                                        </div>
                                        <div
                                            v-if="!notifications.length"
                                            class="infoDR__no_items">
                                            {{ $t('frontend.app.components.pageparts.header.notifications.empty') }}
                                        </div>
                                    </div>
                                    <div class="infoDR__footer">
                                        <button
                                            :disabled="notificationOptions.loaded"
                                            @click="fetchNotifications">
                                            {{ $t('frontend.app.components.pageparts.header.notifications.load_more') }}
                                        </button>
                                        <button
                                            @click="goTo('/notifications')"
                                            @click.middle="goTo('/notifications', true)">
                                            {{ $t('frontend.app.components.pageparts.header.notifications.view_all') }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <div class="header__showDropdown">
                                <a
                                    :data-count="currentUser.unread_messages_count || false"
                                    class="header__counter header__link"
                                    href="/messages">
                                    <i class="GlobalIcon-message color__icons" />
                                </a>
                                <div class="infoDR showDrop">
                                    <div class="infoDR__head">
                                        <b> <span class="fs__24">{{ currentUser.unread_messages_count || '' }}</span> {{
                                            $t('frontend.app.components.pageparts.header.messages.mess_count')
                                        }}</b>
                                    </div>
                                    <div class="infoDR__body infoDR__messagesBody">
                                        <div
                                            v-for="conversation in conversations"
                                            :key="conversation.id">
                                            <message-tile
                                                v-if="conversation.messages"
                                                :key="conversation.messages[conversation.messages.length - 1].id"
                                                :message="conversation.messages[conversation.messages.length - 1]"
                                                @openMessageModal="openMessageModal(conversation.id)" />
                                        </div>
                                    </div>
                                    <div class="infoDR__footer">
                                        <button
                                            :disabled="conversationOptions.loaded"
                                            @click="fetchConversation">
                                            {{ $t('frontend.app.components.pageparts.header.messages.load_more') }}
                                        </button>
                                        <button
                                            @click="goTo('/messages')"
                                            @click.middle="goTo('/messages', true)">
                                            {{ $t('frontend.app.components.pageparts.header.messages.view_all') }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div
                            v-if="!currentUser.confirmed_at"
                            class="header__confirmEmail header__mobileConfirmEmail">
                            <span>{{ $t('frontend.app.components.pageparts.header.confirm_email') }}</span>
                            <m-btn
                                size="xs"
                                type="main"
                                @click="resendEmailConfirmation">
                                {{ $t('frontend.app.components.pageparts.header.rewrite_email') }}
                            </m-btn>
                        </div>
                        <div
                            v-if="isMenuOpen"
                            class="header__status">
                            <div
                                v-if="!currentUser.confirmed_at"
                                class="header__confirmEmail header__desctopConfirmEmail">
                                <span>{{ $t('frontend.app.components.pageparts.header.confirm_email') }}</span>
                                <m-btn
                                    size="xs"
                                    type="main"
                                    @click="resendEmailConfirmation">
                                    {{ $t('frontend.app.components.pageparts.header.rewrite_email') }}
                                </m-btn>
                            </div>

                            <join @toggle="sessionsListToggle" />

                            <!-- <template v-if="nearestSession">
                <m-btn v-if="millisecondsToSesions <= 0"
                      @click="join"
                      @click.middle="join"
                      :class="{focusHeaderSearch: focusSearchDelayed || search.length}"
                      type="main"
                      size="s"
                      class="btn header__joinButton menu_btn">
                  {{$t('frontend.app.components.pageparts.header.join')}}
                </m-btn>
                <div v-else
                    v-show="!isMenuOpen"
                    class="header__status__next_session"
                    :class="{focusHeaderSearch: focusSearchDelayed || search.length}">
                  {{$t('frontend.app.components.pageparts.header.next')}} {{millisecondsToSesions | timeToSession}}
                </div>
              </template> -->

                            <template v-if="currentUser.can_become_a_creator && isWizardEnabled">
                                <a
                                    :class="{focusHeaderSearch: focusSearchDelayed || search.length}"
                                    :href="startCreatingLink"
                                    class="header__wizardButton btn btn__main btn__normal text__uppercase margin-t__10 margin-b__10">
                                    {{ startCreatingName }}
                                </a>
                            </template>
                        </div>
                        <div class="UserAvatarDropdown header__showDropdown">
                            <span
                                :style="`background-image: url('${currentUser.avatar_url}')`"
                                class="userAvatar display-block"
                                @click="goTo('/users/' + currentUser.slug, false)" />
                            <i
                                v-if="!isMenuOpen"
                                class="GlobalIcon-angle-down arrow color__icons" />
                            <a
                                v-if="isMenuOpen"
                                :href="'/users/' + currentUser.slug">{{ currentUser.public_display_name }}</a>
                            <div class="header__dropdown showDrop navDrop">
                                <a :href="'/users/' + currentUser.slug">{{ currentUser.public_display_name }}
                                    <i class="GlobalIcon-user" />
                                </a>
                                <a href="/dashboard">{{ $t('frontend.app.components.pageparts.header.user.dashboard') }}
                                    <i class="GlobalIcon-4cube" />
                                </a>
                                <div v-if="organizations && organizations.length > 1" class="header__organization__limitHeight">
                                    <a
                                        v-if="currentOrganization"
                                        :href="getOrganizationPath">
                                        <div class="header__organization">
                                            <div class="header__organization__name">
                                                {{ currentOrganization.name }}
                                            </div>
                                            <m-icon
                                                class="header__organization__icon"
                                                size="0">GlobalIcon-check
                                            </m-icon>
                                            <div
                                                :style="`background-image: url('${currentOrganization.logo_url}')`"
                                                class="header__organization__logo" />
                                        </div>
                                    </a>
                                    <div
                                        v-for="organization in organizations"
                                        :key="organization.id">
                                        <a
                                            v-if="currentOrganization.id != organization.id"
                                            class="header__organization__submenu"
                                            href="#"
                                            @click="setCurrentOrganization(organization)">
                                            <div class="header__organization">
                                                <div class="header__organization__name">
                                                    {{ organization.name }}
                                                </div>
                                                <div
                                                    :style="`background-image: url('${organization.logo_url}')`"
                                                    class="header__organization__logo" />
                                            </div>
                                        </a>
                                    </div>
                                </div>
                                <a
                                    v-else-if="currentOrganization"
                                    :href="getOrganizationPath">
                                    <div class="header__organization">
                                        <div class="header__organization__name">
                                            {{ currentOrganization.name }}
                                        </div>
                                        <div
                                            :style="`background-image: url('${currentOrganization.logo_url}')`"
                                            class="header__organization__logo" />
                                    </div>
                                </a>
                                <a href="/profile/edit_general">{{ $t('frontend.app.components.pageparts.header.user.settings') }}
                                    <i class="GlobalIcon-settings" />
                                </a>
                                <a
                                    v-if="this.currentUser.platform_role == 'platform_owner' || credentialsAbility && credentialsAbility.can_view_revenue_report"
                                    href="/reports/network_sales_reports">{{ $t('frontend.app.components.pageparts.header.user.reports') }}
                                    <i class="GlobalIcon-info-square" />
                                </a>
                                <a
                                    v-if="help_page"
                                    href="/pages/help-center">{{ $t('frontend.app.components.pageparts.header.user.help') }}
                                    <i class="GlobalIcon-help" />
                                </a>
                                <!-- <a
                                    href="/my_feed">{{ $t('frontend.app.components.pageparts.header.user.my_feed') }}
                                    <i class="GlobalIcon-list" />
                                </a> -->
                                <a
                                    href="/users/sign_out"
                                    @click="logout">{{ $t('frontend.app.components.pageparts.header.user.logout') }}
                                    <i class="GlobalIcon-exit" />
                                </a>
                            </div>
                        </div>
                    </div>
                    <div
                        v-if="!sessionsList"
                        class="header__accountMenu">
                        <div
                            :class="{active: isNavOpen}"
                            class="showNav full__width">
                            <a
                                v-if="credentialsAbility && credentialsAbility.can_create_session"
                                :href="newSessionLink"
                                @click="goLive">{{ $t('frontend.app.components.pageparts.header.sessions_create.go_live') }}
                                <i class="GlobalIcon-stream-video" />
                            </a>
                            <a
                                v-if="currentUser.can_create_session && credentialsAbility && credentialsAbility.can_start_session && credentialsAbility.can_create_session && subscriptionAbility.can_create_interactive_stream"
                                @click="openCIS">{{
                                                     $t('frontend.app.components.pageparts.header.sessions_create.fast_interactive')
                                                 }}
                                <i class="GlobalIcon-users" />
                            </a>
                            <a
                                v-if="credentialsAbility && credentialsAbility.can_upload_recording"
                                href="/dashboard/uploads">{{
                                                              $t('frontend.app.components.pageparts.header.sessions_create.upload')
                                                          }}
                                <i class="GlobalIcon-upload" />
                            </a>
                        </div>
                        <a href="/dashboard">{{ $t('frontend.app.components.pageparts.header.user.dashboard') }}
                            <i class="GlobalIcon-4cube" />
                        </a>
                        <div
                            v-if="organizations && organizations.length > 1"
                            class="header__organization__wrapper">
                            <a
                                v-if="currentOrganization"
                                :href="getOrganizationPath">
                                <div class="header__organization">
                                    <div class="header__organization__name">
                                        {{ currentOrganization.name }}
                                    </div>
                                    <m-icon
                                        class="header__organization__icon"
                                        size="0">GlobalIcon-check
                                    </m-icon>
                                    <div
                                        :style="`background-image: url('${currentOrganization.logo_url}')`"
                                        class="header__organization__logo" />
                                </div>
                            </a>
                            <div
                                v-for="organization in organizations"
                                :key="organization.id">
                                <a
                                    v-if="currentOrganization.id != organization.id"
                                    class="header__organization__submenu"
                                    @click="setCurrentOrganization(organization)">
                                    <div class="header__organization">
                                        <div class="header__organization__name">
                                            {{ organization.name }}
                                        </div>
                                        <div
                                            :style="`background-image: url('${organization.logo_url}')`"
                                            class="header__organization__logo" />
                                    </div>
                                </a>
                            </div>
                        </div>
                        <a
                            v-else-if="currentOrganization"
                            :href="getOrganizationPath">
                            <div class="header__organization">
                                <div class="header__organization__name">
                                    {{ currentOrganization.name }}
                                </div>
                                <div
                                    :style="`background-image: url('${currentOrganization.logo_url}')`"
                                    class="header__organization__logo" />
                            </div>
                        </a>
                        <a href="/profile/edit_general">{{ $t('frontend.app.components.pageparts.header.user.settings') }}
                            <i class="GlobalIcon-settings" />
                        </a>
                        <a
                            v-if="this.currentUser.platform_role == 'platform_owner' || credentialsAbility && credentialsAbility.can_view_revenue_report"
                            href="/reports/network_sales_reports">{{ $t('frontend.app.components.pageparts.header.user.reports') }}
                            <i class="GlobalIcon-info-square" />
                        </a>
                        <a
                            v-if="help_page"
                            href="/pages/help-center">{{ $t('frontend.app.components.pageparts.header.user.help') }}
                            <i class="GlobalIcon-help" />
                        </a>
                        <a
                            href="#"
                            @click="logout">{{ $t('frontend.app.components.pageparts.header.user.logout') }}
                            <i class="GlobalIcon-exit" />
                        </a>
                    </div>
                </div>
                <div
                    v-else
                    class="header__right">
                    <div class="header__navWrapper">
                        <div class="header__unauthorizedUser">
                            <a
                                v-if="isWizardEnabled && !startCreatingOnlyAuthorizated"
                                :class="{focusHeaderSearch: focusSearchDelayed}"
                                class="header__wizardButton margin-r__20 margin-l__20 btn btn__main btn__normal text__uppercase"
                                :href="startCreatingLink">{{
                                    startCreatingName
                                }}</a>
                            <!--header__wizardButton will ignore custom styles if add .btn class-->
                            <m-btn
                                v-if="sign_up"
                                class="text__uppercase margin-r__20"
                                type="bordered"
                                @click="openSignUp">
                                {{ $t('frontend.app.components.pageparts.header.sign_up') }}
                            </m-btn>
                            <m-btn
                                class="text__uppercase"
                                type="bordered"
                                @click="openLogin">
                                {{ $t('frontend.app.components.pageparts.header.sign_in') }}
                            </m-btn>
                        </div>
                    </div>
                </div>
            </header>
            <div
                id="mobileHeader"
                :class="{pushLeft: isMenuOpen}"
                class="mobileHeader">
                <div
                    class="mobileHeader__wrapper">
                    <div
                        v-if="back_to_home"
                        v-tooltip="'Back to homepage'"
                        class="header__back"
                        @click="goToHome()">
                        <m-icon
                            class="header__back__icon"
                            size="0">
                            GlobalIcon-home
                        </m-icon>
                    </div>
                    <div class="header__logo">
                        <a
                            v-if="!getOrganizationLogo2"
                            href="/">
                            <img
                                :src="$img[logo_size]"
                                alt
                                class="active">
                        </a>
                        <a
                            v-if="getOrganizationLogo2"
                            class="mobileHeader__customLogo"
                            href="/">
                            <img
                                :src="getOrganizationLogo2"
                                alt
                                class="active">
                        </a>
                    </div>
                    <div
                        v-if="!enterprise"
                        v-click-outside="focusout"
                        :class="{MbSearch: mobileSearch}"
                        class="mobileHeader__search"
                        @click="goToSearch()"
                        @keypress.enter="onSearch">
                        <div class="input__block__search">
                            <input
                                v-model="search"
                                placeholder="Search"
                                type="text">
                            <div
                                class="respSearch"
                                @click="openMobileSearch()">
                                <i class="GlobalIcon-Search" />
                            </div>
                        </div>
                    </div>
                </div>
                <div class="mobileHeader__join_btn_menu_toggle_wrap">
                    <!-- <template v-if="nearestSession">
            <m-btn v-if="millisecondsToSesions <= 0"
            v-show="!mobileSearch"
            @click="join"
            @click.middle="join"
            :class="{focusHeaderSearch: focusSearch}"
            type="main"
            size="s"
            class="btn header__joinButton margin-r__15">
              {{$t('frontend.app.components.pageparts.header.join')}}
            </m-btn>
            <div v-else
            v-show="!mobileSearch"
            class="header__status__next_session"
            :class="{focusHeaderSearch: focusSearch}">
              {{$t('frontend.app.components.pageparts.header.next')}} {{millisecondsToSesions | timeToSession}}
            </div>
          </template> -->

                    <!-- <join class="3" @toggle="sessionsListToggle" /> -->

                    <div
                        class="mobileHeader__toggleMenu"
                        @click="toggleMenu">
                        <span />
                        <span />
                        <span />
                    </div>
                </div>
            </div>
        </div>
        <div class="header__headerFix" />
        <div
            id="overlay"
            :class="{active: isMenuOpen}"
            class="site-overlay"
            @click="toggleMenu" />
        <m-modal
            ref="messageModal"
            class="messageModal">
            <template v-if="conversation">
                <div class="">
                    <div
                        v-if="conversation.messages.length"
                        class="fs__16 padding-b__15">
                        {{ conversation.messages[0].subject }}
                    </div>
                    <div
                        v-for="message in conversation.messages"
                        :key="message.id"
                        class="messageModal__item">
                        <div>
                            <span>{{ message.sender.public_display_name }}</span>
                            <span>[ <timeago :datetime="message.created_at" /> ]</span>
                        </div>
                        <div
                            class="break-word"
                            v-html="message.body" />
                    </div>
                </div>
            </template>
        </m-modal>
    </div>
</template>

<script>
import axios from "@plugins/axios.js"
import ClickOutside from "vue-click-outside"
import {deleteCookie, getCookie, setCookie} from "@utils/cookies"
import eventHub from "@helpers/eventHub.js"

import Notification from '@models/Notification'
import Conversation from '@models/Conversation'
import NearestSession from '@models/NearestSession'
import Organization from '@models/Organization'
import User from "@models/User"

import NotificationTile from '@components/pageparts/NotificationTile'
import MessageTile from '@components/pageparts/MessageTile'
import ConversationGroup from '@components/pageparts/im-conversation/ConversationGroup'
import ModalForm from '../modals/CIS/ModalForm.vue'
import MIcon from '../../uikit/MIcon.vue'
import Join from './Join.vue'
import CurrentUserPlaceholder from './placeholders/CurrentUserPlaceholder.vue'
import AuthModal from '../modals/AuthModal.vue'
import MFlashMessage from '@uikit/MFlashMessage.vue'
import Vue from 'vue/dist/vue.esm'

import SubsPlansTemplate from '@components/modals/SubscriptionPlans'
import planInfo from '@components/modals/planInfo'

export default {
    directives: {
        ClickOutside
    },
    components: {
        NotificationTile,
        MessageTile,
        ModalForm,
        MIcon,
        Join,
        CurrentUserPlaceholder,
        AuthModal,
        MFlashMessage,
        ConversationGroup,
        SubsPlansTemplate,
        planInfo
    },
    data() {
        return {
            // let it snow
            snowRun: false,
            // let it snow
            isScrolled: false,
            sign_up: true,
            help_page: false,
            search: "",
            mobileSearch: false,
            instant_messaging_globalConfig: false, //check for global config, default false
            isMenuOpen: false,
            isNavOpen: false,
            isSearchOpen: false,
            conversationId: null,
            showUserDropdown: false,
            focusSearch: false,
            focusSearchDelayed: false,
            _focusSearchDelayedTimeout: null,
            notificationOptions: {
                loaded: false,
                requestParams: {
                    limit: 10,
                    offset: 0
                }
            },
            conversationOptions: {
                loaded: false,
                requestParams: {
                    limit: 10,
                    offset: 0
                }
            },
            millisecondsToSesions: 0,
            resendEmailBtnText: this.$t('frontend.app.components.pageparts.header.rewrite_email'),
            organizationLogo: null,
            isCustomChannelLink: false,
            channelFromId: null,
            enterprise: false,
            sessionsList: false,
            loading: true,
            loaded: false,
            validSinupToken: null
        }
    },
    computed: {
        back_to_home() {
            return this.home_banner && location.pathname != '/' && this.getOrganizationLink != '/'
        },
        home_banner() {
            return this.$railsConfig.frontend.home_banner
        },
        logo_size() {
            let config = this.$railsConfig.frontend.logo_size
            return config == 'default' ? 'logo' : ('logo_' + config)
        },
        logoName() {
            return this.$railsConfig.global.project_name || null
        },
        isWizardEnabled() {
            return (this.$railsConfig.global.wizard.enabled && !this.currentUser) ||
                    (this.$railsConfig.global.wizard.enabled && this.currentUser?.start_creating) ||
                    (this.currentUser?.can_use_wizard) ||
                    (this.validSinupToken)
        },
        credentialsAbility() {
            return this.currentUser.credentialsAbility
        },
        subscriptionAbility() {
            return this.currentUser.subscriptionAbility
        },
        notifications() {
            return Notification.query().orderBy('created_at', 'desc').get()
        },
        nearestSession() {
            return NearestSession.query().last()
        },
        conversation() {
            return Conversation.query().with('messages').find(this.conversationId)
        },
        conversations() {
            return Conversation.query().orderBy('created_at', 'desc').with('messages').get()
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        organizations() {
            return this.$store.getters["Users/organizations"]
        },
        pageOrganization() {
            return this.$store.getters["Users/pageOrganization"]
        },
        getOrganizationLink() {
            if (this.pageOrganization) return this.pageOrganization.logo_link
            if (["/dashboard", "/reports"].some(e => location.pathname.includes(e)) && this.currentOrganization && this.currentOrganization.logo_link) return this.currentOrganization.logo_link
            if (window.Immerss?.session && this.isCustomChannelLink) return location.origin + window.Immerss.session.organizer_path
            if (window.Immerss?.recording && this.isCustomChannelLink) return location.origin + window.Immerss.recording.organizer_path
            else return '/'
        },
        getOrganizationLogo2() {
            let blackListByPart = ["/pages"]
            if(blackListByPart.some(p => location.pathname.includes(p))) return null

            if (this.pageOrganization) return this.pageOrganization.custom_logo_url
            if (this.$route.matched.find(e => e.name === "dashboard") && this.organizationLogo !== '') return this.organizationLogo
            if (location.pathname.includes("/dashboard/") && this.organizationLogo !== '') return this.organizationLogo
            // for video pages
            let blackList = ["/", "/landing", "/pricing"]
            let blackListPart = ["/users/"]
            if (!blackList.includes(location.pathname) &&
                !blackListPart.find(e => location.pathname.includes(e)) &&
                this.organizationLogo !== '') {
                return this.organizationLogo
            }
            return null
        },
        getOrganizationPath() {
            if (!this.currentOrganization) return null
            return location.origin + this.currentOrganization.relative_path
        },
        newSessionLink() {
            return this.channelFromId ? `/sessions/new?channel_from_id=${this.channelFromId}` : '/sessions/new'
        },
        isShowOnMonolithPage() {
            let flag = true
            if (window.spaMode === "monolith") {
                if (!this.currentUser) {
                    let landings = ["enklav", "morphx"]
                    if (document.body.classList.contains("home-landing") &&
                        landings.find(page => document.body.classList.contains(page))) {
                        flag = false
                    }
                }
            }
            return flag
        },
        startCreatingName() {
            if(this.currentUser && this.currentUser?.become_creator_title != "START CREATING") {
                return this.currentUser.become_creator_title
            }
            let name = this.$t('frontend.app.components.pageparts.header.start_creating')
            if(this.$railsConfig.frontend?.start_creating_link?.name) {
                if(this.$t(this.$railsConfig.frontend.start_creating_link.name)) name = this.$t(this.$railsConfig.frontend.start_creating_link.name)
                else name = this.$railsConfig.frontend.start_creating_link.name
            }
            return name
        },
        startCreatingLink() {
            if(this.currentUser && this.currentUser?.become_creator_link != "/landing") {
                return this.currentUser?.become_creator_link
            }
            let link = "/landing"
            if(this.$railsConfig.frontend?.start_creating_link?.link) {
                link = this.$railsConfig.frontend?.start_creating_link?.link
            }
            return link
        },
        startCreatingOnlyAuthorizated() {
            let only_authorizated = false
            if(this.$railsConfig.frontend?.start_creating_link) {
                only_authorizated = this.$railsConfig.frontend?.start_creating_link?.only_authorizated
            }
            return only_authorizated
        }
    },
    watch: {
        currentUser(val) {
            if (val) {
                this.$nextTick(() => {
                    this.loading = false
                })

                setTimeout(() => {
                    this.checkSignUpToken()
                    this.checkMoreInfo()
                }, 500)
            }
        },
        nearestSession(val) {
            if (val) {
                this.updateMillisecondsToSesions()
                this.counterStarter()
            }
        }
    },
    mounted() {
        let _24hInMills = 86400000
        this.enterprise = this.$railsConfig.global.enterprise
        this.sign_up = this.$railsConfig.global.sign_up.enabled
        this.help_page = this.$railsConfig.global.pages.help
        this.instant_messaging_globalConfig = this.$railsConfig.global.instant_messaging.enabled //check for chat enabled in global config, default false

        if (this.$device.android()) {
            let searchField = document.querySelector('.mobileHeader__search input')
            searchField.addEventListener('input', (e) => {
                this.search = e.target.value
            })
        }
        window.addEventListener('scroll', () => {
            this.isScrolled = window.scrollY > 0
        })
        this.logo_link = location.origin

        window.addEventListener('resize', () => {
            if (this.isMenuOpen && window.innerWidth > 768) {
                this.isMenuOpen = false
                eventHub.$emit("isMobileMenuSwitched", this.isMenuOpen)
            }
        })
        if (window.loadedOrganizationLogo !== '') {
            this.organizationLogo = window.loadedOrganizationLogo
            this.loaded = true
        }
        this.isCustomChannelLink = window.isCustomChannelLink === 'true' ? true : false

        this.$eventHub.$on('channel-page-channel-retrieved', (data) => {
            this.channelFromId = data.channelId
        })

        if (location.pathname === "/users/invitation/accept") {
            this.$eventHub.$emit("open-modal:auth", "sign-up", null, {backdrop: false})
        }

        window.addEventListener('storage', function (e) {
            if (e.key === "_unite_session_uid") {
                setTimeout(() => {
                    location.reload()
                }, 3000)
            }
        })

        window.flash = this.$refs["flash"].flash
        Vue.prototype.$flash = this.$refs["flash"].flash

        let flashMessage = getCookie("flash_message")
        if (flashMessage) {
            let fm = JSON.parse(flashMessage)
            this.$flash(fm.message, fm.type)
        }

        this.$eventHub.$on("currentUser:null", () => {
            this.loading = false
            this.checkSignUpToken()
        })

        setTimeout(() => {
            if (this.currentUser) {
                this.fetchNotifications().then(() => {
                    this.fetchConversation().then(() => {
                        NearestSession.api().GET()
                    })
                })
            }
        }, 1000)

    },
    methods: {
        setCurrentOrganization(company) {
            let result = confirm("Your current organization will be changed?")
            if (result) {
                Organization.api().setCurrentOrganization({id: company.id}).then(() => {
                    if(company.user_id != this.currentUser.id) {
                        location.href = location.origin + company.relative_path
                    }
                    else {
                        location.reload()
                    }
                }).catch(error => {
                    if (error?.response?.data?.message) {
                        this.$flash(error.response.data.message)
                    } else {
                        this.$flash('Something went wrong please try again later')
                    }
                })
            }

        },
        openCIS() {
            eventHub.$emit('openModalCIS')
        },
        goLive() {
            if (!this.currentUser.confirmed_at) {
                this.$flash('You have to confirm your email address before continuing', "warning", 6000)
            } else {
                this.goTo(this.newSessionLink)
            }
        },
        goToHome() {
            this.goTo('/')
        },
        goToSearch() {
            if (this.search.length > 0 || this.search !== '') {
                this.goTo('/search?utf8=✓&fq=' + this.search)
            }
        },
        toggleMenu() {
            this.isMenuOpen = !this.isMenuOpen
            eventHub.$emit("isMobileMenuSwitched", this.isMenuOpen)
            this.focusSearch = false
            this.search = ''
            this.sessionsList = false
        },
        openMobileSearch() {
            this.mobileSearch = true
        },
        focusout() {
            this.mobileSearch = false
        },
        toggleNav() {
            this.isNavOpen = !this.isNavOpen
            this.$eventHub.$emit("ToggleJoin", this.isNavOpen)
            this.sessionsList = false
        },
        openSearch() {
            this.isSearchOpen = !this.isSearchOpen
        },
        openMessageModal(conversationId) {
            Conversation.api().fetchOne(conversationId).then(() => {
                this.conversationId = conversationId
                this.$refs.messageModal.openModal()
            })
        },
        fetchNotifications(requestParams) {
            return new Promise((resolve, reject) => {
                Notification.api().fetch({...this.notificationOptions.requestParams, ...requestParams}).then((response) => {
                    this.notificationOptions.requestParams.offset += this.notificationOptions.requestParams.limit
                    this.notificationOptions.loaded = this.notificationOptions.requestParams.offset >= response.response.data.pagination?.count
                    resolve()
                })
            })
        },
        fetchConversation(requestParams) {
            return new Promise((resolve, reject) => {
                Conversation.api().fetch({...this.conversationOptions.requestParams, ...requestParams}).then((response) => {
                    this.conversationOptions.requestParams.offset += this.conversationOptions.requestParams.limit
                    this.conversationOptions.loaded = this.conversationOptions.requestParams.offset >= response.response.data.pagination?.count
                    resolve()
                })
            })
        },
        markNotificationsAsRead() {
            Notification.api().mark_as_read({id: 'all'}).then(response => {
                Notification.update({
                    where: record => response.response.data.message?.includes(record.id),
                    data: {is_read: true}
                })
                this.$store.commit('Users/UPDATE_NOTIFICATIONS_COUNT', 0)
            })
        },
        clearAll() {
            Notification.api().remove({id: 'all'}).then(() => {
                Notification.create({data: []})
            })
        },
        openSignUp() {
            this.$eventHub.$emit("open-modal:auth", "sign-up")
        },
        openLogin() {
            this.$eventHub.$emit("open-modal:auth", "login")
        },
        logout() {
            User.api().logout().then(() => {
                this.$flash(this.$t("frontend.app.components.pageparts.header.user.logout_message"), "success")
                setCookie("flash_message", JSON.stringify({
                    message: this.$t("frontend.app.components.pageparts.header.user.logout_message"),
                    type: "success"
                }), new Date().getTime() + 10000)

                let env = this.$railsConfig.global.env.toLowerCase()
                deleteCookie("_unite_session_jwt")
                deleteCookie("_cable_jwt")
                deleteCookie("_unite_session_jwt_refresh")
                this.$eventHub.$emit("logout")
                localStorage.setItem("_unite_session_uid", null)
                localStorage.setItem("last_conversation_user_id", -1)
                if (env === 'production') {
                    deleteCookie(`_${this.$railsConfig.global.project_name.toLowerCase()}_session`)
                    deleteCookie(`_${this.$railsConfig.global.project_name.toLowerCase()}_n_session`)
                } else {
                    deleteCookie(`_${this.$railsConfig.global.project_name.toLowerCase()}_${env}_session`)
                    deleteCookie(`_${this.$railsConfig.global.project_name.toLowerCase()}_${env}_n_session`)
                }
                this.$store.dispatch("Users/setCurrents", null)
                Notification.create({data: []})
                Conversation.create({data: []})
                NearestSession.create({data: []})
            })
        },
        onSearch() {
            window.location = location.origin + "/search?utf8=✓&fq=" + this.search
        },
        updateMillisecondsToSesions() {
            if (this.nearestSession?.start_at) {
                let tz = this.currentUser.manually_set_timezone || 'Europe/London'
                this.millisecondsToSesions = moment(this.nearestSession.start_at).tz(tz) - moment().tz(tz)
            }
        },
        counterStarter() {
            let _24hInMilliseconds = 86400000
            if (this.millisecondsToSesions < _24hInMilliseconds) {
                let interval = setInterval(() => {
                    this.updateMillisecondsToSesions()
                    if (this.millisecondsToSesions <= 0) {
                        clearInterval(interval)
                    }
                }, 1000)
            }
        },
        join() {
            if (!this.nearestSession.presenter && this.nearestSession.type == "livestream") {
                this.goTo(this.nearestSession.relative_path)
            } else if (this.nearestSession.service_type == 'zoom') {
                this.goTo(this.nearestSession.show_page_paths[0], true)
            } else {
                if (this.$device.mobile() && this.$device.ios()) {
                    this.goTo(this.nearestSession.show_page_paths[0], true)
                }
                axios.get(this.nearestSession.existence_path)
                    .then(() => {
                        window.open(
                            this.nearestSession.show_page_paths[0],
                            'Live Session',
                            `width=${parseInt(screen.width - screen.width * 0.1)},
            height=${parseInt(screen.height - screen.height * 0.1)},
            top=${parseInt(screen.height * 0.1 / 2)},
            left=${parseInt(screen.width * 0.1 / 2)},
            resizable=yes,
            scrollbars=yes,
            status=no,
            menubar=no,
            toolbar=no,
            location=no,
            directories=no`
                        )
                    })
                    .catch(error => {
                        if (error?.response?.data?.message) {
                            this.$flash(error.response.data.message)
                        } else {
                            this.$flash(this.$t('frontend.app.uikit.m_blocking_message.wrong'))
                        }
                    })
            }
        },
        resendEmailConfirmation() {
            this.resendEmailBtnText = this.$t('frontend.app.components.pageparts.header.resending_instructions')
            axios.post('/api/v1/user/confirmations').then(() => {
                this.$flash(this.$t('frontend.app.components.pageparts.header.check_inbox'), 'success')
                this.resendEmailBtnText = this.$t('frontend.app.components.pageparts.header.rewrite_email')
            }).catch(() => {
                this.$flash(this.$t('frontend.app.uikit.m_blocking_message.wrong'))
                this.resendEmailBtnText = this.$t('frontend.app.components.pageparts.header.rewrite_email')
            })
        },
        toggleHoverSearch(boolean) {
            if (boolean) {
                clearTimeout(this._focusSearchDelayedTimeout)
                this.focusSearch = boolean
                this.focusSearchDelayed = boolean
            } else {
                this.focusSearch = boolean
                this._focusSearchDelayedTimeout = setTimeout(() => {
                    this.focusSearchDelayed = boolean
                }, 500)
            }
        },
        sessionsListToggle(flag) {
            this.sessionsList = flag
            if (flag) {
                this.isNavOpen = false
            }
        },
        getUrlParams() {
            return window.location.search.slice(1)
                .split('&')
                .reduce(function _reduce(/*Object*/ a, /*String*/ b) {
                    b = b.split('=')
                    a[b[0]] = decodeURIComponent(b[1])
                    return a
                }, {})
        },
        checkSignUpToken() {
            let urlParams = this.getUrlParams()
            if(urlParams.signup_token) {
                User.api().checkSignUpToken({signup_token: urlParams.signup_token}).then(res => {
                    let token = res.response.data.response?.signup_token?.token
                    this.validSinupToken = token
                    if(token && this.currentUser) {
                        User.api().useSignUpToken({signup_token: {token}})
                    }
                    if(token && !this.currentUser) {
                        this.$eventHub.$emit("open-modal:auth", "sign-up", {action: 'redirect-to-wizard'}, {mode: "with-email"})
                    }
                })
            }
            if(urlParams.token && !this.currentUser) {
                this.$eventHub.$emit("open-modal:auth", "sign-up")
            }
            if(urlParams.wizard) {
                this.$eventHub.$emit("open-modal:auth", "sign-up", {action: 'redirect-to-wizard'})
            }
        },
        checkMoreInfo() {
            this.$eventHub.$emit("open-modal:auth", "more-info")
        }
    }
}
</script>

<style lang="scss">
    .header {
        &__search {
            margin-left: 4.4rem;
        }

        &__responsiveNav {
            @media all and (max-width: 767px) {
                font-size: 1.9rem;
                position: relative;
                top: 0.5rem;
                left: 0.7rem;
            }
        }

        &__dropdown {
            width: 23rem;

            a {
                padding-top: 1.4rem;
                padding-bottom: 1.4rem;
                font-size: 1.3rem !important;
            }

            i {
                font-size: 1.5rem;
            }
        }

        &__counter:before {
            right: -1.8rem;
        }

        .userAvatarDropdown {
            margin-left: 1.6rem;
            margin-right: 1.5rem;
        }
    }
</style>
