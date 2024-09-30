<template>
    <div class="modal-auth-template GuestLogin">
        <div class="GuestLogin__image">
            <guest-image />
        </div>
        <div class="GuestLogin__welcome">
            {{ $t('frontend.app.components.modals.template.guest_template.welcome', {service_name: service_name}) }}
        </div>
        <m-form
            ref="guestName"
            v-model="disabled"
            :form="user"
            @onSubmit="enter">
            <m-input
                v-if="guestEnabled"
                v-model="user.name"
                :errored="error && disabled"
                :pure="true"
                :required="true"
                rules="required"
                autocomplete="off"
                class="fs__16"
                placeholder="Enter your guest name"
                type="text" />
            <m-btn
                v-if="guestEnabled"
                :disabled="disabled || forceDisabled"
                :full="true"
                class="fs__16 margin-t__20 disabledButton"
                size="l"
                type="main">
                {{ $t('frontend.app.components.modals.template.guest_template.enter_as_guest') }}
            </m-btn>
        </m-form>
        <div
            v-if="guestEnabled"
            class="GuestLogin__title margin-b__15 margin-t__15 text__center fs__16">
            {{ $t('frontend.app.components.modals.template.guest_template.or') }}
        </div>

        <!-- if  not guest openLogin-->
        <div
            v-if="guestEnabled"
            class="text__center">
            <button
                :full="true"
                class="fs__16 btn__reset color__main color__active"
                @click="openLogin">
                {{ $t('frontend.app.components.modals.template.guest_template.log_in') }}
            </button>
        </div>
        <m-btn
            v-else
            :full="true"
            class="fs__16"
            size="l"
            @click="openLogin">
            {{ $t('frontend.app.components.modals.template.guest_template.log_in') }}
        </m-btn>
        <!-- if guest openLogin-->
    </div>
</template>

<script>
import {getCookie, setCookie} from "@utils/cookies"
import Room from "@models/Room"
import User from '@models/User'
import GuestImage from "./GuestImage"

export default {
    components: {
        GuestImage
    },
    props: {
        afterSignAction: Object
    },
    data() {
        return {
            user: {
                name: ""
            },
            disabled: true,
            forceDisabled: false,
            errorMessage: "Name",
            error: false,
            service_name: null,
            guestEnabled: false
        }
    },
    watch: {
        "user.name": {
            handler(val) {
                this.error = false
                this.forceDisabled = false
            }
        }
    },
    mounted() {
        this.service_name = this.$railsConfig.global.service_name

        if(getCookie('current_guest_name')) {
            this.user.name = getCookie('current_guest_name')
            this.$nextTick(() => {
                this.$refs?.guestName?.isInvalid(true)
            })
        }

        Room.api().checkGuestEnabled({token: this.$route.params.token}).then(res => {
            this.guestEnabled = res?.response?.data?.response?.interactive_access_token?.guests
            this.$emit("guestEnabled", this.guestEnabled)
        }).catch(err => {
        })
    },
    methods: {
        openLogin() {
            this.$emit("change", "login")
        },
        enter() {
            let token = this.$route.params.token
            // Ensure we have guest token + set new name
            User.api().createGuestJwt({
                visitor_id: getCookie("visitor_id"),
                public_display_name: this.user.name
            }).then(res => {
                setCookie('current_guest_id', res.response.data.response.guest.id, new Date(res.response.data.response.jwt_exp).getTime())
                setCookie('current_guest_name', res.response.data.response.guest.public_display_name, new Date(res.response.data.response.jwt_exp).getTime())
                setCookie('_guest_jwt', res.response.data.response.jwt_token, +(parseJwt(res.response.data.response.jwt_token)?.exp + '000'))
                setCookie('_guest_jwt_refresh', res.response.data.response.jwt_token_refresh, +(parseJwt(res.response.data.response.jwt_token_refresh)?.exp + '000'))
                this.$store.dispatch('Users/setCurrentGuest', res.response.data.response.guest)
                this.$eventHub.$emit("updateJwt")

                Room.api().joinByToken({token, isGuest: true}).then(res => {
                    if (this.afterSignAction.action == 'close-and-emit-res') {
                        this.$emit("close")
                        let current_room_member = res.response.data.response.room.current_room_member
                        this.$eventHub.$emit(this.afterSignAction.event, current_room_member)
                        this.$store.dispatch("VideoClient/setRoomMember", current_room_member)
                    }
                }).catch(error => {
                    this.disabled = true
                    this.error = true
                    if (error?.response?.data?.message?.error) this.$eventHub.$emit("flash-client", error?.response?.data?.message?.error)
                    else if (error?.response?.data?.message) this.$eventHub.$emit("flash-client", error?.response?.data?.message)
                    else {
                        this.$eventHub.$emit("flash-client", "Sorry, guests are not allowed in this session, please login")
                    }
                    setTimeout(() => {
                        window.onbeforeunload = null
                        window.opener = self
                        location.href = location.origin
                    }, 2000)
                })
            }).catch(error => {
                this.disabled = true
                this.error = true
                if (error?.response?.data?.message?.error) this.$flash(error?.response?.data?.message?.error)
                else if (error?.response?.data?.message) this.$flash(error?.response?.data?.message)
                else {
                    this.$flash("Sorry, guests are not allowed in this session, please login")
                }
                setTimeout(() => {
                    window.onbeforeunload = null
                    window.opener = self
                    location.href = location.origin
                }, 2000)
            })
        }
    }
}
</script>
