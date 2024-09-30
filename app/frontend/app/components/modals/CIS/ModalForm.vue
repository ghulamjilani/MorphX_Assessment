<template>
    <m-modal
        id="cis"
        ref="cis">
        <div class="unobtrusive-flash-container" />
        <div class="cis">
            <div class="cis__image">
                <modal-image />
            </div>
            <div class="cis__form">
                <div class="cis__form__header">
                    {{ $t('components.modals.cis.modal_form.cis') }}
                </div>
                <m-form
                    ref="form"
                    v-model="disabled"
                    @onSubmit="createSession">
                    <m-input
                        v-model="title"
                        class="cis__form__title"
                        field-id="title"
                        label="Session Title *"
                        rules="required|min-length:6|max-length:80" />
                    <m-select
                        v-model="channel_id"
                        :options="options"
                        :with-image="true"
                        class="cis__form__channel"
                        label="Channel *"
                        placeholder="Select Channel"
                        rules="required"
                        type="default" />
                    <div class="cis__form__duration">
                        <div class="cis__form__duration__title">
                            <m-icon
                                class="cis__form__icon"
                                size="1.6rem">
                                GlobalIcon-clock
                            </m-icon>
                            {{ $t('components.modals.cis.modal_form.duration') }}
                        </div>
                        <div class="cis__form__duration__range">
                            <vue-slider
                                v-model="duration"
                                :interval="5"
                                :max="sessionSettings.max_session_duration"
                                :min="15"
                                :tooltip="'none'"
                                class="rangeSlider"
                                style="width: 90%; height: .5rem; margin: auto;">
                                <template #process="{style}">
                                    <div
                                        :style="style"
                                        class="rangeSlider__process" />
                                </template>
                                <template #dot>
                                    <m-btn
                                        class="rangeSlider__dot"
                                        tag-type="button">
                                        {{ duration }} {{ $t('components.modals.cis.modal_form.min') }}
                                    </m-btn>
                                </template>
                            </vue-slider>
                        </div>
                    </div>
                    <div class="cis__form__row">
                        <div class="cis__form__row__left">
                            <m-icon
                                class="cis__form__icon"
                                size="1.6rem">
                                GlobalIcon-message-square
                            </m-icon>
                            {{ $t('components.modals.cis.modal_form.chat') }}
                        </div>
                        <div class="cis__form__row__right">
                            <m-toggle v-model="allow_chat" />
                        </div>
                    </div>
                    <div class="cis__form__row">
                        <div class="cis__form__row__left">
                            <m-icon
                                class="cis__form__icon"
                                size="1.6rem">
                                GlobalIcon-voicemail
                            </m-icon>
                            {{ $t('components.modals.cis.modal_form.record') }}
                        </div>
                        <div class="cis__form__row__right">
                            <m-toggle v-model="record" />
                        </div>
                    </div>
                    <rlayout
                        v-if="record"
                        v-model="recording_layout" />
                    <div class="cis__form__row">
                        <div class="cis__form__row__left">
                            <m-icon
                                class="cis__form__icon"
                                size="1.6rem">
                                GlobalIcon-users
                            </m-icon>
                            {{ $t('components.modals.cis.modal_form.participants') }}
                        </div>
                        <div class="cis__form__row__right">
                            <m-input
                                v-model="max_number_of_immersive_participants"
                                :max="sessionSettings.max_interactive_participants"
                                :min="1"
                                :number="true"
                                class="cis__form__participants"
                                field-id="participants"
                                type="number" />
                        </div>
                    </div>
                    <div class="cis__form__row">
                        <div class="cis__form__row__left">
                            <m-icon
                                class="cis__form__icon"
                                size="1.6rem">
                                GlobalIcon-lock
                            </m-icon>
                            {{ $t('components.modals.cis.modal_form.privacy') }}
                        </div>
                        <div class="cis__form__buttons">
                            <m-btn
                                :class="{'cis__form__button__active': !isPrivate}"
                                class="cis__form__button"
                                tag-type="button"
                                @click="setPrivacy(false)">
                                {{ $t('components.modals.cis.modal_form.public') }}
                            </m-btn>
                            <m-btn
                                :class="{'cis__form__button__active': isPrivate}"
                                class="cis__form__button"
                                tag-type="button"
                                :disabled="!canBePrivate"
                                @click="setPrivacy(true)">
                                {{ $t('components.modals.cis.modal_form.private') }}
                            </m-btn>
                        </div>
                    </div>
                    <div
                        v-if="!canBePrivate"
                        class="cis__form__text">
                        <m-icon
                            class="cis__form__icon"
                            style="color: var(--tp__inputs__validation);"
                            size="1.6rem">
                            GlobalIcon-info
                        </m-icon>
                        {{ $t('components.modals.cis.modal_form.free_limit_message') }}
                    </div>
                </m-form>
            </div>
        </div>
        <template #black_footer>
            <div class="cis__form__actions">
                <m-btn
                    class="cis__form__actions__cancel"
                    type="secondary"
                    @click="close()">
                    {{ $t('components.modals.cis.modal_form.cancel') }}
                </m-btn>
                <m-btn
                    :disabled="disabled"
                    :loading="loading"
                    class="cis__form__actions__start"
                    type="main"
                    @click="submit()">
                    {{ $t('components.modals.cis.modal_form.start_session') }}
                </m-btn>
            </div>
        </template>
    </m-modal>
