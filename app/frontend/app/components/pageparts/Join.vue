<template>
    <div
        v-if="sessions.length"
        class="header__status__sessionsList">
        <m-btn
            class="btn header__joinButton menu_btn"
            size="s"
            type="main"
            @click="OpenSessionsList()">
            {{ haveLive ? $t('frontend.app.components.pageparts.join.join_session') : $t('frontend.app.components.pageparts.join.upcoming_session') }}
            <i
                :class="{active : sessionListOpen}"
                class="GlobalIcon-angle-down" />
        </m-btn>
        <div
            v-if="sessionListOpen"
            class="header__sessionsList__Wrapper">
            <label>{{ $t('frontend.app.components.pageparts.join.live_sessions') }}</label>
            <div class="header__sessionsList">
                <a
                    v-for="session in sessions"
                    :key="session.session.id"
                    class="header__sessionsList__item"
                    :href="session.session.url"
                    target="_blank" >
                    <!-- <i class="GlobalIcon-clear"></i> -->
                    <div class="logo__m avatar">
                        <img
                            :src="session.presenter.avatar_url"
                            @click.prevent="openUser(session.presenter)">
                    </div>
                    <div class="header__sessionsList__item__body">
                        <b @click.prevent="openUser(session.presenter)">{{ session.presenter.display_name }}</b> <span
                            v-if="canJoinNow(session)">is now live!</span>
                        <div class="header__sessionsList__item__bottom">
                            <a>{{ session.session.always_present_title }}</a>
                            <div class="buy">
                                <span><timeago
                                    :auto-update="10"
                                    :datetime="session.session.start_at" /></span>
                                <div class="costAndJoin">
                                    <div
                                        v-if="!session.session.livestream_free || session.session.immersive_purchase_price"
                                        class="chips__dollar">
                                        $
                                    </div>
                                    <m-btn
                                        v-if="canJoinNow(session)"
                                        type="main"
                                        @click.prevent="join(session)">
                                        {{ $t('frontend.app.components.pageparts.join.join') }}
                                    </m-btn>
                                </div>
                            </div>
                            <div class="AcceptDecline">
                                <!-- <m-btn type="main" @click="join(session)">Accept</m-btn> -->
                                <!-- <m-btn type="bordered" @click="join(session)">Decline</m-btn> -->
                            </div>
                        </div>
                    </div>
                </a>
            </div>
        </div>
    </div>
</template>

<script>
import Session from "@models/Session"
import ClickOutside from "vue-click-outside"

export default {
    directives: {
        ClickOutside
    },
    data() {
        return {
            sessionListOpen: false,
            sessions: [],
            time: new Date(),
            haveLive: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.checkLive()
        setInterval(() => {
            this.time = new Date()
        }, 2000)
        this.load()
        this.$eventHub.$on("ToggleJoin", (flag) => {
            if (flag) {
                this.sessionListOpen = false
            }
        })
    },
    methods: {
        OpenSessionsList() {
            this.sessionListOpen = !this.sessionListOpen
            this.$emit("toggle", this.sessionListOpen)
            if (this.sessionListOpen) this.load()
        },
        load() {
            Session.api().getSessionsForUser().then(res => {
                this.sessions = res.response.data.response
            })
        },
        close() {
            this.sessionListOpen = false
        },
        join(session) {
            if (this.canJoinButtonNow(session)) {
                let url = "/rooms/" + session.room.id
                if (session.zoom_meeting && session.zoom_meeting.join_url)
                    url = session.zoom_meeting.join_url

                if (this.$device.mobile() && this.$device.ios() || session.room.service_type == 'zoom') {
                    this.goTo(url, true)
                } else {
                    window.open(
                        url,
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
                }
            } else {
                location.href = session.session.url
            }
        },
        canJoinNow(session) {
            let preTime = session.session?.pre_time ? session.session.pre_time * 60 * 1000 : 0
            if(session.role !== "presenter") preTime = 0
            return (new Date(session.session.start_at) - preTime) < this.time
            // return session.session.start_now ||
        },
        canJoinButtonNow(session) {
            if (session.session.service_type !== "webrtcservice" && this.currentUser && this.currentUser?.id === session?.presenter?.id) return true
            if (session.session.service_type === "webrtcservice") return true
            return false
        },
        openUser(user) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: user
            })
        },
        checkLive() {
            setInterval(() => {
                let flag = false
                this.sessions.forEach(session => {
                    if(this.canJoinNow(session)) flag = true
                })
                this.haveLive = flag
            }, 2000)
        }
    }
}
</script>

