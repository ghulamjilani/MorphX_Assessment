<template>
    <div
        v-if="exit"
        class="client__header__info__exit__modal__wrapper">
        <div class="client__header__info__exit__modal">
            <div>
                <div class="client__header__info__exit__modal__text">
                    {{ $t('frontend.app.pages.video_client.header_exit_modal.exit_session') }}
                </div>
                <div
                    v-if="isPresenter"
                    class="client__header__info__exit__modal__buttons">
                    <m-btn
                        type="secondary"
                        @click="close">
                        {{ $t('frontend.app.pages.video_client.header_exit_modal.leave_session') }}
                    </m-btn>
                    <m-btn
                        type="save"
                        :disabled="isEndSession"
                        @click="stop">
                        {{ $t('frontend.app.pages.video_client.header_exit_modal.end_session') }}
                    </m-btn>
                </div>
                <div
                    v-else
                    class="client__header__info__exit__modal__buttons">
                    <m-btn
                        type="secondary"
                        @click="close">
                        {{ $t('frontend.app.pages.video_client.header_exit_modal.leave_session') }}
                    </m-btn>
                    <m-btn
                        type="save"
                        @click="closeModal">
                        {{ $t('frontend.app.pages.video_client.header_exit_modal.cancel') }}
                    </m-btn>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import Room from "@models/Room"

export default {
    props: {
        exit: Boolean,
        roomInfo: Object
    },
    data() {
        return {
            isEndSession: false
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        }
    },
    methods: {
        close() {
            window.onbeforeunload = null
            window.opener = self
            window.close()
            location.href = location.origin
        },
        stop() {
            this.isEndSession = true
            window.onbeforeunload = null
            Room.api().closeRoom({id: this.roomInfo.id}).then(res => {
                this.close()
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        closeModal() {
            this.$emit("close")
        }
    }
}
</script>