</template>

<script>
import VueSlider from 'vue-slider-component'
import ModalImage from './ModalImage'
import User from "@models/User"
import eventHub from "@helpers/eventHub.js"
import Rlayout from '@components/replay-layout/Rlayout.vue'

export default {
    components: {ModalImage, VueSlider, Rlayout},
    data() {
        return {
            channels: [],
            options: [],
            channel_id: null,
            duration: null,
            allow_chat: false,
            record: false,
            max_number_of_immersive_participants: null,
            isPrivate: true,
            canBePrivate: true,
            disabled: false,
            loading: false,
            recording_layout: 'grid',
            sessionSettings: {},
            title: '',
            standartSessionSettings: {
                max_session_duration: 180,
                streaming_time: 10000,
                ppv: true,
                ip_cam: true,
                encoder: true,
                interactive_stream: true,
                instream_shopping: true,
                max_interactive_participants: 49
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    watch: {
        currentUser() {
            this.checkPrivate()
        }
    },
    mounted() {
        eventHub.$on('openModalCIS', () => {
            if (!this.currentUser.confirmed_at) {
                this.$flash('You have to confirm your email address before continuing', "warning", 6000)
            } else {
                this.open()
            }
        })
        this.checkPrivate()
    },
    methods: {
        getDefaultParams() {
            User.api().getDefaultSessionParams().then((res) => {
                this.duration = res.response.data.response.session.duration
                this.allow_chat = res.response.data.response.session.allow_chat
                this.record = res.response.data.response.session.record
                this.max_number_of_immersive_participants = res.response.data.response.session.max_number_of_immersive_participants
                this.isPrivate = true//res.response.data.response.session.private
                this.title = res.response.data.response.session.title
                let settings = res.response.data.response.feature_parameters
                if (settings) {
                    let jsonSettings = {}
                    settings.forEach(s => {
                        let val
                        switch (s.parameter_type) {
                            case "integer":
                                val = +s.value
                                break
                            case "boolean":
                                val = s.value == "true"
                                break
                            default:
                                val = s.value
                                break
                        }
                        jsonSettings[s.code] = val
                    })
                    this.sessionSettings = {...this.standartSessionSettings, ...jsonSettings}
                }
                // setup channels select
                this.channels = res.response.data.response.channels
                this.options = this.channels.map((e) => {
                    return {
                        name: e.title,
                        value: e.id,
                        image: e.logo_url,
                        is_default: e.is_default
                    }
                })
                if (this.options.length) {
                    let i = 0
                    this.options.map((o, index) => {
                        if (o.is_default) {
                            i = index
                        }
                    })
                    this.channel_id = this.options[i].value
                }
                this.checkPrivate()
            }).catch((error) => {
                let message = error.response.data.message['room.base'][0]
                if (message) {
                    this.$flash(message, "warning", 7000)
                } else {
                    this.$flash('Something went wrong please try again later', "warning", 2000)
                }
            })
        },
        setPrivacy(isPrivate) {
            this.isPrivate = isPrivate
        },
        submit() {
            this.$refs.form.onSubmit()
        },
        open() {
            this.getDefaultParams()
            this.$refs.cis.openModal()
        },
        close() {
            this.$refs.cis.closeModal()
        },
        createSession() {
            if (!this.currentUser) return
            if (!this.currentUser.confirmed_at) {
                return this.$flash('You have to confirm your email address before continuing', "warning", 6000)
            }
            this.loading = true
            User.api().createSession({
                channel_id: this.channel_id,
                title: this.title,
                duration: this.duration,
                allow_chat: this.allow_chat,
                record: this.record,
                max_number_of_immersive_participants: this.max_number_of_immersive_participants,
                private: this.isPrivate,
                recording_layout: this.recording_layout
            }).then((res) => {
                let room_id = res.response.data.response.room.id
                location.href = location.origin + "/rooms/" + room_id
            }).catch((error) => {
                let message = null
                if (error.response.data.message['room.base']) message = error.response.data.message['room.base'][0]
                if (error.response.data.message.business_plan) message = error.response.data.message.business_plan[0]
                if (message) {
                    this.$flash(message, "warning", 7000)
                } else {
                    this.$flash('Something went wrong please try again later', "warning", 2000)
                }
            }).then(() => {
                this.loading = false
            })
        },
        checkPrivate() {
            if(this.currentUser &&
            !this.currentUser.can_create_free_private_sessions_without_permission &&
            this.currentUser.free_private_sessions_without_admin_approval_left_count < 1) {
                this.isPrivate = false
                this.canBePrivate = false
            }
        }
    }
}
</script>

<style lang="scss">
@import 'vue-slider-component/theme/antd.css';
</style>